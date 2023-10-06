CREATE   PROCEDURE [dbo].[adm_readLgota]
(
	@Nom_lgot	 SMALLINT
   ,@service_id1 VARCHAR(10)
   ,@type1		 VARCHAR(10)
)
AS
	--
	--  Параметры льгот для редактирования
	--
	SET NOCOUNT ON

	SELECT
		dscgroup_id
	   ,service_id
	   ,PROPTYPE_ID
	   ,(Percentage * 100) as Percentage
	   ,owner_only
	   ,norma_only
	   ,nowork_only
	FROM dbo.discounts 
	WHERE dscgroup_id = @Nom_lgot
	AND service_id = @service_id1
	AND PROPTYPE_ID = @type1
go

