CREATE   PROCEDURE [dbo].[rep_dom_raion]
(
	@div_id1	SMALLINT	= NULL --район
	,@street_id	INT			= NULL  -- Код улицы  
	,@sector_id	INT			= NULL  -- Код участка  
)
AS
/*
	Список домов по району(сортировка улица,дом)

	rep_dom_raion 5
*/
	SET NOCOUNT ON


	SELECT
		b.id
		,b.div_name AS raion
		,b.street_name AS streets
		,b.nom_dom
		,b.sector_id
		,b.levels
		,b.material_name AS Material
		,b.KolFlats as KolFlats
		,b.KolLic AS KolOcc
		,b.KolPeople as KolPeople
	FROM dbo.View_BUILDINGS AS b
	WHERE 
		b.div_id = COALESCE(@div_id1, b.div_id)
		AND b.sector_id = COALESCE(@sector_id, b.sector_id)
		AND b.street_id = COALESCE(@street_id, b.street_id)
	ORDER BY b.street_name, b.nom_dom_sort
go

