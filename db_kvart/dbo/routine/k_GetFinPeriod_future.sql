-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Получаем список фин.периодов вперёд
-- =============================================
CREATE PROCEDURE [dbo].[k_GetFinPeriod_future]
(
	@fin_start	SMALLINT
	,@kol_mes	SMALLINT	= 12
)
AS
BEGIN
	/*
	exec [dbo].[k_GetFinPeriod_future] 180,20
	*/
	SET NOCOUNT ON;
	IF @kol_mes IS NULL
		SET @kol_mes = 12

	DECLARE @start_date SMALLDATETIME

	SELECT
		@start_date = start_date
	FROM dbo.GLOBAL_VALUES
	WHERE fin_id = @fin_start

	SELECT
		@fin_start + n AS fin_id
		,DATEADD(MONTH, n, @start_date) AS [start_date]
		,DATENAME(MONTH, DATEADD(MONTH, n, @start_date)) + ' ' + DATENAME(YEAR, DATEADD(MONTH, n, @start_date)) AS name1
	FROM dbo.Fun_GetNums(0, @kol_mes-1) AS Nums;

END
go

