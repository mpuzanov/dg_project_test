CREATE   PROCEDURE [dbo].[k_GetSpisokFinPeriod]
(
	@add1 SMALLINT = 0 -- если 1 то выдавать список без текущего фин периода
)
AS
/*
	Выдаем список финансовых периодов в базе
	exec k_GetSpisokFinPeriod 
	exec k_GetSpisokFinPeriod 1
*/
	SET NOCOUNT ON

	DECLARE @fin_id1 SMALLINT
	SET @fin_id1 = 1000

	IF @add1 = 1
	BEGIN
		SELECT
			@fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)
	END

	SELECT
		gb.fin_id
	   ,gb.StrMes2 AS [name]  -- августе 2020
	   ,gb.StrMes AS name1	 -- август 2020
	   ,CONCAT(M.name2 , ' ' , STR(YEAR(gb.start_date), 4)) AS name2 -- августа 2020
	   ,gb.start_date AS [start_date]
	   ,CONVERT(VARCHAR(10), gb.start_date, 126) AS start_date_str  --yyyy-MM-dd
	   ,gb.end_date
	   ,gb.KolDayFinPeriod
	   ,'' AS account_rep
	FROM dbo.Global_values AS gb 
	JOIN dbo.Month AS M
		ON M.id = MONTH(gb.start_date)
	WHERE gb.fin_id < @fin_id1
	ORDER BY fin_id DESC
go

