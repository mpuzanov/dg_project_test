CREATE   PROCEDURE [dbo].[adm_del_jeu]
(
	@jeu1 INT
)
AS
	--
	--  Удаляем участок
	--

	SET NOCOUNT ON

	-- Проверяем есть ли дом обсуживаемый этим участком участком
	IF EXISTS (SELECT
				1
			FROM dbo.BUILDINGS
			WHERE sector_id = @jeu1)
	BEGIN
		RAISERROR ('Удалить нельзя! Так как есть дом обсуживаемый этим участком', 16, 1)
		RETURN 1
	END

	DELETE FROM dbo.SECTOR
	WHERE id = @jeu1

	DELETE FROM dbo.SECTOR_TYPES
	WHERE sector_id = @jeu1
go

