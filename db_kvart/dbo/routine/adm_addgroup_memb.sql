CREATE   PROCEDURE [dbo].[adm_addgroup_memb](
    @user_id1 INT,
    @group_name VARCHAR(25)
)
AS
/*
	Процедура добавляет пользователя в группу (если его там нет)
*/
    SET NOCOUNT ON
    SET XACT_ABORT ON

	DECLARE	@group_id VARCHAR(10)
		, @er        INT
		, @LoginUser VARCHAR(30)
		, @role1     VARCHAR(25)

	SELECT @group_id = group_id, @role1 = sys_group
	FROM dbo.user_groups
	WHERE [name] = @group_name;

	SELECT @LoginUser = [login] FROM dbo.users WHERE id = @user_id1;

    -- Проверяем есть ли такой пользователь в базе данных, если нет создаем
    IF (@LoginUser not in ('sa', 'dbo')) and NOT EXISTS(SELECT 1
                                                        FROM sys.database_principals
                                                        WHERE name = @LoginUser)
        BEGIN
            EXEC @er=sp_grantdbaccess @LoginUser
            IF @er != 0
                BEGIN
                    RAISERROR (N'Ошибка добавления User!',11,1)
                END
        END

-- Проверяем вхождение в группу
    CREATE TABLE #rolemembers
    (
        dbrole      sysname,
        memebername sysname,
        membersid   VARBINARY(85)
    )
	INSERT INTO #rolemembers EXEC sp_helprolemember @role1
    IF NOT EXISTS(SELECT *
                  FROM #rolemembers
                  WHERE memebername = @LoginUser) and (@LoginUser not in ('sa', 'dbo'))
        BEGIN
            EXEC @er=sp_addrolemember @role1, @LoginUser
            IF @er != 0
                BEGIN
                    RAISERROR (N'Ошибка добавления в группу %s',16,1,@role1)
                END

            INSERT INTO dbo.group_membership (group_id, USER_ID)
            VALUES (@group_id, @user_id1)
        END
    ELSE
        IF NOT EXISTS(SELECT * FROM dbo.group_membership WHERE group_id = @group_id and [USER_ID] = @user_id1)
            BEGIN
                INSERT INTO dbo.group_membership (group_id, USER_ID)
                VALUES (@group_id, @user_id1)
            END
go

