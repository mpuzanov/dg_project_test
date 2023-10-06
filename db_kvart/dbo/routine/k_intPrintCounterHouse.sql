-- =============================================
-- Author:		Пузанов Михаил
-- Create date: 
-- Description:	для квитанции (справочная таблица по дому)
-- =============================================
CREATE         PROCEDURE [dbo].[k_intPrintCounterHouse]
(
	  @occ1 INT = NULL
	, @fin_id SMALLINT = NULL
	, @debug BIT = 0
	, @time SMALLINT = 0
	, @build_id INT = NULL
)
AS
/*
EXEC k_intPrintCounterHouse @occ1=910003291, @fin_id=243, @debug=1, @time=0
EXEC k_intPrintCounterHouse @build_id=6795, @fin_id=232, @debug=1, @time=0

EXEC k_intPrintCounterHouse @occ1=910001486, @fin_id=244, @debug=0, 0
EXEC k_intPrintCounterHouse @occ1=322215, @fin_id=146, @debug=1, 0
EXEC k_intPrintCounterHouse @occ1=291721, @fin_id=162, @debug=1, 0

EXEC k_intPrintCounterHouse @occ1=NULL, @fin_id=245, 1, 0,6830

*/
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #t2 (
		  tip_id SMALLINT
		, build_id INT
		, service_id VARCHAR(10) COLLATE database_default
		, short_name VARCHAR(50) COLLATE database_default
		, unit_id VARCHAR(10) COLLATE database_default
		, short_id VARCHAR(10) COLLATE database_default DEFAULT NULL
		, is_boiler BIT DEFAULT 0
		, V_start DECIMAL(15, 6) DEFAULT 0
		, V1 DECIMAL(15, 6) DEFAULT 0
		, V_arenda DECIMAL(15, 6) DEFAULT 0
		, V_norma DECIMAL(15, 6) DEFAULT 0
		, V_add DECIMAL(15, 6) DEFAULT 0
		, V_load_odn DECIMAL(15, 6) DEFAULT 0
		, V2 DECIMAL(15, 6) DEFAULT 0
		, V3 DECIMAL(15, 6) DEFAULT 0
		, V_economy DECIMAL(15, 6) DEFAULT 0		
		, block_paym_V BIT DEFAULT 0
		, v_itog DECIMAL(15, 6) DEFAULT 0		
	)

	IF @occ1 IS NULL
		AND @fin_id IS NULL
		AND @build_id IS NULL
	BEGIN
		SELECT *
		FROM #t2
		RETURN
	END

	DECLARE @is_ValueBuildMinus BIT
		  , @DB_NAME VARCHAR(20) = UPPER(DB_NAME())
		  , @tip_id SMALLINT
		  , @info_account_no BIT
		  , @soi_boiler_only_hvs BIT

	IF @occ1 IS NOT NULL
		SELECT @occ1 = dbo.Fun_GetFalseOccIn(@occ1)

	--SELECT
	--	@build_id = bldn_id
	--	,@tip_id = voa.tip_id
	--	,@is_ValueBuildMinus = COALESCE(OT.is_ValueBuildMinus, 0)
	--FROM dbo.View_OCC_ALL_LITE AS voa
	--JOIN dbo.OCCUPATION_TYPES OT 
	--	ON voa.tip_id = OT.id
	--WHERE voa.fin_id = @fin_id
	--AND (voa.occ = @occ1 OR @occ1 IS NULL)
	--AND (voa.build_id = @build_id OR @build_id IS NULL)

	SELECT @build_id = f.bldn_id
		 , @tip_id = o.tip_id
		 , @is_ValueBuildMinus = OT.is_ValueBuildMinus
		 , @info_account_no = COALESCE(b.info_account_no, 0)
		 , @soi_boiler_only_hvs = ot.soi_boiler_only_hvs
	FROM dbo.Occupations AS o 
		JOIN dbo.Flats f ON o.flat_id = f.id
		JOIN dbo.Occupation_Types OT  ON o.tip_id = OT.id
		JOIN dbo.Buildings b ON f.bldn_id = b.id
	WHERE (@occ1 IS NULL OR o.Occ = @occ1)
		AND (@build_id IS NULL OR f.bldn_id = @build_id)
	OPTION (RECOMPILE)

	IF @tip_id IS NULL
	BEGIN
		RAISERROR('Лицевой или дом не найден', 16, 1)
		RETURN -1
	END

	IF @debug = 1
		PRINT 'Код дома: ' + STR(@build_id) + ' is_ValueBuildMinus:' + STR(@is_ValueBuildMinus) + ' @info_account_no: ' + STR(@info_account_no)

	IF @fin_id IS NULL
		SELECT @fin_id = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, @occ1)

	IF EXISTS (
			SELECT 1
			FROM dbo.CounterHouse 
			WHERE fin_id = @fin_id
				AND tip_id = @tip_id
				AND build_id = @build_id				
				AND (DateCreate >= DATEADD(MINUTE, -@time, current_timestamp)) -- OR manual_edit = 1)
		)
	BEGIN
		IF @debug = 1
			PRINT 'без обработки (по времени)'

		SELECT tip_id
			 , build_id
			 , service_id
			 , short_name
			 , u.short_id2 AS unit_id
			 , is_boiler
			 , t.V_start
			 , V1 AS V1
			 , V_arenda AS V_arenda
			 , V_norma AS V_norma
			 , V_add AS V_add
			 , V_load_odn AS V_load_odn
			 , V2 AS V2
			 , V3 AS V3
			 , t.V_economy
			 , block_paym_V
			 --, 0 AS v_itog			 
		FROM dbo.CounterHouse AS t
			LEFT JOIN dbo.Units AS u ON t.unit_id = u.id               --- CounterHouse.unit_id   -- находиться не код ед.изм. а short_id
		WHERE fin_id = @fin_id
			AND tip_id = @tip_id
			AND build_id = @build_id			
			AND NOT (@DB_NAME LIKE '%KR1%' AND is_boiler=1 AND service_id='гвод' AND block_paym_V=0) -- 23/05/22
		RETURN
	END

	IF @debug = 1
		PRINT 'Обработка'

	DECLARE @t TABLE (
		  tip_id SMALLINT
		, build_id INT
		, service_id VARCHAR(10)
		, short_name VARCHAR(50)
		, unit_id VARCHAR(10) DEFAULT NULL
		, short_id VARCHAR(10) DEFAULT NULL
		, is_boiler BIT DEFAULT 0
		, V_start DECIMAL(15, 6) DEFAULT 0
		, V1 DECIMAL(15, 6) DEFAULT 0
		, V_arenda DECIMAL(15, 6) DEFAULT 0
		, V_norma DECIMAL(15, 6) DEFAULT 0
		, V_add DECIMAL(15, 6) DEFAULT 0
		, V_load_odn DECIMAL(15, 6) DEFAULT 0
		, V2 DECIMAL(15, 6) DEFAULT 0
		, V3 DECIMAL(15, 6) DEFAULT 0
		, V_economy DECIMAL(15, 6) DEFAULT 0
		, block_paym_V BIT DEFAULT 0
		, V_itog DECIMAL(15, 6) DEFAULT 0
		, is_volume_direct BIT DEFAULT 0
	)

	IF @info_account_no = 1
	BEGIN
		SELECT tip_id
			 , build_id
			 , service_id
			 , short_name
			 , unit_id
			 --, short_id
			 , is_boiler
			 , V_start
			 , V1
			 , V_arenda
			 , V_norma
			 , V_add
			 , V_load_odn
			 , V2
			 , V3
			 , V_economy
			 , block_paym_V
			 --, v_itog			 
		FROM @t
		RETURN
	END

	-- список лицевых в доме
	SELECT Occ
		 , o.flat_id
		 , F.bldn_id
	INTO #t_occ
	FROM dbo.Occupations AS o 
		JOIN dbo.Flats AS F  ON F.id = o.flat_id
	WHERE F.bldn_id = @build_id
		AND o.status_id <> 'закр'

	IF EXISTS (
			SELECT 1
			FROM dbo.Build_source_value bsv 
			WHERE bsv.fin_id = @fin_id
				AND build_id = @build_id
		)
	BEGIN
		IF @debug = 1
			PRINT 'BUILD_SOURCE_VALUE'

		DELETE bsv 
		FROM [dbo].[Build_source_value] AS bsv
		WHERE bsv.build_id = @build_id
			AND bsv.fin_id = @fin_id
			AND NOT EXISTS (
				SELECT 1
				FROM [dbo].[Paym_occ_build] AS t2 
					JOIN #t_occ AS voa ON t2.Occ = voa.Occ
				WHERE t2.service_in = bsv.service_id
					AND t2.fin_id = bsv.fin_id
			)

		--INSERT INTO #t2 EXEC k_intPrintCounterHouse2 @build_id, @fin_id, @debug
		INSERT INTO #t2 (tip_id
					   , build_id
					   , service_id
					   , short_name
					   , unit_id
					   , short_id
					   , is_boiler
					   , V_start
					   , V1
					   , V_arenda
					   , V_norma
					   , V_add
					   , V_load_odn
					   , V2
					   , V3
					   , V_economy
					   , block_paym_V
					   , v_itog)
		SELECT tip_id
			 , build_id
			 , service_id
			 , short_name
			 , unit_id
			 , short_id
			 , is_boiler
			 , V_start
			 , V1
			 , V_arenda
			 , V_norma
			 , V_add
			 , V_load_odn
			 , V2
			 , V3
			 , V_economy
			 , block_paym_V
			 , v_itog			 
		FROM dbo.Fun_CounterHouse_Table(@build_id, @fin_id, @debug)

		UPDATE #t2
		SET V_norma = V_norma - V_add

		IF @debug = 1
			SELECT tab = '#t2'
				 , *
			FROM #t2

	END

	INSERT INTO @t (tip_id
				  , build_id
				  , service_id
				  , short_name
				  , unit_id
				  , short_id)
	SELECT @tip_id
		 , @build_id
		 , S.id
		 , S.short_name
		 , u.unit_id
		 , u.short_id
	FROM dbo.Services AS S 
		OUTER APPLY (
			SELECT TOP (1) u.id AS unit_id
						 , u.short_id
			FROM dbo.Service_units AS su 
				JOIN dbo.Units u ON su.unit_id = u.id
			WHERE fin_id = @fin_id
				AND service_id = S.id
				AND tip_id = @tip_id
		) AS u
	WHERE S.is_counter = CAST(1 AS BIT)
		AND (S.is_build = CAST(0 AS BIT) OR S.id IN ('элмп', 'Эдом'))
		AND S.id NOT IN ('вотв', 'вот2', 'хдпк', 'гдпк')	-- 05.06.2017
		AND s.is_paym=CAST(1 AS BIT)
	--AND S.id NOT IN ('вотв', 'вот2', 'хвпк', 'хдпк', 'гвпк', 'гдпк', 'вопк')

	IF @debug = 1
		SELECT tab = '@t'
			 , *
		FROM @t

	UPDATE t
	SET is_boiler = t2.is_boiler
	  , V1 = t2.V1
	  , block_paym_V = t2.block_paym_V
	FROM @t AS t
		JOIN (
			SELECT C.build_id
				 , C.service_id
				 , is_boiler = COALESCE(B.is_boiler, 0)
				 , COALESCE(SUM(CI.actual_value), 0) AS V1
				 , COALESCE(CI.is_info, 0) AS block_paym_V
			FROM dbo.Counters AS C 
				JOIN dbo.Buildings AS B  ON B.id = C.build_id
				JOIN dbo.Counter_inspector AS CI  ON CI.counter_id = C.id
				JOIN dbo.Services AS S  ON C.service_id = S.id
				JOIN dbo.Global_values AS GV  ON CI.fin_id = GV.fin_id
					AND CI.inspector_date BETWEEN GV.start_date AND GV.end_date
			WHERE C.build_id = @build_id
				AND C.is_build = 1
				AND CI.fin_id = @fin_id
				AND NOT EXISTS (
					SELECT 1
					FROM #t2 AS t
					WHERE t.service_id = C.service_id
				)
			GROUP BY C.build_id
				   , C.service_id
				   , B.is_boiler
				   , CI.is_info
		) AS t2 ON t.build_id = t2.build_id
			AND t.service_id = t2.service_id

	IF @debug = 1
		SELECT tab = '@t UPDATE t SET is_boiler'
			 , *
		FROM @t

	-- где уже был расчёт по домовым, объёмы не считаем
	--UPDATE T
	--SET block_paym_V = 1
	--FROM @t AS T
	--WHERE EXISTS (SELECT
	--		T.service_id
	--	FROM #t2 AS t2
	--	WHERE t2.service_id = T.service_id)

	--IF @DB_NAME IN ('KR1', 'ARX_KR1')
	--	UPDATE T
	--	SET block_paym_V = 1
	--	FROM @t AS T
	--	WHERE service_id = 'элмп'

	UPDATE t -- последнее значение объема аренды
	SET V_arenda = COALESCE(
		(
			SELECT TOP 1 CI.volume_arenda
			FROM dbo.Counter_inspector AS CI 
				JOIN dbo.Counters AS C ON 
					CI.counter_id = C.id
			WHERE CI.fin_id = @fin_id
				AND C.is_build = 1
				AND C.build_id = t.build_id
				AND C.service_id = t.service_id
			ORDER BY CI.inspector_date DESC
		), 0) 
	FROM @t AS t

	-- Сохраняем начисления(количество) по дому во временной таблице для дальнейшего использования
	CREATE TABLE #t_paym_build (
		  service_id VARCHAR(10) COLLATE database_default
		, unit_id VARCHAR(10) COLLATE database_default
		, short_id VARCHAR(10) COLLATE database_default
		, kol_norma DECIMAL(15, 6)
		, kol_add DECIMAL(15, 6)
	)

	INSERT INTO #t_paym_build
	SELECT vp.service_id
		 , U.id AS unit_id
		 , U.short_id
		 , SUM(
		   CASE COALESCE(vp.metod, 1)
			   WHEN 1 THEN COALESCE(vp.kol_norma, 0)
			   --WHEN 4 THEN COALESCE(vp.kol_norma, 0)  --27.02.2014 закомментировал
			   ELSE COALESCE(vp.kol, 0)
		   END ) AS kol_norma
		 , SUM(CASE
			   WHEN (COALESCE(vp.kol_added, 0) <> 0) THEN vp.kol_added
			   WHEN (vp.Added <> 0 AND tarif <> 0) THEN vp.Added / vp.tarif
			   ELSE 0
		   END) AS kol_add
	FROM #t_occ AS t_occ
		JOIN dbo.View_paym AS vp ON t_occ.Occ = vp.Occ
		JOIN dbo.Units AS U ON vp.unit_id = U.id
		JOIN @t AS t ON vp.service_id = t.service_id
	WHERE vp.fin_id = @fin_id
		AND (vp.Value <> 0 OR vp.Added <> 0 OR vp.metod=3 OR vp.kol_added<>0)  -- ДОБАВИЛ OR vp.added<>0 27.10.2014
		AND NOT EXISTS (
			SELECT 1
			FROM #t2 AS t2
			WHERE t2.service_id = t.service_id
		)
	GROUP BY vp.service_id
		   , U.id
		   , U.short_id
	OPTION (RECOMPILE)

	IF @debug = 1
		SELECT '#t_paym_build'
			 , *
		FROM #t_paym_build
	--***********************************************************************

	UPDATE t
	SET t.V_norma = COALESCE((
			SELECT TOP (1) vp.kol_norma
			FROM #t_paym_build AS vp
			WHERE vp.service_id = t.service_id
				AND vp.kol_norma <> 0
		), 0)
	  , t.V_add = COALESCE((
			SELECT TOP (1) vp.kol_add
			FROM #t_paym_build AS vp
			WHERE vp.service_id = t.service_id
				AND vp.kol_add <> 0
		), 0)
	FROM @t AS t

	UPDATE t
	SET unit_id = tpb.unit_id
	FROM @t AS t
		JOIN #t_paym_build AS tpb ON tpb.service_id = t.service_id


	IF @debug = 1
		SELECT '#t2' AS '#t2'
			 , vp2.*
		FROM #t2 AS vp2
		WHERE vp2.service_id IN ('гвод', 'гвс2', 'хвод', 'хвс2')

	IF @debug = 1
		SELECT '@t'
			 , *
		FROM @t

	--UPDATE t
	--SET	V2	= V_arenda + V_norma + V_add
	--	,V3	= V1 - (V_arenda + V_norma + V_add)
	--FROM @t AS t

	--IF @debug=1 SELECT * FROM @t

	UPDATE t
	SET is_boiler = COALESCE(B.is_boiler, t.is_boiler)
	  , V_start = COALESCE(t2.V_start, t.V_start)
	  , V1 = COALESCE(t2.V1, t.V1)
	  , V_arenda = COALESCE(t2.V_arenda, t.V_arenda)
	  , V_norma = COALESCE(t2.V_norma, t.V_norma)
	  , V_add = COALESCE(t2.V_add, t.V_add)
	  , V_load_odn = COALESCE(t2.V_load_odn, t.V_load_odn)
	  , V2 = COALESCE(t2.V2, t.V2) --_norma--+t2.V_arenda
	  , V3 = COALESCE(t2.V3, t.V3)
	  , V_economy = COALESCE(t2.V_economy, t.V_economy)
	  , unit_id = COALESCE(t.unit_id, t2.unit_id)
	  , V_itog = COALESCE(t2.V_itog, t.V_itog)
	FROM @t AS t
		JOIN dbo.Buildings B ON t.build_id = B.id
		LEFT JOIN #t2 AS t2 ON t2.build_id = t.build_id
			AND t.service_id = t2.service_id
	WHERE COALESCE(B.info_account_no, 0) <> 1

	--if @DB_NAME LIKE '%KR1%' AND @build_id in (6870)  
	--UPDATE @t SET is_boiler=0

	IF @debug = 1
	BEGIN
		SELECT '@t'
			 , 'is_boiler' = 1
			 , *
		FROM @t
		WHERE is_boiler = 1

		SELECT '@t гвод хвод'
			 , vp.service_id
			 , SUM(vp.V_norma) AS V_norma
			 , SUM(vp.V_add) AS V_add
		FROM @t AS vp
		WHERE vp.service_id IN ('гвод', 'гвс2', 'хвод', 'хвс2')
		GROUP BY vp.service_id
	END

	if @soi_boiler_only_hvs=0
	UPDATE t
	SET t.V_norma =
				   CASE
					   WHEN t.service_id IN ('хвод', 'хвс2', 'гвод', 'гвс2') AND
						   t.V1 > 0 THEN COALESCE((
							   SELECT SUM(vp.V_norma)--+SUM(vp.V_add)
							   FROM @t AS vp
							   WHERE vp.service_id IN ('хвод', 'хвс2', 'гвод', 'гвс2')
								   AND vp.V1 > 0
						   ), 0)
					   ELSE t.V_norma

				   END
	  , t.V_add =
				 CASE
					 WHEN t.service_id IN ('хвод', 'хвс2', 'гвод', 'гвс2')
					 AND t.V1 > 0   -- 27.06.2022 убрал комментарий
					 THEN COALESCE((
							 SELECT SUM(vp.V_add)
							 FROM @t AS vp
							 WHERE vp.service_id IN ('хвод', 'хвс2', 'гвод', 'гвс2')
								AND vp.V1 > 0
						 ), 0)
					 ELSE t.V_add

				 END
	FROM @t AS t
	WHERE t.is_boiler = 1

	--IF @debug = 1
	--BEGIN
	--	SELECT 'is_boiler' = 2
	--		 , *
	--	FROM @t
	--	WHERE is_boiler = 1
	--END

	--UPDATE t
	--SET	V3	= V1 - V_norma
	--	,V2	= V_norma
	--FROM @t AS t
	--WHERE t.is_boiler = 1

	UPDATE t
	SET V2 = V_arenda + V_norma + V_add
	  , V3 = t.V_start + V1 - (V_arenda + V_norma + V_add)
	FROM @t AS t
	--WHERE t.is_boiler = 1	

	--IF @debug = 1
	--	SELECT 'is_boiler' = 3
	--		 , *
	--	FROM @t
	--	WHERE is_boiler = 1

	UPDATE t
	SET V3 = 0
	FROM @t AS t
	WHERE (t.V3 < 0 AND @is_ValueBuildMinus = 0)
		OR t.V2 = 0
		OR t.V1 = 0

	-- при загрузке одн и после расчета 
	UPDATE t
	SET V3 = CASE
                 WHEN t.V_load_odn <> 0 AND t.V_itog > 0 THEN t.V_itog
                 ELSE V3
        END
	FROM @t AS t

	IF @debug = 1
		SELECT '1'
			 , *
		FROM @t

	-- Изменяем если есть названия услуг по разным типам фонда
	UPDATE t
	SET short_name = st.service_name
	FROM @t AS t
		JOIN dbo.Services_types AS st ON t.tip_id = st.tip_id
			AND t.service_id = st.service_id

	-- Изменяем если есть названия услуг по разным домам
	UPDATE t
	SET short_name = sb.service_name
	  , t.block_paym_V = sb.blocked_account_info
	FROM @t AS t
		JOIN dbo.Services_build AS sb ON t.service_id = sb.service_id
	WHERE sb.build_id = @build_id

	-- Объём по прямым договорам  17.12.2022
	UPDATE t
	SET V2 = COALESCE(ci.volume_direct_contract, 0)  -- Объём по прямым договорам	
	, V3 = COALESCE(ci.volume_odn, 0)
	, is_volume_direct =1
	FROM @t AS t
		JOIN dbo.Services_build AS sb ON t.service_id = sb.service_id AND sb.is_direct_contract=1
		CROSS APPLY (
			SELECT TOP (1) 
				sum(COALESCE(CI.volume_direct_contract, 0)) as volume_direct_contract
				--,sum(COALESCE(CI.value_paym, 0)) as value_paym
				,sum(COALESCE(CI.volume_odn, 0)) as volume_odn
			FROM dbo.Counter_inspector AS CI 
				JOIN dbo.Counters AS C ON CI.counter_id = C.id
			WHERE CI.fin_id = @fin_id
				AND C.is_build = CAST(1 AS BIT)
				AND C.build_id = t.build_id
				AND C.service_id = t.service_id		
		) as ci
	WHERE sb.build_id = @build_id

	-- по кому нет общедомовых расчётов убираем показ последних 2-х колонок
	--IF @DB_NAME IN ('KOMP', 'ARX_KOMP')
	UPDATE T
	SET block_paym_V = 1
	FROM @t AS T
	WHERE 1=1
	AND is_volume_direct=0
	AND NOT EXISTS (
			SELECT 1
			FROM #t2 AS t2
			WHERE t2.service_id = T.service_id
				AND t2.short_id = T.short_id   --unit_id 17.12.21  AND t2.unit_id = T.short_id
		)
	IF @debug = 1 SELECT '2',* FROM @t
	IF @debug = 1 SELECT '2 #t2',* FROM #t2

	UPDATE t
	SET V2 =
			CASE
				WHEN V_arenda = V2 THEN 0
				ELSE V2
			END
	  , V3 = 0   -- раскомментировал 27/01/17
	FROM @t AS t
	WHERE block_paym_V = 1

	--IF @debug = 1 SELECT '21',* FROM @t
	--IF @debug = 1 SELECT '21',* FROM #t2

	-- По отоплению не бывает ОДН
	UPDATE t
	SET V3 = 0
	  , V2 =
			CASE
				WHEN V1 > 0 THEN V2 -- есть показания общедомового счётчика
				ELSE 0
			END
	FROM @t AS t
	WHERE t.service_id = 'отоп'

	-- 28/05/2023
	UPDATE t 
	SET V2 = V2 + V3, V3 = 0
	FROM @t AS t
	WHERE t.service_id = 'тепл'

	--IF @debug=1 SELECT '1',* FROM @t

	DELETE FROM @t
	WHERE V1 = 0
		AND V2 = 0
		AND V3 = 0

	-- 31.10.14		
	DELETE FROM @t
	WHERE V_norma = 0
		AND V1 = 0
		AND V2 = V_add
		AND block_paym_V = 1

	--IF @debug=1 SELECT '2 2',* FROM @t

	DELETE t
	FROM @t AS t
		JOIN dbo.Services_build AS st ON t.build_id = st.build_id
			AND t.service_id = st.service_id
	WHERE st.blocked_account_info = CAST(1 AS BIT)
	--IF @debug=1 SELECT '2 3',* FROM @t
	DELETE t
	FROM @t AS t
		JOIN dbo.Services_types AS st ON t.tip_id = st.tip_id
			AND t.service_id = st.service_id
	WHERE st.blocked_account_info = CAST(1 AS BIT)

	IF @debug = 1
		SELECT '3', * FROM @t

	BEGIN TRAN

	DELETE FROM dbo.CounterHouse 
	WHERE fin_id = @fin_id
		AND tip_id = @tip_id
		AND build_id = @build_id
		AND manual_edit=CAST(0 AS BIT)

	IF @debug = 1
		SELECT 'CounterHouse'
			 , *
		FROM dbo.CounterHouse
		WHERE fin_id = @fin_id
		AND tip_id = @tip_id
		AND build_id = @build_id

	IF @soi_boiler_only_hvs=1
	BEGIN
		IF @debug=1 PRINT '@soi_boiler_only_hvs'

		UPDATE t 
		SET t.V_norma=t.V_norma+COALESCE(t2.V_norma,0), 
			t.V_arenda=t.V_arenda+COALESCE(t2.V_arenda,0),
			t.V_add=t.V_add+COALESCE(t2.V_add,0), 
			t.V2=t.V2+COALESCE(t2.V2,0), 
			t.V3=CASE
                     WHEN t.V3 - COALESCE(t2.V2, 0) < 0 THEN 0
                     ELSE t.V3 - COALESCE(t2.V2, 0)
                END
		FROM @t t
		CROSS APPLY (SELECT * FROM @t t2 WHERE t2.is_boiler=1 AND t2.service_id='гвод') AS t2 
		WHERE t.is_boiler=1
		AND t.service_id='хвод'
		
		IF @debug = 1		
		SELECT '4'
			 , *
		FROM @t

		DELETE FROM @t
		WHERE is_boiler=1
		AND service_id='гвод'
	END

	INSERT INTO dbo.CounterHouse (fin_id
								, tip_id
								, build_id
								, service_id
								, short_name
								, unit_id
								, is_boiler
								, V_start
								, V1
								, V_arenda
								, V_norma
								, V_add
								, V_load_odn
								, V2
								, V3
								, V_economy
								, block_paym_V)
