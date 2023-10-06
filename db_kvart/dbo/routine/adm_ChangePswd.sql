CREATE   PROCEDURE [dbo].[adm_ChangePswd]
(
	@user_id1 INT
   ,@newpswd  VARCHAR(25)
)
AS

	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @er INT
	DECLARE @login	 VARCHAR(25)
		   ,@oldpswd VARCHAR(25)

	SELECT
		@login = login
	   ,@oldpswd = RTRIM(pswd)
	FROM dbo.USERS
	WHERE id = @user_id1
	IF (@login = 'dbo')
		OR (@login = 'sa')
	BEGIN
		RAISERROR ('У этого пользователя нельзя менять пароль!', 16, 10)
		RETURN
	END

	EXEC @er = sp_password @old = @oldpswd
						  ,@new = @newpswd
						  ,@loginame = @login
	IF @er != 0
	BEGIN
		RAISERROR ('Ошибка изменения пароля пользователя', 16, 10)
		RETURN
	END


	-- OPEN SYMMETRIC KEY SSN_Key_01
	--DECRYPTION BY CERTIFICATE UsersPswd1;

	DECLARE @key NVARCHAR(4000) = 'Пузанов Михаил Анатольевич'

	UPDATE dbo.USERS
	SET pswd		 = @newpswd
	   ,pswd_encrypt = ENCRYPTBYPASSPHRASE(@key, @newpswd)
	WHERE id = @user_id1

--CLOSE SYMMETRIC KEY SSN_Key_01
go

