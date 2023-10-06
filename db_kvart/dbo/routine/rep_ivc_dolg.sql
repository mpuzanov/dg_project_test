CREATE   PROCEDURE [dbo].[rep_ivc_dolg]
(
	  @fin_id SMALLINT = NULL
	, @tip_str VARCHAR(2000) = ''
	, @sup_id SMALLINT = NULL
	, @build_id INT = NULL
	, @only_dolg SMALLINT = 0 -- 0 - все, 1 - только долги, 2 - только переплата, 3-только переплату  
	, @is_only_paym BIT = NULL
	, @format VARCHAR(10) = NULL
	, @debug BIT = NULL
)
AS
	/*
	Формирование файла по долгам на начало периода
	
	exec rep_ivc_dolg @fin_id=254,@tip_str='2',@only_dolg=0, @format='json'
	exec rep_ivc_dolg @fin_id=254,@tip_str='2',@only_dolg=0, @format='xml'
	exec rep_ivc_dolg @fin_id=254,@tip_str='2',@only_dolg=0, @format='xlsx'

	exec rep_ivc_dolg @fin_id=232,@tip_str='1',@sup_id=345,@only_dolg=3
	
	*/
	SET NOCOUNT ON

	IF @only_dolg IS NULL
		SET @only_dolg = 0

	DECLARE @DB_NAME VARCHAR(20) = UPPER(DB_NAME())

	DECLARE @tip TABLE (
		  tip_id INT PRIMARY KEY
		, tip_name VARCHAR(50)
		, fin_id INT DEFAULT NULL
		, strmes VARCHAR(15) DEFAULT NULL
		, [start_date] DATETIME DEFAULT NULL
		, end_date DATETIME DEFAULT NULL
	)
	INSERT INTO @tip
		(tip_id
	   , tip_name
	   , fin_id)
	SELECT t.Value
		 , ot.name
		 , COALESCE(@fin_id, ot.fin_id)
	FROM STRING_SPLIT(@tip_str, ',') AS t
		JOIN dbo.Occupation_Types ot ON t.Value = ot.ID
	WHERE RTRIM(t.Value) <> ''

	UPDATE t
	SET strmes = gv.strmes
	  , start_date = gv.start_date
	  , end_date = gv.end_date
	FROM @tip AS t
		JOIN Global_values gv ON t.fin_id = gv.fin_id

	IF @debug=1
	 SELECT * FROM @tip

	CREATE TABLE #dolgi (
		  OCC INT PRIMARY KEY
		, SUM_DOLG DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, SUM_SERV DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, SUM_PENY DECIMAL(15, 2) DEFAULT 0 NOT NULL
		, TOWN_NAME VARCHAR(50) COLLATE database_default
		, STREETS VARCHAR(60) COLLATE database_default
		, NOM_DOM VARCHAR(12) COLLATE database_default
		, NOM_KVR VARCHAR(20) COLLATE database_default
		, tip_id SMALLINT
		, strmes VARCHAR(15) COLLATE database_default
		, [start_date] SMALLDATETIME
		, end_date SMALLDATETIME
		, OCC1 INT DEFAULT NULL
		, tip_name VARCHAR(50) COLLATE database_default DEFAULT NULL
		, [ADDRESS] AS (CONCAT(TOWN_NAME,', ',STREETS,', д. ', NOM_DOM,' кв. ', NOM_KVR))
		, TOTAL_SQ DECIMAL(10, 4) DEFAULT NULL
		, Tip_OCC VARCHAR(20) COLLATE database_default DEFAULT 'ЖКУ'
		, fin_id SMALLINT DEFAULT NULL
	)
	--CREATE INDEX Idx1 ON #t1(OCC1);

	--IF @sup_id IS NOT NULL
	--BEGIN
	INSERT INTO #dolgi
		(OCC
	   , SUM_DOLG
	   , SUM_SERV
	   , SUM_PENY
	   , TOWN_NAME
	   , STREETS
	   , NOM_DOM
	   , NOM_KVR
	   , tip_id
	   , strmes
	   , [start_date]
	   , end_date
	   , OCC1
	   , tip_name
	   , TOTAL_SQ
	   , Tip_OCC
	   , fin_id)
	SELECT occ = os.occ_sup
		 , (os.SALDO + os.Penalty_old) AS SUM_DOLG
		 , os.SALDO AS SUM_SERV
		 , os.Penalty_old AS SUM_PENY
		 , t.name AS TOWN_NAME
		 , s.short_name AS STREETS
		 , b.NOM_DOM AS NOM_DOM
		 , o.NOM_KVR AS NOM_KVR
		 , o.tip_id
		 , tip.StrMes AS StrMes
		 , tip.START_DATE AS [START_DATE]
		 , tip.end_date
		 , o.occ
		 , o.tip_name
		 , o.TOTAL_SQ
		 , CASE
               WHEN sup.Tip_OCC = 3 THEN 'Кап. ремонт'
               ELSE 'ЖКУ'
               END AS Tip_OCC
		 , o.fin_id
	FROM dbo.View_occ_all_lite AS o 
		JOIN dbo.Buildings AS b ON 
			o.bldn_id = b.ID
		JOIN dbo.VStreets AS s ON 
			b.street_id = s.ID
		JOIN dbo.Occ_Suppliers AS os ON 
			o.occ = os.occ
			AND o.fin_id = os.fin_id
		JOIN dbo.Suppliers_all AS sup ON 
			os.sup_id = sup.ID
		JOIN dbo.Towns AS t ON 
			b.town_id = t.ID
		JOIN dbo.Occupation_Types ot ON 
			b.tip_id = ot.ID
		JOIN @tip AS tip ON 
			tip.tip_id = o.tip_id
			AND o.fin_id = tip.fin_id
		LEFT JOIN dbo.Intprint AS i ON 
			o.occ = i.occ
			AND o.fin_id = i.fin_id
		LEFT JOIN dbo.People p ON 
			i.Initials_owner_id = p.ID
	WHERE 
		o.status_id <> 'закр'
		AND b.blocked_house = 0 
		AND os.fin_id = @fin_id
		AND (@sup_id IS NULL OR os.sup_id = @sup_id)
		AND sup.Tip_OCC IN (1, 3)
		AND os.occ_sup <> 0
		AND (@build_id IS NULL OR b.ID = @build_id)
		AND (@is_only_paym IS NULL OR b.is_paym_build = @is_only_paym) 

	--	GOTO END_PROCESS
	--END

	IF @debug=1
		RAISERROR ('поставщиков выгрузили', 10, 1) WITH NOWAIT;
	--IF @debug=1
	--	SELECT * from #dolgi

	INSERT INTO #dolgi
		(OCC
	   , SUM_DOLG
	   , SUM_SERV
	   , SUM_PENY
	   , TOWN_NAME
	   , STREETS
	   , NOM_DOM
	   , NOM_KVR
	   , tip_id
	   , strmes
	   , [start_date]
	   , end_date
	   , OCC1
	   , tip_name
	   , TOTAL_SQ
	   , fin_id)
	SELECT dbo.Fun_GetFalseOccOut(o.occ, o.tip_id) AS occ
		 , (o.SALDO + o.Penalty_old) AS SUM_DOLG
		 , o.SALDO AS SUM_SERV
		 , o.Penalty_old AS SUM_PENY
		 , t.name AS TOWN_NAME
		 , s.short_name AS STREETS
		 , b.NOM_DOM AS NOM_DOM
		 , o.NOM_KVR AS NOM_KVR
		 , o.tip_id
		 , tip.StrMes AS StrMes
		 , tip.START_DATE AS [START_DATE]
		 , tip.end_date
		 , o.occ
		 , o.tip_name
		 , o.TOTAL_SQ
		 , o.fin_id
	FROM dbo.View_occ_all_lite AS o 
		JOIN dbo.Buildings AS b ON 
			o.bldn_id = b.ID
		JOIN dbo.VStreets AS s ON 
			b.street_id = s.ID
		JOIN dbo.Towns AS t ON 
			b.town_id = t.ID
		JOIN dbo.Occupation_Types ot ON 
			b.tip_id = ot.ID
		JOIN @tip AS tip ON 
			tip.tip_id = o.tip_id
			AND o.fin_id = tip.fin_id
		LEFT JOIN Intprint AS i ON 
			o.occ = i.occ
			AND o.fin_id = i.fin_id
		LEFT JOIN dbo.People p ON 
			i.Initials_owner_id = p.ID
	WHERE 
		o.status_id <> 'закр'
		AND b.blocked_house = 0
		AND (@build_id IS NULL OR b.ID = @build_id)
		AND (@is_only_paym IS NULL OR b.is_paym_build = @is_only_paym)
		AND (@sup_id IS NULL OR @sup_id=0)

	IF @debug=1
		RAISERROR ('по ед.лицевым выгрузили', 10, 1) WITH NOWAIT;

