CREATE   PROCEDURE [dbo].[k_raschet_peny]
(
	  @occ1 INT
	, @debug BIT = 0
	, @fin_id1 SMALLINT = NULL -- финансовый период
	, @DateCurrent1 SMALLDATETIME = NULL
)
AS
	/*
		--Перерасчет пени по заданному лицевому
		--автор: Пузанов
		
		exec dbo.k_raschet_peny @occ1=350260067,@debug=1	
		exec dbo.k_raschet_peny @occ1=6242428,@debug=1		
		exec dbo.k_raschet_peny @occ1=680003591,@debug=1		
	*/

	SET NOCOUNT ON

	DECLARE @err INT -- код ошибки
		  , @fin_current SMALLINT -- текущий фин. период

	DECLARE @fin_pred1 SMALLINT -- предыдущий фин. период
		  , @fin_pred2 SMALLINT -- пред предыдущий фин. период
		  , @fin_Dolg SMALLINT -- код периода за который долг

	DECLARE @end_date SMALLDATETIME
		  , @start_date SMALLDATETIME
		  , @PenyProc DECIMAL(10, 4) -- процент пени в день
		  , @kol_day SMALLINT -- кол-во дней просрочки
		  , @PaymClosed1 BIT -- признак закрытия платежного периода
		  , @Penalty_old_edit TINYINT -- признак ручного изменения пени        
		  , @PaymClosedData SMALLDATETIME
		  , @PaymClosedDataPred SMALLDATETIME -- дата закрытия предыдущего периода
		  , @Paymaccount DECIMAL(9, 2) = 0 --  оплата в этом месяце
		  , @Paymaccount_sum DECIMAL(9, 2) = 0 --  оплата в этом месяце
		  , @tip_id SMALLINT
		  , @Penalty_metod SMALLINT = 1
		  , @LastPaym TINYINT -- Последний день оплаты (напр. 10 число)
		  , @LastPaymBuild TINYINT -- Последний день оплаты по дому (напр. 20 число)
		  , @LastDatePaym SMALLDATETIME -- Последний день оплаты (напр. 10 число)
		  , @Last_day_month TINYINT -- Последний день месяца
		  , @Peny_old DECIMAL(9, 2) = 0
		  , @saldo DECIMAL(9, 2) = 0
		  , @penalty_paym_no BIT = 0 -- не оплачиваем пени по л/счёту	
		  , @PenyBeginDolg DECIMAL(9, 2) -- начальная сумма долга для расчёта пени
		  , @Penalty_old_new DECIMAL(9, 2) = 0
		  , @Penalty_old_new2 DECIMAL(9, 2) = 0

	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	BEGIN TRY

		IF dbo.Fun_GetOccClose(@occ1) = 0
		BEGIN
			-- raiserror('Лицевой счет %d закрыт! Работа с ним запрещена',16,1,@occ1)
			DELETE FROM dbo.Peny_all
			WHERE occ = @occ1
				AND fin_id = @fin_current
			DELETE FROM dbo.Peny_detail
			WHERE occ = @occ1
				AND fin_id = @fin_current
			RETURN
		END

		SELECT @start_date = start_date
			 , @end_date = end_date
			 , @Last_day_month = DAY(end_date)
			 , @PenyProc = PenyProc
		FROM dbo.Global_values 
		WHERE fin_id = @fin_current

		IF @DateCurrent1 IS NULL
			SET @DateCurrent1 = CAST(current_timestamp AS DATE)

		IF @end_date > @DateCurrent1
			SET @end_date = @DateCurrent1

		IF (@fin_id1 IS NULL)
			OR (@fin_id1 = 0)
			SET @fin_id1 = @fin_current

		DECLARE @penalty_calc1 BIT -- признак начисления пени на лицевом
			  , @penalty_calc_tip1 BIT -- признак начисления пени на типе фонде
			  , @penalty_calc_build BIT -- признак начисления пени на доме
			  , @peny_paym_blocked BIT -- признак блокировки оплаты пени на типе фонда
			  , @peny_nocalc_date_begin SMALLDATETIME -- дата начала перерыва начисления пени на лицевом
			  , @peny_nocalc_date_end SMALLDATETIME -- дата окончания перерыва начисления пени на лицевом

		DECLARE @paym_order_metod VARCHAR(10)
			  , @paying_order_metod VARCHAR(10)
			  , @total_sq DECIMAL(9, 2)
			  , @is_peny_blocked_total_sq_empty BIT = 0

		SELECT @Peny_old = o.penalty_old
			 , @Penalty_old_edit = o.Penalty_old_edit
			 , @penalty_calc1 = o.Penalty_calc
			 , @penalty_calc_tip1 = ot.penalty_calc_tip
			 , @Penalty_metod = ot.penalty_metod
			 , @peny_paym_blocked = ot.peny_paym_blocked
			 , @penalty_calc_build = CASE
                                         WHEN b.is_paym_build = 0 THEN 0
                                         ELSE b.penalty_calc_build
            END
			 , @LastPaym = COALESCE(ot.lastpaym, @LastPaym)
			 , @peny_nocalc_date_begin = o.peny_nocalc_date_begin
			 , @peny_nocalc_date_end = o.peny_nocalc_date_end
			 , @tip_id = o.tip_id
			 , @paym_order_metod = ot.paym_order_metod
			 , @LastPaym = ot.lastpaym
			 , @LastPaymBuild = b.lastpaym
			 , @PaymClosed1 = ot.PaymClosed
			 , @PaymClosedData = dbo.Fun_GetOnlyDate(ot.PaymClosedData)
			 , @Paymaccount = paymaccount
			 , @saldo = o.saldo
			 , @penalty_paym_no = COALESCE(b.penalty_paym_no, 0)
			 , @PenyBeginDolg = ot.PenyBeginDolg
			 , @Penalty_old_new = o.Penalty_old_new
			 , @total_sq = o.total_sq
			 , @is_peny_blocked_total_sq_empty = ot.is_peny_blocked_total_sq_empty
		FROM dbo.Occupations AS o 
			JOIN dbo.Occupation_Types AS ot ON o.tip_id = ot.id
			JOIN dbo.Flats AS f ON o.flat_id = f.id
			JOIN dbo.Buildings AS b ON f.bldn_id = b.id
		WHERE occ = @occ1

		--IF @Penalty_metod>2 SET @Penalty_metod=2
		IF @debug = 1
			PRINT 'Метод пени: ' + STR(@Penalty_metod)
		IF @Penalty_metod > 2
		BEGIN
			EXEC k_raschet_peny_2016 @occ1 = @occ1
								   , @fin_id1 = @fin_id1
								   , @debug = @debug
			RETURN
		END
		ELSE
		IF @debug = 1
			PRINT 'EXEC k_raschet_peny'

		IF @tip_id IS NULL
		BEGIN
			IF @debug = 1
				PRINT 'Лицевой ' + STR(@occ1) + ' для расчёта пени не найден'
			RETURN
		END

		IF @debug = 1
			PRINT 'Лицевой ' + STR(@occ1) + ' ****************************' + STR(@Peny_old)

		IF @penalty_calc_build = 0
			OR @penalty_calc_tip1 = 0
			SET @penalty_calc1 = 0

		IF @total_sq = 0
			AND @is_peny_blocked_total_sq_empty = 1
			SET @penalty_calc1 = 0

		-- Если есть действующее соглашение о рассрочке то пени не считаем
		IF EXISTS (
				SELECT 1
				FROM dbo.Pid 
				WHERE occ = @occ1
					AND pid_tip = 3
					AND @start_date BETWEEN data_create AND data_end
			)
			SET @penalty_calc1 = 0

		IF @debug = 1
			SELECT @DateCurrent1
				 , @end_date
		-- Последний раз можно считать в день закрытия платежного периода
		IF (@PaymClosed1 = 1)
			AND (@PaymClosedData < @DateCurrent1) --  27.09.2005
			AND (@end_date > @PaymClosedData) -- 05.03.2015
		BEGIN
			--PRINT 'Платежный период закрыт пени считать больше не буду!'
			--RETURN 0        -- 15/07/12
			SELECT @DateCurrent1 = @PaymClosedData
				 , @end_date = @PaymClosedData
		END
		IF @debug = 1
			SELECT @DateCurrent1
				 , @end_date
		--  14.03.2006
		IF EXISTS (
				SELECT 1
				FROM dbo.Occupations AS o 
				WHERE o.occ = @occ1
					AND NOT EXISTS (
						SELECT 1
						FROM dbo.Paym_list pl
						WHERE pl.occ = o.occ
							AND pl.account_one = 0
						GROUP BY pl.occ
						HAVING SUM(pl.paymaccount) = o.paymaccount
					)
			)
		BEGIN -- оплата еще не раскидана
			--  Процедура раскидки оплаты
			EXEC dbo.k_raschet_paymaccount @occ1
		END

		--DECLARE @t_paym_order TABLE
		--	(
		--		id		INT	IDENTITY (1, 1)
		--		,name	VARCHAR(20)
		--	)
		--INSERT
		--INTO @t_paym_order
		--		SELECT
		--			*
		--		FROM STRING_SPLIT(@paym_order, ';')

		--SELECT
		--	@NumberPeny = id
		--FROM @t_paym_order
		--WHERE name = 'Пени'
		--SELECT
		--	@NumberDolg = id
		--FROM @t_paym_order
		--WHERE name = 'Долг'
		--SELECT
		--	@NumberPaym = id
		--FROM @t_paym_order
		--WHERE name = 'Начисление'

		IF @debug = 1
			PRINT 'Метод оплаты пени по типу фонда:' + LTRIM(@paym_order_metod)
		--PRINT 'Пени:' + LTRIM(STR(@NumberPeny)) + ' Долг:' + LTRIM(STR(@NumberDolg)) + ' Начисление:' + LTRIM(STR(@NumberPaym))

		SET @fin_pred1 = @fin_id1 - 1
		SET @fin_pred2 = @fin_id1 - 2
		SELECT @PaymClosedDataPred = dbo.Fun_GetOnlyDate(PaymClosedData)
		FROM dbo.Occupation_Types_History AS OTH
		WHERE fin_id = @fin_pred1
			AND id = @tip_id

		DECLARE @t1 TABLE (
			  id SMALLINT IDENTITY (1, 1) 		--DEFAULT 0  --SMALLINT
			, data1 SMALLDATETIME
			, data2 SMALLDATETIME
			, paymaccount DECIMAL(9, 2) DEFAULT 0
			, paying_id INT DEFAULT NULL
			, peny_old DECIMAL(9, 2) DEFAULT 0
			, peny_old_new DECIMAL(9, 2) DEFAULT 0
			, paymaccount_peny DECIMAL(9, 2) DEFAULT 0
			, dolg DECIMAL(9, 2) DEFAULT 0
			, dolg_peny DECIMAL(9, 2) DEFAULT 0
			, kol_day AS DATEDIFF(DAY, data1, data2)
			, penalty_value DECIMAL(9, 2) DEFAULT 0--as dolg_peny*PenyProc*0.01*DATEDIFF(DAY,data1,data2)
			, descrip VARCHAR(1000) DEFAULT NULL
			, paying_order_metod VARCHAR(10) DEFAULT NULL
		)

		IF @debug = 1
			SELECT @peny_nocalc_date_begin AS peny_nocalc_date_begin
				 , @start_date AS start_date
				 , @end_date AS end_date
				 , @penalty_calc1 AS Penalty_calc
				 , @DateCurrent1 AS DateCurrent
				 , @PaymClosedDataPred AS PaymClosedDataPred

		--============================================================================
		IF @peny_nocalc_date_begin IS NOT NULL
			OR @peny_nocalc_date_end IS NOT NULL
		BEGIN
			if @debug=1 PRINT 'корректировка перерыва расчета пени'
			
			IF @peny_nocalc_date_begin IS NULL
			BEGIN
				IF @peny_nocalc_date_end<@start_date
					SET @peny_nocalc_date_begin=@peny_nocalc_date_end
				ELSE
					SET @peny_nocalc_date_begin=@start_date
			END

			IF @peny_nocalc_date_end IS NULL
			BEGIN
				IF @peny_nocalc_date_begin>@end_date
					SET @peny_nocalc_date_end=@peny_nocalc_date_begin
				ELSE
					SET @peny_nocalc_date_end=@end_date
			END
		END
		IF @start_date between @peny_nocalc_date_begin AND @peny_nocalc_date_end
			SET @penalty_calc1=0
		IF @end_date between @peny_nocalc_date_begin AND @peny_nocalc_date_end
			SET @penalty_calc1=0
		--============================================================================

		IF @end_date < @start_date
			SET @end_date = @start_date

		IF @LastPaymBuild IS NOT NULL
			AND @LastPaymBuild > 0
			SET @LastPaym = @LastPaymBuild

		IF @LastPaym IS NULL
			SET @LastPaym = 10

		IF @LastPaym = 31
			OR @LastPaym > 31
			SET @LastPaym = 1

		-- в феврале может быть 28
		IF @LastPaym > @Last_day_month
			SET @LastPaym = @Last_day_month

		SET @LastDatePaym = DATEFROMPARTS(YEAR(@start_date), MONTH(@start_date), @LastPaym)

		IF @debug = 1
			SELECT @LastPaym AS LastPaym
				 , @LastDatePaym AS LastDatePaym
				 , @PaymClosedDataPred AS PaymClosedDataPred
				 , @peny_nocalc_date_begin AS peny_nocalc_date_begin
				 , @start_date AS start_date
				 , @end_date AS end_date
				 , @penalty_calc1 AS Penalty_calc
				 , @PenyProc AS PenyProc

		DECLARE @d1 SMALLDATETIME
			  , @i SMALLINT = 1
		SELECT @d1 = @start_date - 20 -- даём 20 дней (если не все были закрыты платежи в прошлом месяце)

		INSERT INTO @t1 (paying_id
					   , data1
					   , paymaccount
					   , paying_order_metod)
		SELECT p.id
			 , pd.day
			 , p.value
			 , po.paying_order_metod
		FROM dbo.Payings AS p 
			JOIN dbo.Paydoc_packs AS pd ON pd.id = p.pack_id
			JOIN dbo.Paycoll_orgs AS po ON pd.fin_id = po.fin_id
				AND pd.source_id = po.id
			JOIN dbo.Paying_types AS pt ON po.vid_paym = pt.id
		WHERE p.fin_id = @fin_id1
			AND p.occ = @occ1
			AND p.sup_id = 0
			AND pt.peny_no = 0 -- доля оплаты пени только такие виды платежей
			AND p.forwarded = 1

		IF @debug = 1
			PRINT DATEDIFF(DAY, @d1, @end_date)

		IF NOT EXISTS (SELECT 1 FROM @t1)
		BEGIN
			INSERT INTO @t1 (data1)
			SELECT DATEADD(DAY, n, @d1)
			FROM dbo.Fun_GetNums(1, DATEDIFF(DAY, @d1, @end_date))
		END

		UPDATE @t1
		SET paying_id = 0
		WHERE data1 IN (@start_date, @LastDatePaym)
			AND paymaccount = 0 -- 21.10.2015

		DELETE FROM @t1
		WHERE paying_id IS NULL

		UPDATE t1
		SET data2 = (
			SELECT TOP 1 data1
			FROM @t1 AS t2
			WHERE t2.data1 > t1.data1
			ORDER BY t2.id
		)
		FROM @t1 AS t1

		UPDATE @t1
		SET data2 = @end_date
		WHERE id = (
				SELECT TOP 1 id
				FROM @t1
				ORDER BY id DESC
			)
		UPDATE @t1
		SET data2 = data1 --  29.06.17 может @end_date  ?
		WHERE data2 IS NULL

		IF @Paymaccount > 0
			AND NOT EXISTS (
				SELECT 1
				FROM @t1
				WHERE paymaccount <> 0
			)
		BEGIN
			UPDATE td
			SET paymaccount = p.value
			  , paying_id = p.id
			  , paying_order_metod = po.paying_order_metod
			FROM dbo.Payings AS p 
				JOIN dbo.Paydoc_packs AS pd ON pd.id = p.pack_id
				JOIN dbo.Paycoll_orgs AS po ON pd.fin_id = po.fin_id
					AND pd.source_id = po.id
				JOIN dbo.Paying_types AS pt ON po.vid_paym = pt.id
				JOIN @t1 AS td ON td.id = (
						SELECT TOP 1 id
						FROM @t1
						ORDER BY id
					)
			WHERE p.fin_id = @fin_id1
				AND p.occ = @occ1
				AND p.service_id IS NULL
				AND p.sup_id = 0
				AND pt.peny_no = 0
				AND p.forwarded = 1
		END

		SELECT @Paymaccount_sum = SUM(COALESCE(paymaccount, 0))
		FROM @t1
		IF @debug = 1
			PRINT 'Paymaccount=' + STR(@Paymaccount, 9, 2) + ' Paymaccount_sum=' + STR(@Paymaccount_sum, 9, 2)
		--IF @Paymaccount>@Paymaccount_sum
		--BEGIN
		--	UPDATE t
		--	SET paymaccount=@Paymaccount-@Paymaccount_sum
		--	FROM @t1 AS t
		--	WHERE id=(SELECT TOP 1 id FROM @t1 WHERE t.paymaccount=0 ORDER BY id)
		--END

		-- Первая строка
		UPDATE t
		SET peny_old = @Peny_old
		FROM @t1 AS t
		WHERE id = (
				SELECT TOP 1 id
				FROM @t1
				ORDER BY id
			)

		--IF @debug=1 SELECT * FROM @t1
		--UPDATE t
		--SET id=(select COUNT(*) FROM @t1 as t2 where t.data1>=t2.data1)
		--FROM @t1 AS t


		--if @debug=1 select * from @t1 ORDER BY data1
		--return 
		-- ************************************************
		DECLARE @SumPaymaccount DECIMAL(9, 2)
			  , @SumPaymaccount1 DECIMAL(9, 2) = 0
			  , @DataPaym SMALLDATETIME
			  , @data1 SMALLDATETIME
			  , @DataPaymPred SMALLDATETIME
			  , @Dolg DECIMAL(9, 2) = 0
			  , @Dolg_peny DECIMAL(9, 2) = 0
			  , @Paid_Pred DECIMAL(9, 2) = 0
			  , @Paid_Pred_begin DECIMAL(9, 2) = 0
			  , @Peny_new_serv DECIMAL(9, 2)
			  , @paying_id1 INT
			  , @Peny_old_new DECIMAL(9, 2) = 0
			  , @Peny_old_new_tmp DECIMAL(9, 2) = 0
			  , @Paymaccount_peny DECIMAL(9, 2)
			  , @Paymaccount_serv DECIMAL(9, 2)
			  , @Paymaccount_peny_out DECIMAL(9, 2)
			  , @Description VARCHAR(1000) = ''
			  , @peny_fin_pred_new DECIMAL(9, 2) = 0 -- Рассчитанные пени в прошлом месяце

		--********** Сохраняем сумму начислений предыдущего месяца        
		SELECT @Paid_Pred = SUM(p.paid)
			 , @peny_fin_pred_new = SUM(p.penalty_serv + p.Penalty_old) --SUM(COALESCE(p.penalty_serv, 0))
		FROM dbo.Paym_history AS p 
		--JOIN dbo.SERVICES AS s 
		--	ON p.service_id = s.id
		--AND s.is_peny = 1 -- !!! для расчёта пени
		WHERE p.occ = @occ1
			AND p.fin_id = @fin_pred1
			AND (p.account_one = 0)

		IF @Paid_Pred IS NULL
			SET @Paid_Pred = 0

		SELECT @Paid_Pred_begin = @Paid_Pred

		--************************************************      
		-- обнуляем оплачено пени для начала
		UPDATE p WITH (ROWLOCK)
		SET paymaccount_peny = 0
		FROM dbo.Payings AS p
		--JOIN dbo.PAYDOC_PACKS AS pd 
		--	ON pd.id = p.pack_id
		WHERE p.fin_id = @fin_id1
			AND p.occ = @occ1
			AND p.sup_id = 0
			AND p.peny_save = 0   -- ручная корректировка
			AND p.forwarded = 1

		UPDATE ps WITH (ROWLOCK)
		SET paymaccount_peny = 0
		FROM dbo.Paying_serv AS ps
			JOIN dbo.Payings AS p ON ps.paying_id = p.id
		WHERE p.fin_id = @fin_current
			AND p.occ = @occ1
			AND p.sup_id = 0
			AND p.forwarded = 1

		--************************************************ 
		DELETE FROM dbo.Peny_all
		WHERE occ = @occ1 AND fin_id=@fin_id1
		DELETE FROM dbo.Peny_detail
		WHERE fin_id = @fin_id1
			AND occ = @occ1

		-- ***********************************************

		IF @fin_id1 = @fin_current
		BEGIN
			EXEC dbo.k_raschet_peny_serv_old @occ = @occ1
										   , @fin_id = @fin_id1
										   , @debug = @debug
		END
		-- ***********************************************

		SET @Peny_old_new = @Peny_old
		DECLARE curs CURSOR LOCAL FOR
			SELECT id
				 , paymaccount
				 , data2
				 , paying_id
				 , data1
				 , paying_order_metod
			FROM @t1
			ORDER BY id

		OPEN curs
		FETCH NEXT FROM curs INTO @i, @SumPaymaccount, @DataPaym, @paying_id1, @data1, @paying_order_metod

		WHILE (@@fetch_status = 0)
		BEGIN
			IF @paying_order_metod IS NULL
				SET @paying_order_metod = @paym_order_metod

			IF @penalty_calc1 = 1
			BEGIN
				EXEC dbo.k_GetSumDolg @occ1
									, @fin_current
									, @data1
									, @LastDatePaym
									, 0
									, @Dolg OUT
									, @fin_Dolg OUT
									, @Description OUT
				EXEC dbo.k_GetSumDolgPeny @occ1
										, @fin_current
										, @data1
										, @LastDatePaym
										, 0
										, @Dolg_peny OUT
			END
			--SELECT @Dolg = dbo.Fun_GetSumDolg(@occ1, @fin_current, @data1, @LastDatePaym)						
			--SELECT @Dolg_peny = dbo.Fun_GetSumDolgPeny(@occ1, @fin_current, @data1, @LastDatePaym)


			IF @debug = 1
			BEGIN
				PRINT '@data1=' + CONVERT(VARCHAR(10), @data1, 112)
				PRINT '@LastDatePaym=' + CONVERT(VARCHAR(10), @LastDatePaym, 112)
				PRINT '@Paid_Pred_begin=' + STR(@Paid_Pred_begin, 9, 2)
				PRINT '@fin_current=' + STR(@fin_current)
				PRINT '@Dolg=' + STR(@Dolg, 9, 2)
				PRINT '@Dolg_peny=' + STR(@Dolg_peny, 9, 2)
				PRINT '@paying_order_metod= ' + @paying_order_metod
			END
			--IF @Dolg_peny < 0
			--	SET @Dolg_peny = 0

			--IF @Penalty_metod = 1 AND @Dolg_peny > @Paid_Pred_begin
			--	SET @Dolg_peny = @Paid_Pred_begin -- по методу 1 не более суммы начислений

			SET @Paymaccount_peny = 0

			--****************************************************************************
			-- Порядок оплаты: Пени, Долг, Начисление
			--IF @NumberPeny = 1
			--	AND @NumberDolg = 2
			--	AND @NumberPaym = 3
			IF @paying_order_metod = 'пени1'
			BEGIN
				IF @debug = 1
					PRINT 'Порядок оплаты: Пени, Долг, Начисление'
				SET @Paymaccount_serv = @SumPaymaccount

				-- Находим оплачено пени
				IF (@Peny_old_new > 0)
					AND (@Paymaccount_serv > 0)
					AND (@penalty_paym_no = 0)
				BEGIN
					SET @Peny_old_new = @Peny_old_new - @Paymaccount_serv
					IF @Peny_old_new <= 0
					BEGIN
						SET @Paymaccount_peny = @Paymaccount_serv + @Peny_old_new
						SET @Paymaccount_serv = ABS(@Peny_old_new)
						SET @Peny_old_new = 0
					END
					ELSE
					BEGIN
						SET @Paymaccount_peny = @Paymaccount_serv
						SET @Paymaccount_serv = 0
					END
					IF @debug = 1
						PRINT '@Peny_old_new:' + STR(@Peny_old_new, 9, 2) + ' @Paymaccount_peny:' + STR(@Paymaccount_peny, 9, 2) + ' @Paymaccount_serv:' + STR(@Paymaccount_serv, 9, 2)
				END --
				--IF @debug=1 PRINT '-2'+STR(@Peny_old,9,2)+' '+STR(@Paymaccount_serv,9,2)+' '+STR(@Peny_old_new,9,2)			 
				--IF @debug=1 PRINT '@dolg_peny 1'+str(@dolg_peny,9,2)

				SET @Dolg_peny = @Dolg_peny - @Paymaccount_serv ---@Paymaccount_peny --
				IF @Dolg_peny <= 0
				BEGIN
					SELECT @Paymaccount_serv = @Dolg_peny
					SELECT @Dolg_peny = 0
				END
				ELSE
				BEGIN
					SELECT @Paymaccount_serv = 0
				END

				IF @Paymaccount_serv > 0
					SET @Paid_Pred = @Paid_Pred - @Paymaccount_serv

				IF @Dolg < 0 -- если есть переплата у @Dolg знак минус    5 сентября 2005 Пузанов
					-- чтобы оплата+переплата вычиталась пени
					SET @Paid_Pred = @Paid_Pred + @Dolg

				IF @Paid_Pred < 0
				BEGIN
					SET @Paymaccount_serv = -1 * @Paid_Pred
				END
				ELSE
					SET @Paymaccount_serv = 0
			-- ***************************************************************************
			END
			ELSE
			BEGIN -- Порядок оплаты: Начисление,Долг,Пени
				-- ***************************************************************************       
				IF @debug = 1
				BEGIN
					PRINT 'Порядок оплаты: Начисление,Долг,Пени'
					PRINT '0  ' + STR(@Dolg, 9, 2) + ' ' + STR(@Paid_Pred, 9, 2) + '   ' + STR(@SumPaymaccount, 9, 2) + '   ' + STR(COALESCE(@Paymaccount_serv, 0), 9, 2)
				END

				--IF (@fin_current > @fin_Dolg)  -- 11.06.15
				----AND (@data1>@start_date)
				----IF @Paid_Pred < 0  -- возможно надо закомментировать(надо погашать оплату так как в долг сейчас её не беру)			
				--BEGIN
				--	SELECT
				--		@Dolg = @Dolg + @Paid_Pred

				--	IF @Paid_Pred < 0
				--		SELECT
				--			@Dolg_peny = @Dolg_peny + @Paid_Pred
				--END

				SELECT @Paymaccount_serv = @SumPaymaccount - @Dolg
				IF @Paymaccount_serv < 0
					SET @Paymaccount_serv = 0

				SELECT @Dolg_peny = @Dolg_peny - @SumPaymaccount
					 , @Dolg = @Dolg - @SumPaymaccount -- 24/10/13

				--IF @Dolg < 0 -- если есть переплата у @Dolg знак минус    24/10/13 закоментировал
				--	-- чтобы оплата+переплата вычиталась пени
				--	SET @Dolg_peny = @Dolg_peny + @Dolg					
				IF @data1 >= @start_date
					SET @peny_fin_pred_new = 0

				IF @debug = 1
				BEGIN
					PRINT '@data1=' + CONVERT(VARCHAR(10), @data1, 112)
					PRINT '@Paymaccount_serv=' + STR(@Paymaccount_serv, 9, 2)
					PRINT '@SumPaymaccount=' + STR(@SumPaymaccount, 9, 2)
					PRINT '@Peny_old_new=' + STR(@Peny_old_new, 9, 2)
					PRINT '@Dolg_peny=' + STR(@Dolg_peny, 9, 2)
					PRINT '@Dolg=' + STR(@Dolg, 9, 2)
					PRINT '@Paid_Pred=' + STR(@Paid_Pred, 9, 2)
					PRINT '@fin_Dolg=' + STR(@fin_Dolg) + ' @fin_current=' + STR(@fin_current)
				END

				IF @Paymaccount = @saldo
					SET @penalty_paym_no = 1 -- 21/08/13 не делать оплату пени кто оплатил ровно

				IF (@Dolg) <= 0
					AND (
					((@Peny_old_new - @peny_fin_pred_new) > 0 -- если фин.период ещё не начался нельзя оплачивать пени этого месяца
					AND (@data1 < @start_date))
					OR ((@Peny_old_new > 0)
					AND (@data1 >= @start_date))
					)
					--AND @Peny_old_new > 0
					AND (@Paymaccount_serv > 0)
					AND (@SumPaymaccount > 0)
					AND (@penalty_paym_no = 0) --@Dolg <= 0 AND 
				BEGIN
					IF @debug = 1
						PRINT 'Находим оплачено пени ' + STR(@paying_id1)

					SET @Peny_old_new_tmp = @Peny_old_new - @peny_fin_pred_new
					SET @Peny_old_new = @Peny_old_new_tmp - @Paymaccount_serv

					IF @debug = 1
						PRINT '1' + STR(@Peny_old, 9, 2) + ' ' + STR(@Paymaccount_serv, 9, 2) + ' ' + STR(@Peny_old_new, 9, 2)
					IF @Peny_old_new <= 0
					BEGIN
						SET @Paymaccount_peny = @Paymaccount_serv + @Peny_old_new
						SET @Paymaccount_serv = ABS(@Peny_old_new)
						SET @Peny_old_new = 0
					END
					ELSE
					BEGIN
						SET @Paymaccount_peny = @Paymaccount_serv
						SET @Paymaccount_serv = 0
					END
					SET @Peny_old_new = @Peny_old_new + @peny_fin_pred_new
				END
			-- ***************************************************************************	  
			END

			IF @penalty_paym_no = 1
				SET @Paymaccount_peny = 0

			IF @Paid_Pred_begin < 0
				SET @Dolg_peny = @Dolg_peny + @Paid_Pred_begin
			IF @Dolg_peny < 0
				SET @Dolg_peny = 0

			-- ********************************************

			IF @Penalty_metod = 1
				AND @Dolg_peny > @Paid_Pred_begin
			BEGIN
				SET @Dolg_peny = @Paid_Pred_begin -- по методу 1 не более суммы начисления
				IF @Dolg_peny < 0 -- ещё раз так как бывает начисление с минусом
					SET @Dolg_peny = 0
			END

			UPDATE @t1
			SET dolg = @Dolg
			  , dolg_peny = @Dolg_peny
			  , peny_old = @Peny_old
			  , peny_old_new = @Peny_old_new
			  , paymaccount_peny = @Paymaccount_peny
			  , penalty_value =
							   CASE
								   WHEN (@Dolg_peny > @PenyBeginDolg) THEN @Dolg_peny * 0.01 * @PenyProc * kol_day
								   ELSE 0
							   END
			  , descrip = @Description
			WHERE id = @i

			SET @Paymaccount_peny_out = 0
			--Раскидываем оплачено пени по услугам по платежу
			IF @paying_id1 <> 0
			BEGIN

				IF @debug = 1
					PRINT 'Раскидываем оплачено пени по услугам по платежу ' + STR(@paying_id1) + ' ' + STR(@Paymaccount_peny, 9, 2)
				EXEC k_paying_serv_peny @paying_id = @paying_id1
									  , @Paymaccount_peny = @Paymaccount_peny
									  , @sup_id = 0
									  , @debug = @debug
									  , @Paymaccount_peny_out = @Paymaccount_peny_out OUTPUT
				IF @debug = 1
					PRINT 'Раскидали:' + STR(@Paymaccount_peny_out, 9, 2)
			END
			IF @Paymaccount_peny <> @Paymaccount_peny_out
				SET @Paymaccount_peny = 0
			-- ===============================================

			IF @debug = 1
				PRINT '@dolg: ' + STR(@Dolg, 9, 2) + ' @dolg_peny: ' + STR(@Dolg_peny, 9, 2) + ' @Paid_Pred: ' + STR(@Paid_Pred, 9, 2)


			FETCH NEXT FROM curs INTO @i, @SumPaymaccount, @DataPaym, @paying_id1, @data1, @paying_order_metod
		END

		CLOSE curs
		DEALLOCATE curs
		-- ************************************************

		--UPDATE t
		--SET penalty_value=Dolg_peny*0.01*@PenyProc*kol_day
		--FROM @t1 AS t

		IF @debug = 1
			SELECT @occ1
				 , *
			FROM @t1
			ORDER BY data1
		--SELECT TOP 1 peny_old FROM @t1 ORDER BY id
		--return

		SELECT @SumPaymaccount1 = SUM(COALESCE(p.value, 0))
			 , @Paymaccount_peny = SUM(COALESCE(p.paymaccount_peny, 0))
		FROM dbo.Payings AS p 
		--JOIN dbo.PAYDOC_PACKS AS pd 
		--	ON p.pack_id = pd.id
		WHERE occ = @occ1
			AND p.fin_id = @fin_id1
			AND p.sup_id = 0
			AND p.forwarded = 1
		OPTION (RECOMPILE)

		DECLARE @penalty_added DECIMAL(9, 2)
		SET @penalty_added = COALESCE((
			SELECT pa.value_added
			FROM dbo.Peny_added pa
			WHERE pa.fin_id = @fin_id1
				AND pa.occ = @occ1
		), 0)

		IF @peny_paym_blocked = 1
		BEGIN
			SELECT @Paymaccount_peny = 0
				 , @Peny_old_new = @Peny_old
		END


		INSERT INTO dbo.Peny_all (fin_id
								 , occ
								 , dolg
								 , dolg_peny
								 , paid_pred
								 , paymaccount
								 , paymaccount_peny
								 , peny_old
								 , peny_old_new
								 , penalty_added
								 , penalty_value
								 , kolday
								 , data_rascheta
								 , metod
								 , occ1
								 , sup_id)
		SELECT @fin_id1
			 , @occ1
			 , COALESCE((
				   SELECT TOP 1 dolg
				   FROM @t1
				   ORDER BY data1
			   ), 0) AS dolg
			 , COALESCE((
				   SELECT TOP 1 dolg_peny
				   FROM @t1
				   ORDER BY data1
			   ), 0) AS dolg_peny
			 , @Paid_Pred_begin
			 , COALESCE(@SumPaymaccount1, 0) AS paymaccount
			 , COALESCE(@Paymaccount_peny, 0) AS paymaccount_peny
			 , @Peny_old AS peny_old
			 , @Peny_old - COALESCE(@Paymaccount_peny, 0) AS peny_old_new
			 , @penalty_added
			 , COALESCE((
				   SELECT SUM(COALESCE(penalty_value, 0))
				   FROM @t1
			   ), 0) AS penalty_value
			 , COALESCE((
				   SELECT SUM(COALESCE(kol_day, 0))
				   FROM @t1
			   ), 0) AS kolday
			 , current_timestamp AS data_rascheta
			 , @Penalty_metod AS metod
			 , @occ1
			 , 0 AS sup_id

		IF @debug = 1
			SELECT *
			FROM dbo.Peny_all
			WHERE fin_id = @fin_id1
				AND occ = @occ1

		IF @penalty_calc1 = 1
			INSERT INTO dbo.Peny_detail (fin_id
									   , occ
									   , paying_id
									   , data1
									   , kol_day
									   , dolg_peny
									   , paid_pred
									   , paymaccount_serv
									   , paymaccount_peny
									   , peny_old
									   , peny_old_new
									   , Peny
									   , dat1
									   , dolg
									   , [description])
			SELECT @fin_id1
				 , @occ1
				 , paying_id
				 , data2
				 , kol_day
				 , dolg_peny
				 , @Paid_Pred_begin
				 , paymaccount
				 , paymaccount_peny
				 , peny_old
				 , peny_old_new
				 , penalty_value
				 , data1
				 , dolg
				 , CASE
					   WHEN (penalty_value <> 0) OR
						   (paymaccount <> 0) THEN descrip
					   ELSE NULL
				   --ELSE descrip
				   END
			FROM @t1

		-- Если на ЛС не расчитываем пени то зануляем
		UPDATE dbo.Peny_all WITH (ROWLOCK)
		SET penalty_value = CASE
                                WHEN @penalty_calc1 = 0 THEN 0
                                ELSE penalty_value
            END
		  , paymaccount_peny = CASE
                                   WHEN @peny_paym_blocked = 1 THEN 0
                                   ELSE paymaccount_peny
            END
		WHERE occ = @occ1
			AND fin_id = @fin_id1
		--AND @penalty_calc1 = 0
		--OR @penalty_calc_tip1 = 0
		--OR @penalty_calc_build = 0)

		IF @fin_id1 < @fin_current
		BEGIN
			DELETE FROM dbo.Peny_detail
			WHERE occ = @occ1
				AND fin_id = @fin_id1
			DELETE FROM dbo.Peny_all WITH (ROWLOCK)
			WHERE occ = @occ1
				AND fin_id = @fin_id1
		END

		-- Обновляем на лицевом
		UPDATE o
		SET penalty_value = COALESCE(ps.penalty_value, 0)
		  , @Penalty_old_new2 = Penalty_old_new = COALESCE(ps.peny_old_new, 0)
		  , paymaccount_peny = COALESCE(ps.paymaccount_peny, 0)
		  , Penalty_added = COALESCE(@penalty_added, 0)
		  , penalty_calc = @penalty_calc1
		FROM dbo.Occupations AS o
			JOIN (
				SELECT occ
					 , penalty_value = SUM(penalty_value)
					 , peny_old_new = SUM(peny_old_new)
					 , paymaccount_peny = SUM(paymaccount_peny)
				FROM dbo.Peny_all
				WHERE occ = @occ1
					AND fin_id = @fin_id1
				GROUP BY occ
			) AS ps ON o.occ = ps.occ
		WHERE o.occ = @occ1

		IF @fin_id1 = @fin_current
		BEGIN
			IF @Penalty_old_new2 <> @Penalty_old_new
				EXEC dbo.k_raschet_peny_serv_old @occ = @occ1
											   , @fin_id = @fin_id1

			EXEC dbo.k_raschet_peny_serv @occ = @occ1
									   , @fin_id = @fin_id1
		END

	END TRY
	BEGIN CATCH
		EXEC dbo.k_err_messages
	END CATCH
go

