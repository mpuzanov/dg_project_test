CREATE   PROCEDURE [dbo].[k_replgot]
(
	  @occ1 INT
	, @prop1 VARCHAR(10) = NULL
)
AS
	SET NOCOUNT ON

	SELECT DISTINCT dsc1.name
				  , s.service_no
				  , dsc.*
				  , s.short_name
	FROM dbo.People AS p 
		JOIN dbo.Occupations AS o ON p.occ = o.occ
		JOIN dbo.Discounts AS dsc ON p.lgota_id = dsc.dscgroup_id
		JOIN dbo.View_services AS s ON dsc.service_id = s.id
		JOIN dbo.Dsc_groups AS dsc1 ON dsc.dscgroup_id = dsc1.id
	WHERE p.occ = @occ1
		AND p.lgota_id <> 0
		AND dsc.proptype_id = COALESCE(@prop1, o.proptype_id)

	ORDER BY dsc.dscgroup_id
		   , s.service_no
go

