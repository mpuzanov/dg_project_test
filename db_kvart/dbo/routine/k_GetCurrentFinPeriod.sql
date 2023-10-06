CREATE   PROCEDURE [dbo].[k_GetCurrentFinPeriod]
(
	@tip_id SMALLINT = NULL
)
AS
/*
	Выдаем информацию по текущему финансовому периоду
	k_GetCurrentFinPeriod 169
*/
	SET NOCOUNT ON

	DECLARE @fin_id SMALLINT

	IF COALESCE(@tip_id,0) = 0
		SELECT TOP 1
			@fin_id = fin_id
		FROM dbo.Global_values
		ORDER BY fin_id DESC
	ELSE
		SELECT
			@fin_id = dbo.Fun_GetFinCurrent(@tip_id, NULL, NULL, NULL)

	SELECT
		fin_id
		,start_date
		,end_date
		,StrMes AS StrFinPeriod
		,StrMes2 AS StrFinPeriod2
		,Closed
		,DATEADD(DAY, LastPaym - 1, start_date) AS LastDayPaym
		,DATENAME(MONTH, DATEADD(MONTH, -1, start_date)) + ' ' + DATENAME(YEAR, DATEADD(MONTH, -1, start_date)) AS StrPaymPeriod --платёжный период (пред.месяц)
		,PaymClosed
		,CASE
				WHEN SubClosedData IS NULL THEN 0
				ELSE 1
			END AS SubClosed
	FROM dbo.Global_values 
	WHERE fin_id = @fin_id
go

