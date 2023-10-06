CREATE   PROCEDURE [dbo].[adm_user_edit]
(
	@user_id1	  INT
   ,@last_name1	  VARCHAR(30)
   ,@first_name1  VARCHAR(30)
   ,@second_name1 VARCHAR(30)
   ,@comments1	  VARCHAR(50)
   ,@email1		  VARCHAR(50)
)
AS
	SET NOCOUNT ON

	UPDATE dbo.USERS
	SET last_name   = RTRIM(@last_name1)
	   ,first_name  = RTRIM(@first_name1)
	   ,second_name = RTRIM(@second_name1)
	   ,comments	= RTRIM(@comments1)
	   ,email		= RTRIM(@email1)
	   ,date_edit   = current_timestamp
	   ,user_edit   = (SELECT
				u.Initials
			FROM dbo.USERS u
			WHERE u.login = system_user)
	WHERE Id = @user_id1
go

