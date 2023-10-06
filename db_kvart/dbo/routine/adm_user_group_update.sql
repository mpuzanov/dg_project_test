-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[adm_user_group_update]
(
	  @user_id1 INT
	, @debug BIT = 0
)
AS

BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON

	DROP TABLE IF EXISTS #rolemembers
	CREATE TABLE #rolemembers (
		  dbrole SYSNAME
		, memebername SYSNAME
		, membersid VARBINARY(85)
	)
	INSERT INTO #rolemembers EXEC sp_helprolemember 'admin'
	INSERT INTO #rolemembers EXEC sp_helprolemember 'superoper'
	INSERT INTO #rolemembers EXEC sp_helprolemember 'oper'
	INSERT INTO #rolemembers EXEC sp_helprolemember 'oper_read'
	--if @debug = 1 select dbrole, memebername  from #rolemembers

	DECLARE @LoginUser VARCHAR(30)
		  , @run1 VARCHAR(30)
		  , @sys_group1 VARCHAR(30)
		  , @er INT

	SELECT @LoginUser = u.login
	FROM dbo.Users u
	WHERE u.id = @user_id1

	DECLARE curs CURSOR LOCAL FOR
		SELECT ug.sys_group AS sys_group
			 , CASE
                   WHEN gm.group_id IS NULL THEN 'delete'
                   ELSE 'add'
            END AS run
		FROM dbo.User_groups AS ug
			JOIN dbo.Users u ON 
				u.login = @LoginUser
			LEFT JOIN dbo.Group_membership gm ON 
				gm.group_id = ug.group_id
				AND u.id = gm.user_id

	OPEN curs
	FETCH NEXT FROM curs INTO @sys_group1, @run1

	WHILE (@@fetch_status = 0)
	BEGIN
		IF @run1 = 'delete'
		BEGIN
			IF EXISTS (
					SELECT *
					FROM #rolemembers r
					WHERE dbrole = @sys_group1
						AND memebername = @LoginUser
				)
			BEGIN
				IF @debug = 1
					PRINT N'удаляем из группы ' + @sys_group1 + '  ' + @LoginUser

				EXEC @er = sp_droprolemember @sys_group1
										   , @LoginUser
				IF @er != 0
				BEGIN
					RAISERROR (N'Ошибка удаления из группы %s', 16, 1, @sys_group1)
				END
			END
		END
		ELSE
		IF @run1 = 'add'
		BEGIN
			IF NOT EXISTS (
					SELECT *
					FROM #rolemembers
					WHERE dbrole = @sys_group1
						AND memebername = @LoginUser
				)
			BEGIN
				IF @debug = 1
					PRINT N'добавляем в группу ' + @sys_group1 + '  ' + @LoginUser

				EXEC @er = sp_addrolemember @sys_group1
										  , @LoginUser
				IF @er != 0
				BEGIN
					RAISERROR (N'Ошибка добавления в группу %s', 16, 1, @sys_group1)
				END
			END

		END

		FETCH NEXT FROM curs INTO @sys_group1, @run1
	END

	CLOSE curs;
	DEALLOCATE curs;

END
go

