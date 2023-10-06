CREATE   PROCEDURE [dbo].[adm_DelStreets]
(
	@id1 INT
)
AS
	--
	--  Удаляем улицу
	--
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT
				1
			FROM dbo.BUILDINGS
			WHERE street_id = @id1)
		AND NOT EXISTS (SELECT
				1
			FROM dbo.BUILDINGS_HISTORY
			WHERE street_id = @id1)
	BEGIN
		DELETE FROM dbo.STREETS
		WHERE id = @id1
	END
	ELSE
	BEGIN
		DECLARE @street_name VARCHAR(50)
		SELECT
			@street_name = name
		FROM dbo.STREETS S
		WHERE id = @id1
		RAISERROR ('Улица <%s> используется в истории по домам! Удалить её нельзя!', 16, 1, @street_name)
	END
go

