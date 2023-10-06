CREATE   PROCEDURE [dbo].[adm_del_person]
(
	@id1 VARCHAR(10)   -- код статуса прописки
)
AS
	--
	--  Удалить статус прописки
	--
	SET NOCOUNT ON

	IF EXISTS (SELECT
				1
			FROM dbo.People
			WHERE Status2_id = @id1)
	BEGIN
		RAISERROR ('Удалить нельзя! Этот статус прописки используется! ', 16, 1)
		RETURN
	END
	ELSE
	BEGIN
		DELETE FROM Person_statuses
		WHERE id = @id1
	END
go

