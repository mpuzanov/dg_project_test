-- =============================================
-- Author:		Пузанов
-- Create date: 22.12.2012
-- Description:	Автоматический перерасчет по внутр. счётчикам если в прошлый месяц начислено по норме
-- =============================================
CREATE             PROCEDURE [dbo].[ka_counter_norma3]
(
	  @occ INT
	, @fin_current SMALLINT = NULL
	, @debug BIT = 0
	, @doc_no VARCHAR(10) = '888'
)
AS
/*
exec ka_counter_norma3 @occ=700005579, @fin_current=157, @debug=1
exec ka_counter_norma3 @occ=166040, @fin_current=254, @debug=1

metod_old = 
0-не начислять,
1-по норме,
2-по среднему,
3-по счетчику, 
4-по общедомовому счётчику

metod_old = 5 - делать возврат
*/
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	IF @fin_current IS NULL
		SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ);

	IF @doc_no IS NULL
		SET @doc_no = '888';

	--select * FROM dbo.ADDED_PAYMENTS ap WHERE ap.occ=@occ AND ap.add_type=12 AND ap.doc_no=@doc_no

	DECLARE @service_id1 VARCHAR(10)
		  , @doc_no_sub12 VARCHAR(10) = '886'
		  , @tip_id SMALLINT
		  , @build_id INT
		  , @kolmes SMALLINT = 0
		  , @kol_counter DECIMAL(9, 2) = 0
		  , @kol_add DECIMAL(12, 6) = 0
		  , @comments VARCHAR(50) = ''
		  , @sum_add DECIMAL(9, 2) = 0
		  , @doc1 VARCHAR(50) = ''
		  , @first_mes SMALLINT
		  , @last_mes SMALLINT
		  , @str_mes VARCHAR(30) = ''
		  , @sys_user VARCHAR(30) = system_user
		  , @counter_add_ras_norma BIT -- выполнять Автоматический перерасчет по внутр. счётчикам по типу фонда
		  , @blocked_counter_add_ras_norma BIT -- Автоматический перерасчет по внутр. счётчикам. Всё что уже расчитано оставить и более не считать
		  , @counter_votv_norma BIT = 0 -- расчёт водоотведения по норме
		  , @DB_NAME VARCHAR(20) = UPPER(DB_NAME())
		  , @blocked_counter_add BIT = 0
		  , @is_counter_add_balance BIT = 0
		  , @tarif DECIMAL(10, 4)
		  , @ras_no_counter_poverka BIT  -- слежение за датой поверки
		  , @sup_id INT
		  , @is_not_add_date_create BIT = 1 -- убираем из расчета месяц установки счётчика
		  , @is_vozvrat_votv_sum BIT = 0
		  , @start_data_fin_current DATETIME
		  , @end_data_fin_current DATETIME
		  , @status1 VARCHAR(10)
		  , @proptype1 VARCHAR(10)

	IF dbo.strpos('KR1', @DB_NAME) > 0
		SET @is_not_add_date_create = 0

	SELECT @tip_id = b.tip_id
		 , @build_id = b.id
		 , @counter_add_ras_norma = ot.counter_add_ras_norma
		 , @blocked_counter_add_ras_norma = COALESCE(ot.blocked_counter_add_ras_norma, 0)
		 , @counter_votv_norma = COALESCE(ot.counter_votv_norma, 0)
		 , @blocked_counter_add = b.blocked_counter_add
		 , @is_counter_add_balance = ot.is_counter_add_balance
		 , @ras_no_counter_poverka =
           CASE
               WHEN b.ras_no_counter_poverka = 1 THEN b.ras_no_counter_poverka
               ELSE ot.ras_no_counter_poverka
               END
		 , @is_vozvrat_votv_sum = ot.is_vozvrat_votv_sum
		 , @start_data_fin_current = b.date_start
		 , @end_data_fin_current = dbo.fn_end_month(b.date_start)		 
		 , @status1 = o.status_id
		 , @proptype1 = o.proptype_id
	FROM dbo.Occupations AS o
		JOIN dbo.Flats f ON 
			o.flat_id = f.id
		JOIN dbo.Buildings b ON 
			f.bldn_id = b.id
		JOIN dbo.Occupation_Types AS ot ON 
			b.tip_id = ot.id
	WHERE o.occ = @occ;

	IF @blocked_counter_add_ras_norma = 1
		RETURN;
	
	IF @counter_add_ras_norma = 0
		OR @blocked_counter_add = 1
	BEGIN
		DELETE dbo.Added_Payments
		WHERE occ = @occ
			AND add_type = 12
			AND doc_no = @doc_no
			AND fin_id = @fin_current;

		DELETE dbo.Added_Payments
		WHERE occ = @occ
			AND add_type = 15
			AND doc_no = @doc_no_sub12
			AND fin_id = @fin_current;

		RETURN; -- не расчитываем и выходим
	END;

	IF @debug = 1
		SELECT @tip_id AS tip_id
			 , @build_id AS build_id
			 , @counter_add_ras_norma AS counter_add_ras_norma
			 , @blocked_counter_add_ras_norma AS blocked_counter_add_ras_norma
			 , @counter_votv_norma AS counter_votv_norma
			 , @blocked_counter_add AS blocked_counter_add
			 , @ras_no_counter_poverka AS ras_no_counter_poverka
			 , @is_counter_add_balance AS is_counter_add_balance

	SELECT 		
		cp.start_date
		,cl.*
		,c.flat_id
		,c.build_id AS bldn_id
		,c.serial_number
		,c.unit_id
		,c.date_create
		,c.date_del
		,c.date_edit
		,c.PeriodCheck
	INTO #vca
	FROM dbo.Counter_list_all AS cl 
	JOIN dbo.Counters AS c 
		ON cl.counter_id = c.id
	JOIN dbo.Calendar_period as cp ON 
		cp.fin_id=cl.fin_id
	WHERE 
		cl.occ = @occ
		and cl.fin_id>=192 -- начнём с 2018 года

	--********************************************  17/04/2014
	SELECT fin_id, vp.occ, vp.service_id, vp.sup_id, vp.tarif, vp.kol, vp.Value, vp.kol_norma, vp.metod_old, vp.metod, vp.mode_id, vp.source_id, vp.is_counter
	INTO #vp
	FROM dbo.View_paym vp
	WHERE vp.occ=@occ
	and vp.fin_id>=192 -- начнём с 2018 года

	CREATE INDEX occ ON #vp (occ, fin_id, service_id) 

	UPDATE vp
	SET is_counter = 2
	FROM #vp vp  --dbo.Paym_history AS vp 
	WHERE fin_id > (@fin_current - 6)
		AND vp.occ = @occ
		AND COALESCE(vp.is_counter, 0) = 0
		AND vp.service_id IN ('гвод', 'хвод', 'гвс2', 'хвс2')
		AND EXISTS (
			SELECT 1
			FROM #vca AS vci
			WHERE vci.fin_id = vp.fin_id
				AND vci.occ = vp.occ
				AND vci.service_id =
									CASE
										WHEN vp.service_id = 'гвс2' THEN 'гвод'
										WHEN vp.service_id = 'хвс2' THEN 'хвод'
										ELSE vp.service_id
									END
				AND vci.internal = 1
		);

	--********************************************	

	CREATE TABLE #tc
	--DECLARE @tc TABLE
	(
		  fin_id SMALLINT NOT NULL
		, service_id VARCHAR(10) COLLATE database_default NOT NULL
		, kod_counter INT DEFAULT NULL -- сумма кодов счетчиков по услуге (перерасчёт делать только если она совпадает с текущим мес.)
		, metod_old SMALLINT DEFAULT NULL
		, kol DECIMAL(12, 6) DEFAULT 0
		, value DECIMAL(9, 2) DEFAULT 0
		, is_counter SMALLINT DEFAULT 0
		, sup_id INT DEFAULT 0
		, serv2 VARCHAR(10) COLLATE database_default DEFAULT NULL
		, date_create SMALLDATETIME DEFAULT NULL
		, tarif DECIMAL(10, 4) DEFAULT NULL
		, sub12 DECIMAL(9, 2) NOT NULL DEFAULT 0    -- сумма СУБСИДИИ 12% РСО (нужно вычитать из разовых)
		, PeriodCheck SMALLDATETIME DEFAULT NULL
		, counter_id_one INT DEFAULT NULL -- один из ПУ
		, blocked_value BIT DEFAULT 0
		, KolmesForPeriodCheck INT DEFAULT 0 NOT NULL
		--, tarif_last DECIMAL(10, 4) DEFAULT 0
	--,occ INT  DEFAULT NULL
	);

	--;WITH VCA_CTE  
	--AS (SELECT * FROM [dbo].[View_COUNTER_ALL] WHERE occ=@occ)

	INSERT INTO #tc (fin_id
				   , service_id
				   , kod_counter
				   , serv2
				   , date_create
				   , PeriodCheck
				   , sup_id
				   , counter_id_one)
	SELECT vc.fin_id
		 , vc.service_id
		 , SUM(vc.counter_id)
		 , vc.service_id
		 , vc.date_create
		 , vc.PeriodCheck
		 , vp.sup_id  --vp.sup_id
		 , MIN(vc.counter_id)
	FROM #vca vc 
		JOIN #vp vp ON 
			vc.fin_id = vp.fin_id 
			AND vc.occ = vp.occ 
			AND vc.service_id = vp.service_id
	WHERE vc.occ = @occ
		AND (vc.date_del IS NULL OR vc.date_del > @start_data_fin_current) -- 23.09.2022 поставил @start_data_fin_current
		--AND (vc.date_del IS NULL OR vc.date_del > vc.start_date) -- до 23.09.2022
		--AND (vc.date_del IS NULL OR vc.date_del >= DATEADD(MONTH, 1, vc.start_date)) --20.11.20 убираем месяц закрытия счётчика OR vc.date_del > vc.start_date)

		AND (
		(vc.date_create <= vc.start_date AND @is_not_add_date_create = 1) -- убираем месяц установки счётчика
		OR @is_not_add_date_create = 0
		)
	GROUP BY vc.fin_id
		   , vc.service_id
		   , vc.date_create
		   , vc.PeriodCheck
		   , vp.sup_id  --vp.sup_id
	UNION ALL
	SELECT fin_id
		 , 'гвс2'
		 , SUM(counter_id)
		 , 'гвод'
		 , date_create
		 , PeriodCheck
		 , 0
		 , MIN(counter_id)
	FROM #vca vc 
	WHERE occ = @occ
		AND service_id = 'гвод'
		AND (date_del IS NULL OR vc.date_del >= DATEADD(MONTH, 1, vc.start_date)) -- убираем месяц закрытия счётчика OR date_del > start_date)
		AND (
		(vc.date_create <= vc.start_date AND @is_not_add_date_create = 1) -- убираем месяц установки счётчика
		OR @is_not_add_date_create = 0
		)
	GROUP BY fin_id
		   , service_id
		   , date_create
		   , PeriodCheck
	UNION ALL
	SELECT vc.fin_id
		 , 'хвс2'
		 , SUM(vc.counter_id)
		 , 'хвод'
		 , vc.date_create
		 , vc.PeriodCheck
		 , vp.sup_id
		 , MIN(vc.counter_id)
	FROM #vca vc 
		JOIN #vp vp ON vc.fin_id = vp.fin_id AND vc.occ = vp.occ AND vc.service_id = vp.service_id   -- 16.11.16
	WHERE vc.occ = @occ
		AND vc.service_id = 'хвод'
		--AND vp.service_id IN ('хвод','хвс2')   -- 16.11.16
		AND (vc.date_del IS NULL --OR vc.date_del > vc.start_date)
		OR vc.date_del >= DATEADD(MONTH, 1, vc.start_date)) -- убираем месяц закрытия счётчика
		AND (
		(vc.date_create <= vc.start_date AND @is_not_add_date_create = 1) -- убираем месяц установки счётчика
		OR @is_not_add_date_create = 0
		)
	GROUP BY vc.fin_id
		   , vc.service_id
		   , vc.date_create
		   , vc.PeriodCheck
		   , vp.sup_id

	INSERT INTO #tc (fin_id
				   , service_id
				   , kod_counter
				   , serv2
				   , date_create
				   , PeriodCheck
				   , sup_id
				   , counter_id_one)
	SELECT vc.fin_id
		 , 'хвс2'
		 , SUM(vc.counter_id)
		 , 'хвод'
		 , vc.date_create
		 , vc.PeriodCheck
		 , vp.sup_id
		 , MIN(vc.counter_id)
	FROM #vca vc
		JOIN #vp vp ON 
			vc.fin_id = vp.fin_id 
			AND vc.occ = vp.occ --	AND vc.service_id = vp.service_id   -- 16.11.16
	WHERE vc.occ = @occ
		AND vc.service_id IN ('хвод', 'хвс2')
		AND vp.service_id = 'хвс2'   -- 16.11.16
		AND vp.value <> 0
		AND (vc.date_del IS NULL
		--OR vc.date_del > vc.start_date)
		OR vc.date_del >= DATEADD(MONTH, 1, vc.start_date))	-- убираем месяц закрытия счётчика
		AND (
		(vc.date_create <= vc.start_date AND @is_not_add_date_create = 1) -- убираем месяц установки счётчика
		OR @is_not_add_date_create = 0
		)
		AND NOT EXISTS (
			SELECT 1
			FROM #tc t
			WHERE t.fin_id = vp.fin_id
				AND t.service_id = N'хвс2'
		)
	GROUP BY vc.fin_id
		   , vc.service_id
		   , vc.date_create
		   , vc.PeriodCheck
		   , vp.sup_id

	INSERT INTO #tc (fin_id
				   , service_id
				   , serv2
				   , date_create
				   , sup_id)
	SELECT DISTINCT t1.fin_id
				  , 'вотв'
				  , 'вотв'
				  , (
						SELECT TOP 1 t2.date_create
						FROM #tc AS t2
						WHERE t1.fin_id = t2.fin_id
					)
				  , 0
	FROM #tc AS t1
	UNION ALL
	SELECT DISTINCT t1.fin_id
				  , 'вот2'
				  , 'вотв'
				  , (
						SELECT TOP 1 t2.date_create
						FROM #tc AS t2
						WHERE t1.fin_id = t2.fin_id
					)
				  , vca.sup_id
	FROM #tc AS t1
		JOIN #vp vca ON 
			vca.fin_id = t1.fin_id
			AND vca.occ = @occ
			AND vca.service_id = 'вот2'
	UNION ALL
	SELECT DISTINCT fin_id, N'тепл', N'тепл', 
	(SELECT TOP 1 t2.date_create FROM #tc AS t2	WHERE t1.fin_id = t2.fin_id), 0
	FROM #tc AS t1
	UNION ALL
	SELECT DISTINCT fin_id, N'гГВС', N'гГВС', 
	(SELECT TOP 1 t2.date_create FROM #tc AS t2	WHERE t1.fin_id = t2.fin_id), 0
	FROM #tc AS t1
	UNION ALL
	SELECT DISTINCT fin_id, N'элХвсГвс', N'элХвсГвс', 
	(SELECT TOP 1 t2.date_create FROM #tc AS t2 WHERE t1.fin_id = t2.fin_id), 0
	FROM #tc AS t1
	
	-- удалим фин.периоды
	DELETE t1
	FROM #tc AS t1
		JOIN dbo.Services_types st ON t1.service_id = st.service_id
		JOIN dbo.Global_values gv ON t1.fin_id = gv.fin_id
	WHERE st.tip_id = @tip_id
		AND gv.start_date < st.date_ras_start  -- дата в типе фонда - начало расчета услуги

	-- 21.04.23
	DELETE t1
	FROM #tc AS t1
	WHERE t1.service_id in ('хвс2','вот2','гвс2')
	AND NOT EXISTS(SELECT 1 FROM #vp t2 WHERE t2.service_id in ('хвс2','вот2','гвс2') AND t2.tarif>0);

	UPDATE t1
	SET metod_old = COALESCE(vp.metod_old, vp.metod)
	  , kol = CASE WHEN (t1.service_id='отоп' AND t1.fin_id>247 AND vp.value<>0) THEN COALESCE(vp.kol_norma, 0)
					else COALESCE(vp.kol, 0)
				END
	  , t1.value = vp.value
	  , is_counter = vp.is_counter
	  , sup_id = vp.sup_id  --14.05.2014
	  , tarif = CASE
					  WHEN (t1.service_id='отоп' AND t1.fin_id>247 AND vp.value<>0) THEN
					  COALESCE(
							(SELECT r.value
							FROM dbo.Rates AS r 
							WHERE (r.service_id = t1.service_id)
								AND (r.mode_id = vp.mode_id)
								AND (r.source_id = vp.source_id)
								AND (r.FinPeriod = t1.fin_id)
								AND (r.tipe_id = @tip_id)
								AND (r.status_id = @status1)
								AND (r.proptype_id = @proptype1)
								)
							,vp.tarif)
					  ELSE vp.tarif
					  END
	FROM #tc AS t1
		JOIN #vp AS vp ON 
			vp.fin_id = t1.fin_id
			AND vp.service_id = t1.service_id
	WHERE vp.occ = @occ;

	UPDATE t1
	SET value= kol* t1.tarif
	FROM #tc AS t1
	WHERE service_id='отоп' 
		AND fin_id>247

	IF @debug=1 SELECT '1 #tc' AS tbl,* FROM #tc t ORDER BY fin_id DESC

	-- ======================================== 15/04/2023
	IF dbo.strpos('KR1', @DB_NAME) > 0
	BEGIN
		-- хотят вычислять кол-во по текущему тарифу

		UPDATE t1
		SET kol = t1.value / t2.tarif
		FROM #tc AS t1
			JOIN #tc AS t2 ON 
				t1.service_id=t2.service_id 
				AND t1.sup_id=t2.sup_id
		WHERE 
			t2.tarif>0 
			AND t1.value<>0
			AND t2.fin_id=@fin_current
			AND t1.fin_id<@fin_current		
			--AND t1.service_id in ('элек')

		IF @debug=1 SELECT 'kol #tc' AS tbl, * FROM #tc t ORDER BY fin_id DESC
	END
	-- ========================================

	-- Когда несколько счётчиков суммы двойные (удаляем у одного)  24.03.2015
	UPDATE t1
	SET kol = 0
	  , value = 0
	FROM #tc AS t1
		JOIN #tc AS t2 ON 
			t1.fin_id = t2.fin_id
			AND t1.service_id = t2.service_id
			AND t1.kol = t2.kol
			AND t1.value = t2.value
			AND t1.kod_counter < t2.kod_counter;
	--IF @debug=1 SELECT 2,* FROM #tc t
	--***********************************************
	-- 20.11.20 если показание блокировано или для информации не делаем по нему возврат
	UPDATE t1
	SET kol = 0
	  , t1.value = 0
	--if @debug=1	SELECT '[COUNTER_INSPECTOR]',*
	FROM #tc AS t1
		JOIN dbo.[Counter_inspector] AS vp ON 
			vp.[counter_id] = t1.counter_id_one --AND t1.fin_id = vp.fin_id
	WHERE vp.fin_id = @fin_current
		AND (vp.blocked = 1 OR vp.is_info = 1)

	--IF @debug = 1	SELECT 3, *	FROM #tc t	ORDER BY t.fin_id DESC

	--UPDATE t1
	--SET kol = 0
	--  , t1.value = 0
	--  , t1.metod_old = NULL
	--FROM #tc AS t1
	--WHERE t1.fin_id = @fin_current AND t1.kol<0

	--IF @debug=1 SELECT '3 kol<0',* FROM #tc t ORDER BY t.fin_id DESC

	-- ********************************************* 
	IF @debug=1 SELECT 'metod_old', * FROM #tc ORDER BY fin_id desc
	UPDATE t1
	SET metod_old = 3
	FROM #tc AS t1
		JOIN dbo.Counter_inspector AS vp ON 
			vp.fin_id >= t1.fin_id  -- 10.03.2017  добавил знак >
			AND vp.[counter_id] = t1.counter_id_one	  -- соединяемся с одним из счётчиков
			--AND vp.[counter_id] = t1.kod_counter    -- Когда более 1 ИПУ не работает (не сходиться)
	WHERE (metod_old IS NULL OR t1.metod_old IN (1, 2)
		)
		AND vp.tip_value = 0  -- добавил 08.02.2017  (при поверке меняют дату показания инспектора)
	IF @debug=1 SELECT 'metod_old', * FROM #tc ORDER BY fin_id desc
	--==============================================================
	UPDATE t1
	SET metod_old = 3
	FROM #tc AS t1
		JOIN #tc AS t2 ON 
			t2.fin_id = t1.fin_id
	WHERE t1.service_id = 'хвс2'
		AND t2.service_id = 'хвод'
		AND t1.metod_old IS NULL
		AND t2.metod_old = 3;

	UPDATE t1
	SET metod_old = 3
	FROM #tc AS t1
		JOIN #tc AS t2 ON 
			t2.fin_id = t1.fin_id
	WHERE t1.service_id = 'хвод'
		AND t2.service_id = 'хвс2'
		AND t1.metod_old IS NULL
		AND t2.metod_old = 3;
	--==============================================================
	UPDATE t1
	SET metod_old = 3
	FROM #tc AS t1
		JOIN #tc AS t2 ON 
			t2.fin_id = t1.fin_id
	WHERE t1.service_id = 'гвс2'
		AND t2.service_id = 'гвод'
		AND t1.metod_old IS NULL
		AND t2.metod_old = 3;

	UPDATE t1
	SET metod_old = 3
	FROM #tc AS t1
		JOIN #tc AS t2 ON 
			t2.fin_id = t1.fin_id
	WHERE t1.service_id = 'гвод'
		AND t2.service_id = 'гвс2'
		AND t1.metod_old IS NULL
		AND t2.metod_old = 3;

	--==============================================================							
	UPDATE t1
	SET metod_old = 0
	FROM #tc AS t1
	WHERE t1.service_id IN ('вотв', 'вот2')
		AND t1.metod_old IS NULL
		AND EXISTS (
			SELECT 1
			FROM #tc AS t2
			WHERE t2.fin_id = t1.fin_id
				AND t2.metod_old IS NOT NULL
				AND t2.service_id IN ('хвод', 'гвод', 'хвс2', 'гвс2')
		);

	UPDATE t1
	SET kod_counter = 2
	FROM #tc AS t1
	WHERE t1.service_id = 'вот2';
	UPDATE t1
	SET kod_counter = 1
	FROM #tc AS t1
	WHERE t1.service_id = 'вотв';

	-- ====================== 17.02.2022 возврат гГВС по гвод
	UPDATE t1
	SET metod_old=t2.metod_old
	FROM #tc AS t1
	JOIN #tc AS t2 ON t1.fin_id = t2.fin_id
	WHERE t1.service_id in ('гГВС','элХвсГвс','тепл')
	AND t2.service_id='гвод'
	

	--*****************************************************************
	-- блокируем расчёт по поставщику кому не начисляем
	UPDATE t1
	SET blocked_value =
					   CASE
						   WHEN (sb.id IS NOT NULL AND sb.paym_blocked = 0 AND sb.add_blocked = 0) THEN 0
						   WHEN (sb.id IS NOT NULL AND (sb.paym_blocked = 1 OR sb.add_blocked = 1)) THEN 1
						   WHEN (ST.id IS NOT NULL AND ST.paym_blocked = 0 AND ST.add_blocked = 0) THEN 0
						   WHEN (ST.id IS NOT NULL AND (ST.paym_blocked = 1 OR ST.add_blocked = 1)) THEN 1
						   ELSE 0
					   END
	--IF @debug=1 SELECT 'SUPPLIERS_TYPES',*
	FROM #tc AS t1
		JOIN dbo.Consmodes_list cl ON 
			t1.service_id = cl.service_id
			AND t1.sup_id = cl.sup_id
		JOIN dbo.Suppliers s ON 
			cl.source_id = s.id
			AND cl.service_id = s.service_id
		LEFT JOIN dbo.Suppliers_types AS ST ON 
			s.sup_id = ST.sup_id
			AND (t1.service_id = ST.service_id OR ST.service_id = '')
			AND ST.tip_id = @tip_id
		LEFT JOIN dbo.Suppliers_build sb ON 
			s.sup_id = sb.sup_id
			AND (t1.service_id = sb.service_id OR sb.service_id = '')
			AND sb.build_id = @build_id
	WHERE cl.occ = @occ

	--IF @debug = 1 SELECT 4, * FROM #tc t ORDER BY fin_id DESC

	-- блокируем расчёт по типу фонда кому не начисляем
	UPDATE t1
	SET blocked_value = ST.no_vozvrat
	--IF @debug=1 SELECT *
	FROM #tc AS t1
		JOIN dbo.Services_type_counters AS ST ON 
			t1.service_id = ST.service_id
	WHERE ST.tip_id = @tip_id
	--AND ST.no_vozvrat = 1;

	--IF @debug = 1 SELECT 5, * FROM #tc t ORDER BY fin_id DESC

	-- блокируем расчёт по дому кому не начисляем
	UPDATE t1
	SET blocked_value = ST.no_vozvrat
	--IF @debug=1 SELECT *
	FROM #tc AS t1
		JOIN dbo.Services_build AS ST ON 
			t1.service_id = ST.service_id
	WHERE ST.build_id = @build_id
	--AND ST.no_vozvrat = 1;

	--IF @debug = 1 SELECT 6, * FROM #tc t ORDER BY fin_id DESC

	-- блокируем расчёт по лиц.счёту где не надо возвращать или период поверки истёк
	UPDATE t1
	SET blocked_value = 1, KolmesForPeriodCheck=cla.KolmesForPeriodCheck
	--IF @debug=1 SELECT *
	FROM #tc AS t1
		JOIN #vca AS cla ON
			-- t1.service_id = cla.service_id
			t1.serv2 = cla.service_id
			AND t1.fin_id = cla.fin_id
	WHERE cla.occ = @occ
		--AND cla.fin_id = @fin_current
		AND (COALESCE(cla.no_vozvrat, 0) = 1 OR (cla.KolmesForPeriodCheck < 0    --cla.KolmesForPeriodCheck <= 0   25.06.2020 убрал = 
		AND t1.PeriodCheck IS NOT NULL AND @ras_no_counter_poverka = 1));

	
	IF (dbo.strpos('KR1', @DB_NAME) > 0)
	BEGIN
		-- добавил 07.12.22
		UPDATE t1
		SET blocked_value = 1
		--IF @debug=1 SELECT *
		FROM #tc AS t1
		where t1.PeriodCheck<@end_data_fin_current  --CURRENT_TIMESTAMP

		DELETE FROM #tc WHERE fin_id<248 AND service_id in ('отоп') -- добавил 26.12.22
	END

	UPDATE t1
	SET value = 0
	  , kol = 0
	FROM #tc AS t1
	WHERE t1.blocked_value = 1;

	--добавим служебные услуги по Водоотведению
	DECLARE @t_votv TABLE (
		  serv1 VARCHAR(10)
		, serv2 VARCHAR(10)
	)
	INSERT INTO @t_votv (serv1
					   , serv2)
	VALUES('вотвГВС'
		 , 'гвод')
		, ('вотвХВС'
		 , 'хвод');

	INSERT INTO #tc (fin_id
				   , service_id
				   , serv2
				   , metod_old
				   , sup_id
				   , kol
				   , tarif)
	SELECT DISTINCT t1.fin_id
				  , tv.serv1
				  , tv.serv1 
				  , t1.metod_old
				  , t1.sup_id
				  , t1.kol
				  , t2.tarif
	FROM #tc AS t1
		JOIN @t_votv tv ON 
			tv.serv2 = t1.serv2
		JOIN #tc AS t2 ON 
			t1.fin_id = t2.fin_id
			AND t2.serv2 = 'вотв'
	WHERE t1.serv2 IN ('гвод', 'хвод')
		AND t1.kol <> 0
		--AND t1.tarif > 0  -- тарифов может не быть
		--AND t2.tarif > 0

	--*****************************************************************

	--IF @debug = 1	SELECT '#tc 1' AS tab, * FROM #tc ORDER BY fin_id DESC;

	DECLARE @t TABLE (
		  occ INT
		, service_id VARCHAR(10)
		, tarif DECIMAL(10, 4) DEFAULT 0
		, kolmes SMALLINT DEFAULT 0
		, kol_counter DECIMAL(9, 2) DEFAULT NULL
		, kol_add DECIMAL(9, 4) DEFAULT 0
		, sum_add DECIMAL(9, 2) DEFAULT 0
		, kod_counter INT DEFAULT 0
		, serv2 VARCHAR(10) DEFAULT NULL
		, unit_id VARCHAR(10) DEFAULT NULL
		, sup_id INT DEFAULT 0
		, sub12 DECIMAL(9, 2) DEFAULT 0
		, first_mes SMALLINT DEFAULT 0
		, last_mes SMALLINT DEFAULT 0
		, fin_id_str VARCHAR(400) DEFAULT ''
	);

	-- находим текущие показания по счетчику
	INSERT INTO @t (occ
				  , service_id
				  , tarif
				  , kol_counter
				  , kod_counter
				  , serv2
				  , unit_id
				  , sup_id)
	SELECT p1.occ
		 , p1.service_id
		 , p1.tarif
		 , CASE
               WHEN p1.service_id IN ('вотв', 'вот2') THEN SUM(COALESCE(p1.kol_norma, 0))
               ELSE SUM(COALESCE(cp2.kol, 0))
        END
		 , tc.kod_counter
		 , tc.serv2
		 , p1.unit_id
		 , p1.sup_id
	FROM dbo.View_paym AS p1 
		LEFT JOIN dbo.[Counter_paym2] AS cp2 ON 
			p1.occ = cp2.occ
			AND p1.fin_id = cp2.fin_id
			AND p1.service_id = cp2.service_id
		LEFT JOIN #tc AS tc ON 
			p1.fin_id = tc.fin_id
			AND p1.service_id = tc.service_id
	WHERE p1.fin_id = @fin_current
		AND p1.occ = @occ
		--AND p1.metod IN (3, 4)
		AND (
		(tc.is_counter = 2 AND tc.metod_old IN (3, 4)) OR (tc.is_counter = 0 AND tc.service_id IN (N'вотв', N'вот2', N'тепл', N'гГВС',N'элХвсГвс'))	   -- добавил услугу тепл 05.10.2017
		)
	GROUP BY p1.occ
		   , p1.service_id
		   , p1.sup_id
		   , p1.tarif
		   , kod_counter
		   , tc.serv2
		   , p1.unit_id;

	-- ======================================15/06/15
	IF NOT EXISTS (
			SELECT 1
			FROM @t
			WHERE service_id = 'вот2'
		)
		INSERT INTO @t (occ
					  , service_id
					  , tarif
					  , kol_counter
					  , kod_counter
					  , serv2
					  , unit_id)
		SELECT occ
			 , 'вот2'
			 , tarif
			 , 0
			 , 2
			 , 'вотв'
			 , unit_id
		FROM @t
		WHERE service_id = 'вотв';
	-- ======================================

	UPDATE t
	SET kol_counter = (
		SELECT SUM(kol_counter)
		FROM @t AS t2
		WHERE service_id IN ('хвод', 'хвс2', 'гвод', 'гвс2')
	)
	FROM @t AS t
	WHERE service_id IN ('вотв', 'вот2');

	DELETE t
	FROM @t AS t
	WHERE service_id IN ('тепл', 'гГВС', 'элХвсГвс')
		AND NOT EXISTS (
			SELECT *
			FROM @t AS t2
			WHERE service_id IN ('гвод', 'гвс2')
		)

	--IF @debug = 1	SELECT '@t' AS tab, * FROM @t;

	-- Удаляем водоотведение если нет ХВС или ГВС   21.11.2011
	IF EXISTS (
			SELECT 1
			FROM @t
			WHERE serv2 = 'вотв'
		)
		AND NOT EXISTS (
			SELECT 1
			FROM @t
			WHERE serv2 IN ('хвод', 'гвод')
		)
		DELETE FROM @t
		WHERE service_id IN ('вотв', 'вот2', 'вотвГВС', 'вотвХВС');

	DELETE FROM @t
	WHERE serv2 IS NULL

	IF @debug = 1
		SELECT '@t 2' AS tbl, * FROM @t;

	-- находим кол-во месяцев по норме от текущего	
	DECLARE @fin_id1 SMALLINT
		  , @fin_id_tmp SMALLINT
		  , @kol DECIMAL(12, 6)
		  , @kod_counter INT
		  , @metod_old SMALLINT
		  , @unit_id VARCHAR(10);

	-- ******* 19.10.2015
	SELECT TOP (1) @fin_id_tmp = fin_id
	FROM #tc
	WHERE service_id IN ('вотв', 'вот2')
		AND fin_id < @fin_current
		AND metod_old = 3
	ORDER BY fin_id DESC;

	SET @fin_id_tmp = COALESCE(@fin_id_tmp, 0)

	DELETE FROM #tc
	WHERE service_id IN ('вотв', 'вот2')
		AND fin_id < COALESCE(@fin_id_tmp, @fin_current - 6);

	IF @debug = 1
		PRINT N'Минимальный период по водоотведению: ' + STR(@fin_id_tmp);
	-- ******* 


	SELECT @last_mes = @fin_current - 1;

	--
	UPDATE t
	SET sub12 = COALESCE(ap.value, 0)
	FROM #tc AS t
		JOIN (
			SELECT va.fin_id
				 , va.service_id
				 , va.sup_id
				 , SUM(va.value) AS value
			FROM dbo.View_added_lite va
			WHERE va.occ = @occ
				AND va.add_type = 15
			GROUP BY va.fin_id
				   , va.service_id
				   , va.sup_id
		) AS ap ON t.fin_id = ap.fin_id
			AND t.service_id = ap.service_id
			AND t.sup_id = ap.sup_id

	DECLARE curs_1 CURSOR LOCAL FOR
		SELECT DISTINCT service_id
					  , sup_id
		FROM @t;
	--WHERE service_id NOT IN ('вотв', 'вот2')   -- 09/12/14 закомментировал
	OPEN curs_1;
	FETCH NEXT FROM curs_1 INTO @service_id1, @sup_id;

	WHILE (@@fetch_status = 0)
	BEGIN
		SET @fin_id_tmp = @fin_current;
		DECLARE curs_2 CURSOR LOCAL FOR
			SELECT kod_counter
				 , fin_id
				 , metod_old
				 , kol
			FROM #tc
			WHERE service_id = @service_id1
				AND sup_id = @sup_id
				AND fin_id < @fin_current
			--AND kol <> 0  -- 22/05/2014  -- 21/10/2014 снова закомментировал бывает по норме 0
			ORDER BY fin_id DESC;

		OPEN curs_2;
		FETCH NEXT FROM curs_2 INTO @kod_counter, @fin_id1, @metod_old, @kol;

		WHILE (@@fetch_status = 0)
		BEGIN
			IF @debug = 1
				PRINT CONCAT(@service_id1,' ',@fin_id1,' ',@fin_id_tmp,' ',COALESCE(@metod_old, 0),' кол:',@kol,' sup_id:', @sup_id)

			--IF @service_id1 IN ('вотв','вот2') AND @kol=0
			--	SET @metod_old = 3			

			--IF @debug = 1 SELECT @service_id1,fin_id1=@fin_id1,kod_counter=@kod_counter,metod_old=@metod_old

			IF @metod_old = 3
				OR (@fin_id_tmp - @fin_id1) > 1 --OR @metod_old IS NULL
			BEGIN
				UPDATE #tc
				SET metod_old = NULL
				WHERE fin_id < @fin_id1
					AND service_id = @service_id1
					AND kod_counter = @kod_counter
					AND sup_id = @sup_id;
				BREAK;
			END;

			UPDATE tc
			SET metod_old = 5
			FROM #tc AS tc
			WHERE tc.fin_id = @fin_id1
				AND tc.service_id = @service_id1
				AND tc.sup_id = @sup_id
				AND (tc.is_counter <> 1)
				AND tc.kol <> 0
				AND COALESCE(tc.metod_old, 1) IN (0, 1, 2)
				AND ((tc.kod_counter = @kod_counter) OR (tc.kod_counter IS NULL AND tc.service_id IN (N'тепл', N'гГВС', N'элХвсГвс')));

			--IF @debug = 1
			--	PRINT @fin_id1
			SET @fin_id_tmp = @fin_id1;
			FETCH NEXT FROM curs_2 INTO @kod_counter, @fin_id1, @metod_old, @kol;
		END;

		CLOSE curs_2;
		DEALLOCATE curs_2;

		FETCH NEXT FROM curs_1 INTO @service_id1, @sup_id;
	END;

	CLOSE curs_1;
	DEALLOCATE curs_1;

	IF @debug = 1
		SELECT '1 #tc' AS tbl, * FROM #tc ORDER BY fin_id DESC;

	UPDATE tc
	SET metod_old = 5
	FROM #tc AS tc
	WHERE tc.service_id IN ('вотв', 'вот2', 'вотвГВС', 'вотвХВС')
		AND tc.is_counter = 0
		AND metod_old <> 3    -- 09/12/14
		AND tc.kol <> 0
		AND EXISTS (
			SELECT 1
			FROM #tc AS tc2
			WHERE tc2.fin_id = tc.fin_id
				AND tc2.service_id IN ('хвод', 'хвс2', 'гвод', 'гвс2')
				AND tc2.sup_id = tc.sup_id
				AND tc2.metod_old = 5
		);

	-- Убираем водоотведение для расчёта где не было 'хвод', 'хвс2', 'гвод', 'гвс2'
	UPDATE tc
	SET metod_old = NULL
	FROM #tc AS tc
	WHERE tc.service_id IN ('вотв', 'вот2', 'вотвГВС', 'вотвХВС')
		AND tc.is_counter = 0
		AND metod_old = 5
		AND tc.kol <> 0
		AND NOT EXISTS (
			SELECT 1
			FROM #tc AS tc2
			WHERE tc2.fin_id = tc.fin_id
				AND tc2.sup_id = tc.sup_id
				AND tc2.service_id IN ('хвод', 'хвс2', 'гвод', 'гвс2')
				AND tc2.metod_old = 5
		);

	-- Убираем Тепловая энергия для расчёта где не было 'гвод', 'гвс2'
	UPDATE tc
	SET metod_old = NULL
	FROM #tc AS tc
	WHERE tc.service_id IN ('тепл', 'гГВС', 'элХвсГвс')
		--AND tc.is_counter = 0   -- закомментировал 15.10.18
		AND metod_old = 5
		AND tc.kol <> 0
		AND NOT EXISTS (
			SELECT 1
			FROM #tc AS tc2
			WHERE tc2.fin_id = tc.fin_id
				AND tc2.service_id IN ('гвод', 'гвс2')
				AND tc2.sup_id = tc.sup_id
				AND tc2.metod_old = 5
		);


	--***********************************************

	IF @debug = 1
		SELECT '2 #tc' AS tbl, * FROM #tc ORDER BY fin_id DESC;

	UPDATE t
		SET first_mes = t_fin.first_mes
	  , last_mes = t_fin.last_mes
	  , fin_id_str = STUFF((
			SELECT CONCAT(',' , LTRIM(STR(fin_id)))
			FROM #tc AS tc
			WHERE tc.service_id = t.service_id
				AND tc.sup_id = t.sup_id
				AND tc.metod_old = 5
				AND tc.kol <> 0
			ORDER BY fin_id
			FOR XML PATH ('')
		), 1, 1, '')
	FROM @t AS t
	OUTER APPLY (  -- 03.04.2023
			SELECT 
				MIN(fin_id) AS first_mes, MAX(fin_id) AS last_mes
			FROM #tc AS tc
			WHERE tc.service_id = t.service_id
				AND tc.sup_id = t.sup_id
				AND tc.metod_old = 5 
				AND tc.kol <> 0
	) as t_fin

	--IF @debug=1
	--SELECT *
	--		FROM @t AS t
	--		ORDER BY first_mes DESC

	SELECT TOP (1) @first_mes = first_mes
	FROM @t AS t
	WHERE first_mes IS NOT NULL -- 22/05/2014
	ORDER BY first_mes; --DESC -- 22/05/2014

	DELETE FROM #tc	WHERE fin_id < @first_mes;

	--IF @debug=1
	--SELECT
	--		*
	--	FROM #tc AS tc
	--	WHERE metod_old = 5

	UPDATE t
	SET kol_add = t2.kol
	  , kolmes = t2.kolmes
	  , sum_add = t2.value
	  , sub12 = sub12_value
	FROM @t AS t
		JOIN (
			SELECT tc.service_id
				 , tc.sup_id
				   --,SUM(tc.value + tc.sub12) AS value
				 , SUM(tc.value) AS value
				 , SUM(tc.sub12) AS sub12_value
				 , COUNT(*) AS kolmes
				 , SUM(kol) AS kol
			FROM #tc AS tc
			WHERE tc.metod_old = 5
				--AND tc.value <> 0 -- 03.04.2021
				AND tc.kol <> 0
			GROUP BY tc.service_id
				   , tc.sup_id
		) AS t2 ON t2.service_id = t.service_id
			AND t2.sup_id = t.sup_id
	;

	-- добавим в @t вотвХВС и вотвГВС
	INSERT INTO @t (occ
				  , service_id
				  , tarif
				  , kolmes
				  , kol_counter
				  , kol_add
				  , sum_add
				  , kod_counter
				  , serv2
				  , unit_id
				  , sup_id
				  , sub12
				  , first_mes
				  , last_mes
				  , fin_id_str)
	SELECT @occ
		 , t2.serv2
		 , t2.tarif
		 , t.kolmes
		 , t.kol_counter
		 , t.kol_add
		 , sum_add = t2.sum_add
		 , kod_counter = 0
		 , t2.serv2
		 , t.unit_id
		 , t.sup_id
		 , sub12 = 0
		 , t.first_mes
		 , t.last_mes
		 , t.fin_id_str
	FROM @t AS t
		CROSS APPLY (
			SELECT MAX(tc2.serv2) AS serv2
				 , MAX(tc2.tarif) AS tarif
				 , SUM(tc2.kol) AS kol
				 , SUM(tc2.kol * tc2.tarif) AS sum_add
			FROM #tc AS tc
				JOIN @t_votv tv ON 
					tc.serv2 = tv.serv2
				JOIN #tc AS tc2 ON 
					tc.fin_id = tc2.fin_id
					AND tc2.service_id = tv.serv1
			WHERE tc.serv2 = t.serv2
				AND tc.metod_old = 5
				AND tc.kol <> 0
				AND tc2.tarif > 0
		) AS t2
	WHERE t.serv2 IN ('хвод', 'гвод')
		AND t.kolmes > 0

	IF @debug = 1
	BEGIN
		SELECT MAX(tc2.serv2) AS serv2
			 , MAX(tc2.tarif) AS tarif
			 , SUM(tc2.kol) AS kol
			 , SUM(tc2.kol * tc2.tarif) AS sum_add
		FROM #tc AS tc
			JOIN @t_votv tv ON 
				tc.serv2 = tv.serv2
			JOIN #tc AS tc2 ON 
				tc.fin_id = tc2.fin_id
				AND tc2.service_id = tv.serv1
		WHERE tc.serv2 IN ('хвод', 'гвод')
			AND tc.metod_old = 5
			AND tc.kol <> 0
			AND tc2.tarif > 0

		SELECT N = 3
			 , '@t' AS TABL
			 , *
		FROM @t;
	END;

	--RETURN

	--==========================================================================
	-- удалить дубликаты
	;
	WITH cte AS
	(
		SELECT RN = ROW_NUMBER() OVER (PARTITION BY service_id, kol_add, sum_add, kolmes, kol_counter, tarif, unit_id, sup_id, sub12, fin_id_str
			ORDER BY service_id)
		FROM @t
		WHERE sum_add <> 0
	)
	DELETE FROM cte
	WHERE RN > 1;
	--=====================================
	
	DECLARE @sum_kol_serv DECIMAL(12, 4) -- совокупный объём по ГВС и ХВС		        
		  , @sum_kol_votv DECIMAL(12, 4) -- объем по водоотведению
		  , @diff_kol_votv DECIMAL(12, 4) -- разница между ними

	SELECT @sum_kol_serv = COALESCE(SUM(COALESCE(kol_add, 0)), 0)
	FROM @t
	WHERE service_id IN ('хвод', 'хвс2', 'гвод', 'гвс2')
		--AND sum_add <> 0 -- 23.08.22

	SELECT @sum_kol_votv = COALESCE(SUM(COALESCE(kol_add, 0)), 0)
	FROM @t
	WHERE service_id IN ('вотв', 'вот2')
		--AND sum_add <> 0 -- 23.08.22

	SELECT @diff_kol_votv = @sum_kol_votv - @sum_kol_serv

	IF @debug = 1
	BEGIN
		PRINT CONCAT(N'Объём по услугам: ',@sum_kol_serv,', водоотв: ',@sum_kol_votv,', разница: ', @diff_kol_votv)
			
		SELECT N = 4
			 , '@t' AS tbl
			 , t.*
			 , @sum_kol_serv AS sum_kol_serv
		FROM @t AS t
		WHERE service_id IN ('вотв', 'вот2');
	END;

	--==========================================================================
	IF @debug = 1
	BEGIN
		PRINT N'расчёт вотв по норме: ' + CASE
                                              WHEN @counter_votv_norma = 1 THEN N'Да'
                                              ELSE N'Нет'
            END;
		SELECT @counter_votv_norma AS counter_votv_norma, @is_vozvrat_votv_sum AS is_vozvrat_votv_sum, @diff_kol_votv AS diff_kol_votv
	END
	
	IF @counter_votv_norma = 0 OR @is_vozvrat_votv_sum = 1
	BEGIN

		IF @diff_kol_votv <> 0
		BEGIN
			IF @debug = 1
				PRINT N'=== корректируем объём водоотведения ==='

			UPDATE t
			SET kol_add = t2.kol_add
			  , sum_add = t2.sum_add
			  , kolmes = t2.kolmes
			  , first_mes = t2.first_mes
			  , last_mes = t2.last_mes
			  , fin_id_str = t2.fin_id_str
			FROM @t AS t
				CROSS APPLY (
					SELECT SUM(t2.kol_add) AS kol_add
						 , SUM(t2.sum_add) AS sum_add
						 , MAX(t2.kolmes) AS kolmes
						 , MAX(t2.first_mes) AS first_mes
						 , MAX(t2.last_mes) AS last_mes
						 , MAX(t2.fin_id_str) AS fin_id_str
					FROM @t t2
					WHERE t2.serv2 IN ('вотвГВС', 'вотвХВС')
				) AS t2
			WHERE t.service_id in ('вотв','вот2')
				AND t.kol_add <> @sum_kol_serv

			/*
			SELECT TOP (1) @tarif = tc.tarif -- тариф последнего возвращаемого периода
			FROM #tc tc
				JOIN @t AS t ON tc.service_id = t.service_id
					AND tc.fin_id = t.last_mes
			WHERE tc.service_id = 'вотв'
			ORDER BY tc.fin_id DESC

			IF @debug = 1
				PRINT 'тариф для корректировки: ' + STR(@tarif, 9, 4)
			IF @debug = 1
				SELECT 'до коррекитр. вотв'
					 , *
				FROM @t AS t
				WHERE service_id = 'вотв'

			UPDATE t
			SET kol_add = @sum_kol_serv
				--, sum_add = @sum_kol_votv * t.tarif
				-- добавляем только разницу по текущему тарифу (обычно это ошибки округления или без одной услуги)
			  , sum_add = sum_add - (@diff_kol_votv * COALESCE(@tarif, t.tarif))
			FROM @t AS t
			WHERE service_id = 'вотв'
				AND kol_add > @sum_kol_serv;
			*/

			IF @debug = 1
				SELECT N'после коррекитр. вотв' AS tbl
					 , *
				FROM @t AS t
				WHERE service_id = N'вотв'
		END
		ELSE
		IF @debug = 1
			PRINT N'=== корректировка объёма водоотведения не требуется ==='

		--IF (dbo.strpos('KR1', @DB_NAME) > 0)
		--	UPDATE t
		--	SET kol_add = @sum_kol_serv
		--	--,sum_add = @sum_kol_add * t.tarif  -- здесь тариф за текущий месяц, а надо с учётом прошлых  23.12.2019
		--	FROM @t AS t
		--	WHERE service_id = N'вотв'
		--		AND kol_add > @sum_kol_serv;
	END;


	UPDATE @t
	SET kol_add = -1 * kol_add
	  , sum_add = -1 * sum_add;

	-- Удаляем водоотведение если нет начислений по ХВС или ГВС 2.06.2012
	DELETE FROM @t
	WHERE service_id='вотв'
	AND NOT EXISTS (
			SELECT 1
			FROM @t
			WHERE service_id IN ('хвод', 'гвод') )
	
	DELETE FROM @t
	WHERE service_id=N'вот2'
	AND NOT EXISTS (
			SELECT 1
			FROM @t
			WHERE service_id IN ('хвс2', 'гвс2') 
			AND (kol_add<>0 OR sum_add<>0) --21.04.23
			)

			
	UPDATE pl
	SET sum_add = 0, kol_add=0
	FROM @t AS pl
	WHERE pl.service_id = 'вотв'
	AND EXISTS (
		SELECT 1
		FROM @t AS t
		WHERE t.service_id = 'вот2'
			AND t.sum_add <> 0
			)

	--IF EXISTS (
	--		SELECT 1
	--		FROM @t
	--		WHERE service_id IN (N'вотв', N'вот2')
	--	)
	--	AND NOT EXISTS (
	--		SELECT 1
	--		FROM @t
	--		WHERE service_id IN (N'хвод', N'хвс2', N'гвод', N'гвс2')
	--			--AND sum_add <> 0  -- 23.08.22
	--	)
	--	DELETE FROM @t
	--	WHERE service_id IN (N'вотв', N'вот2');


	IF @debug = 1
	BEGIN
		SELECT @first_mes AS first_mes
		SELECT '@t' AS tbl, * FROM @t;
	END;
	-- удаляем с нулями если уже были
	--delete ap from dbo.ADDED_PAYMENTS ap JOIN @t as t ON ap.occ=t.occ and ap.service_id=t.service_id
	--where ap.occ=@occ and ap.add_type=12 and ap.doc_no=@doc_no and t.sum_add=0

	DELETE dbo.Added_Payments 
	WHERE occ = @occ
		AND add_type = 12
		AND doc_no = @doc_no
		AND fin_id = @fin_current;

	DELETE dbo.Added_Payments 
	WHERE occ = @occ
		AND add_type = 15
		AND doc_no = @doc_no_sub12
		AND fin_id = @fin_current;

	DELETE dbo.Paym_occ_build 
	WHERE fin_id = @fin_current
		AND occ = @occ
		--AND service_id = @service_id1
		AND procedura = 'ka_counter_norma3';

	UPDATE @t
	SET sup_id = dbo.Fun_GetSup_idOcc(@occ, service_id)
	WHERE sup_id IS NULL

	-- добавляем разовые
	DECLARE @sub12 DECIMAL(9, 2) = 0
	DECLARE curs_1 CURSOR LOCAL FOR
		SELECT DISTINCT service_id
					  , kol_add
					  , sum_add
					  , kolmes
					  , first_mes
					  , kol_counter
					  , tarif
					  , unit_id
					  , sup_id
					  , last_mes
					  , sub12
		FROM @t AS t
			JOIN dbo.Services s ON t.service_id = s.id
		WHERE kol_add <> 0
			OR sum_add <> 0   -- 03.04.2021
	OPEN curs_1;
	FETCH NEXT FROM curs_1 INTO @service_id1, @kol_add, @sum_add, @kolmes, @first_mes, @kol_counter, @tarif, @unit_id, @sup_id, @last_mes, @sub12;

	WHILE (@@fetch_status = 0)
	BEGIN
		SET @comments = CONCAT(N'кол.мес: ', @kolmes,',кол-во: ', @kol_add);

		IF @debug = 1
			PRINT CONCAT(N'добавляем разовые по ',@occ,' service_id: ',@service_id1,', sup_id: ',@sup_id,', сумма: ',@sum_add,', кол.: ', @kol_add)

		SELECT @str_mes = SUBSTRING(CONVERT(VARCHAR(8), start_date, 3), 4, 5)
		FROM dbo.Global_values 
		WHERE fin_id = @first_mes;

		IF @kolmes > 1
		BEGIN
			SELECT @str_mes = @str_mes + '-' + SUBSTRING(CONVERT(VARCHAR(8), start_date, 3), 4, 5)
			FROM dbo.Global_values 
			WHERE fin_id = @last_mes
		END

		SET @doc1 = N'Коррект.по ИПУ за ' + @str_mes;

		IF @debug = 1
			PRINT @doc1;

		-- ************************************************************************************
		--exec dbo.ka_add_added_3 @occ1=@occ,@service_id1=@service_id1,@add_type1=12,@value1=@sum_add, 
		--	@doc1=@doc1,@comments=@comments, @kol=@kol_add, @doc_no1=@doc_no

		-- Отмечаем услуги по которым расчёт по типу фонда или по дому заблокирован 21.12.21
		IF EXISTS (
				SELECT 1
				FROM dbo.Services_build AS Sb 
				WHERE Sb.service_id = @service_id1
					AND Sb.build_id = @build_id
					AND sb.paym_blocked=1
			)
			OR EXISTS (
				SELECT 1
				FROM dbo.Services_types AS ST 
				WHERE ST.service_id = @service_id1
					AND ST.tip_id = @tip_id
					AND st.paym_blocked=1
			)
			SET @sum_add = 0


		BEGIN TRAN;

		IF @is_counter_add_balance = 0
		BEGIN

			-- Добавить в таблицу added_payments
			INSERT INTO dbo.Added_Payments (occ
										  , service_id
										  , sup_id
										  , add_type
										  , doc
										  , value
										  , doc_no
										  , doc_date
										  , user_edit
										  , dsc_owner_id
										  , comments
										  , kol
										  , fin_id)
			VALUES(@occ
				 , @service_id1
				 , @sup_id
				 , 12
				 , @doc1
				 , @sum_add
				 , @doc_no
				 , NULL
				 , NULL
				 , NULL
				 , @comments
				 , @kol_add
				 , @fin_current);

			IF @sub12 <> 0
				INSERT INTO dbo.Added_Payments (occ
											  , service_id
											  , sup_id
											  , add_type
											  , doc
											  , value
											  , doc_no
											  , doc_date
											  , user_edit
											  , dsc_owner_id
											  , comments
											  , kol
											  , fin_id)
				VALUES(@occ
					 , @service_id1
					 , @sup_id
					 , 15
					 , N'Возврат Субсидия 12% РСО'
					 , @sub12 * -1
					 , @doc_no_sub12
					 , NULL
					 , NULL
					 , NULL
					 , @str_mes
					 , NULL
					 , @fin_current);

		END;
		ELSE
		BEGIN
			IF @debug = 1
				SELECT N'пишем в таблицу PAYM_OCC_BUILD'

			--PRINT @service_id1
			--PRINT @kol_add
			--PRINT @kol_counter
			--PRINT @unit_id

			SELECT @kol = @kol_counter + @kol_add;
			IF @kol < 0
				SELECT @kol_add = @kol
					 , @kol = 0;
			ELSE
				SELECT @kol_add = 0;
			SELECT @sum_add = @tarif * @kol;

			INSERT INTO dbo.Paym_occ_build (fin_id
										  , occ
										  , service_id
										  , kol
										  , tarif
										  , value
										  , comments
										  , unit_id
										  , procedura
										  , kol_add
										  , sup_id)
			VALUES(@fin_current
				 , @occ
				 , @service_id1
				 , @kol
				 , @tarif
				 , @sum_add
				 , @comments
				 , @unit_id
				 , 'ka_counter_norma3'
				 , @kol_add
				 , @sup_id);

			DELETE FROM dbo.Paym_occ_balance
			WHERE fin_id = @fin_current
				AND occ = @occ
				AND service_id = @service_id1
				AND sup_id = @sup_id;

			IF @kol_add <> 0
				INSERT INTO Paym_occ_balance (fin_id
											, occ
											, service_id
											, sup_id
											, kol_balance)
				VALUES(@fin_current
					 , @occ
					 , @service_id1
					 , @sup_id
					 , @kol_add);

		END;

		COMMIT TRAN;

		-- ************************************************************************************
		--end

		FETCH NEXT FROM curs_1 INTO @service_id1, @kol_add, @sum_add, @kolmes, @first_mes, @kol_counter, @tarif, @unit_id, @sup_id, @last_mes, @sub12;
	END;

	CLOSE curs_1;
	DEALLOCATE curs_1;

	-- Изменить значения в таблице paym_list
	UPDATE pl 
	SET added = COALESCE((
		SELECT SUM(value)
		FROM dbo.Added_Payments ap 
		WHERE ap.occ = @occ
			AND ap.service_id = pl.service_id
			AND ap.sup_id = pl.sup_id
			AND ap.fin_id = @fin_current
	), 0)
	FROM dbo.Paym_list AS pl
	WHERE pl.occ = @occ
		AND pl.fin_id = @fin_current;

	IF @debug = 1
		SELECT *
		FROM @t;


END;
go

