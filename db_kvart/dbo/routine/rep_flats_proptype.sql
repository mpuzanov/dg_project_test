CREATE   PROCEDURE [dbo].[rep_flats_proptype]

(
	@fin_id		SMALLINT	= NULL
	,@tip		SMALLINT	= NULL
	,@build		INT			= NULL
	,@socnaim	BIT			= NULL

)

AS
	/*
	Статусы квартир по районам в разрезе участков
	
	дата создания:  6.04.09
	автор: Пузанов
	
	
	*/

	SET NOCOUNT ON


	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)
	IF @fin_id IS NULL
		SET @fin_id = @fin_current

	SELECT
		divname = d.Name
		,sector = b.sector_id
		,oh.PROPTYPE_ID
		,COUNT(oh.occ) AS occ
		,SUM(oh.kol_people) AS kol_people
		,SUM(oh.total_sq) AS total_sq
	FROM dbo.View_OCC_ALL AS oh 
	JOIN dbo.View_BUILD_ALL AS b 
		ON b.fin_id = oh.fin_id AND oh.bldn_id = b.bldn_id
	JOIN dbo.DIVISIONS AS d 
		ON b.div_id = d.id
	WHERE 1=1
		AND b.tip_id = COALESCE(@tip, b.tip_id)
		AND oh.fin_id = @fin_id
		AND oh.status_id <> 'закр'
		AND oh.SOCNAIM = COALESCE(@socnaim, oh.SOCNAIM)
		AND b.bldn_id = COALESCE(@build, b.bldn_id)
	GROUP BY	d.Name
				,b.sector_id
				,oh.PROPTYPE_ID
	ORDER BY d.Name, b.sector_id
go

