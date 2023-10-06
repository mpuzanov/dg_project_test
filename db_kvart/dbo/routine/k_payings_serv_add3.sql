CREATE   PROCEDURE [dbo].[k_payings_serv_add3]
(
	  @paying_id INT -- код платежа
	, @debug BIT = 0
)
AS
	/*

Процедура  раскидки платежа по услугам 

Раскидка даже на отрицательные суммы (оплата может быть отрицательной)

автор: Пузанов
дата изменения: 10.08.18

DECLARE	@return_value int
EXEC	@return_value = [dbo].[k_payings_serv_add3]
		@paying_id = 495412, --496920,
		@debug = 1
SELECT	'Return Value' = @return_value
GO

-- DELETE FROM [dbo].[PAYING_LOG] WHERE paying_id = @paying_id
*/
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @trancount INT;
	SET @trancount = @@trancount;

	DECLARE @debug_file BIT = 1 -- логирование работы в таблицу PAYING_LOG
		  , @Db_Name VARCHAR(20) = UPPER(DB_NAME())
		  , @msg_log VARCHAR(1000) = ''
		  , @metod_name VARCHAR(50)
		  , @metod_ostatok VARCHAR(50)

	DECLARE @fin_id SMALLINT -- код фин. периода в котором проходит платеж
		  , @fin_prev SMALLINT -- код предыдущего фин. периода
		  , @fin_current SMALLINT -- код текущего фин. периода
		  , @Fin_id_start SMALLINT -- код периода для выборки начислений за период
		  , @occ1 INT	-- лицевой счет
		  , @tip_id1 SMALLINT
		  , @Paymaccount DECIMAL(9, 2) --  оплата
		  , @service_paying VARCHAR(10) -- код услуги платежа 
		  , @forwarded BIT -- признак закрытия платежа
		  , @sup_id INT -- Код поставщика
		  , @date_paym SMALLDATETIME -- дата платежа
		  , @pack_id INT -- код пачки

	DECLARE @SumSaldo1 DECIMAL(9, 2) -- сумма сальдо
		  , @SumSaldo DECIMAL(9, 2) -- сумма сальдо c учетом платежей до этого
		  , @SumSaldoPlus DECIMAL(9, 2)
		  , @SumValue DECIMAL(9, 2) -- сумма начислений
		  , @SumPaid DECIMAL(9, 2) -- сумма постоянных начислений
		  , @Sumpaid_prev DECIMAL(9, 2) -- постоянное начисление в предыдущем месяце
		  , @SumTarif DECIMAL(9, 2) -- сумма тарифов
		  , @SumPenaltyOld DECIMAL(9, 2) -- пени предыдущих периодов
		  , @ostatok DECIMAL(9, 2)
		  , @koef DECIMAL(16, 10) -- коэф. для раскидки по услугам
		  , @Paymaccount_peny DECIMAL(9, 2) = 0
		  , @Paym_start DECIMAL(9, 2) = 0
		  , @Paym_saldo DECIMAL(9, 2) = 0
		  , @Paymaccount_old DECIMAL(9, 2) = 0 -- оплата до текущего платежа
		  , @Paymaccount_peny_old DECIMAL(9, 2) = 0 -- оплата пени до текущего платежа
		  , @commission DECIMAL(9, 2) = 0
		  , @Sum_Paym_plus DECIMAL(9, 2) = 0
		  , @paying_vozvrat INT = NULL
		  , @build_id INT
		  , @paying_manual BIT = 0 -- ручное изменение по услугам
		  , @is_overpayment BIT = 0 -- есть услуги для раскидки переплаты
		  , @is_paying_saldo_no_paid BIT = 1 -- Не учитывать тек.начисление при оплате
		  , @Paymaccount_minus BIT = 0 -- формирование отрицательных оплат при переплате
		  , @paying_uid UNIQUEIDENTIFIER

	-- начисления по текущему фин. периоду
	DECLARE @t1 TABLE (
		  paying_id INT
		, fin_id SMALLINT
		, occ INT
		, sup_id INT NOT NULL DEFAULT 0
		, service_id VARCHAR(10)
		, tarif DECIMAL(10, 4)
		, saldo DECIMAL(9, 2) NOT NULL DEFAULT 0
		, saldo_new DECIMAL(9, 2) NOT NULL DEFAULT 0
		, value DECIMAL(9, 2) NOT NULL DEFAULT 0
		, paid DECIMAL(9, 2) NOT NULL DEFAULT 0
		, paid_prev DECIMAL(9, 2) NOT NULL DEFAULT 0 -- конечное сальдо в предыдущем месяце
		, paymaccount DECIMAL(9, 2) NOT NULL DEFAULT 0
		, paymaccount_peny DECIMAL(9, 2) NOT NULL DEFAULT 0
		, Paymaccount_old DECIMAL(9, 2) NOT NULL DEFAULT 0
		, Paymaccount_peny_old DECIMAL(9, 2) NOT NULL DEFAULT 0
		, is_counter BIT DEFAULT 0
		, dolg AS saldo - paymaccount
		, procent AS paymaccount / (CASE
			  WHEN paid_prev <= 0 THEN 1
			  ELSE paid_prev
		  END)
		, commission DECIMAL(9, 2) NOT NULL DEFAULT 0
		, account_one BIT DEFAULT 0
		, penalty_old DECIMAL(9, 2) NOT NULL DEFAULT 0
		, mode_id INT NOT NULL DEFAULT 0
		, sort_no SMALLINT DEFAULT 99
		, overpayment_blocked BIT DEFAULT 0
		, [debt] AS (([saldo] + [paid]) - ([paymaccount] - [paymaccount_peny]))
		, [debt_new] AS ([saldo_new] + [paid]) - ([paymaccount] - [paymaccount_peny])
	)

	BEGIN TRY

		SELECT @occ1 = p.occ
			 , @fin_id = pd.fin_id
			 , @pack_id = p.pack_id
			 , @Paymaccount = p.value
			 , @service_paying = p.service_id
			 , @forwarded = p.forwarded
			 , @sup_id = p.sup_id
			 , @Paymaccount_peny = p.paymaccount_peny
			 , @commission = p.commission
			 , @tip_id1 = pd.tip_id
			 , @date_paym = pd.day
			 , @paying_vozvrat = p.paying_vozvrat
			 , @build_id = f.bldn_id
			 , @paying_manual = p.paying_manual
			 , @is_paying_saldo_no_paid = OT.is_paying_saldo_no_paid
			 , @Paymaccount_minus = OT.paymaccount_minus
			 , @paying_uid = paying_uid
		FROM dbo.Payings AS p 
			JOIN dbo.Paydoc_packs AS pd ON 
				p.pack_id = pd.id
			JOIN dbo.Occupations o ON 
				p.occ = o.occ
			JOIN dbo.Flats f ON 
				o.flat_id = f.id
			JOIN dbo.Occupation_Types AS OT ON 
				o.tip_id = OT.id
		WHERE p.id = @paying_id;

		-- Если ручная раскидка по услугам и уже есть суммы по услугам
		IF (@paying_manual = 1)
			AND EXISTS (
				SELECT 1
				FROM dbo.Paying_serv 
				WHERE paying_id = @paying_id
			)
		BEGIN
			IF @debug = 1
				PRINT N'Платёж с ручной раскидкой по услугам! Выходим'
			RETURN 0
		END

		IF @Paymaccount = 0
		--OR @forwarded = 0
		BEGIN
			DELETE FROM dbo.Paying_serv 
			WHERE paying_id = @paying_id
			--AND fin_id = @fin_id
			--AND occ = @occ1
			IF @debug = 1
				PRINT N'Выходим @Paymaccount = 0'
			RETURN 0
		END

		IF @debug = 1
			SELECT @Paymaccount AS paymaccount
				 , @service_paying AS service_paying
				 , @paying_vozvrat AS paying_vozvrat
				 , @sup_id AS sup_id
				 , @paying_manual AS paying_manual

		IF @paying_vozvrat IS NOT NULL
		BEGIN
			INSERT INTO @t1 (paying_id
						   , fin_id
						   , occ
						   , service_id
						   , paymaccount
						   , commission
						   , paymaccount_peny
						   , sup_id)
			SELECT @paying_id
				 , @fin_id
				 , occ
				 , service_id
				 , value * -1
				 , commission * -1
				 , paymaccount_peny * -1
				 , Ps.sup_id
			FROM dbo.Paying_serv Ps
			WHERE paying_id = @paying_vozvrat
				AND occ = @occ1;

			SELECT @Paym_start = SUM(paymaccount)
			FROM @t1;

			IF @debug = 1
			BEGIN
				RAISERROR (N'возвращаем платёж %d', 10, 1, @paying_vozvrat) WITH NOWAIT;
				SELECT *
				FROM @t1
			END
			GOTO LABEL_ADD_PAYINGS
		END

		-- если оплата по конкретной услуге
		-- переносим её напрямую
		IF @service_paying = ''
			SET @service_paying = NULL

		IF @service_paying IS NOT NULL
		BEGIN
			IF @debug = 1
				PRINT N'Платёж по услуге: ' + @service_paying
			DECLARE @is_counter BIT = 0 -- 1-внешний счётчик

			SELECT @is_counter = CASE
                                     WHEN is_counter = 1 THEN 1
                                     ELSE 0
                END
			FROM dbo.Consmodes_list 
			WHERE occ = @occ1
				AND service_id = @service_paying
				AND sup_id = @sup_id

			INSERT INTO @t1 (paying_id
						   , fin_id
						   , occ
						   , service_id
						   , tarif
						   , saldo
						   , value
						   , paid
						   , paid_prev
						   , paymaccount
						   , paymaccount_peny
						   , is_counter
						   , sup_id)
			SELECT @paying_id
				 , @fin_id
				 , @occ1
				 , @service_paying
				 , 0
				 , 0
				 , 0
				 , 0
				 , 0
				 , @Paymaccount
				 , @Paymaccount_peny
				 , @is_counter
				 , @sup_id

			IF @debug = 1
				SELECT *
				FROM @t1

			SELECT @Paym_start = SUM(paymaccount)
			FROM @t1

			IF COALESCE(@sup_id, 0) = 0
				GOTO LABEL_ADD_PAYINGS

		END

		---- если оплата по Поставщику
		--IF COALESCE(@sup_id, 0) > 0
		--BEGIN

		--	IF @debug = 1
		--		PRINT 'оплата по поставщику'

		--	EXECUTE k_payings_serv_add_sup @paying_id
		--								  ,@debug
		--	RETURN

		--END

		-- текущий фин. период
		SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

		-- предыдущий фин. период
		SELECT @fin_prev = @fin_current - 1

		IF NOT EXISTS (
				SELECT 1
				FROM dbo.Global_values 
				WHERE fin_id = @fin_prev
			)
		BEGIN
			SET @fin_prev = @fin_id
		END

		IF @debug = 1
			SELECT '@fin_prev' = @fin_prev
				 , '@fin_id' = @fin_id
				 , '@fin_current' = @fin_current
				 , Paymaccount = @Paymaccount
				 , Commission = @commission

		IF @fin_current <= @fin_id
		BEGIN
			INSERT INTO @t1 (paying_id
						   , fin_id
						   , occ
						   , service_id
						   , tarif
						   , saldo
						   , value
						   , paid
						   , paid_prev
						   , paymaccount
						   , paymaccount_peny
						   , account_one
						   , penalty_old
						   , mode_id
						   , sort_no
						   , sup_id)
			SELECT @paying_id
				 , @fin_id
				 , @occ1
				 , s.id
				 , COALESCE(p.tarif,0)
				 , COALESCE(p.saldo,0)
				 , COALESCE(p.value,0)
				 , COALESCE(p.paid,0)
				 , 0
				 , 0
				 , 0
				 , p.account_one
				 , COALESCE(p.penalty_old,0)
				 , COALESCE(p.mode_id, 0)
				 , s.sort_no
				 , @sup_id AS sup_id
			FROM dbo.Services AS s 
				LEFT JOIN dbo.Paym_list AS p ON s.id = p.service_id
					AND p.occ = @occ1
					AND p.sup_id = @sup_id
					AND p.subsid_only = 0 -- добавил 11.03.2005
			--AND COALESCE(p.is_counter, 0) <> 1 -- внешний счетчик 
			WHERE s.id <> N'пени'
			ORDER BY s.service_no
		END

		IF @fin_current > @fin_id
		BEGIN
			INSERT INTO @t1 (paying_id
						   , fin_id
						   , occ
						   , service_id
						   , tarif
						   , saldo
						   , value
						   , paid
						   , paid_prev
						   , paymaccount
						   , paymaccount_peny
						   , account_one
						   , mode_id
						   , sup_id)
			SELECT @paying_id
				 , @fin_id
				 , p.occ
				 , p.service_id
				 , p.tarif
				 , p.saldo
				 , p.value
				 , p.paid
				 , 0
				 , 0
				 , 0
				 , COALESCE(p.account_one, 0)
				 , COALESCE(p.mode_id, 0)
				 , p.sup_id
			FROM dbo.Paym_history AS p 
			WHERE p.occ = @occ1
				AND p.fin_id = @fin_id
				AND p.sup_id = @sup_id
				AND p.subsid_only = 0 -- добавил 11.03.2005 
		--AND COALESCE(p.is_counter, 0) <> 1 -- внешний счетчик 
		END

		--IF @debug=1	SELECT '@t1', * FROM @t1

		IF @sup_id > 0
			DELETE t
			FROM @t1 AS t
			WHERE t.sup_id <> @sup_id

		-- услуги с блокировкой переплаты
		UPDATE T
		SET T.overpayment_blocked = St.overpayment_blocked
		FROM @t1 AS T
			JOIN dbo.Services_types AS St ON St.service_id = T.service_id
		WHERE St.tip_id = @tip_id1

		-- помечаем услуги где должна быть переплата  ********************
		DECLARE @t_serv_overpayment TABLE (
			  service_id VARCHAR(10)
			, occ INT
		)
		INSERT INTO @t_serv_overpayment (service_id
									   , occ)
		SELECT St.service_id
			 , @occ1
		FROM dbo.Services_types AS St 
		WHERE St.tip_id = @tip_id1
			AND St.overpayment_only = 1

		IF EXISTS (SELECT 1 FROM @t_serv_overpayment)
		BEGIN
			SET @is_overpayment = 1
			UPDATE T
			SET T.overpayment_blocked = 1
			FROM @t1 AS T
			WHERE NOT EXISTS (
					SELECT 1
					FROM dbo.Services_types AS St 
					WHERE St.tip_id = @tip_id1
						AND St.service_id = T.service_id
						AND St.overpayment_only = 1
				)
		END

		-- удаляем услуги по которым блокируется раскидка оплаты по типу фонда или не наступила ещё дата расчета услуги
		DELETE t
		FROM @t1 AS t
			JOIN dbo.Services_types AS ST ON ST.service_id = t.service_id
		WHERE ST.tip_id = @tip_id1
			AND (ST.paym_rasckidka_no = 1
			OR @date_paym < ST.date_paying_start)

		-- удаляем услуги по которым блокируется раскидка оплаты по дому
		DELETE T
		FROM @t1 AS T
			JOIN dbo.Services_build sb ON sb.service_id = T.service_id
		WHERE sb.build_id = @build_id
			AND sb.paym_rasckidka_no = 1

		-- Если платёж ранее 20190201 не распределять на услугу "Обращение с ТКО"
		IF dbo.strpos('KVART', UPPER(@Db_Name)) > 0
			AND @tip_id1 IN (27, 28)
			AND (@date_paym < '20190201')
				DELETE t
				FROM @t1 AS t
				WHERE t.service_id = N'втбо';

		-- 10.12.12 -- учтённые платежи до текущего
		UPDATE t
		SET Paymaccount_old = t2.paymaccount
		  , Paymaccount_peny_old = COALESCE(t2.paymaccount_peny, 0)
		FROM @t1 AS t
			JOIN (
				SELECT PS.service_id
					 , SUM(PS.value)            AS paymaccount
					 , SUM(PS.paymaccount_peny) AS paymaccount_peny
				FROM dbo.Paydoc_packs AS pd
					JOIN dbo.Payings AS p ON pd.id = p.pack_id
					JOIN dbo.Paying_serv AS PS ON p.id = PS.paying_id
				WHERE pd.fin_id = @fin_id
					AND p.occ = @occ1
					AND p.forwarded = cast(1 as bit)
					AND p.sup_id = @sup_id    --- 10.08.2018
					AND PS.paying_id < @paying_id
				GROUP BY PS.service_id
			) AS t2 ON t.service_id = t2.service_id

		-- начисление предыдущего месяца
		UPDATE t1
		SET paid_prev =
					   CASE
						   WHEN ph.paid > 0 THEN ph.paid
						   WHEN (ph.value - ph.discount - ph.compens) > 0 THEN (ph.value - ph.discount - ph.compens)
						   ELSE 0
					   END
		FROM @t1 AS t1
			JOIN dbo.Paym_history AS ph ON t1.occ = ph.occ
				AND t1.service_id = ph.service_id
		WHERE ph.occ = @occ1
			AND ph.fin_id = @fin_prev

		-- Если текущих начислений и сальдо нет 
		-- то раскидывать оплату по этим услугам не надо
		UPDATE t1
		SET paid_prev = 0
		FROM @t1 AS t1
		WHERE saldo = 0
			AND value = 0
			AND paid = 0

		UPDATE t1
		SET saldo_new = saldo - Paymaccount_old - Paymaccount_peny_old
		FROM @t1 AS t1

		--DELETE FROM @t1
		--WHERE account_one = 1

		SELECT @SumSaldoPlus = COALESCE(SUM(saldo_new), 0)
		FROM @t1
		WHERE saldo_new > 0

		SELECT @SumSaldo1 = COALESCE(SUM(saldo), 0)
			 , @SumSaldo = COALESCE(SUM(saldo_new), 0)
			 , @SumTarif = COALESCE(SUM(tarif), 0)
			 , @SumValue = COALESCE(SUM(value), 0)
			 , @Paymaccount_old = COALESCE(SUM(Paymaccount_old), 0)
			 , @Paymaccount_peny_old = COALESCE(SUM(Paymaccount_peny_old), 0)
		FROM @t1

		SELECT @SumPaid = COALESCE(SUM(paid), 0)
		FROM @t1
		WHERE paid > 0
		SELECT @Sumpaid_prev = COALESCE(SUM(paid_prev), 0)
		FROM @t1
		WHERE paid_prev > 0

		IF @debug = 1
		BEGIN
			SELECT *
			FROM @t1
			SELECT '@SumTarif' = @SumTarif
				 , '@SumSaldo1' = @SumSaldo1
				 , '@SumSaldo' = @SumSaldo
				 , '@SumSaldoPlus' = @SumSaldoPlus
				 , '@SumValue' = @SumValue
				 , '@SumPaid' = @SumPaid
				 , '@Sumpaid_prev' = @Sumpaid_prev
				 , '@Paymaccount' = @Paymaccount
				 , '@Paymaccount_old' = @Paymaccount_old
				 , '@Paymaccount_peny_old' = @Paymaccount_peny_old
		END

		SET @Paym_start = @Paymaccount

		UPDATE @t1
		SET paymaccount = 0
		WHERE paymaccount <> 0

	-- Раскидываем оплату
	LABEL_SumSaldoPlus:
		IF @Paymaccount <> 0
		BEGIN
			-- 1. Пробуем раскидать по saldo
			IF @SumSaldoPlus > 0
				AND @Paymaccount >= @SumSaldo
				AND @SumSaldo > 0
			BEGIN

				IF @Paymaccount_minus = 1
				BEGIN
					SET @metod_name = 'Метод - Saldo 1(-)'
					IF @debug = 1
						PRINT @metod_name + ' ' + STR(@SumSaldo, 9, 2) + ' Раскидать: ' + STR(@Paymaccount, 9, 2)
					SELECT @Paym_saldo = @SumSaldo
						 , @Paymaccount = @Paymaccount - @SumSaldo
					UPDATE @t1
					SET paymaccount = saldo_new
					SET @msg_log = @msg_log + ';@SumSaldo=' + LTRIM(STR(@SumSaldo, 9, 2))
				END
				ELSE
				BEGIN
					SET @metod_name = 'Метод - Saldo 1(+)'
					IF @debug = 1
						PRINT @metod_name + ' ' + STR(@SumSaldoPlus, 9, 2) + ' Раскидать: ' + STR(@Paymaccount, 9, 2)

					IF @SumSaldoPlus > 0
					BEGIN
						IF @SumSaldoPlus <= @Paymaccount
						BEGIN
							IF @debug = 1
								PRINT '@SumSaldoPlus<@Paymaccount'
							SELECT @Paym_saldo = @SumSaldoPlus
								 , @Paymaccount = @Paymaccount - @SumSaldoPlus
							UPDATE @t1
							SET paymaccount = saldo_new
							WHERE saldo_new > 0
							SET @msg_log = @msg_log + ';@SumSaldoPlus=' + LTRIM(STR(@SumSaldoPlus, 9, 2))
						END
						ELSE
						BEGIN
							IF @debug = 1
								PRINT '@SumSaldoPlus>@Paymaccount'
							SET @koef = @Paymaccount / @SumSaldoPlus
							UPDATE @t1
							SET paymaccount = paymaccount + saldo_new * @koef
							WHERE saldo_new > 0
							SET @msg_log = @msg_log + ';@SumSaldoPlus=' + LTRIM(STR(@SumSaldoPlus, 9, 2))

							GOTO LABEL_OSTATOK1
						END
					END

				END

				IF @debug = 1
					PRINT N'Осталось раскидать: ' + STR(@Paymaccount, 9, 2)
			--IF @debug = 1 SELECT * FROM @t1
			END
			ELSE
			IF @SumSaldo > 0
			BEGIN
				IF @Paymaccount_minus = 0
					OR ((@SumSaldo) < (@Paymaccount - @Paymaccount_peny))
				BEGIN -- раскидываем только на долг(сальдо с +)
					SET @metod_name = 'Метод - Saldo 2(+)'
					SET @koef = @Paymaccount / @SumSaldoPlus

					IF @debug = 1
						PRINT @metod_name + ' Раскидка только на положит. сальдо . Коэф:' + STR(@koef, 9, 6)

					--IF ABS(ROUND(@koef, 4)) BETWEEN 0.0001 AND 1000
					UPDATE @t1
					SET paymaccount = paymaccount + saldo_new * @koef
					WHERE saldo_new > 0
					SET @msg_log = @msg_log + ';@SumSaldoPlus=' + LTRIM(STR(@SumSaldoPlus, 9, 2))
				END
				ELSE
				BEGIN
					SET @metod_name = 'Метод - Saldo 2(-)'
					--SET @koef = (@Paymaccount - @Paymaccount_peny) / @SumSaldo
					SET @koef = @Paymaccount / @SumSaldo

					IF @debug = 1
						PRINT @metod_name + N' Раскидка так же на отриц. сальдо . Коэф:' + STR(@koef, 16, 10)

					UPDATE @t1
					SET paymaccount = paymaccount + saldo_new * @koef
					SET @msg_log = @msg_log + ';@SumSaldo=' + LTRIM(STR(@SumSaldo, 9, 2))
				END

				GOTO LABEL_OSTATOK1
			END -- if @SumSaldo<>0

			IF @Paymaccount = 0
				GOTO LABEL_OSTATOK1

			SET @msg_log = @msg_log + ';@Paymaccount=' + LTRIM(STR(@Paymaccount, 9, 2))
		-- 2. Пробуем раскидать по paid_prev
		--region PAID_PREV
		PAID_PREV:
			IF (@Paymaccount <> 0)
				AND ((@Sumpaid_prev * 1.01) > ABS(@Paymaccount)) -- 14 ноября 2005   @Sumpaid_prev+1%
			BEGIN
				SET @metod_name = 'Метод - paid_prev'
				SET @msg_log = @msg_log + ';@Sumpaid_prev=' + LTRIM(STR(@Sumpaid_prev, 9, 2))
				SET @koef = @Paymaccount / @Sumpaid_prev

				IF @debug = 1
					PRINT @metod_name + ' Раскидать:' + STR(@Paymaccount, 9, 2) + ' Коэф:' + STR(@koef, 9, 5)

				UPDATE @t1
				SET paymaccount = paymaccount + (paid_prev * @koef)
				WHERE paid_prev > 0

				GOTO LABEL_OSTATOK1
			END -- if @Sumpaid_prev>0   
		--endregion

		-- 3. Пробуем раскидать по paid
		--region PAID
		PAID:
			IF @SumPaid > 0
				AND ABS(@Paymaccount) > 0
			BEGIN
				SET @metod_name = 'Метод - PAID'
				SET @msg_log = @msg_log + ';@SumPaid=' + LTRIM(STR(@SumPaid, 9, 2))
				SET @koef = @Paymaccount / @SumPaid
				IF @debug = 1
					PRINT @metod_name + ' Раскидать: ' + STR(@Paymaccount, 9, 2) + ' Коэф:' + STR(@koef, 9, 5)

				UPDATE @t1
				SET paymaccount = paymaccount + (paid * @koef)
				WHERE paid > 0

				GOTO LABEL_OSTATOK1
			END -- if @SumPaid>0   
		--endregion PAID

		-- 4. Пробуем раскидать по value
		--region VALUE
		VALUE:

			BEGIN /* 4. Пробуем раскидать по value */
				IF (@Paymaccount <> 0)
					AND @SumValue > 0
				BEGIN
					SET @metod_name = 'Метод - VALUE'
					SET @msg_log = @msg_log + ';@SumValue=' + LTRIM(STR(@SumValue, 9, 2))
					SET @koef = @Paymaccount / @SumValue

					IF @debug = 1
						PRINT @metod_name + ' Раскидать: ' + STR(@Paymaccount, 9, 2) + ' Коэф:' + STR(@koef, 9, 5)

					UPDATE @t1
					SET paymaccount = paymaccount + (value * @koef)
					WHERE value > 0

					GOTO LABEL_OSTATOK1
				END -- if @SumValue>0   
			END
			--endregion

			-- 5. Раскидываем по истории предыдущих начислений
			IF (@Paymaccount <> 0)
			BEGIN
				SET @metod_name = 'Метод - History VALUE'
				IF @debug = 1
					PRINT N'Раскидываем по истории предыдущих начислений'

				SET @Fin_id_start = @fin_id - 12

				UPDATE t
				SET value = p.value
				FROM @t1 AS t
					JOIN (
						SELECT service_id
							 , SUM(ph.value) AS value
						FROM dbo.Paym_history ph 
						WHERE ph.occ = @occ1
							AND ph.fin_id > @Fin_id_start
							AND ph.sup_id = @sup_id
						GROUP BY ph.service_id
					) AS p ON t.service_id = p.service_id

				SELECT @SumValue = SUM(value)
				FROM @t1
				IF @SumValue > 0
				BEGIN
					SET @koef = @Paymaccount / @SumValue
					SET @msg_log = @msg_log + ';@SumValue=' + LTRIM(STR(@SumValue, 9, 2))

					UPDATE @t1
					SET paymaccount = paymaccount + (value * @koef)
					WHERE value > 0

					GOTO LABEL_OSTATOK1
				END

			END

			-- 6. Раскидываем по тарифам
			IF (@Paymaccount <> 0)
				AND @SumTarif > 0
			BEGIN
				SET @metod_name = 'Метод - Tarif'
				SET @msg_log = @msg_log + ';@SumTarif=' + LTRIM(STR(@SumTarif, 9, 2))
				SET @koef = @Paymaccount / @SumTarif
				IF @debug = 1
					PRINT @metod_name + ' Раскидать: ' + STR(@Paymaccount, 9, 2) + ' Коэф:' + STR(@koef, 9, 5)

				UPDATE @t1
				SET paymaccount = paymaccount + (tarif * @koef)
				WHERE tarif > 0;

				GOTO LABEL_OSTATOK1;
			END -- if @SumTarif>0   


			--7. Если есть пени с прошлого месяца - раскидаем пропорционально прошлому пени		
			SELECT @SumPenaltyOld = COALESCE(SUM(peny_old), 0)
			FROM dbo.Peny_all pa 
			WHERE occ = @occ1
				AND pa.fin_id = @fin_id;

			IF (@Paymaccount <> 0)
				AND @SumPenaltyOld > 0
			BEGIN
				SET @metod_name = 'Метод - PenaltyOld'
				SET @msg_log = @msg_log + ';@SumPenaltyOld=' + LTRIM(STR(@SumPenaltyOld, 9, 2))
				SET @koef = @Paymaccount / @SumPenaltyOld
				IF @debug = 1
					PRINT @metod_name + ' :' + STR(@SumPenaltyOld, 12, 2) + ' Коэф:' + STR(@koef, 9, 5)

				UPDATE t
				SET paymaccount = t.paymaccount + (t.penalty_old * @koef)
				FROM @t1 AS t
				WHERE t.penalty_old > 0;

				GOTO LABEL_OSTATOK1;
			END

			--8 Раскидываем на оплату, которую уже раскидали ранее
			SELECT @ostatok = SUM(paymaccount)
			FROM @t1
			IF @Paymaccount <> 0
				AND @ostatok > 0		  -- @Paymaccount- осталось раскидать
			BEGIN   -- Расскидываеи пропорционально оплате
				SET @metod_name = 'Метод - Paymaccount'
				SET @koef = @Paymaccount / @ostatok
				IF @debug = 1
					PRINT @metod_name + ' Раскидать: ' + STR(@Paymaccount, 9, 2) + ' Коэф:' + STR(@koef, 9, 5)

				UPDATE @t1
				SET paymaccount = paymaccount + (paymaccount * @koef)
				WHERE paymaccount > 0

				GOTO LABEL_OSTATOK1
			END

		--**********************
		LABEL_OSTATOK1:

			IF @debug = 1
				PRINT N'Проверяем остатки'

			UPDATE T
			SET paymaccount = paymaccount + debt_new
			FROM @t1 AS T
			WHERE debt_new < 0
				AND overpayment_blocked = 1;

			SELECT @ostatok = SUM(paymaccount)
			FROM @t1

			SET @ostatok = @Paym_start - @ostatok;

			IF @ostatok = 0
			BEGIN
				IF @debug = 1
					PRINT N'Остатка нет'
			END
			ELSE
			BEGIN
				DECLARE @serv1 VARCHAR(10) = NULL --услуга на которую надо кинуть погрешность

				SELECT TOP 1 @serv1 = service_id
				FROM @t1
				WHERE value > 0
				ORDER BY overpayment_blocked
					   , value DESC
					   , procent DESC
				SET @metod_ostatok = CASE
                                         WHEN @serv1 IS NOT NULL THEN 'Вариант 1'
                                         ELSE NULL
                    END
				IF @debug = 1
					PRINT N'Услуга по overpayment_blocked, value DESC, procent DESC: ' + COALESCE(@serv1, '-')

				IF @serv1 IS NULL
				BEGIN
					SELECT TOP 1 @serv1 = service_id
					FROM @t1
					WHERE saldo <> 0
						OR paid <> 0
						OR tarif <> 0
					ORDER BY saldo DESC
						   , paid
						   , tarif
					IF @debug = 1
						PRINT N'Услуга по ORDER BY saldo DESC,paid,tarif: ' + COALESCE(@serv1, '-')
					SET @metod_ostatok = CASE
                                             WHEN @serv1 IS NOT NULL THEN 'Вариант 2'
                                             ELSE NULL
                        END
				END

				--**************************************************************
				IF @serv1 IS NULL
				BEGIN
					-- находим общие итоги начислений по услугам
					SET @Fin_id_start = 144 --@fin_id - 6

					UPDATE t
					SET value = p.value
					FROM @t1 AS t
						JOIN (
							SELECT service_id
								 , SUM(ph.value) AS value
							FROM dbo.Paym_history ph 
							WHERE ph.occ = @occ1
								AND ph.fin_id > @Fin_id_start
								AND ph.sup_id = @sup_id
							GROUP BY ph.service_id
						) AS p ON t.service_id = p.service_id

					SELECT TOP 1 @serv1 = service_id
					FROM @t1
					WHERE value > 0
					ORDER BY value DESC
					SET @metod_ostatok = CASE
                                             WHEN @serv1 IS NOT NULL THEN 'Вариант 3'
                                             ELSE NULL
                        END
					IF @debug = 1
						PRINT N'Услуга из истории начислений: ' + COALESCE(@serv1, '-')
				END
				--**************************************************************
				IF @serv1 IS NULL
				BEGIN
					SELECT TOP 1 @serv1 = service_id
					FROM @t1
					WHERE (mode_id % 1000) > 0
					ORDER BY sort_no

					SET @metod_ostatok = CASE
                                             WHEN @serv1 IS NOT NULL THEN 'Вариант 4'
                                             ELSE NULL
                        END
					IF @debug = 1
						PRINT N'Услуга c режимом и ORDER BY sort_no: ' + COALESCE(@serv1, '-')
				END

				IF @debug = 1
				BEGIN
					SELECT '@ostatok' = @ostatok
						 , '@koef' = @koef
						 , '@serv1' = @serv1
					PRINT @serv1 + ' - ' + STR(@ostatok, 9, 2)
				END

				;WITH cte AS(
					SELECT TOP (1) * FROM @t1 WHERE service_id = @serv1
				)
				UPDATE cte
				SET paymaccount = paymaccount + @ostatok;
				
				SET @msg_log = @msg_log + ';@serv1=' + COALESCE(@serv1, '?')
				SET @msg_log = STUFF(@msg_log, 1, 1, '')  -- убираем первый символ ";"
			END
			IF @debug_file = 1
			BEGIN
				DELETE FROM [dbo].[Paying_log]
				WHERE paying_id = @paying_id

				INSERT INTO Paying_log (paying_id
									  , pack_id
									  , occ
									  , sup_id
									  , value
									  , koef
									  , ostatok
									  , metod_name
									  , metod_ostatok
									  , msg_log)
				VALUES(@paying_id
					 , @pack_id
					 , @occ1
					 , @sup_id
					 , @Paym_start
					 , @koef
					 , @ostatok
					 , @metod_name
					 , @metod_ostatok
					 , @msg_log);
				IF @debug = 1
					SELECT 'PAYING_LOG'
						 , *
					FROM Paying_log
					WHERE paying_id = @paying_id
			END
			IF @debug = 1
				SELECT t.*
				FROM @t1 AS t

		END --if @Paymaccount>0

		-- Проверяем
		SELECT @ostatok = SUM(paymaccount)
		FROM @t1

		IF @debug = 1
			SELECT '@Paymaccount' = @Paym_start
				 , ostatok = @ostatok

		IF @ostatok <> @Paym_start
		BEGIN

			IF (@ostatok = 0)
				AND (@Paym_start <> 0)
				BEGIN
					;WITH cte AS (
						SELECT top(1) * FROM @t1 where dolg<>0 or paid<>0 or paid_prev<>0 or penalty_old<>0
					)
					UPDATE cte
					SET paymaccount = @Paym_start;					
				END
			ELSE
				RETURN -1 -- не смогли раскидать по услугам

		END

		-- раскидываем банковскую комиссию по услугам
		IF @commission <> 0
			AND @Paym_start <> 0
		BEGIN

			IF @debug = 1
				PRINT N'Коммиссия:' + STR(@commission, 9, 2)

			SELECT @Sum_Paym_plus = SUM(paymaccount)
			FROM @t1
			WHERE paymaccount <> 0;

			SET @koef = @commission / @Sum_Paym_plus;

			UPDATE @t1
			SET commission = paymaccount * @koef
			WHERE paymaccount <> 0;

			-- проверяем
			SELECT @ostatok = SUM(commission)
			FROM @t1

			IF @ostatok <> @commission
			BEGIN
				SET @ostatok = @commission - @ostatok;

				WITH cte AS	(
					SELECT TOP (1) * FROM @t1 WHERE commission <> 0	ORDER BY commission DESC
				)
				UPDATE cte
				SET commission = commission + @ostatok;

				IF @debug = 1
					PRINT N'Остаток коммиссии:' + STR(@ostatok, 9, 2)
			END

		END

	LABEL_ADD_PAYINGS:

		IF @debug = 1
			PRINT 'Paym_start: ' + STR(@Paym_start, 9, 2)

		IF (@Paym_start <> 0)
		BEGIN
			IF @debug = 1
				PRINT 'LABEL_ADD_PAYINGS'

			IF @trancount = 0
				BEGIN TRANSACTION
			ELSE
				SAVE TRANSACTION k_payings_serv_add3;

			IF @debug = 1
				SELECT 'LABEL_ADD_PAYINGS'
					 , paying_id
					 , service_id
					 , fin_id
					 , occ
					 , sup_id
					 , paymaccount
					 , commission
				FROM @t1
				WHERE paymaccount <> 0
			
			IF @debug = 1
				SELECT 'PAYING_SERV'
					 , paying_id
					 , service_id
					 , occ
					 , sup_id
					 , value
					 , commission
				FROM dbo.Paying_serv
				WHERE paying_id = @paying_id
					--AND occ = @occ1

			DELETE FROM dbo.Paying_serv
			WHERE paying_id = @paying_id
			--AND fin_id = @fin_id
			--AND occ = @occ1

			INSERT INTO dbo.Paying_serv (paying_id
									   , service_id
									   , occ
									   , sup_id
									   , value
									   , commission)
			SELECT @paying_id
				 , service_id
				 , occ
				 , sup_id
				 , paymaccount
				 , commission
			FROM @t1
			WHERE paymaccount <> 0;

			IF @debug = 1
				SELECT paying_id
					 , service_id
					 , fin_id
					 , occ
					 , sup_id
					 , paymaccount
					 , commission
				FROM @t1
				WHERE paymaccount <> 0

			IF @trancount = 0
				COMMIT TRAN

			-- раскидка оплаты пени
			IF @Paymaccount_peny <> 0
			BEGIN
				IF @debug = 1
				BEGIN
					PRINT 'Раскидка оплаты пени'
					PRINT CONCAT('EXEC dbo.k_paying_serv_peny @paying_id=',@paying_id,',@Paymaccount_peny=', dbo.nstr(@Paymaccount_peny),',@debug=', @debug)
				END
				EXEC dbo.k_paying_serv_peny @paying_id = @paying_id
										  , @Paymaccount_peny = @Paymaccount_peny
										  , @debug = @debug
			END

			-- раскидка оплаты для фискализации чеков
			IF @debug = 1
			BEGIN
				PRINT 'раскидка оплаты для фискализации чеков'
				PRINT CONCAT('EXEC dbo.k_pay_cash_update @paying_id=', @paying_id,',@occ1=', @occ1)
			END
			EXEC k_pay_cash_update @occ1 = @occ1
								 , @paying_id1 = @paying_id

		END

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
			ROLLBACK TRANSACTION k_payings_serv_add3;


		DECLARE @strerror VARCHAR(4000) = ''
		EXECUTE k_GetErrorInfo @visible = 0
							 , @strerror = @strerror OUT
		RAISERROR (@strerror, 16, 1)

	END CATCH
go

