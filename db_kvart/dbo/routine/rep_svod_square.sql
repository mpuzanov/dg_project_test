CREATE   PROCEDURE [dbo].[rep_svod_square]
(
	@fin_id1	SMALLINT	= NULL
	,@tip_id1	SMALLINT	= NULL
	,@jeu1		SMALLINT	= NULL
	,@dom		INT			= NULL
)
AS
/*
Информация по площади в домах

exec rep_svod_square 250, 1
*/
	--*******************************************************************
	SET NOCOUNT ON

	IF @fin_id1 IS NULL
		SET @fin_id1 = dbo.Fun_GetFinCurrent(@tip_id1, @dom, NULL, NULL)

	SELECT
		t.name AS tip
		,b.sector_id AS jeu
		,sec.name AS sec_name
		,CurrentDate
		,s.name AS street
		,b.nom_dom AS nom_dom
		,SUM(d.SQUARE) AS [square]
		,SUM(d.SquareLive) AS SquareLive
	FROM dbo.Dom_svod AS d
		JOIN dbo.Buildings AS b
			ON d.build_id = b.id
		JOIN dbo.VOcc_types AS t
			ON b.tip_id = t.id
		JOIN dbo.VStreets AS s
			ON s.id = b.street_id
		JOIN dbo.Sector AS sec 
			ON b.sector_id = sec.id
	WHERE 
		d.fin_id = @fin_id1
		AND b.tip_id = COALESCE(@tip_id1, b.tip_id)
		AND b.sector_id = COALESCE(@jeu1, b.sector_id)
		AND b.id = COALESCE(@dom, b.id)
	GROUP BY	t.name
				,b.sector_id
				,sec.name
				,CurrentDate
				,s.name
				,b.nom_dom
	ORDER BY b.sector_id, s.name, MIN(b.nom_dom_sort)
go

