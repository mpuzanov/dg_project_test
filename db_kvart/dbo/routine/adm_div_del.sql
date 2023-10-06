CREATE   PROCEDURE [dbo].[adm_div_del]
(
	@id1 SMALLINT
)
AS
	--
	--  Удаление района
	--
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT
				1
			FROM dbo.Buildings
			WHERE div_id = @id1)
	BEGIN
		DELETE FROM dbo.Divisions
		WHERE id = @id1
	END
	ELSE
		RAISERROR ('Район используется!', 16, 10)
go

