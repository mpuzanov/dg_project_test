CREATE   PROCEDURE [dbo].[rep_added_2]
(
	@fin_id1		SMALLINT	= 0
	,@jeu1			SMALLINT	= NULL
	,@build1		INT			= NULL
	,@type_id1		INT			= NULL
	,@tip			SMALLINT	= NULL
	,@div_id1		SMALLINT	= NULL
	,@tip_counter	SMALLINT	= NULL-- тип счетчика
	,@sup_id		INT			= NULL
)
AS
/*
	Ведомость по перерасчетам
	Отчет: add_1.fr3
		
	exec rep_added_2 @fin_id1=255,@tip=1
	
*/
	SET NOCOUNT ON

	IF COALESCE(@fin_id1, 0) = 0
		SET @fin_id1 = dbo.Fun_GetFinCurrent(@tip, @build1, NULL, NULL)
	
	SELECT
		ap.Occ
		,o.address AS address
		,adt.short_name
		,serv.short_name AS service_id
		,SUM(ap.VALUE) AS VALUE
	FROM dbo.View_added AS ap 
	JOIN dbo.Occupations o
		ON ap.Occ = o.Occ
	JOIN dbo.Flats f 
		ON o.flat_id = f.id
	JOIN dbo.View_buildings AS b 
		ON f.bldn_id = b.id
	JOIN dbo.Added_Types AS adt 
		ON ap.add_type = adt.id
	JOIN dbo.View_services AS serv
		ON ap.service_id = serv.id
	WHERE 
		ap.fin_id = @fin_id1
		AND (b.id = @build1 OR @build1 IS NULL)
		AND (b.tip_id = @tip OR @tip IS NULL)
		AND (b.sector_id = @jeu1 OR @jeu1 IS NULL)
		AND (b.div_id = @div_id1 OR @div_id1 IS NULL)
		AND (ap.add_type = @type_id1 OR @type_id1 IS NULL)
		AND (ap.sup_id = @sup_id OR @sup_id IS NULL)
	GROUP BY	ap.Occ
				,adt.short_name
				,o.address
				,serv.short_name
	ORDER BY ap.Occ
go

