CREATE   PROCEDURE [dbo].[adm_arxiv_rar]
(
	@DirStr_source	VARCHAR(100)   -- без слеша  -- файл для архивации
	,@DirStr		VARCHAR(100)   -- без слеша  -- каталог с архивом
)
AS

	/*
	Хр. процедура архивации
	Вход: 
	Файл для архивации
	Директория создания архивов
	
	*/
	SET NOCOUNT ON

	DECLARE	@result		INT
			,@strExec	VARCHAR(300)
	DECLARE @FileIsDir TINYINT

	-- Проверяем существование файла
	DROP TABLE IF EXISTS #t
	CREATE TABLE #t
	(
		FileExists		TINYINT
		,FileIsDir		TINYINT
		,ParDirExists	TINYINT
	)
	INSERT #t EXEC [master].dbo.xp_fileexist @DirStr_source
	SELECT
		@FileIsDir = FileExists
	FROM #t
	IF @FileIsDir <> 1
	BEGIN
		RAISERROR ('Файла нет', 16, 1)
		RETURN
	END

	-- Проверяем существование каталога
	IF OBJECT_ID('tempdb..#t2', 'U') IS NOT NULL
		DROP TABLE #t2
	CREATE TABLE #t2
	(
		FileExists		TINYINT
		,FileIsDir		TINYINT
		,ParDirExists	TINYINT
	)
	INSERT #t2 EXEC master.dbo.xp_fileexist @DirStr
	SELECT
		@FileIsDir = FileIsDir
	FROM #t2
	IF @FileIsDir <> 1
	BEGIN
		RAISERROR ('Каталога нет', 16, 1)
		RETURN
	END


	DECLARE	@StrFile		VARCHAR(50)
			,@StrYear		VARCHAR(4)
			,@StrMonth		VARCHAR(2)
			,@StrDay		VARCHAR(2)
			,@CurrentDate	DATETIME
			,@StrServName	VARCHAR(10)

	SET @CurrentDate = current_timestamp
	SET @StrYear = YEAR(@CurrentDate)
	SET @StrMonth = MONTH(@CurrentDate)
	SET @StrDay = DAY(@CurrentDate)
	SET @StrServName = '_' + @@servername
	SET @StrMonth = REPLICATE('0', 2 - DATALENGTH(@StrMonth)) + @StrMonth
	SET @StrDay = REPLICATE('0', 2 - DATALENGTH(@StrDay)) + @StrDay

	--
	--  Архивирование(rar) из SQL Server
	--
	SET @strExec = @DirStr + '\rar.exe a -m1 -ag '
	SET @strExec = @strExec + @DirStr + '\  ' + @DirStr_source
	PRINT @strExec
	EXEC @result = master.dbo.xp_cmdshell	@strExec
										,no_output
go

