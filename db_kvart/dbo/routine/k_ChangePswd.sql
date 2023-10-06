CREATE   PROCEDURE [dbo].[k_ChangePswd] 

	@old sysname = NULL,        -- the old (current) password
    @new sysname,               -- the new password
    @loginame sysname = NULL    -- user to change password on
AS

	SET NOCOUNT ON
	DECLARE @exec_stmt NVARCHAR(4000), @user_id1 SMALLINT

    IF @loginame IS NULL
        SELECT @loginame = SUSER_SNAME()

	SELECT @user_id1=u.id FROM users AS u WHERE LOGIN=@loginame

    IF @new IS NULL
        SELECT @new = ''

	-- CHECK IT'S A SQL LOGIN --
    IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE
                   loginname = @loginame AND isntname = 0)
	BEGIN
		RAISERROR(15007,-1,-1,@loginame)
		RETURN (1)
	END

	IF @old IS NULL
		SET @exec_stmt = 'alter login ' + QUOTENAME(@loginame) +
			' with password = ' + QUOTENAME(@new, '''')
	ELSE
		SET @exec_stmt = 'alter login ' + QUOTENAME(@loginame) +
			' with password = ' + QUOTENAME(@new, '''') + ' old_password = ' + QUOTENAME(@old, '''')

	EXEC (@exec_stmt)	

	IF @@ERROR <> 0
		RETURN (1)

	DECLARE @key NVARCHAR(4000)='Пузанов Михаил Анатольевич'
	
    IF @loginame<>'sa'
    BEGIN
    	UPDATE users SET pswd=@new, pswd_encrypt = ENCRYPTBYPASSPHRASE(@key,@new)
    	WHERE id=@user_id1
	END

    -- RETURN SUCCESS --
	RETURN  (0)
go

