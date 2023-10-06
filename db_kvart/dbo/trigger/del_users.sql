CREATE   TRIGGER [dbo].[del_users]
ON [dbo].[Users]
FOR DELETE
AS
	SET NOCOUNT ON

	DECLARE @login1	  VARCHAR(25)
		   ,@msg	  VARCHAR(80)
		   ,@user_id1 INT

	SELECT
		@login1 = d.login
	   ,@user_id1 = d.id
	FROM DELETED AS d

	IF (@login1 = 'sa')
		OR (@login1 = 'dbo')
	BEGIN
		SELECT
			@msg = CONCAT('Пользователя <',@login1,'> удалять нельзя! ')
		RAISERROR (@msg, 16, 10)
		ROLLBACK TRAN
		RETURN
	END

	IF EXISTS (SELECT
				1
			FROM Op_Log AS o
			WHERE o.user_id = @user_id1)
	BEGIN
		SELECT
			@msg = CONCAT('Пользователя <',@login1,'> удалить нельзя! Т.к. он уже изменял лицевые счета')
		RAISERROR (@msg, 16, 10)
		ROLLBACK TRAN
		RETURN
	END
go

