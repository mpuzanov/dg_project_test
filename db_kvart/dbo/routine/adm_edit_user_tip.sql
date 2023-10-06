CREATE   PROCEDURE [dbo].[adm_edit_user_tip]
(
	@user_id1 SMALLINT
   ,@tip_id1  SMALLINT
   ,@add1	  BIT = 1--добавить             0-убрать доступ
)
AS
	/*
	 
	 Добавляем или убираем доступ пользователей к определенным программам  
	 adm_edit_user_tip @user_id1, @tip_id1, @add1
	 
	*/
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @login1 VARCHAR(30)

	SELECT
		@login1 = login
	FROM dbo.USERS
	WHERE id = @user_id1

	IF @add1 = 1
	BEGIN
		IF NOT EXISTS (SELECT
					*
				FROM dbo.USERS_OCC_TYPES AS pa 
				WHERE pa.sysuser = @login1
				AND pa.ONLY_TIP_ID = @tip_id1)

			INSERT INTO dbo.USERS_OCC_TYPES
			(sysuser
			,ONLY_TIP_ID)
			VALUES (@login1
				   ,@tip_id1)
	END
	ELSE
	BEGIN
		DELETE FROM pa
			FROM dbo.USERS_OCC_TYPES AS pa 
			JOIN dbo.USERS AS u
				ON pa.sysuser = u.login
		WHERE u.id = @user_id1
			AND pa.ONLY_TIP_ID = @tip_id1
	END
go

