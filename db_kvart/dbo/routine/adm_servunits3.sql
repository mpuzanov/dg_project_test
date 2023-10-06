CREATE   PROCEDURE [dbo].[adm_servunits3]
(
	@fin_id1   SMALLINT -- Код фин. периода
   ,@tip_id1   SMALLINT -- тип жилого фонда
   ,@serv1	   VARCHAR(10) = NULL -- код услуги
   ,@roomtype1 VARCHAR(10) = NULL -- тип квартиры    'отдк' 'комм' 'об10' 'об06'
)
AS
	/*
	adm_servunits3 212, 28, 'площ', 'отдк'
	adm_servunits3 212, 28, 'площ'
	adm_servunits3 211, 28
	*/
	SET NOCOUNT ON

	SELECT 
		su.fin_id
		,su.tip_id as tip_id
		,su.service_id as service_id
		,s.name as serv_name
		,rt.id as roomtype_id
		,rt.name as roomtype_name
		,su.unit_id
	FROM dbo.Service_units  as su 
		JOIN dbo.Services as s ON su.service_id=s.id
		JOIN dbo.Room_types as rt ON su.roomtype_id=rt.id
	WHERE su.fin_id = @fin_id1
		AND su.tip_id = @tip_id1
		AND (su.service_id = @serv1
		OR @serv1 IS NULL)
		AND (su.roomtype_id = @roomtype1
		OR @roomtype1 IS NULL)
	ORDER BY s.name,rt.name
go

