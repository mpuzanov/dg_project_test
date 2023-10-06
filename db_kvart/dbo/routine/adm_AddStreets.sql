CREATE   PROCEDURE [dbo].[adm_AddStreets]
(
	@name1	 VARCHAR(30)
   ,@town_id SMALLINT = NULL
)
AS
	/*
		Добавляем улицу
		adm_AddStreets 'Ленина 888',1
	*/

	SET NOCOUNT ON

	DECLARE @id1 INT
	IF @town_id IS NULL
		SET @town_id = 1

	BEGIN TRAN

		SELECT
			@id1 = MAX(id)
		FROM STREETS

		SET @id1 = COALESCE(@id1, 0) + 1

		INSERT INTO STREETS
		(id
		,name
		,town_id)
		VALUES (@id1
			   ,@name1
			   ,@town_id)

		COMMIT TRAN
go

