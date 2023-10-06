CREATE   PROCEDURE [dbo].[rep_pay_cash]
(
	  @date1 DATETIME = NULL
	, @date2 DATETIME = NULL
	, @tip_id SMALLINT = NULL
	, @fin_id1 SMALLINT = NULL
	, @sup_id INT = NULL
	, @build_id INT = NULL
	, @fin_id2 SMALLINT = NULL
	, @tip_str1 VARCHAR(2000) = NULL -- список типов фонда через запятую
)
AS
	/*
  Протокол ввода платежей
  по дате закрытия 
  по услугам

  EXEC	[dbo].[rep_pay_cash]
		@tip_id = 28,
		@fin_id1 = 175,
		@fin_id2 = 175
		,@tip_str1='28'
		,@sup_id=323  --347 323

  EXEC	[dbo].[rep_pay_cash]
		@tip_id = null,
		@fin_id1 = 175,
		@fin_id2 = 175
		,@tip_str1=null--'28'
		  
  dbo.rep_pay_7 '20120613 00:00:00','20120613 23:59:59',NULL,2,NULL,NULL,NULL,NULL    
  
  10.04.2012
*/
	--SET STATISTICS IO ON, TIME ON
	SET NOCOUNT ON

	IF @tip_id IS NULL
		AND @tip_str1 IS NULL
		AND @build_id IS NULL
		SET @tip_id = 0

	--************************************************************************************
	-- Таблица значениями Типа жил.фонда
	DECLARE @tip_table TABLE (
		  tip_id SMALLINT DEFAULT NULL PRIMARY KEY
	)

	INSERT INTO @tip_table
	SELECT CASE
               WHEN Value = 'Null' THEN NULL
               ELSE Value
               END
	FROM STRING_SPLIT(@tip_str1, ',')
	WHERE RTRIM(Value) <> ''

	IF @tip_id IS NOT NULL
	BEGIN
		INSERT INTO @tip_table
		SELECT id
		FROM dbo.VOcc_types
		WHERE id = @tip_id
			AND NOT EXISTS (
				SELECT 1
				FROM @tip_table
				WHERE tip_id = @tip_id
			)
	END
	--select * from @tip_table
	--************************************************************************************

	IF @date2 IS NULL
		SET @date2 = @date1

	IF @fin_id1 IS NULL
		AND @date1 IS NULL
		AND @date2 IS NULL
		SELECT @fin_id1 = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, NULL)

	IF @fin_id1 IS NOT NULL
		SELECT @date1 = '19000101'
			 , @date2 = '20500101'

	IF @fin_id1 IS NOT NULL
		AND @fin_id2 IS NULL
		SET @fin_id2 = @fin_id1

	-- для ограничения доступа услуг
	DROP TABLE IF EXISTS #s
	CREATE TABLE #s (
		  id VARCHAR(10) COLLATE database_default PRIMARY KEY
		, [name] VARCHAR(100) COLLATE database_default
		, sort_no SMALLINT
	)
	INSERT INTO #s (id
				  , name
				  , sort_no)
	SELECT vs.id
		 , vs.name
		 , vs.sort_no
	FROM dbo.View_services AS vs

	--select @tip,@fin_id1,@build
	DROP TABLE IF EXISTS #t1
	SELECT pd.[day] AS date_payment
		 , p.occ_sup AS occ_sup
		 , s.name AS serv_name_kvit
		 , SUM(ps.Value) AS sum_payment
		 , MIN(o.address) AS address
		 , p.id AS paying_id
		 , s.id AS service_id
		 , ot.name AS tip_name
		 , o.tip_id AS tip_id
		 , p.occ AS occ
		 , MIN(F.bldn_id) AS build_id
		 , dbo.Fun_GetFileNamePaying(p.id) AS 'FileNameReestr'
		 , MIN(s.sort_no) AS sort_no
	INTO #t1
	FROM dbo.Occupations AS o 
		JOIN dbo.Flats F ON F.id = o.flat_id
		JOIN dbo.Payings AS p ON o.occ = p.occ
		JOIN dbo.Paydoc_packs AS pd ON p.pack_id = pd.id
		JOIN @tip_table tt ON pd.tip_id = tt.tip_id
		JOIN dbo.Global_values gv ON pd.fin_id = gv.fin_id
		JOIN dbo.Paying_serv AS ps ON p.id = ps.paying_id
		JOIN #s AS s ON ps.service_id = s.id
		JOIN dbo.Buildings AS vb ON F.bldn_id = vb.id
		JOIN dbo.VStreets s1 ON vb.street_id = s1.id
		JOIN dbo.Occupation_Types ot ON tt.tip_id = ot.id
		JOIN dbo.Services_types st ON s.id = st.service_id
			AND ot.id = st.tip_id
		LEFT JOIN dbo.Paym_history AS vca ON vca.occ = p.occ
			AND vca.fin_id = p.fin_id
			AND vca.service_id = ps.service_id
			AND vca.sup_id = p.sup_id
		LEFT JOIN dbo.View_suppliers AS vs ON vca.source_id = vs.id
	WHERE ((@fin_id1 IS NULL AND pd.fin_id BETWEEN pd.fin_id AND pd.fin_id) OR (pd.fin_id BETWEEN @fin_id1 AND @fin_id2))
		AND (F.bldn_id = @build_id OR @build_id IS NULL)
		AND pd.date_edit BETWEEN @date1 AND @date2
		AND pd.forwarded = 1
		AND (pd.sup_id = @sup_id OR @sup_id IS NULL)
		AND st.check_blocked = 0
	GROUP BY CAST(pd.date_edit AS DATE)
		   , pd.[day]
		   , o.tip_id
		   , ot.name
		   , s.name
		   , s.id
		   , vb.id
		   , s1.short_name
		   , vb.nom_dom
		   , F.nom_kvr
		   , F.nom_kvr_sort
			 --,t.name
		   , pd.fin_id
		   , p.occ
		   , p.occ_sup
		   , p.pack_id
		   , p.id
		   , vs.name
	--,PT.name
	--,PRT.name

	UPDATE t
	SET serv_name_kvit = VS.service_name_kvit
	FROM #t1 t
		JOIN View_services_kvit VS ON t.service_id = VS.service_id
			AND t.tip_id = VS.tip_id
			AND (t.build_id = VS.build_id OR VS.build_id IS NULL)

	SELECT t1.FileNameReestr
		 , t1.date_payment
		 , t1.paying_id
		 , t1.occ_sup
		 , t1.serv_name_kvit
		 , SUM(t1.sum_payment) AS sum_payment
	FROM #t1 AS t1
	GROUP BY t1.FileNameReestr
		   , t1.date_payment
		   , t1.paying_id
		   , t1.occ_sup
		   , t1.serv_name_kvit
	--,t1.sort_no
	ORDER BY t1.date_payment
		   , t1.paying_id
		   , t1.occ_sup
		   , t1.serv_name_kvit--, t1.sort_no
	OPTION (RECOMPILE)


	--DROP TABLE #s
	--DROP TABLE #t_occ
go

