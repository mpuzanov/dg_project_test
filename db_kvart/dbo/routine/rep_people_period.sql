CREATE   PROCEDURE [dbo].[rep_people_period]
(
	@fin_id1	SMALLINT
   ,@fin_id2	SMALLINT = NULL
   ,@tip_id		SMALLINT = NULL
   ,@build_id1  INT		 = NULL
   ,@only_izm   BIT		 = 1
   ,@PrintGroup SMALLINT = NULL
   ,@occ1 INT = NULL
)
AS
/*
 Выдаем свод зарегистрированных людей за период
 rep_people_period 138, 139, 2, null,0
 rep_people_period 169, 169, 28, null,0
 rep_people_period @fin_id1=218,@fin_id2=219,@occ1=100000158,@only_izm=1
*/
	SET NOCOUNT ON


	IF @only_izm IS NULL
		SET @only_izm = 1

	IF @fin_id2 IS NULL
		AND @fin_id1 IS NOT NULL
		SET @fin_id2 = @fin_id1

	IF @tip_id IS NULL
		AND @build_id1 IS NULL
		AND @occ1 IS NULL
		SET @tip_id = 0

	DECLARE @start_date	 SMALLDATETIME
		   ,@end_date	 SMALLDATETIME
		   ,@DateRegNull SMALLDATETIME = '19000101'
		   ,@finCurrent	 SMALLINT
		   ,@finPred	 SMALLINT

	SELECT
		@finCurrent = dbo.Fun_GetFinCurrent(@tip_id, @build_id1, NULL, NULL)
	IF @fin_id1 IS NULL
		AND @fin_id2 IS NULL
		SELECT
			@fin_id1 = @finCurrent
		   ,@fin_id2 = @finCurrent

	IF @fin_id2 > @finCurrent
		SET @fin_id2 = @finCurrent

	SELECT
		@start_date = [start_date]
	FROM dbo.GLOBAL_VALUES AS GV
	WHERE fin_id = @fin_id1

	SELECT
		@end_date = end_date
	FROM dbo.GLOBAL_VALUES AS GV
	WHERE fin_id = @fin_id2

	IF @build_id1 IS NULL AND @occ1 IS NOT NULL 
	BEGIN  
		SELECT @build_id1=v.build_id
		FROM dbo.VOCC v
		WHERE v.occ=@occ1
    END
    
	SELECT @finPred=@fin_id1-1

	--PRINT @DateRegNull		
	--PRINT @start_date
	--PRINT @fin_id2	
	--PRINT @end_date

	;
	WITH cte AS	(
	SELECT *
	, (total_people_fin_1+people_plus-people_minus) AS total_people_fin_2
	FROM
		(SELECT
			S.name AS STREETS
		   ,voa.bldn_id AS build_id
		   ,B.nom_dom
		   ,voa.flat_id
		   ,voa.nom_kvr
		   ,voa.occ
		   ,voa.total_sq
		   ,voa.living_sq
		 --  ,(SELECT
			--		COUNT(P.id)
			--	FROM dbo.People AS P 
			--	JOIN dbo.Person_statuses PS ON 
			--		PS.id = P.Status2_id
			--	WHERE P.occ = voa.occ
			--		AND PS.is_kolpeople = 1
			--		AND COALESCE(P.DateReg, @DateRegNull) < @start_date
			--		AND (P.DateDel IS NULL	OR P.DateDel >= @start_date)
			--) AS total_people_fin_1
		   ,(SELECT
					COUNT(P.id)
				FROM dbo.People AS P 
				JOIN dbo.Person_statuses PS ON 
					PS.id = P.Status2_id
				WHERE P.occ = voa.occ
					AND PS.is_kolpeople = 1					
					AND EXISTS(SELECT 1 FROM dbo.People_history as ph WHERE ph.fin_id=@finPred and ph.owner_id=p.id)
			) AS total_people_fin_1
		 --  ,(SELECT
			--		COUNT(P.id)
			--	FROM dbo.People AS P 
			--	JOIN dbo.Person_statuses PS ON 
			--		PS.id = P.Status2_id
			--	WHERE occ = voa.occ
			--		AND PS.is_kolpeople = 1
			--		AND DateReg BETWEEN @start_date AND @end_date
			--) AS people_plus
			,(SELECT
					COUNT(P.id)
				FROM dbo.People AS P 
				JOIN dbo.Person_statuses PS ON 
					PS.id = P.Status2_id
				WHERE p.occ = voa.occ
					AND PS.is_kolpeople = 1
					AND p.DateDel is null
					AND NOT EXISTS(SELECT 1 FROM dbo.People_history as ph WHERE ph.fin_id=@finPred and ph.owner_id=p.id)
			) AS people_plus
		 --  ,(SELECT
			--		COUNT(P.id)
			--	FROM dbo.People AS P 
			--	JOIN dbo.Person_statuses PS ON 
			--		PS.id = P.Status2_id
			--	WHERE P.occ = voa.occ
			--		AND PS.is_kolpeople = 1
			--		AND P.DateDel BETWEEN @start_date AND @end_date
			--) AS people_minus
		   ,(SELECT
					COUNT(P.id)
				FROM dbo.People AS P 
				JOIN dbo.Person_statuses PS ON 
					PS.id = P.Status2_id
				WHERE P.occ = voa.occ
					AND PS.is_kolpeople = 1
					AND (
						(P.DateDel BETWEEN @start_date AND @end_date)
						OR
						(P.DateDel is not null AND P.DateEdit BETWEEN @start_date AND @end_date)
						)
					--AND EXISTS(SELECT 1 FROM dbo.People_history as ph WHERE ph.fin_id=@finPred and ph.owner_id=p.id)
			) AS people_minus
		   ,B.nom_dom_sort
		   ,voa.nom_kvr_sort
		FROM dbo.View_occ_all AS voa 
			JOIN dbo.Buildings AS B ON 
				voa.bldn_id = B.id
			JOIN dbo.VStreets AS S ON 
				S.id = B.street_id
			JOIN dbo.View_OCC_ALL AS voa2 ON 
				voa.occ = voa2.occ
		WHERE 
			voa.fin_id = @fin_id1
			AND voa2.fin_id = @fin_id2
			AND (@tip_id IS NULL OR voa.tip_id = @tip_id)
			AND (@build_id1 IS NULL OR voa.bldn_id = @build_id1)
			AND (@occ1 IS NULL OR voa.occ=@occ1)
			AND (@PrintGroup IS NULL
			OR EXISTS (SELECT
					1
				FROM dbo.PRINT_OCC AS po 
				WHERE po.occ = voa.occ
				AND po.group_id = @PrintGroup)
			) 
	 ) AS t
	)

	SELECT
		*
	FROM cte AS t
	WHERE 
		@only_izm = 0 
		OR (@only_izm = 1 AND people_plus <> 0 OR people_minus <> 0)
	ORDER BY t.STREETS
		, t.nom_dom_sort
		, t.nom_kvr_sort
	OPTION (RECOMPILE)
go

