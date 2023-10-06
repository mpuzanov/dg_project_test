-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[adm_auto_fix_user]
(
	  @user_id SMALLINT
)
AS
/*
adm_auto_fix_user @user_id=367
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @login SYSNAME
		  , @pswd SYSNAME
		  , @sql_statement nvarchar(1000)

	SELECT @login = u.login
		 , @pswd = u.pswd
	FROM dbo.Users u
	WHERE u.id = @user_id


	IF (
			SELECT COUNT(*)
			FROM sys.database_principals
			WHERE name = @login
		) = 0
	BEGIN
		-- создаем пользователя
		SELECT @sql_statement = 'CREATE USER "' + @login + '" FOR LOGIN "' + @login + '"'
		EXEC sp_executesql @sql_statement

		-- прописываем права
		IF EXISTS(SELECT * FROM [dbo].[Group_membership] WHERE user_id=@user_id AND group_id='оптч')
		SELECT @sql_statement = 'ALTER ROLE [oper_read] ADD MEMBER "' + @login + '"'
		EXEC sp_executesql @sql_statement

		IF EXISTS(SELECT * FROM [dbo].[Group_membership] WHERE user_id=@user_id AND group_id='стрш')
		SELECT @sql_statement = 'ALTER ROLE [superoper] ADD MEMBER "' + @login + '"'
		EXEC sp_executesql @sql_statement
  
		IF EXISTS(SELECT * FROM [dbo].[Group_membership] WHERE user_id=@user_id AND group_id='адмн')
		SELECT @sql_statement = 'ALTER ROLE [admin] ADD MEMBER "' + @login + '"'
		EXEC sp_executesql @sql_statement

	END

END
go

