CREATE   PROCEDURE [dbo].[k_counter_modes]
(
	  @build_id1 INT  -- код дома
)
AS
	/*
	Показывает список услуг по дому для ПУ
	
	k_counter_modes 6774
	*/
	SET NOCOUNT ON

	SELECT DISTINCT s.id
				  , s.name AS short_name
				  , s.name AS [name]
					--mode_name=cm.name,
					--source_name=sp.name,
				  , s.service_no
	FROM dbo.Flats AS f 
		JOIN dbo.Occupations AS o ON o.flat_id = f.id
		JOIN dbo.Consmodes_list AS cl ON cl.occ = o.occ
		JOIN dbo.View_services AS s ON s.id = cl.service_id
	WHERE f.bldn_id = @build_id1
		AND ((cl.mode_id % 1000) <> 0 OR (cl.source_id % 1000) <> 0)
		AND s.is_counter = 1
	ORDER BY s.name
go

