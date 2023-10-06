CREATE   PROCEDURE [dbo].[adm_servunits]
(
	@fin_id1   SMALLINT -- Код фин. периода
   ,@tip_id1   SMALLINT -- тип жилого фонда
   ,@serv1	   VARCHAR(10) = NULL -- код услуги
   ,@roomtype1 VARCHAR(10) = NULL  -- тип квартиры    'отдк' 'комм' 'об10' 'об06'
)
AS
	/*
	adm_servunits 212, 28, 'площ', 'отдк'
	adm_servunits 212, 28, 'площ'
	*/
	SET NOCOUNT ON

	IF @roomtype1 IS NOT NULL
		SELECT
			fin_id
		   ,tip_id
		   ,service_id
		   ,roomtype_id
		   ,unit_id
		FROM dbo.Service_units 
		WHERE fin_id = @fin_id1
		AND service_id = @serv1
		AND tip_id = @tip_id1
		AND roomtype_id = @roomtype1
	ELSE
		SELECT
			fin_id
		   ,tip_id
		   ,service_id		   
		   ,MAX(CASE WHEN roomtype_id='отдк' THEN unit_id ELSE NULL END) as unit_id_otd
		   ,MAX(CASE WHEN roomtype_id='комм' THEN unit_id ELSE NULL END) as unit_id_kom
		   ,MAX(CASE WHEN roomtype_id='об10' THEN unit_id ELSE NULL END) as unit_id_ob10
		   ,MAX(CASE WHEN roomtype_id='об06' THEN unit_id ELSE NULL END) as unit_id_ob6
		FROM dbo.Service_units
		WHERE fin_id = @fin_id1
		AND tip_id = @tip_id1
		AND (service_id = @serv1 OR @serv1 IS NULL)
		GROUP BY fin_id, tip_id, service_id
go

