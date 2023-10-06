CREATE   PROCEDURE [dbo].[rep_inf_dom]
(
	@tip_id		SMALLINT	= NULL
	,@div_id	SMALLINT	= NULL
	,@jeu		SMALLINT	= NULL
	,@build		INT			= NULL
)
AS
	/*
	
	Отчёт по статусам квартир по домам
	
	rep_inf_dom 28
	*/
	SET NOCOUNT ON

	IF @tip_id IS NULL
		AND @div_id IS NULL
		AND @jeu IS NULL
		SET @tip_id = 0

	SELECT
		d.name AS div_name
		,o.jeu
		,s.name AS street_name
		,b.nom_dom
		,o.proptype_id
		,COUNT(DISTINCT o.flat_id) AS kol_flat
		,COUNT(o.occ) AS occ
		,SUM(o.kol_people) AS kol_people
		,SUM(o.Total_sq) AS Total_sq
	FROM dbo.VOCC AS o 
	JOIN dbo.BUILDINGS AS b
		ON o.bldn_id = b.id
	JOIN dbo.VSTREETS AS s 
		ON b.street_id = s.id
	JOIN dbo.DIVISIONS AS d 
		ON b.div_id = d.id
	WHERE 1=1
		AND (@tip_id is NULL OR b.tip_id = @tip_id)
		AND (@div_id is null OR b.div_id = @div_id)
		AND (@jeu is null or b.sector_id = @jeu)
		AND (@build is null OR b.id = @build)
		AND o.Status_id <> 'закр'
	GROUP BY	d.name
				,o.jeu
				,s.name
				,b.nom_dom
				,o.proptype_id
	ORDER BY s.name, MIN(b.nom_dom_sort)
go

