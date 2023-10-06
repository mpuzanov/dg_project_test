CREATE   PROCEDURE [dbo].[k_raschet_peny_sup_2016]
(
	  @occ_sup INT -- лицевой поставщика
	, @fin_id1 SMALLINT
	, @debug BIT = 0
	, @DateCurrent1 SMALLDATETIME = NULL --
)
AS
	/*
	Перерасчет пени по заданному лицевому поставщика			
			
	EXEC k_raschet_peny_sup_2016  @occ_sup=85000912, @fin_id1=166, @debug=1
	EXEC k_raschet_peny_sup_2016  @occ_sup=85000918, @fin_id1=166, @debug=1
	
	*/
	SET NOCOUNT ON

	IF @occ_sup = 0
		RETURN

	DECLARE @err INT -- код ошибки
		  , @fin_current SMALLINT -- текущий фин. период
		  , @occ INT -- Единый лицевой счёт
		  , @sup_id INT -- Код поставщика
		  , @db_name VARCHAR(30) = UPPER(DB_NAME())

	DECLARE @fin_pred1 SMALLINT -- предыдущий фин. период
		  , @fin_pred2 SMALLINT -- пред предыдущий фин. период
		  , @fin_Dolg SMALLINT -- код периода за который долг

	DECLARE @end_date SMALLDATETIME
		  , @start_date SMALLDATETIME
		  , @CurStavkaCB DECIMAL(10, 4) -- текущая ставка центрабанка
		  , @isRaschCurStavkaCB BIT = 1  -- Вести расчёт по текущей ставке центрабанка
		  , @kol_day SMALLINT -- кол-во дней просрочки
		  , @PaymClosed1 BIT -- признак закрытия платежного периода
		  , @Penalty_old_edit TINYINT -- признак ручного изменения пени        
		  , @PaymClosedData SMALLDATETIME
		  , @PaymClosedDataPred SMALLDATETIME -- дата закрытия предыдущего периода
		  , @TIP_ID SMALLINT
		  , @build_id INT
		  , @Penalty_metod TINYINT = 1
		  , @LastPaym TINYINT -- Последний день оплаты (напр. 10 число)
		  , @LastPaymBuild TINYINT -- Последний день оплаты по дому (напр. 20 число)
		  , @LastPaymSup TINYINT -- Последний день оплаты у поставщика
		  , @LastDatePaym SMALLDATETIME -- Последний день оплаты (напр. 10 число)
		  , @Peny_old DECIMAL(9, 2) = 0
		  , @penalty_paym_no BIT = 0 -- не оплачиваем пени по л/счёту
		  , @peny_raschet_tip BIT = 0 -- блокируем расчёт пени по поставщику по типу фонда
		  , @Penalty_metod_tip TINYINT = 0
		  , @lastday_without_peny TINYINT -- Последний день оплаты у поставщика у типа фонда
		  , @peny_raschet_build BIT = 0 -- блокируем расчёт пени по поставщику по дому
		  , @lastday_without_peny_build TINYINT -- Последний день оплаты у поставщика у дома
		  , @Penalty_metod_build TINYINT = 0
		  , @peny_blocked BIT = 0	-- Блокировка расчёта пени
		  , @saldo DECIMAL(9, 2) = 0
		  , @Last_day_month TINYINT -- Последний день месяца
		  , @PenyBeginDolg DECIMAL(9, 2) -- начальная сумма долга для расчёта пени
		  , @Penalty_old_new DECIMAL(9, 2) = 0
		  , @Penalty_old_new2 DECIMAL(9, 2) = 0

	DECLARE @penalty_calc1 BIT -- признак начисления пени на лицевом
		  , @penalty_calc_tip1 BIT -- признак начисления пени на типе фонде
		  , @penalty_calc_build BIT -- признак начисления пени на доме
		  , @peny_paym_blocked BIT -- признак блокировки оплаты пени на типе фонда
		  , @peny_nocalc_date_begin SMALLDATETIME -- дата начала перерыва начисления пени на лицевом
		  , @peny_nocalc_date_end SMALLDATETIME -- дата окончания перерыва начисления пени на лицевом
		  , @total_sq DECIMAL(9, 2)
		  , @is_peny_blocked_total_sq_empty BIT = 0

	DECLARE @Sum_peny_save DECIMAL(9, 2) = 0
	DECLARE @paym_order_metod VARCHAR(10)
		  , @paying_order_metod VARCHAR(10)

	BEGIN TRY

		SELECT TOP (1) @build_id = f.bldn_id
					 , @TIP_ID = o.tip_id
		FROM dbo.Occ_Suppliers AS os 
			JOIN dbo.Occupations AS o ON os.occ = o.occ
			JOIN dbo.Flats AS f  ON o.flat_id = f.id
		WHERE os.occ_sup = @occ_sup
			AND os.fin_id = @fin_id1

		IF @debug = 1
			SELECT @build_id AS build_id
				 , @TIP_ID AS tip_id

		SELECT @Peny_old = os.penalty_old
			 , @penalty_calc1 = os.Penalty_calc   --o.penalty_calc
			 , @penalty_calc_tip1 = ot.penalty_calc_tip
			 , @Penalty_metod = COALESCE(sa.penalty_metod, ot.penalty_metod)
			 , @penalty_calc_build = CASE
                                         WHEN b.is_paym_build = 0 THEN 0
                                         ELSE b.penalty_calc_build
            END
			 , @peny_paym_blocked = ot.peny_paym_blocked
			 , @LastPaym = COALESCE(ot.lastpaym, @LastPaym)
			 , @peny_nocalc_date_begin = o.peny_nocalc_date_begin
			 , @peny_nocalc_date_end = o.peny_nocalc_date_end
			 , @TIP_ID = o.tip_id
			   --,@paym_order = ot.paym_order
			 , @paym_order_metod = ot.paym_order_metod
			 , @occ = os.occ
			 , @sup_id = os.sup_id
			 , @PaymClosed1 = ot.PaymClosed
			 , @PaymClosedData = dbo.Fun_GetOnlyDate(PaymClosedData)
			 , @LastPaym = ot.lastpaym
			 , @LastPaymSup = sa.lastpaym
			 , @LastPaymBuild = b.lastpaym
			 , @penalty_paym_no = COALESCE(b.penalty_paym_no, 0)
			 , @Penalty_old_edit = os.Penalty_old_edit
			 , @peny_raschet_tip =
								  CASE
									  WHEN st.is_peny = 'Y' THEN 1
									  WHEN st.is_peny = 'N' THEN 0
									  ELSE NULL
								  END
			 , @lastday_without_peny = COALESCE(st.lastday_without_peny, 0)
			 , @Penalty_metod_tip = COALESCE(st.penalty_metod, 0)
			 , @peny_raschet_build =
									CASE
										WHEN sb.is_peny = 'Y' THEN 1
										WHEN sb.is_peny = 'N' THEN 0
										ELSE NULL
									END
			 , @lastday_without_peny_build = COALESCE(sb.lastday_without_peny, 0)
			 , @Penalty_metod_build = COALESCE(sb.penalty_metod, 0)
			 , @saldo = o.saldo
			 , @PenyBeginDolg =
							   CASE
								   WHEN st.PenyBeginDolg > 0 THEN st.PenyBeginDolg
								   ELSE ot.PenyBeginDolg
							   END
			 , @Penalty_old_new = os.Penalty_old_new
			 , @total_sq = o.total_sq
			 , @is_peny_blocked_total_sq_empty = ot.is_peny_blocked_total_sq_empty
			 , @isRaschCurStavkaCB = ot.is_peny_current_stavka_cb
		FROM dbo.Occ_Suppliers AS os 
			JOIN dbo.Occupations AS o 
				ON os.occ = o.occ
			JOIN dbo.Occupation_Types AS ot 
				ON o.tip_id = ot.id
			JOIN dbo.Flats AS f 
				ON o.flat_id = f.id
			JOIN dbo.Buildings AS b 
				ON f.bldn_id = b.id
			JOIN dbo.Suppliers_all AS sa 
				ON os.sup_id = sa.id

			LEFT JOIN (
				SELECT *
				FROM (
					SELECT tt.*
						 , DENSE_RANK() OVER (PARTITION BY tt.sup_id ORDER BY tt.service_id) AS toprank
					FROM dbo.Suppliers_types tt 
					WHERE tt.tip_id = @TIP_ID
				) AS t
				WHERE t.toprank = 1
			) AS st ON os.sup_id = st.sup_id

			LEFT JOIN (
				SELECT *
				FROM (
					SELECT tt.*
						 , DENSE_RANK() OVER (PARTITION BY tt.sup_id ORDER BY tt.service_id) AS toprank
					FROM dbo.Suppliers_build tt 
					WHERE tt.build_id = @build_id
				) AS t
				WHERE t.toprank = 1
			) AS sb ON os.sup_id = sb.sup_id

		WHERE 
			os.occ_sup = @occ_sup
			AND os.fin_id = @fin_id1;

		SELECT @fin_current = dbo.Fun_GetFinCurrent(@TIP_ID, NULL, NULL, @occ)

		SELECT @Penalty_metod =
							   CASE
								   WHEN @Penalty_metod_build > 0 THEN @Penalty_metod_build
								   WHEN @Penalty_metod_tip > 0 THEN @Penalty_metod_tip
								   ELSE @Penalty_metod
							   END

		DELETE FROM dbo.Peny_all -- если вдруг в истории уже есть
		WHERE occ = @occ_sup
			AND fin_id = @fin_id1;


		IF dbo.Fun_GetOccClose(@occ) = 0
		BEGIN
			DELETE FROM dbo.Peny_all 
			WHERE occ = @occ_sup
				AND fin_id = @fin_current
			
			DELETE FROM dbo.Peny_detail 
			WHERE occ = @occ_sup
				AND fin_id = @fin_current

			RAISERROR ('Лицевой счет %d закрыт! Работа с ним запрещена', 10, 1, @occ_sup) WITH NOWAIT;
			RETURN
		END

		SELECT @start_date = start_date
			 , @end_date = end_date
			 , @Last_day_month = DAY(end_date)
			 , @CurStavkaCB = StavkaCB
		FROM dbo.Global_values 
		WHERE fin_id = @fin_current;

		-- Если есть действующее соглашение о рассрочке то пени не считаем
		IF EXISTS (
				SELECT 1
				FROM dbo.Pid
				WHERE occ = @occ
					AND pid_tip = 3
					AND sup_id = @sup_id
					AND @start_date BETWEEN data_create AND data_end
			)
		BEGIN
			SET @penalty_calc1 = 0
			IF @debug = 1
				PRINT 'Есть соглашение о расрочке. Пени не считаем!'
		END


		IF @DateCurrent1 IS NULL
			SET @DateCurrent1 = dbo.Fun_GetOnlyDate(current_timestamp)

		IF @end_date > @DateCurrent1
			SET @end_date = @DateCurrent1

		-- Последний раз можно считать в день закрытия платежного периода
		IF (@PaymClosed1 = 1)
			AND (@PaymClosedData < @DateCurrent1) --  27.09.2005
			AND (@end_date > @PaymClosedData) -- 05.03.2015
		BEGIN
			--PRINT 'Платежный период закрыт пени считать больше не буду!'
			--RETURN 0   -- 15/07/12
			SELECT @DateCurrent1 = @PaymClosedData
				 , @end_date = @PaymClosedData
		END
		--
		IF (@fin_id1 IS NULL)
			OR (@fin_id1 = 0)
			SET @fin_id1 = @fin_current

		IF @debug = 1
			SELECT @build_id AS build_id
				 , @penalty_calc_build AS penalty_calc_build
				 , @peny_raschet_tip AS peny_raschet_tip
				 , @peny_raschet_build AS peny_raschet_build
				 , @peny_blocked AS peny_blocked

		-- проверяем на поставщике
		IF NOT EXISTS (
				SELECT 1
				FROM dbo.Suppliers_all 
				WHERE id = @sup_id
					AND Penalty_calc = 1
			)
			SET @peny_blocked = 1

		-- проверяем на поставщике по типу фонда	
		SELECT @peny_blocked =
							  CASE
								  WHEN @peny_raschet_tip = 0 THEN 1
								  WHEN (@peny_raschet_tip = 1) AND
									  (@peny_blocked = 1) THEN 0
								  ELSE @peny_blocked
							  END

		-- проверяем на поставщике по дому
		SELECT @peny_blocked =
							  CASE
								  WHEN @peny_raschet_build = 0 THEN 1
								  WHEN (@peny_raschet_build = 1) AND
									  (@peny_blocked = 1) THEN 0
								  ELSE @peny_blocked
							  END
		IF (@peny_blocked = 1)
			SET @penalty_calc1 = 0

		IF @total_sq = 0
			AND @is_peny_blocked_total_sq_empty = 1
			SET @penalty_calc1 = 0

		IF @debug = 1
			SELECT '@peny_blocked' = @peny_blocked
				 , '@penalty_calc1' = @penalty_calc1
				 , '@is_peny_blocked_total_sq_empty' = @is_peny_blocked_total_sq_empty
				 , '@total_sq' = @total_sq

		IF (@peny_blocked = 1)
			AND (@peny_paym_blocked = 1)                     ---- -- оплату пени всё равно надо считать  06.12.17
		BEGIN -- Пени по поставщику не считаем и не раскидываем оплату пени
			IF @debug = 1
				RAISERROR ('Пени по %d по поставщику не считаем', 10, 1, @occ_sup) WITH NOWAIT;

			DELETE FROM dbo.Peny_detail 
			WHERE occ = @occ_sup
				AND fin_id = @fin_id1

			DELETE FROM dbo.Peny_all 
			WHERE occ = @occ_sup
				AND fin_id = @fin_id1

			SELECT @Sum_peny_save = SUM(p.paymaccount_peny)
			FROM dbo.View_payings AS p
			WHERE 
				p.fin_id = @fin_id1
				AND p.occ = @occ
				AND p.sup_id = @sup_id
				AND p.peny_save = 1
				AND p.forwarded = 1

			UPDATE dbo.Occ_Suppliers
			SET penalty_value = 0
			  , paymaccount_peny = COALESCE(@Sum_peny_save, 0)
			  , Penalty_old_new = penalty_old - COALESCE(@Sum_peny_save, 0)
			WHERE 
				occ = @occ
				AND fin_id = @fin_current
				AND sup_id = @sup_id

			EXEC dbo.k_raschet_peny_serv_old @occ
										   , @fin_current
										   , @sup_id
										   , @debug
			EXEC [k_raschet_peny_serv] @occ
									 , @fin_current
									 , @sup_id
									 , @debug

			RETURN
		END

		-- Список услуг поставщика
		DECLARE @serv_sup TABLE (
			  id VARCHAR(10)
		)
		INSERT INTO @serv_sup
		SELECT vs.service_id
		FROM dbo.View_suppliers AS vs 
			JOIN dbo.Services AS s ON vs.service_id = s.id
				AND s.is_peny = 1 -- !!! для расчёта пени
		WHERE vs.sup_id = @sup_id

		IF dbo.Fun_GetOccClose(@occ) = 0
		BEGIN
			-- raiserror('Лицевой счет %d закрыт! Работа с ним запрещена',16,1,@occ1)
			RETURN
		END

		--DECLARE @t_paym_order TABLE
		--	(
		--		id	 INT IDENTITY (1, 1)
		--	   ,name VARCHAR(20)
		--	)
		--INSERT
		--INTO @t_paym_order
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
			PRINT 'Метод оплаты пени в типе фонда:' + LTRIM(@paym_order_metod)

		SET @fin_pred1 = @fin_id1 - 1
		SET @fin_pred2 = @fin_id1 - 2

		SELECT @PaymClosedDataPred = CAST(PaymClosedData AS DATE)
		FROM dbo.VOcc_types_all_lite
		WHERE fin_id = @fin_pred1
			AND id = @TIP_ID;

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
			SET @penalty_calc1=0;
		IF @end_date between @peny_nocalc_date_begin AND @peny_nocalc_date_end
			SET @penalty_calc1=0;
		--============================================================================

		IF @LastPaymBuild IS NOT NULL
			AND @LastPaymBuild > 0
			SET @LastPaym = @LastPaymBuild

		IF @LastPaymSup IS NOT NULL
			SET @LastPaym = @LastPaymSup

		IF @lastday_without_peny > 0
			SET @LastPaym = @lastday_without_peny
		IF @lastday_without_peny_build > 0
			SET @LastPaym = @lastday_without_peny_build

		IF @LastPaym IS NULL
			SET @LastPaym = 10

		IF @LastPaym >= 31
			SET @LastPaym = 31

		---- в феврале может быть 28
		IF @LastPaym > @Last_day_month
			SET @LastPaym = @Last_day_month

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
			  , @Paymaccount DECIMAL(9, 2)
			  , @Paymaccount_peny DECIMAL(9, 2)
			  , @Paymaccount_serv DECIMAL(9, 2)
			  , @Description VARCHAR(1000) = ''

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
			, PRIMARY KEY (fin_id, end_date, date_current)
		)

		IF @debug = 1
		BEGIN
			PRINT '=================================================='
			PRINT 'declare @Dolg DECIMAL(9, 2) = 0, @Dolg_peny DECIMAL(9, 2) = 0'
			PRINT CONCAT(N'exec k_peny_dolg_occ_2018 @occ=',@occ,',@sup_id = ',@sup_id,',@LastDay=',@LastPaym,',@Dolg = @Dolg_peny OUT,@dolg_all = @Dolg OUT, @debug=1')
			PRINT 'select @Dolg as Dolg, @Dolg_peny as Dolg_peny'
			PRINT '=================================================='
		END

		INSERT INTO #table_dolg 
		EXEC dbo.k_peny_dolg_occ_2018 @occ = @occ
									, @sup_id = @sup_id
									, @Dolg = @Dolg_peny OUT
									, @dolg_all = @Dolg OUT
									, @LastDay = @LastPaym

		SELECT @Dolg_peny1 = @Dolg_peny
			 , @Dolg1 = @Dolg
		IF @debug = 1
			SELECT '#table_dolg' AS '#table_dolg'
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
			 , td.end_date
			 , td.date_current
			 , td.dolg
			 , td.dolg
			 , td.kolday
			 , kol_day_mes =
							CASE
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
							   WHEN pmd.koef > 0 AND
								   @isRaschCurStavkaCB = 1 THEN @CurStavkaCB / pmd.koef
							   WHEN pmd.koef > 0 AND
								   @isRaschCurStavkaCB = 0 THEN t.StavkaCB / pmd.koef
							   ELSE 0
						   END
		FROM @t1 t
			JOIN dbo.Peny_metod_detail pmd ON pmd.metod_id = @Penalty_metod
				AND t.kol_day BETWEEN pmd.day1 AND pmd.day2
		--AND (pmd.day1<t.kol_day AND t.kol_day<pmd.day2)  --07.01.2018

		UPDATE @t1
		SET dolg_ostatok = dolg_peny

		IF @debug = 1
			SELECT  @start_date AS start_date
				 , @end_date AS end_date
				 , @penalty_calc1 AS penalty_calc
				 , @DateCurrent1 AS DateCurrent
				 , @PaymClosedDataPred AS PaymClosedDataPred
				 , @peny_nocalc_date_begin AS peny_nocalc_date_begin
				 , @peny_nocalc_date_begin AS peny_nocalc_date_begin
				 , @Penalty_metod AS Penalty_metod


		IF @debug = 1
			SELECT '@t1' AS '@t1'
				 , *
			FROM @t1
			ORDER BY data1
		--return 


		--********** Сохраняем сумму начислений предыдущего месяца        
		SELECT @Paid_Pred = SUM(p.paid)
		FROM dbo.View_paym AS p
		WHERE p.occ = @occ
			AND p.fin_id = @fin_pred1
			AND p.sup_id = @sup_id
		--AND p.is_peny = 1 -- !!! для расчёта пени

		IF @Paid_Pred IS NULL
			SET @Paid_Pred = 0
		SELECT @Paid_Pred_begin = @Paid_Pred

		--************************************************      
		-- обнуляем оплачено пени для начала
		UPDATE p 
		SET paymaccount_peny = 0
		FROM dbo.Payings AS p
			JOIN dbo.Paydoc_packs AS pd 
				ON pd.id = p.pack_id
		WHERE pd.fin_id = @fin_id1
			AND p.occ = @occ
			AND p.sup_id = @sup_id
			AND p.forwarded = 1
			AND p.peny_save = 0   -- ручная корректировка

		UPDATE ps 
		SET paymaccount_peny = 0
		FROM dbo.Paying_serv AS ps
			JOIN dbo.Payings AS p 
				ON ps.paying_id = p.id
		WHERE p.fin_id = @fin_id1
			AND p.occ = @occ
			AND p.sup_id = @sup_id
			AND p.forwarded = 1;

		--************************************************ 
		DELETE FROM dbo.Peny_all 
		WHERE occ = @occ_sup and fin_id=@fin_id1
		DELETE FROM dbo.Peny_detail 
		WHERE fin_id = @fin_id1
			AND occ = @occ_sup

		SET @Peny_old_new = @Peny_old

		-- ******************************************************
		-- раскидка пени по услугам
		IF @fin_id1 = @fin_current
		BEGIN
			EXEC dbo.k_raschet_peny_serv_old @occ
										   , @fin_id1
										   , @sup_id
			--EXEC dbo.k_raschet_peny_serv @occ, @fin_id1, @sup_id
		END

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
			JOIN dbo.Paydoc_packs AS pd 
				ON pd.id = p.pack_id
			JOIN dbo.Paycoll_orgs AS po 
				ON pd.fin_id = po.fin_id
				AND pd.source_id = po.id
			JOIN dbo.Paying_types AS pt ON 
				po.vid_paym = pt.id
		WHERE 
			pd.fin_id = @fin_current
			AND p.occ = @occ
			AND p.sup_id = @sup_id
			AND pt.peny_no = 0
			AND p.forwarded = 1
			AND p.peny_save = 0
		ORDER BY p.id

		IF NOT EXISTS (SELECT 1 FROM @t_paym)
			INSERT INTO @t_paym
			VALUES(0
				 , 0
				 , NULL
				 , NULL)

		IF @debug = 1
			SELECT '@t_paym' AS tabl
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

			IF @paying_order_metod IS NULL
				SET @paying_order_metod = @paym_order_metod

			IF @debug = 1
			BEGIN
				PRINT '@Peny_old= ' + STR(@Peny_old, 9, 2)
				PRINT '@Paid_Pred_begin= ' + STR(@Paid_Pred_begin, 9, 2)
				PRINT '@fin_current= ' + STR(@fin_current)
				PRINT '@Dolg= ' + STR(@Dolg, 9, 2)
				PRINT '@Dolg_peny= ' + STR(@Dolg_peny, 9, 2)
				PRINT '@paying_order_metod= ' + @paying_order_metod
			END

			IF @Dolg_peny < 0
				SET @Dolg_peny = 0

			SET @Paymaccount_peny = 0

			--****************************************************************************		
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
						PRINT CONCAT('@Peny_old_new: ',@Peny_old_new,', @Paymaccount_peny:',@Paymaccount_peny,', @Paymaccount_serv:',@Paymaccount_serv)						
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
							PRINT '1 ' + STR(@id_tmp) + ' ' + CONVERT(VARCHAR(15), @DataPaym, 104) + ' @SumPaymaccount_tmp=' + STR(@SumPaymaccount_tmp, 9, 2) + ' @fin_id_tmp' + STR(@fin_id_tmp)
							+ ' @SumPaymaccount_ostatok=' + STR(@SumPaymaccount_ostatok, 9, 2) + ' @dolg_peny_ostatok=' + STR(@dolg_peny_ostatok, 9, 2) + ' @dolg_peny_tmp=' + STR(@dolg_peny_tmp, 9, 2)

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
								PRINT CONCAT('@SumPaymaccount_ostatok: ', @SumPaymaccount_ostatok)
							--****************************************************************************************************

							SELECT @dolg_peny_tmp =
												   CASE
													   WHEN (@dolg_peny_tmp - @SumPaymaccount_tmp) < 0 THEN 0
													   ELSE @dolg_peny_tmp - @SumPaymaccount_tmp
												   END

							SELECT @dolg_peny_ostatok = @dolg_peny_ostatok - @SumPaymaccount_tmp

							IF @debug = 1
								PRINT '2 ' + STR(@id_tmp) + ' ' + CONVERT(VARCHAR(15), @DataPaym, 104) + ' @SumPaymaccount_tmp=' + STR(@SumPaymaccount_tmp, 9, 2) + ' @fin_id_tmp' + STR(@fin_id_tmp)
								+ ' @SumPaymaccount_ostatok=' + STR(@SumPaymaccount_ostatok, 9, 2) + ' @dolg_peny_ostatok=' + STR(@dolg_peny_ostatok, 9, 2) + ' @dolg_peny_tmp=' + STR(@dolg_peny_tmp, 9, 2)

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
					PRINT '0  ' + STR(COALESCE(@Dolg, 0), 9, 2) + ' ' + STR(COALESCE(@Paid_Pred, 0), 9, 2) + '   ' + STR(COALESCE(@SumPaymaccount, 0), 9, 2) + '   ' + STR(COALESCE(@Paymaccount_serv, 0), 9, 2)
				END

				SELECT @Paymaccount_serv = @SumPaymaccount - @Dolg
				IF @debug = 1
					PRINT '@Paymaccount_serv=' + STR(@Paymaccount_serv, 9, 2)

				IF @Paymaccount_serv < 0
					SET @Paymaccount_serv = 0

				SELECT @Dolg_peny = @Dolg_peny - @SumPaymaccount
					 , @Dolg = @Dolg - @SumPaymaccount -- 24/10/13

				--*****************************************************************
				IF (@paying_id1 > 0)
					AND (@DataPaym > @start_date)
				BEGIN
					SELECT @SumPaymaccount_tmp = @SumPaymaccount
						 , @SumPaymaccount_ostatok = @SumPaymaccount
					SELECT @dolg_peny_ostatok = SUM(dolg_ostatok)
					FROM @t1
					WHERE dolg_ostatok > 0
						AND data2 > @DataPaym

					DECLARE cur2 CURSOR LOCAL FOR
						SELECT id
							 , IDEN
							 , dolg_peny
						FROM @t1
						WHERE dolg_ostatok > 0
							AND data2 > @DataPaym
						ORDER BY id

					OPEN cur2

					FETCH NEXT FROM cur2 INTO @fin_id_tmp, @id_tmp, @dolg_peny_tmp

					WHILE @@fetch_status = 0
					BEGIN
						IF @debug = 1
							PRINT '1 ' + LTRIM(STR(@id_tmp)) + ' ' + LTRIM(STR(@fin_id_tmp)) + ' @DataPaym:' + CONVERT(VARCHAR(15), @DataPaym, 104) + ',@SumPaymaccount_tmp:' + STR(@SumPaymaccount_tmp, 9, 2)
							+ ',@SumPaymaccount_ostatok:' + STR(@SumPaymaccount_ostatok, 9, 2) + ',@dolg_peny_ostatok:' + STR(@dolg_peny_ostatok, 9, 2) + ',@dolg_peny_tmp:' + STR(@dolg_peny_tmp, 9, 2)

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
								PRINT CONCAT('@SumPaymaccount_ostatok: ',@SumPaymaccount_ostatok,', @SumPaymaccount_tmp: ',@SumPaymaccount_tmp,', @dolg_peny_tmp: ', @dolg_peny_tmp)

							SELECT @SumPaymaccount_ostatok = @SumPaymaccount_ostatok - @dolg_peny_tmp
							SELECT @SumPaymaccount_ostatok = CASE
                                                                 WHEN @SumPaymaccount_ostatok < 0 THEN 0
                                                                 ELSE @SumPaymaccount_ostatok
                                END

							IF @debug = 1
								PRINT CONCAT('@SumPaymaccount_ostatok: ', @SumPaymaccount_ostatok)
							--****************************************************************************************************

							SELECT @dolg_peny_tmp =
												   CASE
													   WHEN (@dolg_peny_tmp - @SumPaymaccount_tmp) < 0 THEN 0
													   ELSE @dolg_peny_tmp - @SumPaymaccount_tmp
												   END

							SELECT @dolg_peny_ostatok = @dolg_peny_ostatok - @SumPaymaccount_tmp

							IF @debug = 1
								PRINT @id_tmp

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

						END

						FETCH NEXT FROM cur2 INTO @fin_id_tmp, @id_tmp, @dolg_peny_tmp
					END

					CLOSE cur2
					DEALLOCATE cur2
				END
				--*****************************************************************

				IF @debug = 1
				BEGIN
					PRINT '@Paymaccount_serv=' + STR(@Paymaccount_serv, 9, 2)
					PRINT '@SumPaymaccount=' + STR(@SumPaymaccount, 9, 2)
					PRINT '@Peny_old_new=' + STR(@Peny_old_new, 9, 2)
					PRINT '@Peny_old=' + STR(@Peny_old, 9, 2)
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
				BEGIN
					IF @debug = 1
						PRINT 'Находим оплачено пени по коду платежа:' + STR(@paying_id1)

					--SET @Peny_old_new = @Peny_old - @Paymaccount_serv
					SET @Peny_old_new = @Peny_old_new - @Paymaccount_serv	 -- 21.12.16

					IF @debug = 1
						PRINT '1. @Peny_old:' + STR(@Peny_old, 9, 2) + ', @Paymaccount_serv:' + STR(@Paymaccount_serv, 9, 2) + ',@Peny_old_new:' + STR(@Peny_old_new, 9, 2)
					IF @Peny_old_new <= 0
					BEGIN
						SET @Paymaccount_peny = @Paymaccount_serv + @Peny_old_new
						SET @Paymaccount_serv = ABS(@Peny_old_new)
						SET @Peny_old_new = 0
						IF @debug = 1
							PRINT '@Peny_old_new <= 0 ' + STR(@Peny_old_new, 9, 2)
							+ ' @Paymaccount_peny=' + STR(@Paymaccount_peny, 9, 2)
							+ ' @Paymaccount_serv=' + STR(@Paymaccount_serv, 9, 2)
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

			IF @Dolg_peny < 0
				SET @Dolg_peny = 0

			UPDATE @t1
			SET kol_day_mes = 0
			WHERE kol_day_mes < 0

			-- ********************************************
			UPDATE @t1
			SET penalty_value =
							   CASE
								   WHEN --(@Dolg_peny > 0) AND
									   (dolg_peny > 0) AND
									   (dolg_peny > @PenyBeginDolg) THEN dolg_peny * 0.01 * proc_peny_day * kol_day_mes --kol_day
								   ELSE 0
							   END

			-- Раскидываем оплачено пени по услугам по платежу
			EXEC k_paying_serv_peny @paying_id1
								  , @Paymaccount_peny
								  , @sup_id
			-- ===============================================

			IF @debug = 1
				PRINT '@dolg: ' + STR(@Dolg, 9, 2) + ' @dolg_peny: ' + STR(@Dolg_peny, 9, 2) + ' @Paid_Pred: ' + STR(@Paid_Pred, 9, 2)

			FETCH NEXT FROM curs INTO @SumPaymaccount, @paying_id1, @DataPaym, @paying_order_metod
		END

		CLOSE curs
		DEALLOCATE curs
		-- ************************************************


		IF @debug = 1
			SELECT '@t1' AS '@t1'
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
			JOIN dbo.Paydoc_packs AS pd 
				ON p.pack_id = pd.id
		WHERE occ = @occ
			AND pd.fin_id = @fin_id1
			AND p.sup_id = @sup_id
			AND p.forwarded = 1
		OPTION (RECOMPILE)

		DECLARE @penalty_added DECIMAL(9, 2)
		SET @penalty_added = COALESCE((
			SELECT pa.value_added
			FROM dbo.Peny_added pa
			WHERE pa.fin_id = @fin_id1
				AND pa.occ = @occ_sup
		), 0)

		IF @peny_paym_blocked = 1
			AND @Sum_peny_save = 0
		BEGIN
			SELECT @Paymaccount_peny = 0
				 , @Peny_old_new = @Peny_old
		END

		--IF EXISTS (SELECT
		--			1
		--		FROM @t1)
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
			 , @occ_sup
			 , @Dolg1
			 , @Dolg_peny1
			 , @Paid_Pred_begin
			 , COALESCE(@SumPaymaccount1, 0) AS paymaccount
			 , COALESCE(@Paymaccount_peny, 0) AS paymaccount_peny
			 , peny_old = @Peny_old
			 , @Peny_old - COALESCE(@Paymaccount_peny, 0) AS peny_old_new --  @Peny_old_new peny_old_new = @Peny_old_new
			 , @penalty_added
			 , COALESCE((SELECT SUM(penalty_value) FROM @t1), 0) AS penalty_value
			 , COALESCE((
				   SELECT AVG(kol_day_mes)
				   FROM @t1
				   WHERE proc_peny_day > 0
			   ), 0) AS kolday
			 , current_timestamp AS data_rascheta
			 , @Penalty_metod AS metod
			 , @occ
			 , @sup_id

		IF @debug = 1
			SELECT 'PENY_ALL' AS 'PENY_ALL'
				 , *
			FROM dbo.PENY_ALL
			WHERE fin_id = @fin_id1
				AND occ = @occ_sup

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
									   , occ
									   , paying_id
									   , dat1
									   , data1
									   , kol_day_dolg
									   , paying_id2
									   , kol_day
									   , dolg_peny
									   , paid_pred
									   , paymaccount_serv
									   , paymaccount_peny
									   , peny_old
									   , peny_old_new
									   , Peny
									   , dolg
									   , proc_peny_day
									   , fin_dolg
									   , StavkaCB)
			SELECT @fin_id1
				 , @occ_sup
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

		--IF @debug = 1
		--	SELECT
		--		'PENY_DETAIL'
		--		,*
		--	FROM dbo.PENY_DETAIL
		--	WHERE fin_id = @fin_id1
		--	AND occ = @occ_sup

		IF (@Peny_old + @penalty_added) <= 0
			SET @peny_paym_blocked = 1

		-- Если на ЛС не расчитываем пени то зануляем
		UPDATE dbo.Peny_all WITH (ROWLOCK)
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
            END --01/08/2021
		  , Penalty_added = COALESCE(@penalty_added, 0)
		  , penalty_calc = @penalty_calc1
		WHERE occ = @occ_sup
			AND fin_id = @fin_id1

		DELETE FROM dbo.Peny_all
		WHERE occ = @occ_sup
			AND fin_id = @fin_id1
			AND peny_old = 0
			AND peny_old_new = 0
			AND paymaccount = 0
			AND paymaccount_peny = 0
			AND penalty_value = 0
			AND penalty_added = 0

		IF @fin_id1 < @fin_current
		BEGIN
			DELETE FROM dbo.Peny_detail
			WHERE occ = @occ_sup
				AND fin_id = @fin_id1
			DELETE FROM dbo.Peny_all
			WHERE occ = @occ_sup
				AND fin_id = @fin_id1
		END

		UPDATE os
		SET penalty_value = COALESCE(ps.penalty_value, 0) --+ COALESCE(ps.penalty_added,0)		  
		  , paymaccount_peny = COALESCE(ps.paymaccount_peny, 0)
		  , Penalty_added = COALESCE(@penalty_added, 0)
		  , Penalty_old_new = COALESCE(ps.peny_old_new, 0)
		FROM dbo.Occ_Suppliers os
			LEFT JOIN dbo.Peny_all ps ON os.fin_id = ps.fin_id AND os.occ_sup = ps.occ
		WHERE os.occ = @occ
			AND os.fin_id = @fin_id1
			AND os.sup_id = @sup_id

		DELETE PD
		FROM dbo.Peny_detail PD
			LEFT JOIN dbo.Peny_all PS ON PD.occ = PS.occ
				AND PD.fin_id = PS.fin_id
		WHERE PD.occ = @occ_sup
			AND PD.fin_id = @fin_id1
			AND PS.occ IS NULL

		IF @fin_id1 = @fin_current
		BEGIN
			EXEC dbo.k_raschet_peny_serv_old @occ
											, @fin_id1
											, @sup_id
			EXEC dbo.k_raschet_peny_serv @occ
									   , @fin_id1
									   , @sup_id
		END


	IF @debug=1
	BEGIN
		SELECT * FROM dbo.PENY_all WHERE occ=@occ_sup AND fin_id=@fin_id1
		SELECT * FROM dbo.Occ_Suppliers os WHERE occ=@occ AND fin_id=@fin_id1
		--SELECT * FROM dbo.PENY_DETAIL PD WHERE occ=@occ_sup AND fin_id=@fin_id1
	END

	END TRY
	BEGIN CATCH
		EXEC dbo.k_err_messages
	END CATCH
go

