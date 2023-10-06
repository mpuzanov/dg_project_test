
CREATE PROCEDURE [dbo].[k_gis_update_serv_pd]
(
	@tip_id SMALLINT
)
AS
	/*
	k_gis_update_serv_pd 169
	*/
	SET NOCOUNT ON


	UPDATE st
	SET st.[service_name_gis] = stg.service_name_gis
	FROM [dbo].[SERVICES_TYPES] st
	LEFT JOIN [dbo].[SERVICES_TYPE_GIS] stg
		ON st.tip_id = stg.tip_id
	WHERE st.tip_id = @tip_id
	AND COALESCE(st.[service_name_gis], '') = ''
	AND st.[service_name] = stg.service_name_gis

	-- убираем наименования услуг, которых нет в [SERVICES_TYPE_GIS]
	UPDATE st
	SET st.[service_name_gis] = ''
	FROM [dbo].[SERVICES_TYPES] st
	LEFT JOIN [dbo].[SERVICES_TYPE_GIS] stg
		ON st.tip_id = stg.tip_id AND st.service_name_gis = stg.service_name_gis
	WHERE st.tip_id = @tip_id
	AND stg.[service_name_gis] IS null


	-- Присваивание отдельных услуг
	UPDATE st
	SET st.[service_name_gis] = 'Взнос на капитальный ремонт'
	FROM [dbo].[SERVICES_TYPES] st
	WHERE st.tip_id = @tip_id
	AND COALESCE(st.[service_name_gis], '') = ''
	AND st.[service_id] = 'Крем'

go

