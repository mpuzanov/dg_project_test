CREATE   PROCEDURE [dbo].[adm_usersid]
(
	@user_id1 INT
)
AS


	SET NOCOUNT ON

	SELECT
		id
	   ,last_name
	   ,first_name
	   ,second_name
	   ,login
	   ,pswd
	   ,pswd_encrypt
	   ,comments
	   ,email
	   ,foto
	   ,blocked
	   ,blocked_personal
	   ,Initials
	   ,SuperAdmin
	   ,Only_sup
	   ,blocked_export
	   ,blocked_print
	   ,last_connect
	   ,date_edit
	   ,user_edit
	FROM dbo.USERS
	WHERE Id = @user_id1
go

