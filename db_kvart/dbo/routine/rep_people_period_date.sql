CREATE   PROCEDURE [dbo].[rep_people_period_date]
/*
 Выдаем свод зарегистрированных людей за период дат
 rep_people_period_date '20141125','20141130', 27, null,0
exec rep_people_period_date @date1='20231001', @date2='20231030', @tip_id=204, @build_id1=null, @only_izm=0
exec rep_people_period_date @date1='20231001', @date2='20231030', @tip_id=204, @build_id1=8562, @only_izm=1
*/
(
	@date1		SMALLDATETIME
   ,@date2		SMALLDATETIME = NULL
   ,@tip_id		SMALLINT	  = NULL
   ,@build_id1  INT			  = NULL
   ,@only_izm   BIT			  = 1
   ,@PrintGroup SMALLINT	  = NULL
)
AS
	SET NOCOUNT ON


	IF @only_izm IS NULL
		SET @only_izm = 1

	IF @date2 IS NULL
		AND @date1 IS NOT NULL
		SET @date2 = @date1

	IF @tip_id IS NULL
		AND @build_id1 IS NULL
		SET @tip_id = 0

	DECLARE @DateRegNull SMALLDATETIME = '19000101'
		   ,@finCurrent	 SMALLINT


	;
	WITH cte
	AS
	(SELECT
			*
		   , (total_people_fin_1 + people_plus - people_minus) AS total_people_fin_2
		FROM (SELECT
				S.name AS STREETS
			   ,voa.bldn_id AS build_id
			   ,B.nom_dom
			   ,voa.flat_id
			   ,voa.nom_kvr
			   ,voa.occ
			   ,voa.total_sq
			   ,voa.living_sq
			   ,(SELECT
						COUNT(P.id)
					FROM dbo.PEOPLE AS P
					JOIN dbo.Person_statuses PS ON 
						PS.id = P.Status2_id
					WHERE P.occ = voa.occ
						AND PS.is_kolpeople = 1
						AND (COALESCE(P.DateReg, @DateRegNull) < @date1)						
						AND (COALESCE(p.date_create, @DateRegNull) < @date1)
						AND (P.DateDel IS NULL 
							OR --P.DateDel >= @date1
							(P.DateDel is not null AND P.DateEdit<@date2)
							)
				) AS total_people_fin_1
			   ,(SELECT
						COUNT(P.id)
					FROM dbo.PEOPLE AS P 
					JOIN dbo.Person_statuses PS ON 
						PS.id = P.Status2_id
					WHERE occ = voa.occ
						AND PS.is_kolpeople = 1
						AND (
								(DateReg BETWEEN @date1 AND @date2)
								OR
								(P.date_create BETWEEN @date1 AND @date2)
							)

				) AS people_plus
			   ,(SELECT
						COUNT(P.id)
					FROM dbo.PEOPLE AS P 
					JOIN dbo.Person_statuses PS 
						ON PS.id = P.Status2_id
					WHERE P.occ = voa.occ
						AND PS.is_kolpeople = 1
						AND (
							(P.DateDel BETWEEN @date1 AND @date2)
							OR
							(P.DateDel is not null AND P.DateEdit BETWEEN @date1 AND @date2)
							)
				) AS people_minus
			   ,B.nom_dom_sort
			   ,voa.nom_kvr_sort
			FROM dbo.View_occ_all AS voa 
			JOIN dbo.Occupation_Types AS ot 
				ON voa.tip_id = ot.id				
			JOIN dbo.Buildings AS B 
				ON voa.bldn_id = B.id AND voa.fin_id = b.fin_current
			JOIN dbo.VStreets AS S 
				ON S.id = B.street_id
			WHERE 
				(voa.tip_id = @tip_id OR @tip_id IS NULL)
				AND (voa.bldn_id = @build_id1 OR @build_id1 IS NULL)
				AND (@PrintGroup IS NULL
					OR EXISTS (SELECT
							1
						FROM dbo.PRINT_OCC AS po 
						WHERE po.occ = voa.occ
							AND po.group_id = @PrintGroup
							)
				)
			) AS t
		)
	SELECT
		*
	FROM cte AS t
	WHERE 
		@only_izm = 0
		OR (@only_izm = 1 
			AND people_plus <> 0
			OR people_minus <> 0
			)
	ORDER BY t.STREETS
	, t.nom_dom_sort
	, t.nom_kvr_sort
	OPTION (RECOMPILE)
go

