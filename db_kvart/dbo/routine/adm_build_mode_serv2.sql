CREATE   PROCEDURE [dbo].[adm_build_mode_serv2]
(
	@build_id1	 INT
   ,@service_id1 VARCHAR(10)
)
AS
	/*
		Вывести все режимы потребления которых нет по заданному дому и по заданной услуге
		
		adm_build_mode_serv2 1047, 'ремт'
	*/
	SET NOCOUNT ON

	DECLARE @fin_id SMALLINT
		   ,@tip_id SMALLINT
	SELECT
		@fin_id = b.fin_current
	   ,@tip_id = b.tip_id
	FROM Buildings AS b 
	WHERE id = @build_id1

	SELECT
		cm.id
	   ,cm.service_id
	   ,cm.name
	   ,cm.comments
	   ,cm.unit_id
	   ,[dbo].[Fun_GetTarifStrServ](@fin_id, @tip_id, @service_id1, cm.id) AS tarif
	FROM dbo.Cons_modes AS cm 
	WHERE service_id = @service_id1
go

