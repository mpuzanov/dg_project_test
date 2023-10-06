CREATE   PROCEDURE [dbo].[rep_dom_svod]
(
	@sector		SMALLINT	= NULL
	,@fin_id1	SMALLINT	= NULL
	,@tip		SMALLINT	= NULL
	,@town_id	SMALLINT	= NULL
)
AS
	/*

rep_dom_svod @tip=28,@fin_id1=173

reports: domsvod.fr3

*/
	SET NOCOUNT ON


	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

	IF @fin_id1 IS NULL
		SET @fin_id1 = @fin_current


	SELECT
		b.street_name AS NAME
		,b.sector_id
		,b.sector_name AS sec_name
		,b.nom_dom
		,d.CountFlats AS flat
		,d.*
	FROM dbo.DOM_SVOD AS d 
	JOIN dbo.View_BUILD_ALL AS b 
		ON d.build_id = b.bldn_id
		AND d.fin_id = b.fin_id
	WHERE b.sector_id = COALESCE(@sector, b.sector_id)
	AND (b.tip_id = @tip
	OR @tip IS NULL)
	AND d.fin_id = @fin_id1
	AND b.town_id = COALESCE(@town_id, b.town_id)
	ORDER BY b.sector_id
	, b.street_name
	, b.nom_dom_sort
go

