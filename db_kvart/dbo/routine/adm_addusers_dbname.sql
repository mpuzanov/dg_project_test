-- =============================================
-- Author:		Пузанов М.А.
-- Create date: 12.12.06
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[adm_addusers_dbname]
(
	@login1			SYSNAME
	,@pswd1			SYSNAME
	,@last_name1	VARCHAR(30)
	,@first_name1	VARCHAR(30)
	,@second_name1	VARCHAR(30)
	,@comments1		VARCHAR(50)	= NULL
	,@email1		VARCHAR(50)	= NULL
	,@db_name		VARCHAR(30)	= NULL
)
AS
	/*
	Добавление пользователя в базу
	
	Пузанов
	
	*/
	SET NOCOUNT ON

	DECLARE	@db_name_current	VARCHAR(30)
			,@RC				INT
			,@strExec			NVARCHAR(4000)	= ''

	IF @db_name IS NULL
		SET @db_name = DB_NAME()

	SET @db_name_current = DB_NAME()


	SET @strExec = @strExec + CHAR(13) +
	'EXECUTE ' + @db_name + '.[dbo].[adm_addusers_2005]	@login1
												,@pswd1
												,@last_name1
												,@first_name1
												,@second_name1
												,@comments1
												,@email1'

	PRINT @strExec
	EXECUTE sp_executesql	@strExec
							,N'@login1 SYSNAME, @pswd1 SYSNAME,@last_name1	VARCHAR(30)
							,@first_name1 VARCHAR(30),@second_name1 VARCHAR(30),@comments1 VARCHAR(50),@email1 VARCHAR(50)'
							,@login1 = @login1
							,@pswd1 = @pswd1
							,@last_name1 = @last_name1
							,@first_name1 = @first_name1
							,@second_name1 = @second_name1
							,@comments1 = @comments1
							,@email1 = @email1
go

