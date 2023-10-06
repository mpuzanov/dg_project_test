CREATE   PROCEDURE [dbo].[adm_ShowPersonServ]
(
	@status_id1 VARCHAR(10)
   ,@paym		BIT = 1
)
AS
	/*
		Список услуг на которые надо или не надо начислять
		в зависимости от статуса прописки
	
		exec adm_ShowPersonServ @status_id1='пост', @paym=0
		exec adm_ShowPersonServ @status_id1='пост', @paym=1
	*/
	SET NOCOUNT ON

	IF @paym = 1
	BEGIN
		SELECT
			s.id
		   ,s.name
		   ,a.is_rates
		FROM dbo.person_calc AS a 
		JOIN dbo.View_services AS s 
			ON a.service_id = s.id
		WHERE 
			a.have_paym = @paym
			AND a.status_id = @status_id1
		ORDER BY name
	END
	IF @paym = 0
	BEGIN
		SELECT
			id
		   ,name
		   ,1 AS is_rates
		FROM dbo.View_services 
		WHERE NOT EXISTS (SELECT
				1
			FROM dbo.person_calc 
			WHERE have_paym = 
				cast(1 as bit)
				AND status_id = @status_id1
				AND service_id = id)
		ORDER BY name
	END
go

