CREATE   PROCEDURE [dbo].[adm_div_add]
(
	@name	 VARCHAR(30)
   ,@town_id SMALLINT = NULL
)
AS
	--
	--  Добавление нового района
	--
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT
				*
			FROM dbo.Divisions
			WHERE name = @name
			AND COALESCE(town_id, 1) = COALESCE(@town_id, 1))
	BEGIN
		DECLARE @id1 SMALLINT

		BEGIN TRANSACTION

		SELECT
			@id1 = COALESCE(MAX(id), 0) + 1
		FROM dbo.Divisions

		INSERT INTO dbo.Divisions
		(id
		,name
		,town_id)
		VALUES (@id1
			   ,@name
			   ,@town_id)

		COMMIT TRANSACTION
	END
	ELSE
		RAISERROR ('Район %s уже есть в этом населённом пункте!', 16, 10, @name)
go

