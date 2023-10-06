CREATE   TRIGGER [dbo].[ADDED_PAYMENTS_READONLY]
ON [dbo].[Added_Payments]
FOR INSERT, UPDATE, DELETE
AS
	SET NOCOUNT ON;

	DECLARE	@state_id	VARCHAR(10)
			,@user_id1	SMALLINT

	SELECT TOP(1)
		@state_id = dbo.Fun_GetRejimOcc(occ)
		,@user_id1 = dbo.Fun_GetCurrentUserId()
	FROM INSERTED AS i

	IF EXISTS (SELECT
				1
			FROM dbo.Group_membership
			WHERE group_id = 'оптч'
			AND user_id = @user_id1)
		OR (@state_id <> 'норм')
	BEGIN
		--RAISERROR ('У Вас доступ только для чтения', 16, 1);	
		ROLLBACK TRAN
		RETURN
	END
go

