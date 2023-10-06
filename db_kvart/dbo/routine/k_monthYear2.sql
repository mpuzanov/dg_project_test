CREATE   PROCEDURE [dbo].[k_monthYear2]
AS
	/*
	Процедура выдает список:   
	1 колонка:  дата (последнее число, мес, год)   
	2 колонка:  название месяца и Год
	
	на 18 лет вперёд
		
	k_monthYear2
	
	*/

	SET NOCOUNT ON

	SET LANGUAGE Russian


	DECLARE @CurrentDate SMALLDATETIME
	DECLARE @dat1 SMALLDATETIME

	SELECT TOP 1
		@CurrentDate = start_date
	FROM GLOBAL_VALUES 
	ORDER BY fin_id DESC

	SELECT
		@dat1 = dbo.Fun_GetLastDayMonth(@CurrentDate)

	SELECT '20500131' AS data,'постоянно' AS namemes
	UNION ALL
	SELECT
		DATEADD(MONTH, n, @dat1)
		,DATENAME(MONTH, DATEADD(MONTH, n, @dat1)) + ' ' + DATENAME(YEAR, DATEADD(MONTH, n, @dat1))
	FROM dbo.Fun_GetNums(0, 216)
go

