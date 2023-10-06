CREATE   PROCEDURE [dbo].[rep_added_svod2]
(
	@fin_id1		SMALLINT	= 0
	,@jeu1			SMALLINT	= NULL
	,@build1		INT			= NULL
	,@type_id1		INT			= NULL
	,@tip			SMALLINT	= NULL
	,@div_id1		SMALLINT	= NULL
	,@tip_counter	SMALLINT	= NULL -- тип счетчика
	,@sup_id		INT			= NULL
)
AS
	/*
	Свод по перерасчетам
	
	отчет: add_svod.fr3
	
	rep_added_svod2 171,null,1030
	
	*/
	SET NOCOUNT ON


	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip, @build1, NULL, NULL)
	IF (@fin_current <= @fin_id1)
		OR (@fin_id1 = 0)
		SET @fin_id1 = @fin_current

	CREATE TABLE #s
	(
		id			VARCHAR(10) COLLATE database_default	PRIMARY KEY
		,name		VARCHAR(100) COLLATE database_default
		,short_name	VARCHAR(20) COLLATE database_default
	)
	INSERT
	INTO #s
	(	id
		,name
		,short_name)
		SELECT
			id
			,name
			,short_name
		FROM dbo.View_SERVICES

	SELECT
		b.sector_name AS jeu
		,adt.name AS addtype_name
		,s.short_name AS service_id
		,SUM(ap.VALUE) AS VALUE
	FROM dbo.View_ADDED AS ap 
	JOIN dbo.View_OCC_ALL AS o
		ON ap.fin_id = o.fin_id
		AND ap.occ = o.occ
	JOIN dbo.FLATS AS f 
		ON o.flat_id = f.id
	JOIN dbo.View_BUILD_ALL AS b 
		ON o.fin_id = b.fin_id
		AND f.bldn_id = b.bldn_id
	JOIN dbo.ADDED_TYPES AS adt 
		ON ap.add_type = adt.id
	JOIN #s AS s
		ON ap.service_id = s.id
	WHERE ap.fin_id = @fin_id1
		AND (b.bldn_id = @build1 OR @build1 IS NULL)
		AND (b.tip_id =@tip OR @tip IS NULL)
		AND b.sector_id = COALESCE(@jeu1, b.sector_id)
		AND b.div_id = COALESCE(@div_id1, b.div_id)
		AND adt.id = COALESCE(@type_id1, adt.id)
		AND (ap.sup_id = @sup_id
		OR @sup_id IS NULL)
	--AND cl.is_counter = COALESCE(@tip_counter, cl.is_counter)
	GROUP BY	b.sector_name
				,adt.name
				,s.short_name
go

