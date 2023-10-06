CREATE   PROCEDURE [dbo].[adm_Delgroup_memb]
(
	@user_id1   INT
   ,@group_name VARCHAR(25)
)
AS
	--
	-- Процедура удаляет пользователя из группы (если он там есть)
	--
	SET NOCOUNT ON
    SET XACT_ABORT ON

	DECLARE @LoginUser VARCHAR(30)
	DECLARE @group_id1 VARCHAR(10)
	DECLARE @er	   INT
		   ,@role1 VARCHAR(25)

	SELECT
		@LoginUser = [login]
	FROM dbo.USERS 
	WHERE id = @user_id1

	SELECT
		@group_id1 = group_id, @role1 = sys_group
	FROM dbo.USER_GROUPS
	WHERE name = @group_name

	-- Проверяем вхождение в группу
	CREATE TABLE #rolemembers
	(
		dbrole		SYSNAME
	   ,memebername SYSNAME
	   ,membersid   VARBINARY(85)
	)
	INSERT INTO #rolemembers EXEC sp_helprolemember @role1
	IF EXISTS (SELECT
				*
			FROM #rolemembers
			WHERE memebername = @LoginUser)
	BEGIN
		EXEC @er = sp_droprolemember @role1
									,@LoginUser
		IF @er != 0
		BEGIN
			RAISERROR (N'Ошибка удаления из группы %s', 16, 1, @role1)
		END
	END

	DELETE FROM dbo.GROUP_MEMBERSHIP
	WHERE group_id = @group_id1
		AND user_id = @user_id1
go

