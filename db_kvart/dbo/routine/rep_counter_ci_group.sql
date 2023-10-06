CREATE   PROCEDURE [dbo].[rep_counter_ci_group]
(
	@fin_id1		SMALLINT
	,@tip_id		SMALLINT	= NULL
	,@service_id    VARCHAR(10)	= NULL
)
AS
	/*
	
	exec rep_counter_ci_group 151,28
			
	*/
	SET NOCOUNT ON


	DECLARE	@fin_current	SMALLINT
			,@fin_pred		SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip_id, NULL, NULL, NULL)

	IF @fin_id1 IS NULL
		SET @fin_id1 = @fin_current
	SET @fin_pred = @fin_id1 - 1

	DECLARE @dolg TABLE
		(
			occ			INT	
			,service_id	VARCHAR(10)
			,kol		DECIMAL(15, 6)
		)

	INSERT INTO @dolg
		SELECT
			o.occ
			,i.service_id
			,i.kol/CASE WHEN COALESCE(o.kol_people,1)=0 THEN 1 ELSE o.kol_people END
		FROM dbo.View_OCC_ALL AS o
		JOIN dbo.View_BUILD_ALL AS b 
			ON o.bldn_id = b.bldn_id AND o.fin_id = b.fin_id
		JOIN dbo.COUNTER_PAYM_OCC AS i
			ON o.occ = i.occ AND o.fin_id = i.fin_id
		WHERE o.fin_id = @fin_id1
		AND o.tip_id = COALESCE(@tip_id, o.tip_id)
		AND o.status_id <> 'закр'
		AND i.Kol >= 0

	--SELECT * FROM @dolg ORDER BY OCC

	SELECT
		s.Name
		,COUNT(CASE
			WHEN dolg.kol >= 0 AND dolg.kol < 1 THEN dolg.occ ELSE NULL
		END) AS ooc1
		,COUNT(CASE
			WHEN dolg.kol >= 1 AND dolg.kol < 3 THEN dolg.occ ELSE NULL
		END) AS ooc3
		,COUNT(CASE
			WHEN dolg.kol >= 3 AND dolg.kol < 5 THEN dolg.occ ELSE NULL
		END) AS ooc5
		,COUNT(CASE
			WHEN dolg.kol >= 5 AND dolg.kol < 9 THEN dolg.occ ELSE NULL
		END) AS ooc9
		,COUNT(CASE
			WHEN dolg.kol >= 9 AND dolg.kol < 12 THEN dolg.occ ELSE NULL
		END) AS ooc12
		,COUNT(CASE
			WHEN dolg.kol >= 12 AND dolg.kol < 15 THEN dolg.occ ELSE NULL
		END) AS ooc15
		,COUNT(CASE
			WHEN dolg.kol >= 15 THEN dolg.occ ELSE NULL
		END) AS ooc_high
		--,COUNT(dolg.kol) AS kolITOG
		,COUNT(dolg.occ) AS occITOG
	FROM @dolg AS dolg
	JOIN dbo.SERVICES AS s
		ON dolg.service_id = s.id
	GROUP BY s.name
	ORDER BY s.Name

--select * from @dolg where kolmes=0
--select kolmes, COUNT(*) from @dolg group by kolmes
go

