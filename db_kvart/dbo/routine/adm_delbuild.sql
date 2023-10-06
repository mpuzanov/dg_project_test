CREATE   PROCEDURE [dbo].[adm_delbuild]
(
	@bldn_id1 INT
)
AS
	SET NOCOUNT ON

	IF EXISTS (SELECT
				1
			FROM dbo.View_OCC_ALL AS voa
			WHERE bldn_id = @bldn_id1)
	BEGIN
		RAISERROR ('Дом удалить нельзя! В доме есть лицевые счета.', 16, 1)
		RETURN 1
	END

	DELETE FROM BUILDINGS
	WHERE id = @bldn_id1
go

