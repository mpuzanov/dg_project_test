-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE         PROCEDURE [dbo].[k_payings_serv_add5]
	  @paying_id INT -- код платежа
	, @debug BIT = 0
AS
/*
Процедура  раскидки платежа по услугам

Применяемая технология учитывает следующий приоритет при распределении платежа (в порядке снижения приоритета) в рамках лицевого счета:
1. текущие начисления;
2. задолженность на начало расчетного месяца за вычетом оплаты, учтенной в текущем расчетном периоде;
3. пени;


DECLARE	@return_value int
EXEC	@return_value = [dbo].[k_payings_serv_add5]
		@paying_id = 2128848, --495412 496920,
		@debug = 1
SELECT	'Return Value' = @return_value
GO

-- DELETE FROM [dbo].[PAYING_LOG] WHERE paying_id = @paying_id
*/
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @trancount INT;
	SET @trancount = @@trancount;

	DECLARE @debug_file BIT = 1 -- логирование работы в таблицу PAYING_LOG
		  , @Db_Name VARCHAR(20) = UPPER(DB_NAME())
		  , @msg_log VARCHAR(1000) = ''
		  , @msg_debug VARCHAR(1000) = ''
		  , @metod_name VARCHAR(100) = ''
		  , @metod_ostatok VARCHAR(50)

	DECLARE @fin_id SMALLINT -- код фин. периода в котором проходит платеж
		  , @fin_prev SMALLINT -- код предыдущего фин. периода
		  , @fin_current SMALLINT -- код текущего фин. периода
		  , @Fin_id_start SMALLINT -- код периода для выборки начислений за период
		  , @occ1 INT	-- лицевой счет
		  , @occ_sup1 INT	-- лицевой счет по поставщику
		  , @tip_id1 SMALLINT
		  , @err INT
		  , @Paymaccount DECIMAL(9, 2) --  оплата
		  , @service_paying VARCHAR(10) -- код услуги платежа 
		  , @forwarded BIT -- признак закрытия платежа
		  , @sup_id INT -- Код поставщика
		  , @date_paym SMALLDATETIME -- дата платежа
		  , @pack_id INT -- код пачки

	DECLARE @SumDolg DECIMAL(9, 2) -- сумма долга c учетом платежей до этого
		  , @SumSaldo DECIMAL(9, 2) -- сумма сальдо предыдущего периода
		  , @SumValue DECIMAL(9, 2) -- сумма начислений
		  , @SumPaid DECIMAL(9, 2) -- сумма постоянных начислений		  
		  , @SumPenaltyOld DECIMAL(9, 2) -- пени предыдущих периодов
		  , @SumDebt DECIMAL(9, 2) -- конечное сальдо
		  , @SumTotalPaid DECIMAL(9, 2) -- итого к оплате
		  , @PaymaccountDolg DECIMAL(9, 2) 
		  , @PaymaccountPeny DECIMAL(9, 2) 

		  , @ostatok DECIMAL(9, 2)
		  , @ostatokPeny DECIMAL(9, 2)
		  , @koef DECIMAL(16, 10) -- коэф. для раскидки по услугам
		  , @Paymaccount_peny DECIMAL(9, 2) = 0
		  , @Paym_start DECIMAL(9, 2) = 0 -- для проверки оплаты
		  , @Paym_avans DECIMAL(9, 2) = 0 -- сумма аванса из текущего платежа
		  , @Paymaccount_old DECIMAL(9, 2) = 0 -- оплата до текущего платежа
		  , @commission DECIMAL(9, 2) = 0
		  , @paying_vozvrat INT = NULL
		  , @build_id INT
		  , @paying_manual BIT = 0 -- ручное изменение по услугам
		  , @is_overpayment BIT = 0 -- есть услуги для раскидки переплаты
		  , @is_paying_saldo_no_paid BIT = 1 -- Не учитывать тек.начисление при оплате
		  , @is_raskidka_avans BIT = 1 -- расскидка аванса
		  , @Paymaccount_minus BIT = 0 -- формирование отрицательных оплат при переплате
		  , @paym_order NVARCHAR(100)
		  , @peny_paym_blocked BIT -- признак блокировки оплаты пени на типе фонда
		  , @paying_uid UNIQUEIDENTIFIER

	DECLARE @t1 TABLE (
		 sup_id INT NOT NULL DEFAULT 0
		, service_id VARCHAR(10) NOT NULL
		, saldo DECIMAL(9, 2) NOT NULL DEFAULT 0 -- сальдо предыдущего периода
		, paymaccount_prev DECIMAL(9, 2) NOT NULL DEFAULT 0 -- платежи в прошлом периоде
		, paym_prev DECIMAL(9, 2) NOT NULL DEFAULT 0 -- платежи в текущем периоде до этого платежа
		, dolg DECIMAL(9, 2) NOT NULL DEFAULT 0 -- saldo - paymaccount_prev - paym_prev
		, dolg_koef DECIMAL(9, 6) NOT NULL DEFAULT 0 -- доля услуги в долге		
		, paid DECIMAL(9, 2) NOT NULL DEFAULT 0 -- пост.начисления предыдущего периода
		, paid_koef DECIMAL(9, 6) NOT NULL DEFAULT 0 -- доля услуги в пред.начислении
		, peny DECIMAL(9, 2) NOT NULL DEFAULT 0 -- пени предыдущего периода
		, peny_koef DECIMAL(9, 6) NOT NULL DEFAULT 0 -- доля услуги в пени
		, debt DECIMAL(9, 2) NOT NULL DEFAULT 0 -- конечное сальдо
		, total_paid AS (debt + peny) --DECIMAL(9, 2) NOT NULL DEFAULT 0
		, [value] DECIMAL(9, 2) NOT NULL DEFAULT 0	-- начисления текущего периода
		, paymaccount DECIMAL(9, 2) NOT NULL DEFAULT 0  -- раскиданная оплата по услугам
		, paymaccount_peny DECIMAL(9, 2) NOT NULL DEFAULT 0  -- раскиданная оплата пени по услугам
		, commission  DECIMAL(9, 2) NOT NULL DEFAULT 0  -- раскиданная банк.комиссия по услугам
		, msg VARCHAR(100) DEFAULT ''
	)
	BEGIN TRY

		SELECT @occ1 = p.occ
			 , @fin_id = pd.fin_id
			 , @occ_sup1 = p.occ_sup
			 , @pack_id = p.pack_id
			 , @Paymaccount = COALESCE(p.value, 0)
			 , @service_paying = p.service_id
			 , @forwarded = p.forwarded
			 , @sup_id = p.sup_id
			 , @Paymaccount_peny = COALESCE(p.paymaccount_peny, 0)
			 , @commission = COALESCE(p.commission, 0)
			 , @tip_id1 = pd.tip_id
			 , @date_paym = pd.day
			 , @paying_vozvrat = p.paying_vozvrat
			 , @build_id = f.bldn_id
			 , @paying_manual = p.paying_manual
			 , @is_paying_saldo_no_paid = COALESCE(OT.is_paying_saldo_no_paid, 0)
			 , @Paymaccount_minus = OT.paymaccount_minus
			 , @paym_order = OT.paym_order
			 , @peny_paym_blocked = OT.peny_paym_blocked
			 , @paying_uid = p.paying_uid
			 , @fin_current = b.fin_current
			 , @fin_prev = b.fin_current - 1 -- предыдущий фин. период
		FROM dbo.Payings AS p 
			JOIN dbo.Paydoc_packs AS pd ON p.pack_id = pd.id
			JOIN dbo.Occupations o ON p.occ = o.occ
			JOIN dbo.Flats f ON o.flat_id = f.id
			JOIN dbo.Buildings b ON b.id = f.bldn_id
			JOIN dbo.Occupation_Types AS OT ON OT.id = pd.tip_id
		WHERE p.id = @paying_id

		-- Если ручная раскидка по услугам и уже есть суммы по услугам
		IF (@paying_manual = 1)
			AND EXISTS (
				SELECT *
				FROM dbo.Paying_serv
				WHERE paying_id = @paying_id
			)
		BEGIN
			IF @debug = 1
				PRINT 'Платёж с ручной раскидкой по услугам! Выходим'
			RETURN 0
		END
		IF @occ1 IS NULL
		BEGIN
			RAISERROR ('Лицевой по коду платежа %d не найден', 10, 1, @paying_id);
			RETURN 1
		END

		IF @Paymaccount = 0
		BEGIN
			DELETE FROM dbo.Paying_serv WITH (ROWLOCK)
			WHERE (paying_id = @paying_id)
			IF @debug = 1
				PRINT 'Выходим @Paymaccount = 0'
			RETURN 0
		END
		SELECT @Paym_start = @Paymaccount

		IF @debug = 1
			SELECT @occ1 AS occ
				 , @sup_id AS sup_id
				 , @occ_sup1 AS occ_sup
				 , @Paymaccount AS paymaccount
				 , @paying_manual AS paying_manual		
				 , @fin_id AS '@fin_id'
				 , @fin_current AS '@fin_current'
				 , @commission AS '@commission'
				 , @service_paying AS service_paying
				 , @paying_vozvrat AS paying_vozvrat
				 , @tip_id1 AS tip_id
				 , @build_id AS build_id

		-- Работа с возвратом ============================================
		IF @paying_vozvrat IS NOT NULL
		BEGIN
			IF @debug = 1
				PRINT 'Возврат платёжа по коду: ' + STR(@paying_vozvrat)

			INSERT INTO @t1 (sup_id, service_id, paymaccount, paymaccount_peny, commission)
			SELECT Ps.sup_id
				 , service_id
				 , value * -1
				 , paymaccount_peny * -1
				 , commission * -1				 
			FROM dbo.Paying_serv Ps
			WHERE occ = @occ1
				AND paying_id = @paying_vozvrat

			SELECT @Paym_start = SUM(paymaccount)
			FROM @t1

			IF @debug = 1
			BEGIN
				RAISERROR ('возвращаем платёж %d', 10, 1, @paying_vozvrat) WITH NOWAIT;
				SELECT *
				FROM @t1
			END
			GOTO LABEL_ADD_PAYINGS
		END
		-- ===============================================================

		-- если оплата по конкретной услуге то переносим её напрямую
		IF @service_paying = ''
			SET @service_paying = NULL

		IF @service_paying IS NOT NULL
		BEGIN
			IF @debug = 1
				PRINT 'Платёж по услуге: ' + @service_paying
			DECLARE @is_counter BIT = 0 -- 1-внешний счётчик

			SELECT @is_counter =
								CASE
									WHEN is_counter = 1 THEN 1
									ELSE 0
								END
			FROM dbo.Consmodes_list
			WHERE occ = @occ1
				AND service_id = @service_paying
				AND sup_id = @sup_id

			INSERT INTO @t1 (sup_id, service_id, paymaccount, paymaccount_peny)
			SELECT @sup_id
				 , @service_paying
				 , @Paymaccount
				 , @Paymaccount_peny

			IF @debug = 1
				SELECT *
				FROM @t1

			SELECT @Paym_start = SUM(paymaccount)
			FROM @t1

			GOTO LABEL_ADD_PAYINGS
		END
		-- ===============================================================

		-- загрузка в таблицу для распределения
		;WITH cte AS
		(SELECT COALESCE(pl.sup_id, 0) AS sup_id, s.id AS service_id
				, pl.saldo AS saldo
				, (pl.paymaccount - pl.paymaccount_peny) AS paymaccount_prev
				, COALESCE(t_paym.paymaccount, 0) - COALESCE(t_paym.paymaccount_peny, 0) AS paym_prev
				, COALESCE(pl.paid, 0) AS paid
				, pl.penalty_old + pl.penalty_serv as peny
				, pl.debt
		FROM dbo.Services AS s 
			JOIN dbo.Paym_history AS pl ON s.id = pl.service_id AND pl.occ = @occ1 AND pl.fin_id=@fin_prev
			LEFT JOIN
			(SELECT ps.service_id, sum(ps.value) as paymaccount, sum(ps.paymaccount_peny) as paymaccount_peny
			FROM dbo.Payings as p 
				JOIN dbo.Paying_serv as ps ON ps.paying_id=p.id
				WHERE p.occ=@occ1 AND p.fin_id=@fin_current AND p.id<@paying_id
			GROUP BY ps.service_id
			) as t_paym ON t_paym.service_id=pl.service_id
		WHERE s.id <> 'пени'		
		)
		INSERT INTO @t1 (sup_id, service_id, saldo, paymaccount_prev, paym_prev, dolg, paid, peny, debt)
		SELECT sup_id, service_id, saldo, paymaccount_prev, paym_prev, (saldo-paymaccount_prev-paym_prev) as dolg, paid, peny, debt
		from cte
		WHERE 1=1
		AND (saldo<>0 OR paid<>0 OR peny<>0 OR debt<>0)
		AND (sup_id = @sup_id)
		;
		UPDATE @t1 SET paid=CASE
                                WHEN paid > debt THEN debt
                                ELSE paid
            END
		UPDATE @t1
		SET paid=CASE
                     WHEN paid < 0 THEN 0
                     ELSE paid
                END
			,dolg=CASE
                      WHEN dolg < 0 THEN 0
                      ELSE dolg
            END
			,peny=CASE
                      WHEN peny < 0 THEN 0
                      ELSE peny
            END
		
		SELECT 	
			@SumSaldo=sum(saldo)
			,@SumDolg=sum(dolg)
			,@SumPaid=sum(paid)
			,@SumPenaltyOld=sum(peny)
			,@SumTotalPaid=sum(total_paid)
			,@SumDebt=sum(debt)
		FROM @t1

		UPDATE @t1
		SET dolg_koef=CASE
                          WHEN @SumDolg > 0 THEN dolg / @SumDolg
                          ELSE 0
            END
		,paid_koef=CASE
                       WHEN @SumPaid > 0 THEN paid / @SumPaid
                       ELSE 0
            END
		,peny_koef=CASE
                       WHEN @SumPenaltyOld > 0 THEN peny / @SumPenaltyOld
                       ELSE 0
            END

		IF @debug = 1
		BEGIN
			SELECT @Paymaccount as Paymaccount, @SumSaldo AS SumSaldo, @SumDolg as SumDolg, @SumPaid as SumPaid, @SumDebt AS SumDebt, @SumPenaltyOld AS SumPenaltyOld, @SumTotalPaid AS SumTotalPaid
			--SELECT * from @t1
		END

		SET @Paym_start = @Paymaccount
		--============================================================
	
		-- Таблица 5-1 – Пример распределения поступившего платежа в сумме, меньшей, чем размер текущих начислений
		IF @Paymaccount<@SumPaid
		BEGIN
			UPDATE @t1
			SET paymaccount=@Paymaccount*paid_koef
				,msg = CONCAT('5-1: (',dbo.NSTR(@Paymaccount),' * ',dbo.NSTR(paid_koef),')')
			SELECT @metod_name = '5-1'
			, @msg_log = CONCAT(dbo.NSTR(@Paymaccount), ' < ', dbo.NSTR(@SumPaid))
		END
		ELSE
		-- Таблица 5-2 – Пример распределения поступившего платежа, равного сумме текущих начислений
		IF @Paymaccount=@SumPaid
		BEGIN
			UPDATE @t1
			SET paymaccount=@Paymaccount*paid_koef
			,msg = CONCAT('5-2: (',dbo.NSTR(@Paymaccount),' * ',dbo.NSTR(paid_koef),')' )
			SELECT @metod_name = '5-2'
			, @msg_log = CONCAT(dbo.NSTR(@Paymaccount), ' = ', dbo.NSTR(@SumPaid) )
		END
		ELSE
		-- Таблица 5-3 – Пример распределения поступившего платежа в сумме, большей, чем размер текущих начислений, но меньшей, чем указано в графе «Итого к оплате» 
		IF @Paymaccount>@SumPaid and @Paymaccount<(@SumTotalPaid-@SumPenaltyOld) --AND @SumPenaltyOld=0
		BEGIN			
			SELECT @PaymaccountDolg=@Paymaccount-@SumPaid
			UPDATE @t1
			SET paymaccount=@SumPaid*paid_koef+@PaymaccountDolg*dolg_koef
			,msg = CONCAT('5-3: (',dbo.NSTR(@SumPaid),' * ',dbo.NSTR(paid_koef),') + (',dbo.NSTR(@PaymaccountDolg),' * ', dbo.NSTR(dolg_koef),')' )
			SELECT @metod_name = '5-3'
			, @msg_log = CONCAT(dbo.NSTR(@Paymaccount),' > ', dbo.NSTR(@SumPaid),', @PaymaccountDolg: ', dbo.NSTR(@PaymaccountDolg) )
		END
		ELSE
		-- Таблица 5-4 – Пример распределения поступившего платежа, равного сумме, указанной в графе «Итого к оплате»
		IF @Paymaccount>@SumPaid and @Paymaccount=@SumTotalPaid AND @SumPenaltyOld=0
		BEGIN			
			SELECT @PaymaccountDolg=@Paymaccount-@SumPaid	
			UPDATE @t1
			SET paymaccount=@SumPaid*paid_koef+@PaymaccountDolg*dolg_koef
			,msg = CONCAT('5-4: (',dbo.NSTR(@SumPaid),' * ',dbo.NSTR(paid_koef),') + (',dbo.NSTR(@PaymaccountDolg),' * ',dbo.NSTR(dolg_koef),')' )
			SELECT @metod_name = '5-4'
			, @msg_log = CONCAT(dbo.NSTR(@Paymaccount),' > ', dbo.NSTR(@SumPaid),', PaymaccountDolg: ', dbo.NSTR(@PaymaccountDolg) )
		END
		ELSE
		-- Таблица 5-5 –Пример распределения платежа в сумме, большей, чем размер текущих начислений и задолженности на начало расчетного месяца, но меньшей указанной в графе «Итого к оплате» (при наличии пени) 
		IF @Paymaccount>(@SumPaid+@SumDolg) and @Paymaccount<@SumTotalPaid AND @SumPenaltyOld>0
		BEGIN			
			SELECT @PaymaccountPeny= CASE
                                         WHEN (@Paymaccount - @SumPaid - @SumDolg) > @SumPenaltyOld THEN @SumPenaltyOld
                                         ELSE (@Paymaccount - @SumPaid - @SumDolg)
                END
			UPDATE @t1
			SET paymaccount= @SumPaid*paid_koef + @SumDolg*dolg_koef + @PaymaccountPeny*peny_koef
			,msg = CONCAT('5-5: (',dbo.NSTR(@SumPaid),' * ',dbo.NSTR(paid_koef)
				,') + (',dbo.NSTR(@SumDolg),' * ', dbo.NSTR(dolg_koef)
				,') + (',dbo.NSTR(@PaymaccountPeny),' * ',dbo.NSTR(peny_koef),')' )
			, paymaccount_peny = @PaymaccountPeny*peny_koef
			SELECT @metod_name = '5-5'
			, @msg_log = CONCAT(dbo.NSTR(@Paymaccount),', SumPaid: ',dbo.NSTR(@SumPaid),', SumDolg: ',dbo.NSTR(@SumDolg),', PaymaccountPeny: ',  dbo.NSTR(@PaymaccountPeny) )
		END
		ELSE
		-- Таблица 5-6 –Пример распределения платежа, равного сумме, указанной в графе «Итого к оплате» (при наличии пени)
		IF @Paymaccount=@SumTotalPaid AND @Paymaccount>(@SumPaid+@SumDolg) AND @SumPenaltyOld>0
		BEGIN			
			SELECT @PaymaccountPeny= CASE
                                         WHEN (@Paymaccount - @SumPaid - @SumDolg) > @SumPenaltyOld THEN @SumPenaltyOld
                                         ELSE (@Paymaccount - @SumPaid - @SumDolg)
                END
			UPDATE @t1
			SET paymaccount= @SumPaid*paid_koef + @SumDolg*dolg_koef + @PaymaccountPeny*peny_koef
			,msg = CONCAT('5-6:(',dbo.NSTR(@SumPaid),' * ',dbo.NSTR(paid_koef)
				,') + (',dbo.NSTR(@SumDolg),' * ',dbo.NSTR(dolg_koef)
				,') + (',dbo.NSTR(@PaymaccountPeny),' * ',dbo.NSTR(peny_koef),')' )
			, paymaccount_peny = @PaymaccountPeny*peny_koef
			SELECT @metod_name = '5-6'
			, @msg_log = CONCAT(dbo.NSTR(@Paymaccount),', SumPaid: ',dbo.NSTR(@SumPaid),', @SumDolg: ',dbo.NSTR(@SumDolg),', @PaymaccountPeny: ', dbo.NSTR(@PaymaccountPeny) )
		END		 
		ELSE	
		-- Таблица 5-7 – Пример распределения платежа, размер которого превышает итоговую сумму к оплате (в случае отсутствия пени) 
		IF @Paymaccount>@SumTotalPaid AND @SumPenaltyOld=0 AND @SumTotalPaid>0
		BEGIN			
			UPDATE @t1
			SET paymaccount= @SumPaid*paid_koef + @SumDolg*dolg_koef + (@Paymaccount-@SumPaid-@SumDolg)*paid_koef
			,msg = CONCAT('5-7:(',dbo.NSTR(@SumPaid),' * ',dbo.NSTR(paid_koef)
				,') + (',dbo.NSTR(@SumDolg),' * ',dbo.NSTR(dolg_koef)
				,') + (',dbo.NSTR(@Paymaccount-@SumPaid-@SumDolg),' * ',dbo.NSTR(paid_koef) ,')' )
			SELECT @metod_name = '5-7'
			, @msg_log = CONCAT(dbo.NSTR(@Paymaccount),', SumPaid: ',dbo.NSTR(@SumPaid),', SumDolg: ', dbo.NSTR(@SumDolg) )
		END	
		ELSE
		-- Таблица 5-8 –Пример распределения платежа, размер которого превышает итоговую сумму к оплате (в случае наличия пени) 
		IF @Paymaccount>@SumTotalPaid AND @SumPenaltyOld>0
		BEGIN			
			SET @PaymaccountPeny=@SumPenaltyOld
			UPDATE @t1
			SET paymaccount= @SumPaid*paid_koef + @SumDolg*dolg_koef + @PaymaccountPeny*peny_koef + (@Paymaccount-@SumPaid-@SumDolg-@PaymaccountPeny)*paid_koef
			,msg = CONCAT('5-8:(',dbo.NSTR(@SumPaid),' * ',dbo.NSTR(paid_koef)
				,') + (',dbo.NSTR(@SumDolg),' * ',dbo.NSTR(dolg_koef)
				,') + (',dbo.NSTR(@SumPenaltyOld),' * ',dbo.NSTR(peny_koef)
				,') + (',dbo.NSTR(@Paymaccount-@SumPaid-@SumDolg),' * ',dbo.NSTR(paid_koef) ,')' )
			, paymaccount_peny = @PaymaccountPeny*peny_koef
			SELECT @metod_name = '5-8'
			, @msg_log = CONCAT(dbo.NSTR(@Paymaccount),', SumPaid: ',dbo.NSTR(@SumPaid),', SumDolg: ',dbo.NSTR(@SumDolg),', PaymaccountPeny: ',  dbo.NSTR(@PaymaccountPeny) )
		END
		ELSE
		BEGIN
			IF @debug = 1 PRINT 'метод не определён';
			-- 1. Раскидаем по сальдо @SumSaldo
			IF @SumSaldo<>0
			BEGIN
				UPDATE @t1	SET paymaccount=saldo*@Paymaccount/@SumSaldo, msg = 'saldo'
				SELECT @metod_name = 'saldo', @msg_log = CONCAT(dbo.NSTR(@Paymaccount),', SumSaldo: ',  dbo.NSTR(@SumSaldo) )
			END

			-- 2. надо проверить есть ли текущее начисление
			-- 3. история начислений
		END

		-- раскидка остатка
		SELECT @ostatok = @PaymAccount-(Select Sum(paymaccount) From @t1)
			, @ostatokPeny = @PaymaccountPeny-(Select Sum(paymaccount_peny) From @t1)
		IF @debug = 1 PRINT 'Остаток: ' + STR(@ostatok, 9, 2)+ ' Остаток пени: ' + STR(@ostatokPeny, 9, 2)
		if abs(@ostatok)>0 and abs(@ostatok)<1
			Update t SET paymaccount = paymaccount + @ostatok
			from @t1 t
			Where t.service_id=(SELECT top(1) service_id from @t1 ORDER BY paymaccount DESC)

		if abs(@ostatokPeny)>0 and abs(@ostatokPeny)<1
			Update t SET paymaccount_peny = paymaccount_peny + @ostatokPeny
			from @t1 t
			Where t.service_id=(SELECT top(1) service_id from @t1 ORDER BY paymaccount_peny DESC)
		--===================================================

		SELECT @ostatok = @Paym_start - sum(paymaccount) FROM @t1
		IF @debug = 1
		BEGIN
			PRINT 'Закончили временную раскидку'
			SELECT * from @t1
			SELECT @ostatok AS 'Окончательный Остаток', @ostatokPeny AS 'Остаток оплаты пени'
			PRINT 'Остаток: ' + STR(@ostatok, 9, 2)+', Остаток оплаты пени: ' + STR(@ostatokPeny, 9, 2)
		END

		IF @ostatok>0
		BEGIN	
			IF @debug = 1 SELECT 'Оплату не раскидали' AS ERROR;
			RETURN
		END

		--====================================================	
		IF @debug_file = 1
		BEGIN
			DELETE FROM [dbo].[Paying_log]
			WHERE paying_id = @paying_id

			INSERT INTO Paying_log (paying_id
								  , pack_id
								  , occ
								  , sup_id
								  , value
								  , Koef
								  , ostatok
								  , metod_name
								  , msg_log)
			VALUES(@paying_id
				 , @pack_id
				 , @occ1
				 , @sup_id
				 , @Paym_start
				 , @koef
				 , @ostatok
				 , @metod_name
				 , @msg_log);
			IF @debug = 1
				SELECT 'PAYING_LOG' as tbl
					 , *
				FROM Paying_log
				WHERE paying_id = @paying_id
		END
		--====================================================
	LABEL_ADD_PAYINGS:

			IF @debug = 1
				PRINT 'Записыавем в таблицу по услугам'

			IF @trancount = 0
				BEGIN TRANSACTION
			ELSE
				SAVE TRANSACTION k_payings_serv_add5;

			DELETE FROM dbo.Paying_serv
			WHERE (paying_id = @paying_id)

			INSERT INTO dbo.Paying_serv (paying_id									   
									   , service_id
									   , occ
									   , sup_id
									   , value
									   , paymaccount_peny
									   , commission)
			SELECT @paying_id				 
				 , service_id
				 , @occ1
				 , sup_id
				 , paymaccount
				 , paymaccount_peny
				 , commission
			FROM @t1
			WHERE paymaccount <> 0

			IF @trancount = 0
				COMMIT TRAN

			IF @debug = 1
			BEGIN
				PRINT 'Закончили раскидку'
				SELECT 'Paying_serv' as tbl,service_id, sum(value) as [value], sum(paymaccount_peny) as paymaccount_peny, sum(commission ) as commission
				from dbo.Paying_serv WHERE paying_id=@paying_id GROUP BY ROLLUP (service_id)

			END

			-- раскидка оплаты пени
			--IF @Paymaccount_peny <> 0
			--BEGIN
			--	IF @debug = 1
			--		PRINT CONCAT('Раскидка оплаты пени: EXEC dbo.k_paying_serv_peny @paying_id=',@paying_id,',@Paymaccount_peny=',@Paymaccount_peny,',@debug=', @debug)
				
			--	EXEC dbo.k_paying_serv_peny @paying_id = @paying_id
			--							  , @Paymaccount_peny = @Paymaccount_peny
			--							  , @debug = 0 --@debug
			--END

			-- раскидка оплаты для фискализации чеков
			IF @debug = 1		
				PRINT CONCAT('Раскидка оплаты для фискализации чеков: EXEC dbo.k_pay_cash_update @paying_id=', @paying_id,',@occ1=', @occ1)			
			EXEC k_pay_cash_update @occ1 = @occ1, @paying_id1 = @paying_id


			IF @debug = 1
				PRINT 'Закончили'
	END TRY
	BEGIN CATCH

		DECLARE @xstate INT;
		SELECT @xstate = XACT_STATE();
		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @trancount = 0
			ROLLBACK;
		IF @xstate = 1
			AND @trancount > 0
			ROLLBACK TRANSACTION k_payings_serv_add5;


		DECLARE @strerror VARCHAR(4000) = ''
		EXECUTE k_GetErrorInfo @visible = 0
							 , @strerror = @strerror OUT
		RAISERROR (@strerror, 16, 1)

	END CATCH
END
go

