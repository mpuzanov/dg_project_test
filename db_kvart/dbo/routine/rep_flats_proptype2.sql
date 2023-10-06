CREATE   PROCEDURE [dbo].[rep_flats_proptype2]

(
	@fin_id		SMALLINT	= NULL
	,@town_id	SMALLINT	= NULL
	,@tip		SMALLINT	= NULL
	,@build		INT			= NULL
	,@socnaim	BIT			= NULL

)

AS
	/*
	Статусы квартир по домам
	
	дата создания:  20.01.13
	автор: Пузанов
	
	exec [rep_flats_proptype2] @build=1037
	
	*/

	SET NOCOUNT ON


	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip, @build, NULL, NULL)
	IF @fin_id IS NULL
		SET @fin_id = @fin_current

	SELECT
		b.adres
		,oh.proptype_id
		,COUNT(oh.occ) AS occ
		,SUM(oh.kol_people) AS kol_people
		,SUM(oh.total_sq) AS total_sq
	FROM dbo.View_OCC_ALL AS oh 
	JOIN dbo.View_BUILD_ALL AS b 
		ON b.fin_id = oh.fin_id
		AND b.bldn_id = oh.bldn_id
	WHERE (b.tip_id = @tip OR @tip IS NULL)
	AND (b.town_id = @town_id OR @town_id IS NULL)
	AND oh.fin_id = @fin_id
	AND oh.status_id <> 'закр'
	AND oh.socnaim = COALESCE(@socnaim, oh.socnaim)
	AND (b.bldn_id = @build
	OR @build IS NULL)
	GROUP BY	b.adres
				,oh.proptype_id
	ORDER BY b.adres
go

