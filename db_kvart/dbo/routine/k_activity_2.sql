CREATE   PROCEDURE [dbo].[k_activity_2]
(
	@IpAddress1 VARCHAR(15)
   ,@Program	VARCHAR(20)
)
AS
	/*
	 Пользователь выходит из программы
	*/
	SET NOCOUNT ON

	DECLARE @DataActivity DATETIME
		   ,@sysuser	  VARCHAR(30) = system_user

	SET @DataActivity = DATEADD(MINUTE, -60, current_timestamp)

	UPDATE dbo.ACTIVITY --WITH (SNAPSHOT)
	SET is_work = 0
	WHERE (IPaddress = @IpAddress1)
	AND (program = @Program)
	AND (sysuser = @sysuser)

	DELETE FROM dbo.ACTIVITY --WITH (SNAPSHOT)
	WHERE (DataActivity <= @DataActivity)
go

exec sp_addextendedproperty 'MS_Description', N'Пользователь выходит из программы', 'SCHEMA', 'dbo', 'PROCEDURE',
     'k_activity_2'
go

