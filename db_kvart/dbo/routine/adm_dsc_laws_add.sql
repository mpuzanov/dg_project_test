CREATE   PROCEDURE [dbo].[adm_dsc_laws_add]
(
	@name1 VARCHAR(30)
)
AS
	/*
	 Добавление нового закона по льготам
	*/
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT
				1
			FROM DSC_LAWS
			WHERE name = @name1)
	BEGIN
		BEGIN TRAN

		DECLARE @id1 INT
		SELECT
			@id1 = COALESCE(MAX(id), 0) + 1
		FROM dbo.DSC_LAWS

		INSERT INTO dbo.DSC_LAWS
		(id
		,name)
		VALUES (@id1
			   ,@name1)

		COMMIT TRAN
	END
go

