CREATE   PROCEDURE [dbo].[rep_flat_modes_2]
(
	@street_id1	SMALLINT
	,@nom_dom1	VARCHAR(7) = null
)
AS
/*
	-- Информация о квартире в доме

	rep_flat_modes_2 11

*/
	SET NOCOUNT ON


	SELECT
		cl.occ
		,s.short_name
		,cm.name
		,sm.name
	FROM (SELECT
			o.occ AS occ1
		FROM dbo.OCCUPATIONS AS o 
		JOIN dbo.FLATS AS f 
			ON f.id = o.flat_id
		JOIN dbo.BUILDINGS AS b 
			ON b.id = f.bldn_id
		WHERE b.street_id = @street_id1
		AND b.nom_dom = @nom_dom1
		) AS o1
	JOIN dbo.CONSMODES_LIST AS cl 
		ON cl.occ = o1.occ1
	JOIN dbo.CONS_MODES AS cm 
		ON cl.mode_id = cm.id
	JOIN dbo.View_SUPPLIERS AS sm 
		ON cl.source_id = sm.id
	JOIN dbo.View_SERVICES AS s 
		ON cl.service_id = s.id
go