--IF @debug = 1
	SELECT @fin_id
		 , t.tip_id
		 , t.build_id
		 , t.service_id
		 , t.short_name
		 , t.unit_id
		 , t.is_boiler
		 , ROUND(t.V_start, COALESCE(u.precision, 4)) AS V_start 
		 , ROUND(t.V1, COALESCE(u.precision, 4)) AS V1
		 , ROUND(t.V_arenda, COALESCE(u.precision, 4)) AS V_arenda
		 , ROUND(t.V_norma, COALESCE(u.precision, 4)) AS V_norma
		 , ROUND(t.V_add, COALESCE(u.precision, 4)) AS V_add
		 , ROUND(t.V_load_odn, COALESCE(u.precision, 4)) AS V_load_odn
		 , ROUND(t.V2, COALESCE(u.precision, 4)) AS V2
		 , ROUND(t.V3, COALESCE(u.precision, 4)) AS V3
		 , ROUND(t.V_economy, COALESCE(u.precision, 4)) AS V_economy 
		 , t.block_paym_V
	FROM @t AS t
		LEFT JOIN dbo.Units AS u ON t.unit_id = u.id
	WHERE NOT EXISTS(SELECT * FROM dbo.CounterHouse AS ch
			WHERE ch.tip_id=t.tip_id 
			AND ch.build_id = t.build_id
			AND ch.service_id = t.service_id
			AND ch.fin_id=@fin_id)

	COMMIT TRAN
	
	UPDATE t
	SET short_name = sb.service_name
	FROM dbo.CounterHouse AS t
	JOIN dbo.Services_build AS sb ON sb.build_id=t.build_id AND sb.service_id=t.service_id

	-- когда в ручную в таблицу добавляют бывает такая ситуация
	UPDATE t
	SET short_name = s.short_name
	FROM dbo.CounterHouse AS t
		JOIN dbo.Services as s ON t.service_id=s.id
	WHERE t.short_name is NULL
	

	IF @debug = 1
		SELECT 'CounterHouse 2'
			 , *
		FROM dbo.CounterHouse
		WHERE fin_id = @fin_id
		AND tip_id = @tip_id
		AND build_id = @build_id

	SELECT tip_id
		 , build_id
		 , service_id
		 , short_name
		 , u.short_id2 AS unit_id
		 , is_boiler		 
		 , V_start AS V_start
		 , V1 AS V1
		 , V_arenda AS V_arenda
		 , V_norma AS V_norma
		 , V_add AS V_add
		 , V_load_odn AS V_load_odn
		 , V2 AS V2
		 , V3 AS V3
		 , V_economy AS V_economy 
		 , block_paym_V
		 --, t.v_itog
	--FROM @t AS t
	FROM dbo.CounterHouse t
		JOIN dbo.UNITS AS U ON t.unit_id = U.id
	WHERE tip_id = @tip_id
		AND fin_id = @fin_id
		AND build_id = @build_id
		-- для печати в квитанции убираем одну строку(так как они одинаковые)
		AND NOT (@DB_NAME LIKE '%KR1%' AND is_boiler=1 AND service_id='гвод' AND block_paym_V=0) -- 23/05/22

END
go

