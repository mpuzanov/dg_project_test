CREATE   PROCEDURE [dbo].[k_monthYear]
AS
	/*
	Процедура выдает список:   
	1 колонка:  дата (первое число, мес, год)   
	2 колонка:  название месяца и Год
	
	на 10 лет вперёд
	
	k_monthYear
	
	*/
	SET NOCOUNT ON
	SET LANGUAGE Russian

	CREATE TABLE #month
	(
		data		SMALLDATETIME
		,namemes	NVARCHAR(20) COLLATE database_default
	)

	DECLARE @CurrentDate SMALLDATETIME
	SELECT TOP 1
		@CurrentDate = [start_date]
	FROM dbo.GLOBAL_VALUES
	ORDER BY fin_id DESC

	INSERT
	INTO #month
	VALUES (NULL
			,'постоянно')

	-- начальная дата = первое число текущего месяца
	DECLARE @dat1 SMALLDATETIME

	SELECT
		@dat1 = dbo.Fun_GetFirstDayMonth(@CurrentDate)

	INSERT
	INTO #month
	(	data
		,namemes)
		SELECT
			DATEADD(MONTH, n, @dat1)
			,DATENAME(MONTH, DATEADD(MONTH, n, @dat1)) + ' ' + DATENAME(YEAR, DATEADD(MONTH, n, @dat1))
		FROM dbo.Fun_GetNums(0, 120)

	SELECT
		*
	FROM #month
go

