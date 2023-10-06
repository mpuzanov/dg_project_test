CREATE   PROCEDURE [dbo].[rep_ivc_people_period_date]
(
	  @date1 SMALLDATETIME
	, @date2 SMALLDATETIME = NULL
	, @tip_id SMALLINT = NULL
	, @build_id INT = NULL
	, @occ1 INT = NULL
)
AS
	/*
	 Выдаем свод зарегистрированных людей за период
	
	 rep_ivc_people_period_date @date1='20190301', @date2='20190331', @tip_id=28, @build_id=1031
	 rep_ivc_people_period_date @date1='20190301', @date2='20190331', @tip_id=28
	*/
	SET NOCOUNT ON


	IF @date2 IS NULL
		AND @date1 IS NOT NULL
		SET @date2 = @date1

	IF @tip_id IS NULL
		AND @build_id IS NULL
		AND @occ1 IS NULL
		SET @tip_id = 0

	DECLARE @start_date SMALLDATETIME
		  , @end_date SMALLDATETIME
		  , @DateRegNull SMALLDATETIME = '19000101'
		  , @finCurrent SMALLINT

	IF @build_id IS NULL
		AND @occ1 IS NOT NULL
	BEGIN
		SELECT @build_id = v.build_id
		FROM dbo.VOcc v
		WHERE v.occ = @occ1
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
			SELECT S.Name AS STREETS
				 , B.nom_dom
				 , voa.nom_kvr
				 , voa.occ
				 , voa.TOTAL_SQ
				 , P.id
				 , P.people_uid
				 , P.DateDel
				 , P.DateReg
				 , CASE
                       WHEN P.DateDel IS NOT NULL THEN P.DateDel
                       ELSE P.DateReg
                END AS Date
				 , CAST(P.DateEnd AS DATE) AS DateEnd
				 , PS.Name
				 , PS.is_temp
				 , B.nom_dom_sort
				 , voa.nom_kvr_sort
				 , voa.start_date AS [start_date]
				 , @date2 AS end_date
			FROM dbo.People AS P 
				JOIN dbo.Person_statuses PS ON 
					PS.id = P.status2_id
				JOIN dbo.View_occ_main AS voa ON 
					voa.occ = P.occ
				JOIN dbo.Occupation_Types AS ot ON 
					voa.tip_id = ot.id					
				JOIN dbo.Buildings AS B ON 
					voa.bldn_id = B.id 
					AND voa.fin_id = b.fin_current
				JOIN dbo.VStreets AS S ON 
					S.id = B.street_id
			WHERE 
				(voa.tip_id = @tip_id OR @tip_id IS NULL)
				AND (voa.bldn_id = @build_id OR @build_id IS NULL)
				AND (voa.occ = @occ1 OR @occ1 IS NULL)
				AND (B.is_paym_build = 1)
				AND PS.is_kolpeople = 1

				AND ((DateDel BETWEEN @date1 AND @date2) OR (COALESCE(P.DateReg, @DateRegNull) BETWEEN @date1 AND @date2))
		) AS t
	)

	SELECT
		--t.*
		t.people_uid AS UID_Zhitelya
	  , [Date] AS [Date]
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
	FROM cte AS t
	ORDER BY t.Streets
		   , t.nom_dom_sort
		   , t.nom_kvr_sort
go

