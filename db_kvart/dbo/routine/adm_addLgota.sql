CREATE   PROCEDURE [dbo].[adm_addLgota]
(
	@Nom_Lgota	 SMALLINT
   ,@service_id1 VARCHAR(10)
   ,@Prop_types1 VARCHAR(10)
   ,@Proc1		 MONEY
   ,@O1			 BIT
   ,@N1			 BIT
   ,@W1			 BIT
)
AS
	--
	-- Добавляем или изменяем скидки по услугам
	--
	--*******************************************************************
	SET NOCOUNT ON

	SELECT
		@Proc1 = @Proc1 * 0.01

	--*****************************************************
	IF EXISTS (SELECT
				*
			FROM DISCOUNTS
			WHERE dscgroup_id = @Nom_Lgota
			AND service_id = @service_id1
			AND PROPTYPE_ID = @Prop_types1)
	BEGIN
		UPDATE dbo.Discounts
		SET Percentage  = @Proc1
		   ,Owner_only  = @O1
		   ,Norma_only  = @N1
		   ,NoWork_only = @W1
		WHERE dscgroup_id = @Nom_Lgota
		AND service_id = @service_id1
		AND PROPTYPE_ID = @Prop_types1
	END
	ELSE
	BEGIN
		INSERT INTO dbo.Discounts
		(dscgroup_id
		,service_id
		,PROPTYPE_ID
		,Percentage
		,Owner_only
		,Norma_only
		,Nowork_only)
		VALUES (@Nom_Lgota
			   ,@service_id1
			   ,@Prop_types1
			   ,@Proc1
			   ,@O1
			   ,@N1
			   ,@W1)
	END
go

