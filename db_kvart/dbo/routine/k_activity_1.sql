CREATE   PROCEDURE [dbo].[k_activity_1]
(
	@IpAddress1		VARCHAR(15)
	,@Program		VARCHAR(20)
	,@StrVer		VARCHAR(20)		= NULL -- версия программы пользователя
	,@versiaint		INT				= NULL -- версия программы пользователя ввиде числа для сравнения в базе
	,@dir_program	VARCHAR(100)	= NULL -- путь к вызываемой программе
)
AS
/*
  Пользователь регистрируется в программе
*/

	SET NOCOUNT ON

	DECLARE	@DataActivity	DATETIME	= current_timestamp
			,@sysuser		VARCHAR(30)	= system_user
			,@Activity1		BIT			= 1
			,@Versia_old	BIT			= 0

	IF coalesce(@StrVer,'')=''
		SET @Versia_old = 1

	IF @versiaint IS NOT NULL
	BEGIN -- сравниваем с минимальной 
		IF EXISTS (SELECT
					1
				FROM dbo.VERSION V
				WHERE V.[program_name] = @Program
				AND @versiaint < versiaint_min)
		BEGIN
			SET @Versia_old = 1
		END
	END

	UPDATE dbo.ACTIVITY
	SET	DataActivity	= @DataActivity
		,StrVer			= @StrVer
		,is_work		= @Activity1
		,comp			= HOST_NAME()
		,versia_old		= @Versia_old
		,dir_program	= @dir_program
	WHERE IPaddress = @IpAddress1
		AND program = @Program
		AND sysuser = @sysuser

	IF (@@ROWCOUNT = 0 )  
	BEGIN  
		INSERT
		INTO dbo.ACTIVITY
				(DataActivity
				,IPaddress
				,program
				,SYSUSER
				,is_work
				,StrVer
				,comp
				,versia_old
				,dir_program)
		VALUES (@DataActivity
				,@IpAddress1
				,@Program
				,@sysuser
				,@Activity1
				,@StrVer
				,HOST_NAME()
				,@Versia_old
				,@dir_program);
	END 


	--MERGE dbo.ACTIVITY AS target
	--USING (SELECT
	--		 @IpAddress1 as IpAddress
	--		,@Program as Program
	--		,@sysuser as sysuser
	--		,@dir_program as dir_program) AS source (IpAddress, Program, sysuser, dir_program)
	--ON target.IPaddress = source.IPaddress
	--	AND target.program = source.program
	--	AND target.sysuser = source.SYSUSER
	--WHEN MATCHED
	--	THEN UPDATE
	--		SET	DataActivity	= @DataActivity
	--			,StrVer			= @StrVer
	--			,is_work		= @Activity1
	--			,comp			= HOST_NAME()
	--			,versia_old		= @Versia_old
	--			,dir_program	= @dir_program
	--WHEN NOT MATCHED
	--	THEN INSERT
	--		(	DataActivity
	--			,IPaddress
	--			,program
	--			,sysuser
	--			,is_work
	--			,StrVer
	--			,comp
	--			,versia_old
	--			,dir_program)
	--		VALUES (@DataActivity
	--				,@IpAddress1
	--				,@Program
	--				,@sysuser
	--				,@Activity1
	--				,@StrVer
	--				,HOST_NAME()
	--				,@Versia_old
	--				,@dir_program);


	IF @Versia_old = 1
	BEGIN
		DECLARE @Msg_error VARCHAR(200)
		SET @Msg_error = 'Версия программы устарела! Обновите клиента!' + CHAR(13) +
		'Зайдите в меню "О программе" и скачайте с сайта.' + CHAR(13) +
		'http://www.kvartplata1.narod.ru/download.htm'
		RAISERROR (@Msg_error, 16, 1);
	END


	UPDATE dbo.USERS WITH(ROWLOCK)
	SET last_connect = @DataActivity
	WHERE login = @sysuser
go

exec sp_addextendedproperty 'MS_Description', N'Пользователь регистрируется в программе', 'SCHEMA', 'dbo', 'PROCEDURE',
     'k_activity_1'
go

