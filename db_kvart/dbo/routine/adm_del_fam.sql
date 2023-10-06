CREATE   PROCEDURE [dbo].[adm_del_fam]
(
	@fam_id1 VARCHAR(10)
)
AS

	SET NOCOUNT ON

	IF NOT EXISTS (SELECT
				1
			FROM dbo.PEOPLE
			WHERE Fam_id = @fam_id1)
	BEGIN
		DELETE FROM dbo.FAM_RELATIONS
		WHERE id = @fam_id1
	END
	ELSE
		RAISERROR ('Этот тип используется! Его удалить нельзя!', 16, 1)
go

