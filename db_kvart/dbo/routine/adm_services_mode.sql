CREATE   PROCEDURE [dbo].[adm_services_mode]
(
	@filter_build_id INT = NULL  -- фильтрация по дому где есть режимы и поставщики
)
/*
список услуг для кодификатора

exec adm_services_mode
exec adm_services_mode 6795
*/
AS
	SET NOCOUNT ON

	IF @filter_build_id IS NULL
		SELECT s.id
			 , s.name
			 , s.short_name
			 , s.service_no
		FROM dbo.View_services s 
		ORDER BY name --service_no
	ELSE
		SELECT s.id
			 , s.name
			 , s.short_name
			 , s.service_no
		FROM dbo.View_services s
		WHERE EXISTS (
				SELECT *
				FROM dbo.Build_mode bm
				WHERE bm.build_id = @filter_build_id
					AND bm.service_id = s.id
					AND (bm.mode_id % 1000) <> 0
			)
			OR EXISTS (
				SELECT *
				FROM dbo.Build_source bm
				WHERE bm.build_id = @filter_build_id
					AND bm.service_id = s.id
					AND (bm.source_id % 1000) <> 0
			)
		ORDER BY s.name
go

