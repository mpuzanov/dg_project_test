CREATE   PROCEDURE [dbo].[adm_user_permission_copy_from]
(
	@user_id1	  INT
	,@user_id_from1	  INT
)
AS
    /*
     	-- сделать права доступа аналогичные @user_id_from1
     */

	SET NOCOUNT ON
	SET XACT_ABORT ON

    declare  @sysuser1 nvarchar(30)
        ,@sysuser_from nvarchar(30)

    select @sysuser1 = login from dbo.Users where id=@user_id1
    select @sysuser_from = login from dbo.Users where id=@user_id_from1


	-- 1. Принадлежность группе
    delete
    from dbo.GROUP_MEMBERSHIP
    where user_id = @user_id1

    insert into dbo.GROUP_MEMBERSHIP(user_id, group_id)
    select @user_id1, group_id
    from dbo.GROUP_MEMBERSHIP
    where user_id = @user_id_from1

    -- TODO: надо физически переместить в группах на сервере
    exec adm_user_group_update @user_id1
    --==============================================
    
	-- 2. Запуск программ
    delete
    from dbo.PROGRAM_ACCESS
    where user_id = @user_id1

    insert into dbo.PROGRAM_ACCESS(user_id, program_id)
    select @user_id1, program_id
    from dbo.PROGRAM_ACCESS
    where user_id = @user_id_from1

	-- 3. Типы фонда
    delete from dbo.Users_occ_types where SYSUSER=@sysuser1

    insert into dbo.Users_occ_types(SYSUSER, ONLY_TIP_ID, only_read, fin_id_start)
    select @sysuser1,ONLY_TIP_ID, only_read, fin_id_start
    from dbo.Users_occ_types where SYSUSER=@sysuser_from

	-- 4. Виды платежей
    delete from dbo.USERS_PAY_ORGS where SYSUSER=@sysuser1

    insert into dbo.USERS_PAY_ORGS(SYSUSER, ONLY_PAY_ORGS)
    select @sysuser1,ONLY_PAY_ORGS
    from dbo.USERS_PAY_ORGS where SYSUSER=@sysuser_from

	-- 5. Поставщики
    delete from dbo.USERS_SUP where SYSUSER=@sysuser1

    insert into dbo.USERS_SUP(SYSUSER, ONLY_SUP_ID)
    select @sysuser1, ONLY_SUP_ID
    from dbo.USERS_SUP where SYSUSER=@sysuser_from


	-- 6. Установка доступа
    delete
    from dbo.ALLOWED_AREAS
    where user_id = @user_id1

    insert into dbo.ALLOWED_AREAS(user_id, area_id, group_id, op_id)
    select @user_id1, area_id, group_id, op_id
    from dbo.ALLOWED_AREAS
    where user_id = @user_id_from1
go

