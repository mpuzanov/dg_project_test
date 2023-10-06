CREATE   PROCEDURE [dbo].[k_raschet_peny_sup_new]
(
	  @occ_sup INT -- лицевой поставщика
	, @fin_id1 SMALLINT
	, @debug BIT = 0
	, @DateCurrent1 SMALLDATETIME = NULL --
)
AS
	/*
	 Перерасчет пени по заданному лицевому поставщика			
	 автор: Пузанов
	
	exec k_raschet_peny_sup_new 777315327, 184, 1
	*/

	SET NOCOUNT ON

	IF @occ_sup = 0
		RETURN

	DECLARE @err INT -- код ошибки
		  , @fin_current SMALLINT -- текущий фин. период
		  , @occ INT -- Единый лицевой счёт
		  , @sup_id INT -- Код поставщика
		  , @Db_Name VARCHAR(20) = UPPER(DB_NAME())

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
		  , @TIP_ID SMALLINT
		  , @build_id INT
		  , @Penalty_metod TINYINT = 1
		  , @LastPaym TINYINT -- Последний день оплаты (напр. 10 число)
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
		  , @peny_nocalc_date_begin SMALLDATETIME -- дата начала начисления пени на лицевом
		  , @peny_nocalc_date_end SMALLDATETIME -- дата окончания начисления пени на лицевом

	DECLARE @paym_order_metod VARCHAR(10)
		  , @paying_order_metod VARCHAR(10)

	BEGIN TRY

		SELECT @build_id = b.id
			 , @Peny_old = os.Penalty_old
			 , @penalty_calc1 = os.Penalty_calc  --o.Penalty_calc
			 , @penalty_calc_tip1 = ot.penalty_calc_tip
			 , @Penalty_metod = COALESCE(sa.penalty_metod, 0)
			 , @penalty_calc_build = penalty_calc_build
			 , @LastPaym = COALESCE(ot.lastpaym, @LastPaym)
			 , @peny_nocalc_date_begin =o.peny_nocalc_date_begin
			 , @peny_nocalc_date_end = o.peny_nocalc_date_end
			 , @TIP_ID = o.tip_id
			 , @paym_order_metod = ot.paym_order_metod
			 , @occ = os.occ
			 , @sup_id = os.sup_id
			 , @PaymClosed1 = ot.PaymClosed
			 , @PaymClosedData = dbo.Fun_GetOnlyDate(PaymClosedData)
			 , @LastPaym = ot.lastpaym
			 , @LastPaymSup = sa.lastpaym
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
			 , @saldo = o.SALDO
			 , @PenyBeginDolg =
							   CASE
								   WHEN st.PenyBeginDolg > 0 THEN st.PenyBeginDolg
								   ELSE ot.PenyBeginDolg
							   END
			 , @Penalty_old_new = os.Penalty_old_new
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
			LEFT JOIN dbo.Suppliers_types AS st 
				ON ot.id = st.tip_id
				AND sa.id = st.sup_id
			LEFT JOIN dbo.Suppliers_build AS sb 
				ON b.id = sb.build_id
				AND sa.id = sb.sup_id
		WHERE os.occ_sup = @occ_sup
			AND os.fin_id = @fin_id1

		SELECT @fin_current = dbo.Fun_GetFinCurrent(@TIP_ID, NULL, NULL, @occ)

		SELECT @Penalty_metod =
							   CASE
								   WHEN @Penalty_metod_build > 0 THEN @Penalty_metod_build
								   WHEN @Penalty_metod_tip > 0 THEN @Penalty_metod_tip
								   ELSE @Penalty_metod
							   END
		IF @debug = 1
			PRINT 'Метод=' + STR(@Penalty_metod)

		--IF @Penalty_metod>2 SET @Penalty_metod=2

		IF @Penalty_metod > 2
		BEGIN
			IF @debug = 1
				PRINT 'EXEC k_raschet_peny_sup_2016'

			EXEC k_raschet_peny_sup_2016 @occ_sup = @occ_sup
									   , @fin_id1 = @fin_id1
									   , @debug = @debug
			RETURN
		END

		DELETE FROM dbo.Peny_all
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

		-- Если есть действующее соглашение о рассрочке то пени не считаем
		IF EXISTS (
				SELECT 1
				FROM dbo.Pid
				WHERE occ = @occ
					AND pid_tip = 3
					AND sup_id = @sup_id
					AND @start_date BETWEEN data_create AND data_end
			)
			SET @penalty_calc1 = 0


		IF @LastPaymSup > 0
			SET @LastPaym = @LastPaymSup
		IF @lastday_without_peny > 0
			SET @LastPaym = @lastday_without_peny
		IF @lastday_without_peny_build > 0
			SET @LastPaym = @lastday_without_peny_build

		SELECT @start_date = start_date
			 , @end_date = end_date
			 , @PenyProc = PenyProc
			 , @Last_day_month = DAY(end_date)
		FROM dbo.Global_values 
		WHERE fin_id = @fin_current

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

		IF @end_date > @DateCurrent1
			SET @end_date = @DateCurrent1

		IF (@fin_id1 IS NULL)
			OR (@fin_id1 = 0)
			SET @fin_id1 = @fin_current

		--IF @debug = 1
		--	SELECT @build_id
		--		,@penalty_calc_build
		--		,@peny_raschet_tip
		--		,@peny_raschet_build
		--		,@peny_blocked

		-- проверяем на поставщике
		IF NOT EXISTS (
				SELECT 1
				FROM dbo.Suppliers_all 
				WHERE id = @sup_id
					AND Penalty_calc = 1
			)
			SET @peny_blocked = 1
		--IF @debug = 1 PRINT @peny_blocked

		-- проверяем на поставщике по типу фонда	
		SELECT @peny_blocked =
							  CASE
								  WHEN @peny_raschet_tip = 0 THEN 1
								  WHEN (@peny_raschet_tip = 1) AND
									  (@peny_blocked = 1) THEN 0
								  ELSE @peny_blocked
							  END
		--IF @debug = 1 PRINT @peny_blocked

		-- проверяем на поставщике по дому
		SELECT @peny_blocked =
							  CASE
								  WHEN @peny_raschet_build = 0 THEN 1
								  WHEN (@peny_raschet_build = 1) AND
									  (@peny_blocked = 1) THEN 0
								  ELSE @peny_blocked
							  END
		--IF @debug = 1 PRINT @peny_blocked

		IF (@peny_blocked = 1)
		BEGIN -- Пени по поставщику не считаем
			IF @debug = 1
				RAISERROR ('Пени по %d по поставщику не считаем', 10, 1, @occ_sup) WITH NOWAIT;

			DELETE FROM dbo.Peny_detail
			WHERE occ = @occ_sup
				AND fin_id = @fin_id1

			DELETE FROM dbo.Peny_all
			WHERE occ = @occ_sup
				AND fin_id = @fin_id1

			DECLARE @Sum_peny_save DECIMAL(9, 2) = 0
			SELECT @Sum_peny_save = SUM(p.paymaccount_peny)
			FROM dbo.View_payings AS p
			WHERE p.fin_id = @fin_id1
				AND p.occ = @occ
				AND p.sup_id = @sup_id
				AND p.peny_save = 1
				AND p.forwarded = 1

			UPDATE dbo.Occ_Suppliers
			SET penalty_value = 0
			  , paymaccount_peny = COALESCE(@Sum_peny_save, 0)
			  , Penalty_old_new = Penalty_old - COALESCE(@Sum_peny_save, 0)
			WHERE occ = @occ
				AND fin_id = @fin_current
				AND sup_id = @sup_id

			IF @debug = 1
				PRINT '@Sum_peny_save=' + STR(COALESCE(@Sum_peny_save, 0), 9, 2)

			EXEC dbo.k_raschet_peny_serv @occ
									   , @fin_current
									   , @sup_id
									   , @debug

			EXEC dbo.k_raschet_peny_serv_old @occ
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
			JOIN dbo.Services AS s 
				ON vs.service_id = s.id
				AND s.is_peny = 1 -- !!! для расчёта пени
		WHERE vs.sup_id = @sup_id

		IF dbo.Fun_GetOccClose(@occ) = 0
		BEGIN
			-- raiserror('Лицевой счет %d закрыт! Работа с ним запрещена',16,1,@occ1)
			RETURN
		END

		--DECLARE @t_paym_order TABLE
		--	(
		--		id		INT	IDENTITY (1, 1)
		--		,name	VARCHAR(20)
		--	)
		--INSERT INTO @t_paym_order
		--		SELECT
		--			*
		--		FROM STRING_SPLIT(@paym_order, ';')
		--		WHERE RTRIM(value) <> ''
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
			PRINT 'Метод оплаты пени по типу фонда:' + LTRIM(@paym_order_metod)

		SET @fin_pred1 = @fin_id1 - 1
		SET @fin_pred2 = @fin_id1 - 2
		SELECT @PaymClosedDataPred = dbo.Fun_GetOnlyDate(PaymClosedData)
		FROM dbo.VOcc_types_all
		WHERE fin_id = @fin_pred1
			AND id = @TIP_ID

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
				 , @penalty_calc1 AS penalty_calc
				 , @DateCurrent1 AS DateCurrent

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
				 , @penalty_calc1 AS penalty_calc
				 , @PenyProc AS PenyProc

		DECLARE @d1 SMALLDATETIME
			  , @i SMALLINT = 1
		SELECT @d1 = @start_date - 20 -- даём 30 дней (если не все были закрыты платежи в прошлом месяце)

		--IF @TIP_ID = 109 -- ТСН КОМФОРТ @occ_sup = 777315327
		--	AND @Db_Name IN ('KOMP')
		INSERT INTO @t1 (paying_id
					   , data1
					   , paymaccount
					   , paying_order_metod)
		SELECT p.id
			 , pd.day
			 , p.Value
			 , po.paying_order_metod
		FROM dbo.Payings AS p 
			JOIN dbo.Paydoc_packs AS pd 
				ON pd.id = p.pack_id
			JOIN dbo.Paycoll_orgs AS po 
				ON pd.fin_id = po.fin_id
				AND pd.source_id = po.id
			JOIN dbo.Paying_types AS pt 
				ON po.vid_paym = pt.id
		WHERE pd.fin_id = @fin_id1
			AND p.occ = @occ
			AND p.sup_id = @sup_id
			AND pt.peny_no = 0 -- доля оплаты пени только такие виды платежей   -- 19.01.2012
			AND p.forwarded = 1
		--AND p.peny_save = 0

		IF NOT EXISTS (SELECT 1 FROM @t1)
		BEGIN
			INSERT INTO @t1 (data1)
			SELECT DATEADD(DAY, n, @d1)
			FROM dbo.Fun_GetNums(1, DATEDIFF(DAY, @d1, @end_date))
		END

		UPDATE @t1
		SET paying_id = 0
		WHERE data1 = @start_date
			AND paymaccount = 0 -- 21.10.2015

		UPDATE @t1
		SET paying_id = 0
		WHERE data1 = @start_date
			AND paymaccount = 0 -- 13/06/2012
		UPDATE @t1
		SET paying_id = 0
		WHERE data1 = @LastDatePaym
			AND paymaccount = 0 -- 13/06/2012
		--UPDATE @t1  SET paying_id=0 WHERE data1=@end_date

		DELETE FROM @t1
		WHERE paying_id IS NULL

		UPDATE t1
		SET data2 = (
			SELECT TOP 1 data1
			FROM @t1 AS t2
			WHERE t2.data1 >= t1.data1
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

		-- Первая строка
		UPDATE t
		SET peny_old = @Peny_old
		FROM @t1 AS t
		WHERE id = (
				SELECT TOP 1 id
				FROM @t1
				ORDER BY id
			)
		IF @debug = 1
			SELECT '@t1', *
			FROM @t1
			ORDER BY data1
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
			  , @Paymaccount DECIMAL(9, 2)
			  , @Paymaccount_peny DECIMAL(9, 2)
			  , @Paymaccount_serv DECIMAL(9, 2)
			  , @Description VARCHAR(1000) = ''
			  , @peny_fin_preg_new DECIMAL(9, 2) = 0 -- Рассчитанные пени в прошлом месяце

		--********** Сохраняем сумму начислений предыдущего месяца        
		SELECT @Paid_Pred = SUM(p.Paid)
		FROM dbo.Occ_Suppliers AS os 
			JOIN dbo.View_paym AS p 
				ON os.occ = p.occ
				AND os.fin_id = p.fin_id
			JOIN dbo.Consmodes_list AS cl 
				ON p.occ = cl.occ
				AND p.service_id = cl.service_id
				AND os.occ_sup = cl.occ_serv
			JOIN dbo.Services AS s 
				ON p.service_id = s.id
				AND s.is_peny = 1 -- !!! для расчёта пени
		WHERE os.occ = @occ
			AND os.fin_id = @fin_pred1
			AND os.sup_id = @sup_id
			AND (p.sup_id > 0)


		SELECT @peny_fin_preg_new = ((os.penalty_old_new+os.penalty_added)+os.penalty_value)
		FROM dbo.Occ_Suppliers AS os 
		WHERE os.occ = @occ
			AND os.fin_id = @fin_pred1
			AND os.sup_id = @sup_id

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
			AND p.peny_save = 0   -- ручная корректировка

		--************************************************ 
		DELETE FROM dbo.Peny_all 
		WHERE occ = @occ_sup and fin_id=@fin_id1;

		DELETE FROM dbo.Peny_detail 
		WHERE fin_id = @fin_id1
			AND occ = @occ_sup;

		SET @Peny_old_new = @Peny_old

		-- ******************************************************
		IF @fin_id1 = @fin_current
		BEGIN
			EXEC dbo.k_raschet_peny_serv_old @occ
										   , @fin_id1
										   , @sup_id
		--EXEC dbo.k_raschet_peny_serv @occ, @fin_id1, @sup_id
		END
		-- ******************************************************

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

			--SELECT @Dolg = dbo.Fun_GetSumDolgSup(@occ, @fin_current, @data1, @LastDatePaym, @sup_id)

			EXEC dbo.k_GetSumDolgSup @occ
								   , @fin_current
								   , @data1
								   , @LastDatePaym
								   , @sup_id
								   , 0
								   , @Dolg OUT
								   , @fin_Dolg OUT
								   , @Description OUT

			EXEC dbo.k_GetSumDolgPenySup @occ
									   , @fin_current
									   , @data1
									   , @LastDatePaym
									   , 0
									   , @Dolg_peny OUT
									   , @sup_id

			--SET @Dolg_peny = @Dolg

			IF @debug = 1
			BEGIN
				PRINT '@data1= ' + CONVERT(VARCHAR(12), @data1, 112)
				PRINT '@LastDatePaym= ' + CONVERT(VARCHAR(12), @LastDatePaym, 112)
				PRINT '@Paid_Pred_begin= ' + STR(@Paid_Pred_begin, 9, 2)
				PRINT '@fin_current= ' + STR(@fin_current)
				PRINT '@Dolg= ' + STR(@Dolg, 9, 2)
				PRINT '@Dolg_peny= ' + STR(@Dolg_peny, 9, 2)
				PRINT '@paying_order_metod= ' + @paying_order_metod
			END

			IF @Dolg_peny < 0
				SET @Dolg_peny = 0
			IF @Penalty_metod = 1
				AND @Dolg_peny > @Paid_Pred_begin
				SET @Dolg_peny = @Paid_Pred_begin -- по методу 1 не более суммы начислений

			SET @Paymaccount_peny = 0

			--****************************************************************************
			-- Порядок оплаты: Пени, Долг, Начисление
			IF @paying_order_metod = 'пени1'
			BEGIN
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
					PRINT '0  ' + STR(COALESCE(@Dolg, 0), 9, 2) + ' ' + STR(COALESCE(@Paid_Pred, 0), 9, 2) + '   ' + STR(COALESCE(@SumPaymaccount, 0), 9, 2) + '   ' + STR(COALESCE(@Paymaccount_serv, 0), 9, 2)
				END

				--IF (@fin_current > @fin_Dolg)  -- 20.10.15
				----AND (@data1>@start_date)			
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
					SET @peny_fin_preg_new = 0

				IF @debug = 1
				BEGIN
					PRINT '@data1=' + CONVERT(VARCHAR(10), @data1, 112)
					PRINT '@Paymaccount_serv=' + STR(@Paymaccount_serv, 9, 2)
					PRINT '@SumPaymaccount=' + STR(@SumPaymaccount, 9, 2)
					PRINT '@Peny_old_new=' + STR(@Peny_old_new, 9, 2)
					PRINT '@Dolg_peny=' + STR(@Dolg_peny, 9, 2)
					PRINT '@Dolg=' + STR(@Dolg, 9, 2)
					PRINT '@Paid_Pred=' + STR(@Paid_Pred, 9, 2)
					PRINT '@fin_current=' + STR(@fin_current)
					PRINT '@peny_fin_preg_new=' + STR(@peny_fin_preg_new, 9, 2)
				END

				IF @Paymaccount = @saldo
					SET @penalty_paym_no = 1 -- 21/08/13 не делать оплату пени кто оплатил ровно			

				IF (@Dolg) <= 0
					AND (
					((@Peny_old_new - @peny_fin_preg_new) > 0   -- если фин.период ещё не начался нельзя оплачивать пени этого месяца
					AND (@data1 < @start_date))
					OR ((@Peny_old_new > 0)
					AND (@data1 >= @start_date))
					)
					--AND (@Peny_old_new) > 0
					AND (@Paymaccount_serv > 0)
					AND (@SumPaymaccount > 0)
					AND (@penalty_paym_no = 0) --@Dolg <= 0 AND 
				BEGIN
					IF @debug = 1
						PRINT 'Находим оплачено пени ' + STR(@paying_id1)

					SET @Peny_old_new_tmp = @Peny_old_new - @peny_fin_preg_new
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
					SET @Peny_old_new = @Peny_old_new + @peny_fin_preg_new
				END
			-- ***************************************************************************	  
			END

			IF @penalty_paym_no = 1
				SET @Paymaccount_peny = 0

			IF @Dolg_peny < 0
				SET @Dolg_peny = 0

			-- ********************************************
			UPDATE @t1
			SET dolg = @Dolg
			  , dolg_peny = @Dolg_peny
			  , peny_old = @Peny_old
			  , peny_old_new = @Peny_old_new
			  , paymaccount_peny = @Paymaccount_peny
			  , penalty_value =
							   CASE
								   WHEN 1 = 0 THEN 0
								   WHEN @Dolg_peny < @PenyBeginDolg THEN 0
								   ELSE @Dolg_peny * 0.01 * @PenyProc * kol_day
							   END
			  , descrip = @Description
			WHERE id = @i

			-- Раскидываем оплачено пени по услугам по платежу
			EXEC k_paying_serv_peny @paying_id1
								  , @Paymaccount_peny
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
		--

		IF @debug = 1
			SELECT '@t1' AS '@t1'
				 , *
			FROM @t1
			ORDER BY data1
		--SELECT TOP 1 peny_old FROM @t1 ORDER BY id

		DECLARE @penalty_added DECIMAL(9, 2)
		SET @penalty_added = COALESCE((
			SELECT pa.value_added
			FROM dbo.Peny_added pa
			WHERE pa.fin_id = @fin_id1
				AND pa.occ = @occ_sup
		), 0)

		SELECT @SumPaymaccount1 = SUM(COALESCE(p.Value, 0))
			 , @Paymaccount_peny = SUM(COALESCE(p.paymaccount_peny, 0))
		FROM dbo.Payings AS p 
			JOIN dbo.Paydoc_packs AS pd 
				ON p.pack_id = pd.id
		WHERE occ = @occ
			AND pd.fin_id = @fin_id1
			AND p.sup_id = @sup_id
			AND p.forwarded = 1
		OPTION (RECOMPILE)

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
								 , metod)
		SELECT @fin_id1
			 , @occ_sup
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
			   --(SELECT	SUM(paymaccount) FROM @t1) AS paymaccount
			 , COALESCE(@Paymaccount_peny, 0) AS paymaccount_peny
			   --(SELECT SUM(paymaccount_peny) FROM @t1) as paymaccount_peny
			 , @Peny_old AS peny_old
			   --(SELECT TOP 1 peny_old FROM @t1 ORDER BY id)
			 , @Peny_old - COALESCE(@Paymaccount_peny, 0) AS peny_old_new
			 , @penalty_added
			 , COALESCE((SELECT SUM(penalty_value) FROM @t1), 0) AS penalty_value
			 , COALESCE((SELECT SUM(kol_day) FROM @t1), 0) AS kolday
			 , current_timestamp AS data_rascheta
			 , @Penalty_metod AS metod

		IF @debug = 1
			SELECT 'PENY_ALL'
				 , *
			FROM dbo.Peny_all
			WHERE fin_id = @fin_id1
				AND occ = @occ_sup

		INSERT INTO dbo.Peny_detail (fin_id
								   , occ
								   , paying_id
								   , data1
								   , kol_day
								   , dolg_peny
								   , paid_pred
								   , Paymaccount_Serv
								   , paymaccount_peny
								   , peny_old
								   , peny_old_new
								   , Peny
								   , dat1
								   , dolg
								   , [description])
		SELECT @fin_id1
			 , @occ_sup
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
			   END
		FROM @t1

		-- Если на ЛС не расчитываем пени то зануляем
		UPDATE dbo.Peny_all
		SET penalty_value = 0
		WHERE occ = @occ_sup
			AND fin_id = @fin_id1
			AND @penalty_calc1 = 0

		DELETE FROM dbo.Peny_all 
		WHERE occ = @occ_sup
			AND fin_id = @fin_id1
			AND peny_old = 0
			AND peny_old_new = 0
			AND paymaccount = 0
			AND paymaccount_peny = 0
			AND penalty_value = 0;

		IF @fin_id1 < @fin_current
		BEGIN
			DELETE FROM dbo.Peny_detail
			WHERE occ = @occ_sup
				AND fin_id = @fin_id1;

			DELETE FROM dbo.Peny_all 
			WHERE occ = @occ_sup
				AND fin_id = @fin_id1;
		END

		UPDATE os 
		SET penalty_value = COALESCE(ps.penalty_value, 0) --+ COALESCE(ps.penalty_added, 0)
		  , Penalty_old_new = COALESCE(ps.peny_old_new, 0)
		  , paymaccount_peny = COALESCE(ps.paymaccount_peny, 0)
		  , penalty_added = COALESCE(@penalty_added, 0)
		  , penalty_calc = @penalty_calc1
		FROM dbo.Occ_Suppliers os
			LEFT JOIN dbo.Peny_all ps 
				ON os.fin_id = ps.fin_id
				AND os.occ_sup = ps.occ
		WHERE os.occ = @occ
			AND os.fin_id = @fin_id1
			AND os.sup_id = @sup_id

		DELETE PD
		FROM dbo.Peny_detail PD
			LEFT JOIN dbo.Peny_all PS 
				ON PD.occ = PS.occ
				AND PD.fin_id = PS.fin_id
		WHERE PD.occ = @occ_sup
			AND PD.fin_id = @fin_id1
			AND PS.occ IS NULL

		IF @fin_id1 = @fin_current
		BEGIN
			SELECT @Penalty_old_new2 = COALESCE(ps.peny_old_new, 0)
			FROM dbo.Peny_all ps 
			WHERE ps.fin_id = @fin_id1
				AND ps.occ = @occ_sup

			IF @Penalty_old_new2 <> @Penalty_old_new
				EXEC dbo.k_raschet_peny_serv_old @occ
											   , @fin_id1
											   , @sup_id

			EXEC dbo.k_raschet_peny_serv @occ
									   , @fin_id1
									   , @sup_id
		END


	--IF @debug=1
	--BEGIN
	--	SELECT * FROM dbo.PENY_ALL WHERE occ=@occ_sup AND fin_id=@fin_id1
	--	SELECT * FROM dbo.PENY_DETAIL PD WHERE occ=@occ_sup AND fin_id=@fin_id1
	--END

	END TRY
	BEGIN CATCH
		EXEC dbo.k_err_messages
	END CATCH
go

