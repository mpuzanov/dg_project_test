CREATE   TRIGGER [dbo].[MODES_READONLY]
ON [dbo].[Consmodes_list]
FOR INSERT, UPDATE, DELETE
AS
	SET NOCOUNT ON

	IF system_user = 'sa'
		RETURN

	DECLARE	@user_id1	SMALLINT
			,@occ1		INT
			,@state_id	VARCHAR(10)

	SELECT TOP(1)
		@occ1 = occ
		,@state_id = dbo.Fun_GetRejimOcc(occ)
		,@user_id1 = dbo.Fun_GetCurrentUserId()
	FROM DELETED AS D

	IF EXISTS (SELECT
				1
			FROM dbo.Group_membership
			WHERE group_id = 'оптч'
			AND user_id = @user_id1)
		OR (@state_id <> 'норм')
	BEGIN

		IF NOT EXISTS (SELECT
					dbo.Fun_AccessPayLic())
		BEGIN
			--RAISERROR ('У Вас доступ только для чтения', 16, 1)  WITH NOWAIT;		
			ROLLBACK TRAN
			RETURN
		END

	END
go

