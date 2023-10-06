-- =============================================
-- Author:		Пузанов
-- Create date: 29.12.07
-- Description:	для веб-сервисов
-- =============================================
CREATE   PROCEDURE [dbo].[ws_buildings]
(
	@street_id	INT			= NULL
	,@sector_id	SMALLINT	= NULL
	,@div_id	SMALLINT	= NULL
	,@tip_id	SMALLINT	= NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	IF @street_id = 0
		SET @street_id = NULL
	IF @sector_id = 0
		SET @sector_id = NULL
	IF @div_id = 0
		SET @div_id = NULL
	IF @tip_id = 0
		SET @tip_id = NULL

	--	if (@street_id is null) and (@sector_id is null) 
	--	   and (@div_id is null) and (@tip_id is null)
	--	RETURN


	SELECT
		ROW_NUMBER() OVER (ORDER BY s.Name, b.nom_dom_sort) AS RowNumber
		,b.id
		,s.Name AS street_name
		,nom_dom
		,sec.Name AS sector_name
		,d.Name AS div_name
		,ot.Name AS tip_name
		,b.index_id
		,CAST(b.OLD AS TINYINT) AS OLD
		,COALESCE(b.levels, 0) AS levels
		,b.comments
		,b.street_id
		,b.sector_id
		,b.div_id
		,b.tip_id
	FROM dbo.BUILDINGS AS b
	JOIN dbo.SECTOR AS sec
		ON b.sector_id = sec.id
	JOIN dbo.VSTREETS AS s
		ON b.street_id = s.id
	JOIN dbo.OCCUPATION_TYPES AS ot
		ON b.tip_id = ot.id
	JOIN dbo.DIVISIONS AS d
		ON b.div_id = d.id
	WHERE b.street_id = COALESCE(@street_id, b.street_id)
	AND b.sector_id = COALESCE(@sector_id, b.sector_id)
	AND div_id = COALESCE(@div_id, b.div_id)
	AND tip_id = COALESCE(@tip_id, b.tip_id)
	ORDER BY s.Name, nom_dom_sort

END
go

