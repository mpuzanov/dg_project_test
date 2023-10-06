CREATE   PROCEDURE [dbo].[adm_del_status]
(
	@id1 SMALLINT
)
AS

	SET NOCOUNT ON

	IF NOT EXISTS (SELECT 1
			FROM dbo.People
			WHERE status_id = @id1)
	BEGIN
		DELETE FROM dbo.Status
		WHERE Id = @id1
	END
	ELSE
		RAISERROR ('Этот статус  используется! Его удалить нельзя!', 16, 10)
go

