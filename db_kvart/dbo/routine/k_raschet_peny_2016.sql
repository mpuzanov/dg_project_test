CREATE   PROCEDURE [dbo].[k_raschet_peny_2016]
(
	  @occ1 INT
	, @debug BIT = 0
	, @fin_id1 SMALLINT = NULL -- финансовый период
	, @DateCurrent1 SMALLDATETIME = NULL
)
AS
	/*
    25/11/2018
		Перерасчет пени по заданному лицевому
		автор: Пузанов
		
		exec dbo.k_raschet_peny_2016 @occ1=350260067,@debug=1
		exec dbo.k_raschet_peny_2016 @occ1=6242428,@debug=1
		
	*/

	SET NOCOUNT ON


	DECLARE @err INT -- код ошибки
		  , @fin_current SMALLINT -- текущий фин. период
		  , @db_name VARCHAR(30) = UPPER(DB_NAME())
		  , @msg NVARCHAR(1000)

	DECLARE @fin_pred1 SMALLINT -- предыдущий фин. период
		  , @fin_pred2 SMALLINT -- пред предыдущий фин. период
		  , @fin_Dolg SMALLINT -- код периода за который долг

	DECLARE @end_date SMALLDATETIME
		  , @start_date SMALLDATETIME
		  , @start_fin_period SMALLDATETIME
		  , @end_fin_period SMALLDATETIME
		  , @CurStavkaCB DECIMAL(10, 4) -- текущая ставка центрабанка
		  , @isRaschCurStavkaCB BIT = 1  -- Вести расчёт по текущей ставке центрабанка
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


	-- ************************************************
	DECLARE @SumPaymaccount DECIMAL(9, 2) = 0
		  , @SumPaymaccount1 DECIMAL(9, 2) = 0
		  , @DataPaym SMALLDATETIME
		  , @data1 SMALLDATETIME
		  , @DataPaymPred SMALLDATETIME
		  , @Dolg DECIMAL(9, 2) = 0
		  , @Dolg_peny DECIMAL(9, 2) = 0
		  , @Dolg1 DECIMAL(9, 2) = 0
		  , @Dolg_peny1 DECIMAL(9, 2) = 0
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
		  , @total_sq DECIMAL(9, 2)
		  , @is_peny_blocked_total_sq_empty BIT = 0

	BEGIN TRY

		SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

		IF dbo.Fun_GetOccClose(@occ1) = 0
		BEGIN
			-- raiserror('Лицевой счет %d закрыт! Работа с ним запрещена',16,1,@occ1)
			DELETE FROM dbo.Peny_all
			WHERE Occ = @occ1
				AND fin_id = @fin_current

			DELETE FROM dbo.Peny_detail
			WHERE Occ = @occ1
				AND fin_id = @fin_current
			RETURN
		END

		SELECT @start_date = [start_date]
			 , @end_date = end_date
			 , @start_fin_period = [start_date]
			 , @end_fin_period = end_date
			 , @Last_day_month = DAY(end_date)
			 , @CurStavkaCB = StavkaCB
		FROM dbo.Global_values 
		WHERE fin_id = @fin_current

		IF @DateCurrent1 IS NULL
			SET @DateCurrent1 = dbo.Fun_GetOnlyDate(current_timestamp);

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
			  , @Sum_peny_save DECIMAL(9, 2) = 0

		SELECT @Peny_old = o.Penalty_old
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
			 , @PaymClosedData = CAST(ot.PaymClosedData AS DATE)
			 , @Paymaccount = o.paymaccount
			 , @saldo = o.SALDO
			 , @penalty_paym_no = COALESCE(b.penalty_paym_no, 0)
			 , @PenyBeginDolg = ot.PenyBeginDolg
			 , @Penalty_old_new = o.Penalty_old_new
			 , @total_sq = o.total_sq
			 , @is_peny_blocked_total_sq_empty = ot.is_peny_blocked_total_sq_empty
			 , @isRaschCurStavkaCB = ot.is_peny_current_stavka_cb
		FROM dbo.Occupations AS o 
			JOIN dbo.Occupation_Types AS ot ON o.tip_id = ot.id
			JOIN dbo.Flats AS f  ON o.flat_id = f.id
			JOIN dbo.Buildings AS b ON f.bldn_id = b.id
		WHERE Occ = @occ1

		IF @tip_id IS NULL
		BEGIN
			IF @debug = 1
				PRINT concat('Лицевой ' , @occ1, ' для расчёта пени не найден')
			RETURN
		END

		IF @debug = 1
		BEGIN
			PRINT 'Процедура: k_raschet_peny_2016'
			PRINT concat('Лицевой ' ,@occ1, '  Пени старое:' , @Peny_old)
		END


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
				WHERE Occ = @occ1
					AND pid_tip = 3
					AND @start_date BETWEEN data_create AND data_end
			)
		BEGIN
			SET @penalty_calc1 = 0
			IF @debug = 1
				PRINT 'Есть соглашение о расрочке. Пени не считаем!'
		END

		--IF @debug = 1
		--	SELECT
		--		@DateCurrent1 AS DateCurrent1
		--	   ,@end_date AS end_date

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
			SELECT @DateCurrent1 AS DateCurrent1
				 , @start_date AS [start_date]
				 , @end_date AS end_date


		IF EXISTS (
				SELECT 1
				FROM dbo.Occupations AS o 
				WHERE o.Occ = @occ1
					AND NOT EXISTS (
						SELECT 1
						FROM dbo.Paym_list pl 
						WHERE pl.fin_id = @fin_id1
							AND pl.Occ = o.Occ
							AND pl.sup_id = 0
						GROUP BY pl.Occ
						HAVING SUM(pl.paymaccount) = o.paymaccount
					)
			)
		BEGIN -- оплата еще не раскидана
			IF @debug = 1
				PRINT 'Процедура раскидки оплаты: k_raschet_paymaccount'
			EXEC dbo.k_raschet_paymaccount @occ1
		END

		--DECLARE @t_paym_order TABLE
		--	(
		--		id	 INT IDENTITY (1, 1)
		--	   ,name VARCHAR(20)
		--	)
		--INSERT INTO @t_paym_order
		--	SELECT
		--		*
		--	FROM STRING_SPLIT(@paym_order, ';')
		--	WHERE RTRIM(value) <> ''

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

		--IF @debug = 1
		--	PRINT 'Пени:' + LTRIM(STR(@NumberPeny)) + ' Долг:' + LTRIM(STR(@NumberDolg)) + ' Начисление:' + LTRIM(STR(@NumberPaym))
		IF @debug = 1
			PRINT 'Метод оплаты пени в типе фонда:' + @paym_order_metod

		SET @fin_pred1 = @fin_id1 - 1
		SET @fin_pred2 = @fin_id1 - 2
		SELECT @PaymClosedDataPred = dbo.Fun_GetOnlyDate(PaymClosedData)
		FROM dbo.Occupation_Types_History AS OTH 
		WHERE OTH.fin_id = @fin_pred1
			AND OTH.id = @tip_id

		IF @debug = 1
			SELECT @peny_nocalc_date_begin AS peny_nocalc_date_begin
				 , @peny_nocalc_date_end AS peny_nocalc_date_end
				 , @start_date AS start_date
				 , @end_date AS end_date
				 , @penalty_calc1 AS Penalty_calc
				 , @DateCurrent1 AS DateCurrent
				 , @PaymClosedDataPred AS PaymClosedDataPred
				 , @fin_current AS fin_current

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
				 , @peny_nocalc_date_end AS peny_nocalc_date_end
				 , @start_date AS start_date
				 , @end_date AS end_date
				 , @penalty_calc1 AS Penalty_calc

		--****************************************************
		CREATE TABLE #table_dolg (
			  fin_id SMALLINT
			, end_date SMALLDATETIME
			, fin_str VARCHAR(30) COLLATE database_default DEFAULT ''
			, debt DECIMAL(15, 2) DEFAULT 0
			, paid DECIMAL(15, 2) DEFAULT 0
			, paymaccount DECIMAL(15, 2) DEFAULT 0
			, dolg DECIMAL(15, 2) DEFAULT 0
			, date_current SMALLDATETIME
			, kolday SMALLINT
			, id INT
		--,PRIMARY KEY (fin_id, end_date, date_current)
		)
		IF @debug = 1
		BEGIN
			PRINT '=================================================='
			PRINT 'declare @Dolg DECIMAL(9, 2) = 0, @Dolg_peny DECIMAL(9, 2) = 0'
			PRINT CONCAT(N'exec k_peny_dolg_occ_2018 @occ=',@occ1,',@sup_id = NULL,@LastDay=',@LastPaym,',@Dolg = @Dolg_peny OUT,@dolg_all = @Dolg OUT, @debug=1')
			PRINT 'select @Dolg as Dolg, @Dolg_peny as Dolg_peny'
			PRINT '=================================================='
		END

		--IF (@db_name = 'KOMP')
		--	--AND (@tip_id IN (41, 131))   -- ТСЖ Красноармейская 140,  ТСЖ "Изумруд", 131
		--	AND @occ1 = 326472
		--BEGIN
		--	INSERT
		--	INTO #table_dolg WITH (TABLOCKX)
		--	EXEC dbo.k_peny_dolg_occ_2018_test @occ = @occ1
		--									  ,@Sup_Id = NULL
		--									  ,@Dolg = @Dolg_peny OUT
		--									  ,@dolg_all = @Dolg OUT
		--									  ,@LastDay = @LastPaym
		--END
		--ELSE
		BEGIN
			INSERT INTO #table_dolg --WITH (TABLOCKX)
			--EXEC dbo.k_peny_dolg_occ_2016 @occ = @occ1
			EXEC dbo.k_peny_dolg_occ_2018 @occ = @occ1
										, @sup_id = NULL
										, @fin_current = @fin_current
										, @Dolg = @Dolg_peny OUT
										, @dolg_all = @Dolg OUT
										, @LastDay = @LastPaym
		END

		CREATE UNIQUE INDEX table_dolg_primary ON #table_dolg (fin_id, end_date, date_current);

		SELECT @Dolg_peny1 = @Dolg_peny
			 , @Dolg1 = @Dolg

		IF @debug = 1
			SELECT '#table_dolg' AS tabl
				 , *
			FROM #table_dolg
		DECLARE @t1 TABLE (
			  id SMALLINT DEFAULT 0
			, data1 SMALLDATETIME
			, data2 SMALLDATETIME
			, paymaccount DECIMAL(9, 2) DEFAULT 0
			, paying_id INT DEFAULT NULL
			, peny_old DECIMAL(9, 2) DEFAULT 0
			, peny_old_new DECIMAL(9, 2) DEFAULT 0
			, paymaccount_peny DECIMAL(9, 2) DEFAULT 0
			, dolg DECIMAL(9, 2) DEFAULT 0
			, dolg_peny DECIMAL(9, 2) DEFAULT 0
			, kol_day SMALLINT
			, kol_day_mes SMALLINT
			, proc_peny_day DECIMAL(9, 4) DEFAULT 0
			, penalty_value DECIMAL(9, 2) DEFAULT 0
			, paid DECIMAL(15, 2) DEFAULT 0
			, IDEN INT IDENTITY (1, 1)
			, dolg_ostatok DECIMAL(9, 2) DEFAULT 0
			, StavkaCB DECIMAL(10, 4) DEFAULT 0
			, paying_order_metod VARCHAR(10) COLLATE database_default DEFAULT NULL
		)

		UPDATE #table_dolg
		SET date_current = @end_date
		WHERE date_current > @end_date

		INSERT INTO @t1 (id
					   , data1
					   , data2
					   , dolg
					   , dolg_peny
					   , kol_day
					   , kol_day_mes
					   , paid
					   , paymaccount)
		SELECT td.fin_id
			 , CAST(td.end_date AS DATE)
			 , CAST(td.date_current AS DATE)
			 , td.debt   --dolg
			 , td.dolg
			 , td.kolday
			 , kol_day_mes =
							CASE								
								--WHEN @start_date NOT BETWEEN @start_fin_period AND @end_fin_period THEN 0
								WHEN @end_date < td.end_date THEN 0
								WHEN (td.date_current > @start_date) AND
									(td.date_current < @end_date) THEN DATEDIFF(DAY, @start_date, td.date_current) + 1
								WHEN td.end_date > @start_date THEN DATEDIFF(DAY, td.end_date, date_current)
								ELSE DATEDIFF(DAY, @start_date, @end_date) + 1
							END
			 , td.paid
			 , td.paymaccount
		FROM #table_dolg td

		UPDATE t
		SET StavkaCB = gv.StavkaCB
		FROM @t1 t
			JOIN dbo.Global_values gv ON t.id = gv.fin_id

		UPDATE t
		SET proc_peny_day =
						   CASE
							   WHEN pmd.Koef > 0 AND
								   @isRaschCurStavkaCB = 1 THEN @CurStavkaCB / pmd.Koef
							   WHEN pmd.Koef > 0 AND
								   @isRaschCurStavkaCB = 0 THEN t.StavkaCB / pmd.Koef
							   ELSE 0
						   END
		FROM @t1 t
			JOIN dbo.Peny_metod_detail pmd ON pmd.metod_id = @Penalty_metod
				AND t.kol_day BETWEEN pmd.day1 AND pmd.day2

		UPDATE @t1
		SET dolg_ostatok = dolg_peny


		--SELECT
		--	@Paymaccount_sum = SUM(COALESCE(paymaccount, 0))
		--FROM @t1
		--IF @debug = 1
		--	PRINT 'Paymaccount=' + STR(@Paymaccount, 9, 2) + ' Paymaccount_sum=' + STR(@Paymaccount_sum, 9, 2)


		--UPDATE t
		--SET peny_old = @Peny_old
		--FROM (
		--(SELECT TOP (1) * from @t1 
		--ORDER BY id desc)) AS t


		IF @debug = 1
			SELECT *
			FROM @t1
			ORDER BY data1
		--return 

		--********** Сохраняем сумму начислений предыдущего месяца        
		SELECT @Paid_Pred = SUM(p.paid)
			 , @peny_fin_pred_new = SUM(COALESCE(p.penalty_serv, 0))
		FROM dbo.View_paym AS p 
		--JOIN dbo.SERVICES AS s 
		--	ON p.service_id = s.id
		--AND s.is_peny = 1 -- !!! для расчёта пени
		WHERE p.Occ = @occ1
			AND p.fin_id = @fin_pred1
			AND (p.sup_id = 0)

		IF @Paid_Pred IS NULL
			SET @Paid_Pred = 0

		SELECT @Paid_Pred_begin = @Paid_Pred

		--************************************************      
		--IF @occ1 NOT IN (286322)  -- по л/сч ручная раскидка пени (вся сумма)  26/04/2016
		--BEGIN
		-- обнуляем оплачено пени для начала
		UPDATE p 
		SET paymaccount_peny = 0
		FROM dbo.Payings AS p
		WHERE 
			p.fin_id = @fin_id1
			AND p.Occ = @occ1
			AND p.sup_id = 0
			AND p.peny_save = 0   -- ручная корректировка

		UPDATE ps 
		SET paymaccount_peny = 0
		FROM dbo.Paying_serv AS ps
			JOIN dbo.Payings AS p ON ps.paying_id = p.id
		WHERE 
			p.fin_id = @fin_current
			AND p.Occ = @occ1
			AND p.sup_id = 0
			AND p.peny_save = 0   -- ручная корректировка
			AND p.forwarded = 1
		--END
		--************************************************ 
		DELETE FROM dbo.Peny_all
		WHERE Occ = @occ1
			AND fin_id = @fin_id1

		DELETE FROM dbo.Peny_detail
		WHERE fin_id = @fin_id1
			AND Occ = @occ1

		-- ***********************************************
		-- раскидка пени по услугам
		IF @fin_id1 = @fin_current
		BEGIN
			EXEC dbo.k_raschet_peny_serv_old @occ = @occ1
										   , @fin_id = @fin_id1
		END
		-- ***********************************************

		SET @Peny_old_new = @Peny_old

		--***********************************************
		DECLARE @t_paym TABLE (
			  value DECIMAL(9, 2) DEFAULT 0
			, id INT DEFAULT 0
			, [day] SMALLDATETIME DEFAULT NULL
			, paying_order_metod VARCHAR(10) DEFAULT NULL
		)
		INSERT INTO @t_paym
		SELECT p.value
			 , p.id
			 , pd.day  
			 , po.paying_order_metod
		FROM dbo.Payings AS p
			JOIN dbo.Paydoc_packs AS pd ON pd.id = p.pack_id
			JOIN dbo.Paycoll_orgs AS po ON pd.fin_id = po.fin_id
				AND pd.source_id = po.id
			JOIN dbo.Paying_types AS pt ON po.vid_paym = pt.id
		WHERE p.fin_id = @fin_current
			AND p.Occ = @occ1
			AND p.sup_id = 0
			AND pt.peny_no = CAST(0 AS BIT)
			AND p.forwarded = CAST(1 AS BIT)
			AND p.peny_save = CAST(0 AS BIT) -- 20.05.2016
		ORDER BY p.id
		OPTION (RECOMPILE)

		IF NOT EXISTS (SELECT 1 FROM @t_paym)
			INSERT INTO @t_paym
			VALUES(0
				 , 0
				 , NULL
				 , NULL)

		IF @debug = 1
			SELECT '@t_paym' AS tabl
				 , @peny_nocalc_date_begin AS peny_nocalc_date_begin
				 , *
			FROM @t_paym
		--***********************************************

		DECLARE @fin_id_tmp INT
			  , @id_tmp INT
			  , @dolg_peny_tmp DECIMAL(9, 2) = 0
			  , @dolg_peny_ostatok DECIMAL(9, 2) = 0
			  , @SumPaymaccount_ostatok DECIMAL(9, 2) = 0
			  , @SumPaymaccount_tmp DECIMAL(9, 2) = 0
			  , @kol_day_tmp SMALLINT

		DECLARE curs CURSOR LOCAL FOR
			SELECT value
				 , id
				 , [day]
				 , paying_order_metod
			FROM @t_paym

		OPEN curs
		FETCH NEXT FROM curs INTO @SumPaymaccount, @paying_id1, @DataPaym, @paying_order_metod

		WHILE (@@fetch_status = 0)
		BEGIN
			SET @SumPaymaccount1 = @SumPaymaccount1 + @SumPaymaccount

			-- если в платеже не заполнен, то берём с типа фонда
			IF @paying_order_metod IS NULL
				SET @paying_order_metod = @paym_order_metod

			IF @debug = 1
			BEGIN
				PRINT '@LastDatePaym= ' + CONVERT(VARCHAR(10), @LastDatePaym, 112)
				PRINT '@Paid_Pred_begin= ' + STR(@Paid_Pred_begin, 9, 2)
				PRINT '@fin_current= ' + STR(@fin_current)
				PRINT '@Dolg= ' + STR(@Dolg, 9, 2)
				PRINT '@Dolg_peny= ' + STR(@Dolg_peny, 9, 2)
				PRINT '@Peny_old_new= ' + STR(@Peny_old_new, 9, 2)
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
					PRINT 'Порядок оплаты: Пени, Долг'
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
						PRINT concat('@Peny_old_new:', @Peny_old_new, ' @Paymaccount_peny:', @Paymaccount_peny, ' @Paymaccount_serv:' , @Paymaccount_serv)
				END --
				--IF @debug=1 PRINT '-2'+STR(@Peny_old,9,2)+' '+STR(@Paymaccount_serv,9,2)+' '+STR(@Peny_old_new,9,2)			 
				--IF @debug=1 PRINT '@dolg_peny 1'+str(@dolg_peny,9,2)

				SET @dolg_peny_ostatok = @Dolg_peny
				SET @Dolg_peny = @Dolg_peny - @Paymaccount_serv ---@Paymaccount_peny --
				SET @Dolg = @Dolg - @Paymaccount_serv

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

				--*********************** Расчёты суммы долга по месяцам **************
				IF (@paying_id1 > 0)
					AND (@DataPaym > @start_date)
				BEGIN
					SELECT @SumPaymaccount_tmp = @SumPaymaccount
						 , @SumPaymaccount_ostatok = @SumPaymaccount_ostatok + @SumPaymaccount

					DECLARE cur2 CURSOR LOCAL FOR
						SELECT id
							 , IDEN
							 , dolg_peny
						FROM @t1
						WHERE dolg_ostatok > 0 --AND dolg_peny>0
							AND data2 > @DataPaym
							AND data1 <= @DataPaym
						ORDER BY id
							   , IDEN

					OPEN cur2

					FETCH NEXT FROM cur2 INTO @fin_id_tmp, @id_tmp, @dolg_peny_tmp

					WHILE @@fetch_status = 0
					BEGIN
						IF @debug = 1
							PRINT concat('1 ', @id_tmp, ' ' , CONVERT(VARCHAR(15), @DataPaym, 104) , ' @SumPaymaccount_tmp=', @SumPaymaccount_tmp, ' @fin_id_tmp', @fin_id_tmp
							, ' @SumPaymaccount_ostatok=', @SumPaymaccount_ostatok, ' @dolg_peny_ostatok=', @dolg_peny_ostatok,  ' @dolg_peny_tmp=')

						IF @SumPaymaccount_ostatok > 0
						BEGIN

							--****** 25.11.2018 **********************************************************************************
							SET @SumPaymaccount_tmp =
													 CASE
														 WHEN @dolg_peny_tmp > @SumPaymaccount_ostatok THEN @SumPaymaccount_ostatok
														 --WHEN @dolg_peny_tmp <= @SumPaymaccount_ostatok THEN @SumPaymaccount_ostatok - @dolg_peny_tmp
														 WHEN @dolg_peny_tmp <= @SumPaymaccount_ostatok THEN @dolg_peny_tmp
													 -- ELSE
													 END
							SELECT @SumPaymaccount_tmp = CASE
                                                             WHEN @SumPaymaccount_tmp > @dolg_peny_tmp
                                                                 THEN @dolg_peny_tmp
                                                             ELSE @SumPaymaccount_tmp
                                END
							--****************************************************************************************************

							IF @debug = 1
								PRINT CONCAT('@SumPaymaccount_ostatok: ',@SumPaymaccount_ostatok,', @SumPaymaccount_tmp:',@SumPaymaccount_tmp,', @dolg_peny_tmp:',@dolg_peny_tmp)								

							SELECT @SumPaymaccount_ostatok = @SumPaymaccount_ostatok - @dolg_peny_tmp
							SELECT @SumPaymaccount_ostatok = CASE
                                                                 WHEN @SumPaymaccount_ostatok < 0 THEN 0
                                                                 ELSE @SumPaymaccount_ostatok
                                END

							IF @debug = 1
								PRINT CONCAT('@SumPaymaccount_ostatok:', @SumPaymaccount_ostatok)
							--****************************************************************************************************

							SELECT @dolg_peny_tmp =
												   CASE
													   WHEN (@dolg_peny_tmp - @SumPaymaccount_tmp) < 0 THEN 0
													   ELSE @dolg_peny_tmp - @SumPaymaccount_tmp
												   END

							SELECT @dolg_peny_ostatok = @dolg_peny_ostatok - @SumPaymaccount_tmp

							IF @debug = 1
								PRINT CONCAT('2 ', @id_tmp, ' ' , CONVERT(VARCHAR(15), @DataPaym, 104) , ' @SumPaymaccount_tmp=', @SumPaymaccount_tmp, ' @fin_id_tmp', @fin_id_tmp
								, ' @SumPaymaccount_ostatok=', @SumPaymaccount_ostatok, ' @dolg_peny_ostatok=', @dolg_peny_ostatok, ' @dolg_peny_tmp=', @dolg_peny_tmp)

							INSERT INTO @t1 (id
										   , data1
										   , data2
										   , paymaccount
										   , paying_id
										   , peny_old
										   , peny_old_new
										   , paymaccount_peny
										   , dolg
										   , dolg_peny
										   , kol_day
										   , kol_day_mes
										   , proc_peny_day
										   , penalty_value
										   , paid
										   , dolg_ostatok
										   , paying_order_metod
										   , StavkaCB)
							SELECT id
								 , @DataPaym
								 , data2
								 , @SumPaymaccount_tmp --paymaccount
								 , @paying_id1
								 , peny_old
								 , peny_old_new --@dolg_peny_ostatok --peny_old_new
								 , paymaccount_peny --@SumPaymaccount_ostatok --paymaccount_peny
								 , dolg
								 , @dolg_peny_tmp
								 , kol_day
								 , kol_day_mes
								 , proc_peny_day
								 , penalty_value
								 , paid
								 , @dolg_peny_ostatok
								 , @paying_order_metod
								 , StavkaCB
							FROM @t1
							WHERE IDEN = @id_tmp

							IF @@rowcount > 0
								AND @debug = 1
							BEGIN
								PRINT 'строка добавлена ' + STR(@dolg_peny_tmp, 9, 2)
								SELECT 'Тест 1'
									 , *
								FROM @t1
								WHERE id = @fin_id_tmp
							END

							UPDATE @t1
							SET data2 = @DataPaym
							  , dolg_ostatok = 0
							WHERE IDEN = @id_tmp

							UPDATE @t1
							SET kol_day_mes =
											 CASE
												 WHEN (data1 < @start_date) AND
													 (data2 > @start_date) THEN DATEDIFF(DAY, @start_date, data2) + 1
												 WHEN data1 < data2 THEN DATEDIFF(DAY, data1, data2)
												 ELSE 0
											 END
							WHERE id = @fin_id_tmp

							IF @debug = 1
							BEGIN
								SELECT 'Тест 2'
									 , *
								FROM @t1
								WHERE id = @fin_id_tmp
							END

						END

						FETCH NEXT FROM cur2 INTO @fin_id_tmp, @id_tmp, @dolg_peny_tmp
					END

					CLOSE cur2
					DEALLOCATE cur2
				END

			-- ***************************************************************************
			END
			ELSE
			BEGIN -- Порядок оплаты: Начисление,Долг,Пени
				-- ***************************************************************************       
				IF @debug = 1
				BEGIN
					PRINT 'Порядок оплаты: Долг,Пени'
					PRINT SPACE(10) + 'Платёж!  @DataPaym: ' + CONVERT(VARCHAR(15), @DataPaym, 104) + ', @Dolg:' + LTRIM(STR(@Dolg, 9, 2)) + ', @Paid_Pred:' + LTRIM(STR(@Paid_Pred, 9, 2)) + ' @SumPaymaccount:' + LTRIM(STR(@SumPaymaccount, 9, 2)) + ', @Paymaccount_serv:' + LTRIM(STR(COALESCE(@Paymaccount_serv, 0), 9, 2))
				END

				SELECT @Paymaccount_serv = @SumPaymaccount - @Dolg
				IF @Paymaccount_serv < 0
					SET @Paymaccount_serv = 0

				SELECT @dolg_peny_ostatok = @Dolg_peny
					 , @Dolg_peny = @Dolg_peny - @SumPaymaccount
					 , @Dolg = @Dolg - @SumPaymaccount -- 24/10/13

				--************************** Расчёты суммы долга по месяцам ****************
				IF (@paying_id1 > 0)
					AND (@DataPaym > @start_date)
				BEGIN
					SELECT @SumPaymaccount_tmp = @SumPaymaccount
						 , @SumPaymaccount_ostatok = @SumPaymaccount_ostatok + @SumPaymaccount

					DECLARE cur2 CURSOR LOCAL FOR
						SELECT id
							 , IDEN
							 , dolg_peny
						FROM @t1
						WHERE dolg_ostatok > 0 --AND dolg_peny>0
							AND data2 > @DataPaym
							AND data1 <= @DataPaym
						ORDER BY id
							   , IDEN

					OPEN cur2

					FETCH NEXT FROM cur2 INTO @fin_id_tmp, @id_tmp, @dolg_peny_tmp

					WHILE @@fetch_status = 0
					BEGIN

						IF @debug = 1
							PRINT '1 ' + LTRIM(STR(@id_tmp)) + ' ' + LTRIM(STR(@fin_id_tmp)) + ' @DataPaym:' + CONVERT(VARCHAR(15), @DataPaym, 104) + ',@SumPaymaccount_tmp:' + STR(@SumPaymaccount_tmp, 9, 2)
							+ ',@SumPaymaccount_ostatok:' + STR(@SumPaymaccount_ostatok, 9, 2) + ',@dolg_peny_ostatok:' + STR(@dolg_peny_ostatok, 9, 2) + ',@dolg_peny_tmp:' + STR(@dolg_peny_tmp, 9, 2)

						IF @SumPaymaccount_ostatok > 0
						BEGIN
							--IF @SumPaymaccount_ostatok<@dolg_peny_tmp   --закомментировал 29.05.18
							--begin
							--	SET @dolg_peny_tmp = @dolg_peny_tmp-@SumPaymaccount_ostatok
							--	SET @SumPaymaccount_ostatok = 0
							--	IF @debug = 1 PRINT '1.1  @dolg_peny_tmp='+STR(@dolg_peny_tmp,9,2)
							--end

							--****** 25.11.2018 **********************************************************************************
							SET @SumPaymaccount_tmp =
													 CASE
														 WHEN @dolg_peny_tmp > @SumPaymaccount_ostatok THEN @SumPaymaccount_ostatok
														 --WHEN @dolg_peny_tmp <= @SumPaymaccount_ostatok THEN @SumPaymaccount_ostatok - @dolg_peny_tmp
														 WHEN @dolg_peny_tmp <= @SumPaymaccount_ostatok THEN @dolg_peny_tmp
													 -- ELSE
													 END
							SELECT @SumPaymaccount_tmp = CASE
                                                             WHEN @SumPaymaccount_tmp > @dolg_peny_tmp
                                                                 THEN @dolg_peny_tmp
                                                             ELSE @SumPaymaccount_tmp
                                END
							--****************************************************************************************************

							IF @debug = 1
								PRINT CONCAT('@SumPaymaccount_ostatok: ',@SumPaymaccount_ostatok,', @SumPaymaccount_tmp: ',@SumPaymaccount_tmp,', @dolg_peny_tmp: ', @dolg_peny_tmp)								

							SELECT @SumPaymaccount_ostatok = @SumPaymaccount_ostatok - @dolg_peny_tmp
							SELECT @SumPaymaccount_ostatok = CASE
                                                                 WHEN @SumPaymaccount_ostatok < 0 THEN 0
                                                                 ELSE @SumPaymaccount_ostatok
                                END

							IF @debug = 1
								PRINT CONCAT('@SumPaymaccount_ostatok: ', @SumPaymaccount_ostatok)
							--****************************************************************************************************

							--SELECT									-- закомментировал 21.11.18
							--	@SumPaymaccount_tmp =
							--		CASE
							--			WHEN @SumPaymaccount_tmp > @dolg_peny_tmp AND
							--			@dolg_peny_tmp > 0 THEN @dolg_peny_tmp
							--			ELSE @SumPaymaccount_tmp
							--		END

							--SELECT
							--	@dolg_peny_tmp =
							--		CASE
							--			WHEN (@dolg_peny_tmp - @SumPaymaccount_tmp) < 0 THEN 0
							--			ELSE @dolg_peny_tmp - @SumPaymaccount_tmp
							--		END
							SELECT @dolg_peny_tmp =
												   CASE
													   WHEN (@dolg_peny_tmp - @SumPaymaccount_tmp) < 0 THEN 0
													   ELSE @dolg_peny_tmp - @SumPaymaccount_tmp
												   END
							--SELECT
							--	@SumPaymaccount_ostatok = @SumPaymaccount_ostatok - @dolg_peny_tmp		

							IF @debug = 1
								PRINT '2 ' + LTRIM(STR(@id_tmp)) + ' ' + LTRIM(STR(@fin_id_tmp)) + ' @DataPaym:' + CONVERT(VARCHAR(15), @DataPaym, 104) +
								',@SumPaymaccount_tmp:' + STR(@SumPaymaccount_tmp, 9, 2) + ',@SumPaymaccount_ostatok:' + STR(@SumPaymaccount_ostatok, 9, 2) +
								',@dolg_peny_ostatok:' + STR(@dolg_peny_ostatok, 9, 2) + ',@dolg_peny_tmp:' + STR(@dolg_peny_tmp, 9, 2)

							SELECT @dolg_peny_ostatok = @dolg_peny_ostatok - @SumPaymaccount_tmp

							IF @debug = 1
								PRINT '3 ' + LTRIM(STR(@id_tmp)) + ' ' + LTRIM(STR(@fin_id_tmp)) + ' @DataPaym:' + CONVERT(VARCHAR(15), @DataPaym, 104) + ',@SumPaymaccount_tmp:' + STR(@SumPaymaccount_tmp, 9, 2)
								+ ',@SumPaymaccount_ostatok:' + STR(@SumPaymaccount_ostatok, 9, 2) + ',@dolg_peny_ostatok:' + STR(@dolg_peny_ostatok, 9, 2)
								+ ',@dolg_peny_tmp:' + STR(@dolg_peny_tmp, 9, 2)

							INSERT INTO @t1 (id
										   , data1
										   , data2
										   , paymaccount
										   , paying_id
										   , peny_old
										   , peny_old_new
										   , paymaccount_peny
										   , dolg
										   , dolg_peny
										   , kol_day
										   , kol_day_mes
										   , proc_peny_day
										   , penalty_value
										   , paid
										   , dolg_ostatok
										   , paying_order_metod
										   , StavkaCB)
							SELECT id
								 , @DataPaym
								 , data2
								 , @SumPaymaccount_tmp --@SumPaymaccount_tmp --paymaccount
								 , @paying_id1
								 , peny_old
								 , peny_old_new --@dolg_peny_ostatok --peny_old_new
								 , paymaccount_peny --@SumPaymaccount_ostatok --paymaccount_peny
								 , dolg
								 , @dolg_peny_tmp
								 , kol_day
								 , kol_day_mes
								 , proc_peny_day
								 , penalty_value
								 , paid
								 , @dolg_peny_ostatok
								 , @paying_order_metod
								 , StavkaCB
							FROM @t1
							WHERE IDEN = @id_tmp
							IF @@rowcount > 0
								AND @debug = 1
								PRINT 'строка добавлена ' + STR(@dolg_peny_tmp, 9, 2)

							UPDATE @t1
							SET data2 = @DataPaym
							  , dolg_ostatok = 0
							  , dolg_peny = CASE
                                                WHEN @occ1 = 326472 THEN @SumPaymaccount_tmp
                                                ELSE dolg_peny
                                END -- 20.02.18
							WHERE IDEN = @id_tmp

							IF (@dolg_peny_ostatok - @SumPaymaccount_ostatok) <= 0    -- ???? протестировать
							BEGIN
								--IF @dolg_peny_ostatok <= 0
								UPDATE @t1
								SET dolg_peny = 0
								  , dolg_ostatok = 0
								WHERE data2 > @DataPaym
									AND id = @fin_id_tmp
								IF @debug = 1
									PRINT CONCAT(@fin_id_tmp, ', IF (',@dolg_peny_ostatok,' - ',@SumPaymaccount_ostatok,') <= 0 Обнуляем dolg_ostatok')									
							END
							ELSE
							IF @debug = 1
								PRINT CONCAT(@fin_id_tmp, ', IF (',@dolg_peny_ostatok,' - ',@SumPaymaccount_ostatok,') > 0')

							UPDATE @t1
							SET kol_day_mes =
											 CASE
												 WHEN (data1 < @start_date) AND
													 (data2 > @start_date) THEN DATEDIFF(DAY, @start_date, data2) + 1
												 WHEN data1 < data2 THEN DATEDIFF(DAY, data1, data2)
												 ELSE 0
											 END
							WHERE id = @fin_id_tmp

						END

						FETCH NEXT FROM cur2 INTO @fin_id_tmp, @id_tmp, @dolg_peny_tmp
					END

					CLOSE cur2
					DEALLOCATE cur2
				END

				--*****************************************************************
				IF @DataPaym >= @start_date
					SET @peny_fin_pred_new = 0
				--ELSE
				--	SET @Peny_old_new=@Peny_old_new-@peny_fin_preg_new

				IF @debug = 1
				BEGIN
					PRINT '@DataPaym=' + CONVERT(VARCHAR(10), @DataPaym, 112)
					PRINT '@Paymaccount_serv=' + STR(@Paymaccount_serv, 9, 2)
					PRINT '@SumPaymaccount=' + STR(@SumPaymaccount, 9, 2)
					PRINT '@Peny_old_new=' + STR(@Peny_old_new, 9, 2)
					PRINT '@peny_fin_preg_new=' + STR(@peny_fin_pred_new, 9, 2)
					PRINT '@Dolg_peny=' + STR(@Dolg_peny, 9, 2)
					PRINT '@Dolg=' + STR(@Dolg, 9, 2)
					PRINT '@Paid_Pred=' + STR(@Paid_Pred, 9, 2)
					PRINT CONCAT('Тек.период: ',@fin_current,' (',dbo.Fun_NameFinPeriod(@fin_current),')')
				END

				IF @Paymaccount = @saldo
					SET @penalty_paym_no = 1 -- 21/08/13 не делать оплату пени кто оплатил ровно

				IF (@Dolg) <= 0
					AND (@Paymaccount_serv > 0)
					AND (@SumPaymaccount > 0)
					AND (@Peny_old_new > 0)
					AND (@penalty_paym_no = 0) --@Dolg <= 0 AND 
					AND (
					((@Peny_old_new - @peny_fin_pred_new) > 0 -- если фин.период ещё не начался нельзя оплачивать пени этого месяца
					AND (@DataPaym < @start_date))
					OR ((@Peny_old_new > 0)
					AND (@DataPaym >= @start_date))
					)
				BEGIN
					IF @debug = 1
						PRINT 'Находим оплачено пени по коду: ' + STR(@paying_id1)

					--******************************  11/03/2016
					SET @Paymaccount_serv =
										   CASE
											   WHEN @Paymaccount_serv > @SumPaymaccount THEN @SumPaymaccount
											   ELSE @Paymaccount_serv
										   END
					--******************************
					IF @DataPaym < @start_date
						SET @Peny_old_new = (@Peny_old_new - @peny_fin_pred_new) - @Paymaccount_serv
					ELSE
						SET @Peny_old_new = @Peny_old_new - @Paymaccount_serv

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

			UPDATE @t1
			SET penalty_value =
							   CASE
								   WHEN --(@Dolg_peny > 0) AND
									   (dolg_peny > 0) AND
									   (dolg_peny > @PenyBeginDolg) THEN dolg_peny * 0.01 * proc_peny_day * kol_day_mes --kol_day
								   ELSE 0
							   END

			SET @Paymaccount_peny_out = 0
			--Раскидываем оплачено пени по услугам по платежу
			IF @paying_id1 <> 0
			BEGIN

				IF @debug = 1
					PRINT 'Раскидываем оплачено пени по услугам по платежу ' + STR(@paying_id1) + ' ' + STR(@Paymaccount_peny, 9, 2)
				EXEC k_paying_serv_peny @paying_id = @paying_id1
									  , @Paymaccount_peny = @Paymaccount_peny
									  , @sup_id = NULL
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

			FETCH NEXT FROM curs INTO @SumPaymaccount, @paying_id1, @DataPaym, @paying_order_metod
		END

		CLOSE curs
		DEALLOCATE curs
		-- ************************************************

		--DELETE FROM @t1 WHERE data2<data1
		IF @debug = 1
			SELECT @occ1 AS occ
				 , *
			FROM @t1
			ORDER BY id
				   , data1

		SELECT @SumPaymaccount1 = SUM(COALESCE(p.value, 0))
			 , @Paymaccount_peny = SUM(COALESCE(p.paymaccount_peny, 0))
			 , @Sum_peny_save = SUM(CASE
                                        WHEN p.peny_save = 1 THEN p.paymaccount_peny
                                        ELSE 0
            END)
		FROM dbo.Payings AS p
		WHERE p.Occ = @occ1
			AND p.fin_id = @fin_id1
			AND p.sup_id = 0
			AND p.forwarded = CAST(1 AS BIT)
		OPTION (RECOMPILE)

		DECLARE @penalty_added DECIMAL(9, 2)
		SET @penalty_added = COALESCE((
			SELECT pa.value_added
			FROM dbo.Peny_added pa
			WHERE pa.fin_id = @fin_id1
				AND pa.Occ = @occ1
		), 0)

		IF @peny_paym_blocked = 1
			AND @Sum_peny_save = 0
		BEGIN
			SELECT @Paymaccount_peny = 0
				 , @Peny_old_new = @Peny_old
		END

		IF @debug = 1
			PRINT '@Peny_old: ' + STR(COALESCE(@Peny_old, 0), 9, 2) + ' @Paymaccount_peny: ' + STR(COALESCE(@Paymaccount_peny, 0), 9, 2) +
			' @Sum_peny_save: ' + STR(COALESCE(@Sum_peny_save, 0), 9, 2) + ' @penalty_added:' + STR(COALESCE(@penalty_added, 0), 9, 2)

		IF (COALESCE(@Peny_old, 0) > 0)
			AND (COALESCE(@Peny_old, 0) < COALESCE(@Paymaccount_peny, 0))
		BEGIN
			SET @msg = CONCAT(N'Оплата пени(',@Paymaccount_peny,') больше старого пени(',@Peny_old,')! Лицевой: ', @occ1)
			RAISERROR (@msg, 16, 1)
			RETURN -1
		END

		INSERT INTO dbo.Peny_all (fin_id
								, Occ
								, dolg
								, dolg_peny
								, paid_pred
								, paymaccount
								, paymaccount_peny
								, peny_old
								, peny_old_new
								, Penalty_added
								, penalty_value
								, kolday
								, Data_rascheta
								, metod
								, occ1
								, sup_id)
		SELECT @fin_id1
			 , @occ1
			 , @Dolg1
			 , @Dolg_peny1
			 , @Paid_Pred_begin
			 , COALESCE(@SumPaymaccount1, 0) AS paymaccount
			 , COALESCE(@Paymaccount_peny, 0) AS paymaccount_peny
			 , @Peny_old AS peny_old
			 , @Peny_old - COALESCE(@Paymaccount_peny, 0) AS peny_old_new --  @Peny_old_new 
			 , @penalty_added
			 , COALESCE((SELECT SUM(penalty_value) FROM @t1), 0) AS penalty_value
			 , (
				   SELECT AVG(kol_day_mes)
				   FROM @t1
				   WHERE proc_peny_day > 0
			   ) AS kolday
			 , current_timestamp AS data_rascheta
			 , @Penalty_metod AS metod
			 , @occ1
			 , 0 AS sup_id

		IF @debug = 1
			SELECT *
			FROM dbo.Peny_all
			WHERE fin_id = @fin_id1
				AND Occ = @occ1

		IF @Paymaccount_peny > 0
		BEGIN
			-- закидывем "Оплачено пени" в последний месяц
			UPDATE @t1
			SET paymaccount_peny = @Paymaccount_peny
			WHERE IDEN = (
					SELECT TOP (1) IDEN
					FROM @t1
					WHERE paymaccount > 0
					ORDER BY id DESC
				)
		END
		IF @SumPaymaccount1 > 0
		BEGIN
			-- закидывем остаток "Оплачено" если есть в последний месяц
			DECLARE @ostatok DECIMAL(9, 2)
			SELECT @ostatok = SUM(paymaccount)
			FROM @t1
			SET @ostatok = @SumPaymaccount1 - @ostatok
			IF @debug = 1
				PRINT 'Остаток оплаты: ' + STR(@ostatok, 9, 2)

			UPDATE @t1
			SET paymaccount = paymaccount + @ostatok
			WHERE IDEN = (
					SELECT TOP (1) IDEN
					FROM @t1
					WHERE paymaccount > 0
					ORDER BY id DESC
				)
		END

		IF EXISTS (SELECT 1 FROM @t1)
			INSERT INTO dbo.Peny_detail (fin_id
									   , Occ
									   , paying_id
									   , dat1
									   , data1
									   , kol_day_dolg
									   , paying_id2
									   , kol_day
									   , dolg_peny
									   , paid_pred
									   , Paymaccount_Serv
									   , paymaccount_peny
									   , peny_old
									   , peny_old_new
									   , Peny
									   , dolg
									   , proc_peny_day
									   , fin_dolg
									   , StavkaCB)
			SELECT @fin_id1
				 , @occ1
				 , id
				 , data1
				 , data2
				 , kol_day
				 , COALESCE(paying_id, 0)
				 , kol_day_mes
				 , dolg_peny
				 , paid
				 , paymaccount
				 , paymaccount_peny
				 , peny_old
				 , peny_old_new
				 , CASE
                       WHEN @penalty_calc1 = 0 THEN 0
                       ELSE penalty_value
                END
				 , dolg
				 , proc_peny_day
				 , id
				 , StavkaCB
			FROM @t1

		IF (@Peny_old + @penalty_added) <= 0
			SET @peny_paym_blocked = 1

		-- Если на ЛС не расчитываем пени то зануляем
		UPDATE dbo.Peny_all
		SET penalty_value = CASE
                                WHEN @penalty_calc1 = 0 THEN 0
                                ELSE penalty_value
            END
		  , paymaccount_peny = CASE
                                   WHEN @peny_paym_blocked = 1 AND @Sum_peny_save = 0 THEN 0
                                   ELSE paymaccount_peny
            END
		  , peny_old_new = CASE
                               WHEN @peny_paym_blocked = 1 AND @Sum_peny_save = 0 THEN peny_old
                               ELSE peny_old_new
            END
		  , penalty_calc = @penalty_calc1
		WHERE Occ = @occ1
			AND fin_id = @fin_id1

		IF @fin_id1 < @fin_current
		BEGIN
			DELETE FROM dbo.Peny_detail
			WHERE Occ = @occ1
				AND fin_id = @fin_id1
			DELETE FROM dbo.Peny_all
			WHERE Occ = @occ1
				AND fin_id = @fin_id1
		END

		IF @debug = 1
			PRINT 'Обновляем на лицевом'
		UPDATE o
		SET penalty_value = COALESCE(ps.penalty_value, 0) --+ COALESCE(@penalty_added, 0)		  
		  , paymaccount_peny = COALESCE(ps.paymaccount_peny, 0)
		  , Penalty_added = COALESCE(@penalty_added, 0)
		  , Penalty_old_new = COALESCE(ps.peny_old_new, 0)
		FROM dbo.Occupations AS o
			LEFT JOIN dbo.Peny_all ps ON o.fin_id = ps.fin_id
				AND o.Occ = ps.Occ
		WHERE o.Occ = @occ1
		OPTION (RECOMPILE)

		IF @fin_id1 = @fin_current
		BEGIN
			IF @debug = 1
				PRINT 'k_raschet_peny_serv_old'
			EXEC dbo.k_raschet_peny_serv_old @occ = @occ1
										   , @fin_id = @fin_id1

			IF @debug = 1
				PRINT 'k_raschet_peny_serv'
			EXEC dbo.k_raschet_peny_serv @occ = @occ1
									   , @fin_id = @fin_id1
		END

	END TRY
	BEGIN CATCH
		EXEC dbo.k_err_messages
	END CATCH
go

