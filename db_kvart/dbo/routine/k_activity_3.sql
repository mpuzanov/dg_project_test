CREATE   PROCEDURE [dbo].[k_activity_3]
(
	@IpAddress1 VARCHAR(15)
   ,@Program	VARCHAR(20) = NULL
   ,@Activity1  BIT			= 1 OUT
)
AS
	/*
	  
	  Пользователь периодически подтвеждает свое присутствие
	  
	*/
	SET NOCOUNT ON

	DECLARE @DataActivity DATETIME = current_timestamp
		   ,@blocked	  BIT
		   ,@sysuser	  VARCHAR(30) = system_user
		   ,@Rejim		  VARCHAR(10)
		   ,@user_id	  SMALLINT

	IF @Program IS NULL
		SET @Program = dbo.fn_app_name()

	SELECT
		@Activity1 = 1
	   ,@Rejim = dbo.Fun_GetRejim()

	SELECT
		@blocked = COALESCE(blocked, 0)
	   ,@user_id = ID
	FROM dbo.USERS 
	WHERE login = @sysuser

	IF (@blocked = 1) OR (@Rejim = 'стоп') 
		SET @Activity1 = 0

	IF (@Rejim IN ('адмн', 'адмч'))
		AND NOT EXISTS (SELECT
				1
			FROM dbo.group_membership
			WHERE user_id = @user_id
			AND group_id = 'адмн')
		SET @Activity1 = 0


	UPDATE dbo.ACTIVITY 
	SET DataActivity = @DataActivity
	   ,is_work		 = @Activity1
	WHERE IPaddress = @IpAddress1
	AND program = @Program
	AND sysuser = @sysuser

	IF @@rowcount = 0
		INSERT INTO dbo.ACTIVITY
		(DataActivity
		,IPaddress
		,program
		,sysuser
		,is_work
		,comp)
		VALUES (@DataActivity
			   ,@IpAddress1
			   ,@Program
			   ,@sysuser
			   ,@Activity1
			   ,HOST_NAME())

--MERGE dbo.ACTIVITY AS da
--USING (SELECT
--		IpAddress = @IpAddress1
--		,Program = @Program
--		,sysuser = @sysuser) AS t2
--ON da.IPaddress = t2.IPaddress
--	AND da.program = t2.program
--	AND da.sysuser = t2.sysuser
--WHEN MATCHED
--	THEN UPDATE
--		SET	DataActivity	= @DataActivity
--			,is_work		= @Activity1
--WHEN NOT MATCHED
--	THEN INSERT
--		(	DataActivity
--			,IPaddress
--			,program
--			,sysuser
--			,is_work
--			,comp)
--		VALUES (@DataActivity
--				,@IpAddress1
--				,@Program
--				,@sysuser
--				,@Activity1
--				,HOST_NAME());
go

exec sp_addextendedproperty 'MS_Description', N'Пользователь переодически подтвеждает свое присутствие', 'SCHEMA',
     'dbo', 'PROCEDURE', 'k_activity_3'
go

