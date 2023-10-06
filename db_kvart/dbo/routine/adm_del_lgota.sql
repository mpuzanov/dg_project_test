CREATE   PROCEDURE [dbo].[adm_del_lgota]
(
	@lgota_id1 INT
)
AS

	SET NOCOUNT ON

	IF NOT EXISTS (SELECT
				1
			FROM dbo.DSC_OWNERS
			WHERE dscgroup_id = @lgota_id1)
		AND NOT EXISTS (SELECT
				1
			FROM dbo.PEOPLE
			WHERE lgota_id = @lgota_id1)
	BEGIN
		DELETE FROM dbo.DSC_GROUPS
		WHERE id = @lgota_id1
	END
	ELSE
		RAISERROR (N'Эта льгота используется! Её удалить нельзя!', 16, 1)
go

