CREATE   PROCEDURE [dbo].[rep_ivc_people_period]
(
	  @fin_id SMALLINT
	, @fin_id2 SMALLINT = NULL
	, @tip_id SMALLINT = NULL
	, @build_id INT = NULL
	, @occ INT = NULL
	, @is_only_paym BIT = NULL
	, @format VARCHAR(10) = NULL
)
AS
	/*
	 Выдаем свод зарегистрированных людей за период
	 rep_ivc_people_period @fin_id=232, @fin_id2=233, @tip_id=1, @build_id=6786
	 rep_ivc_people_period @fin_id=232, @fin_id2=233, @tip_id=1, @build_id=null
	*/
	SET NOCOUNT ON

	IF @tip_id IS NULL
		AND @build_id IS NULL
		AND @occ IS NULL
		SET @tip_id = 0

	DECLARE @start_date SMALLDATETIME
		  , @end_date SMALLDATETIME
		  , @DateRegNull SMALLDATETIME = '19000101'
		  , @finCurrent SMALLINT

	SELECT @finCurrent = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, NULL)

	IF @fin_id IS NULL
		SET @fin_id = @finCurrent

	IF @fin_id2 IS NULL
		SET @fin_id2 = @fin_id

	IF @fin_id2 > @finCurrent
		SET @fin_id2 = @finCurrent

	SELECT @start_date = [start_date]
	FROM dbo.Global_values AS GV
	WHERE fin_id = @fin_id

	SELECT @end_date = end_date
	FROM dbo.Global_values AS GV
	WHERE fin_id = @fin_id2

	IF @build_id IS NULL
		AND @occ IS NOT NULL
	BEGIN
		SELECT @build_id = v.build_id
		FROM dbo.VOcc v
		WHERE v.Occ = @occ
	END

	--PRINT @DateRegNull		
	--PRINT @start_date
	--PRINT @fin_id2	
	--PRINT @end_date

	;
	WITH cte AS
	(
		SELECT *
		FROM (
			SELECT S.name AS STREETS
				 , B.nom_dom
				 , voa.nom_kvr
				 , voa.Occ
				 , voa.total_sq
				 , P.Id
				 , P.people_uid
				 , P.DateDel
				 , P.DateReg
				 , CASE
                       WHEN P.DateDel IS NOT NULL THEN P.DateDel
                       ELSE P.DateReg
                END AS Date
				 , CAST(P.DateEnd AS DATE) AS DateEnd
				 , PS.name
				 , PS.is_temp
				 , B.nom_dom_sort
				 , voa.nom_kvr_sort
				 , @start_date AS start_date
				 , @end_date AS end_date
			FROM dbo.View_occ_main AS voa
				JOIN dbo.People AS P 
					ON voa.Occ = P.Occ
				JOIN dbo.Person_statuses PS 
					ON PS.Id = P.status2_id
				JOIN dbo.Buildings AS B 
					ON voa.bldn_id = B.Id
				JOIN dbo.VStreets AS S 
					ON S.Id = B.street_id
				JOIN dbo.View_occ_main AS voa2 
					ON voa.Occ = voa2.Occ
			WHERE 1=1
				AND (@tip_id IS NULL OR voa.tip_id = @tip_id)
				AND (@build_id IS NULL OR voa.bldn_id = @build_id)
				AND (@occ IS NULL OR voa.Occ = @occ)
				AND voa.fin_id = @fin_id
				AND voa2.fin_id = @fin_id2
				AND (@is_only_paym IS NULL OR b.is_paym_build = @is_only_paym)
				AND PS.is_kolpeople = CAST(1 AS BIT)
				AND ((DateDel BETWEEN @start_date AND @end_date) OR (COALESCE(P.DateReg, @DateRegNull) BETWEEN @start_date AND @end_date))
		) AS t
	)

	SELECT CAST(t.people_uid AS VARCHAR(36)) AS UID_Zhitelya
		 , CAST([Date] AS DATE) AS [Date]
		 , CASE
               WHEN DateDel IS NOT NULL THEN 'Снятие с регистрации'
               ELSE 'Регистрация'
        END AS Vid_zapisi
		 , CASE
               WHEN is_temp = '1' THEN 'Временный'
               ELSE 'Постоянная'
        END AS Tip_registracii
		 , CASE
               WHEN is_temp = '1' THEN DateEnd
               ELSE NULL
        END AS 'Date_until'
	INTO #t
	FROM cte AS t
	ORDER BY t.Streets
		   , t.nom_dom_sort
		   , t.nom_kvr_sort

	IF @format IS NULL OR @format NOT IN ('xml','json')
		SELECT *
		FROM #t

	IF @format = 'xml'
		SELECT '<?xml version="1.0" encoding="UTF-8"?>'+ (
				SELECT *
				FROM #t
				FOR XML PATH ('registraciya'), ELEMENTS, ROOT ('registracii')
			) AS result

	IF @format = 'json'
		SELECT (
				SELECT *
				FROM #t
				FOR JSON PATH, ROOT ('registracii')
			) AS result

DROP TABLE IF EXISTS #t;
go

