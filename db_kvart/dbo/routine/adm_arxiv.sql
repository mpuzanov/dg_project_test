CREATE   PROCEDURE [dbo].[adm_arxiv]
(
	@DirStr VARCHAR(100)-- без слеша
)
AS
	--
	--
	--
	-- Хр. процедура архивации
	-- Вход: Директория создания архивов
	--
	--  Надо проводить ежедневную и еженедельную архивацию
	--  создать таблицу куда будет заноситься данная информация
	--
	SET NOCOUNT ON

	DECLARE	@result		INT
			,@strExec	VARCHAR(50)

	DROP TABLE IF EXISTS #t
	CREATE TABLE #t
	(
		FileExists		TINYINT
		,FileIsDir		TINYINT
		,ParDirExists	TINYINT
	)
	INSERT #t EXEC master.sys.xp_fileexist @DirStr
	DECLARE @FileIsDir TINYINT
	SELECT
		@FileIsDir = FileIsDir
	FROM #t
	IF @FileIsDir = 1
		PRINT 'Каталог есть'
	ELSE
	BEGIN
		RAISERROR ('Каталога нет', 16, 1)
		RETURN
	END

	DECLARE	@StrFile			VARCHAR(50)
			,@StrFileSubsidia	VARCHAR(50)
			,@StrFileNaim		VARCHAR(50)
			,@StrFileMsdb		VARCHAR(50)
			,@StrYear			VARCHAR(4)
			,@StrMonth			VARCHAR(2)
			,@StrDay			VARCHAR(2)
			,@CurrentDate		DATETIME
			,@StrServName		VARCHAR(10)

	SET @CurrentDate = current_timestamp
	SET @StrYear = YEAR(@CurrentDate)
	SET @StrMonth = MONTH(@CurrentDate)
	SET @StrDay = DAY(@CurrentDate)
	SET @StrServName = '_' + @@servername

	SET @StrMonth = REPLICATE('0', 2 - DATALENGTH(@StrMonth)) + @StrMonth
	SET @StrDay = REPLICATE('0', 2 - DATALENGTH(@StrDay)) + @StrDay

	SET @StrFile = @DirStr + '\\' + @StrYear + @StrMonth + @StrDay + @StrServName + '_komp.bak'
	SET @StrFileNaim = @DirStr + '\\' + @StrYear + @StrMonth + @StrDay + @StrServName + '_naim.bak'
	SET @StrFileSubsidia = @DirStr + '\\' + @StrYear + @StrMonth + @StrDay + @StrServName + '_sub.bak'
	SET @StrFileMsdb = @DirStr + '\\' + @StrYear + @StrMonth + @StrDay + '_msdb.bak'

	DECLARE @strexec2 VARCHAR(300)


	-- Сохраняем скрипт хр.процедур и функций
	EXEC adm_GenerateSQLScript @DirStr


	BACKUP DATABASE [msdb]
	TO DISK = @StrFileMsdb WITH INIT, NOUNLOAD, COMPRESSION, NAME = N'msdb_backup',
	NOSKIP, STATS = 10, NOFORMAT

	BACKUP DATABASE [komp]
	TO DISK = @StrFile WITH INIT, NOUNLOAD, COMPRESSION, NAME = N'basa_komp_backup',
	NOSKIP, STATS = 10, NOFORMAT

	BACKUP DATABASE [naim]
	TO DISK = @StrFileNaim WITH INIT, NOUNLOAD, COMPRESSION, NAME = N'basa_naim_backup',
	NOSKIP, STATS = 10, NOFORMAT

	BACKUP DATABASE [kvart]
	TO DISK = @StrFileNaim WITH INIT, NOUNLOAD, COMPRESSION, NAME = N'basa_kvart_backup',
	NOSKIP, STATS = 10, NOFORMAT

--
--  Архивирование(rar) из SQL Server
--
--set @strexec2=@DirStr+'\\rar.exe a -m1 '
--set @strexec2=@strexec2+@DirStr+'\\'+@StrYear+@StrMonth+@StrDay+@StrServName
--set @strexec2=@strexec2+'  '+@StrFile
--print @strexec2
--EXEC master..xp_cmdshell @strexec2, no_output


-- Архивируем субсидии
/*
set @strexec2=@DirStr+'\\rar.exe a -m1 '
set @strexec2=@strexec2+@DirStr+'\\'+@StrYear+@StrMonth+@StrDay+@StrServName+'_sub'
set @strexec2=@strexec2+'  '+@StrFileSubsidia
print @strexec2
EXEC master..xp_cmdshell @strexec2, no_output
*/

--  Архивирование OLAP Server
--declare @strexec3 varchar(300)
--set @strexec3='""c:\\Program Files\\Microsoft Analysis Services\\Bin\\msmdarch" /a TOWN2005 '
--set @strexec3=@strexec3+'"c:\\Program Files\Microsoft Analysis Services\\Data\\" "komp2_a" '
--set @strexec3=@strexec3+'"'+@DirStr+'\\OLAP_'+@StrYear+@StrMonth+@StrDay+'komp2.cab""'
--print @strexec3
--EXEC master..xp_cmdshell @strexec3, no_output
go

