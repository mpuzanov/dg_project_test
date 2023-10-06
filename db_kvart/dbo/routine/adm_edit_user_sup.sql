CREATE   PROCEDURE [dbo].[adm_edit_user_sup]
(
	@user_id1	SMALLINT
	,@sup_id1	SMALLINT
	,@add1		BIT	= 1 --добавить             0-убрать доступ

)
AS
	/*
		--  Добавляем или убираем доступ пользователей к определенным поставщикам  
	
	adm_edit_user_sup 29,347,1
	adm_edit_user_sup 59, 323, 1

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
					1
				FROM dbo.USERS_SUP AS pa 
				WHERE pa.[SYSUSER] = @login1
				AND pa.ONLY_SUP_ID = @sup_id1)
			INSERT
			INTO [dbo].[USERS_SUP] 
			(	[SYSUSER]
				,[ONLY_SUP_ID])
			VALUES (@login1, @sup_id1)

	END
	ELSE
	BEGIN
		DELETE FROM pa
			FROM dbo.USERS_SUP AS pa
		WHERE pa.SYSUSER = @login1
			AND pa.ONLY_SUP_ID = @sup_id1
	END
go

