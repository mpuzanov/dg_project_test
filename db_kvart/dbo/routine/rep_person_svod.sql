CREATE   PROCEDURE [dbo].[rep_person_svod]
(
	@tip_str1 VARCHAR(2000)-- список типов фонда через запятую
)
AS
	/*
	  Отчет по обработке персональных данных

	  exec rep_person_svod '1,2'
	*/
	SET NOCOUNT ON

	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

	--************************************************************************************
	-- Таблица значениями Типа жил.фонда
	CREATE TABLE #tip_table (tip_id SMALLINT PRIMARY KEY)
	INSERT INTO #tip_table(tip_id)
	SELECT vs.id
	FROM dbo.VOcc_types AS vs
		OUTER APPLY STRING_SPLIT(@tip_str1, ',') AS t
	WHERE @tip_str1 IS NULL OR t.value=vs.id
	--select * from @tip_table
	--************************************************************************************

	SELECT
		t.name AS tip_name
		,d.name AS div_name
		,(SELECT
				COUNT(*)
			FROM dbo.PEOPLE AS p1
			JOIN dbo.VOCC AS o1 
				ON p1.occ = o1.occ
			JOIN dbo.FLATS AS f1 
				ON o1.flat_id = f1.id
			JOIN dbo.BUILDINGS AS b1 
				ON f1.bldn_id = b1.id
			JOIN dbo.DIVISIONS AS d1 
				ON b1.div_id = d1.id
			JOIN dbo.OCCUPATION_TYPES AS t1 
				ON b1.tip_id = t1.id
			WHERE p1.dateoznac IS NOT NULL
			AND d1.name = d.name
			AND t1.name = t.name)
		AS Oznac
		,(SELECT
				COUNT(*)
			FROM dbo.PEOPLE AS p1
			JOIN dbo.VOCC AS o1 
				ON p1.occ = o1.occ
			JOIN dbo.FLATS AS f1
				ON o1.flat_id = f1.id
			JOIN dbo.BUILDINGS AS b1 
				ON f1.bldn_id = b1.id
			JOIN dbo.DIVISIONS AS d1 
				ON b1.div_id = d1.id
			JOIN dbo.OCCUPATION_TYPES AS t1 
				ON b1.tip_id = t1.id
			WHERE p1.datesoglacie IS NOT NULL
			AND d1.name = d.name
			AND t1.name = t.name)
		AS Soglacie
		,COUNT(*) AS kol
	FROM dbo.PEOPLE AS p 
	JOIN dbo.VOCC AS o 
		ON p.occ = o.occ
	JOIN dbo.FLATS AS f
		ON o.flat_id = f.id
	JOIN dbo.BUILDINGS AS b 
		ON f.bldn_id = b.id
	JOIN dbo.DIVISIONS AS d 
		ON b.div_id = d.id
	JOIN dbo.OCCUPATION_TYPES AS t 
		ON b.tip_id = t.id
	WHERE o.status_id <> 'закр'
	AND EXISTS (SELECT
			1
		FROM #tip_table
		WHERE tip_id = o.tip_id)
	GROUP BY	t.name
				,d.name
	ORDER BY t.name, d.name

DROP TABLE IF EXISTS #tip_table;
go