END_PROCESS:

	DELETE FROM #dolgi
	WHERE TOTAL_SQ = 0
		AND SUM_DOLG <= 0;

	IF @only_dolg = 3
		UPDATE #dolgi
		SET SUM_DOLG = 0
		WHERE SUM_DOLG < 0;


	SELECT OCC AS LC_Nomer
		 , SUM_DOLG AS Dolg
		 , CONVERT(VARCHAR(7), start_date, 126) AS period  --yyyy-MM
		 , Tip_OCC AS Tip_nachisleniya
		 , SUM_SERV AS Dolg_Usluga
		 , SUM_PENY AS Dolg_Peni
	INTO #t
	FROM #dolgi
	WHERE (@only_dolg IN (0, 3))
		OR (@only_dolg = 1 AND SUM_DOLG > 0)
		OR (@only_dolg = 2 AND SUM_DOLG < 0)
	ORDER BY OCC;

	IF @format IS NULL OR @format NOT IN ('xml','json')
		SELECT *
		FROM #t;

	IF @format = 'xml'
	BEGIN
		SELECT '<?xml version="1.0" encoding="UTF-8"?>'+(
				SELECT *
				FROM #t
				FOR XML PATH ('dolg_lc'), ELEMENTS, ROOT ('dolgi')
			) AS result
	END

	IF @format = 'json'
		SELECT (
				SELECT *
				FROM #t
				FOR JSON PATH, ROOT ('dolgi')
			) AS result

DROP TABLE IF EXISTS #t;
DROP TABLE IF EXISTS #dolgi;
go

