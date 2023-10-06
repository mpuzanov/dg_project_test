CREATE   PROCEDURE [dbo].[k_GetSpisokFinPeriodOcc]
(
	@occ INT = NULL
)
AS
/*
Выдаем список финансовых периодов в базе по лицевому счету
exec k_GetSpisokFinPeriodOcc 680000000
exec k_GetSpisokFinPeriodOcc 334878
*/	
	SET NOCOUNT ON

	IF @occ IS NULL
		EXEC k_GetSpisokFinPeriod
	ELSE
		SELECT
			o.fin_id
			,StrMes2 AS [name]
			,StrMes AS name1
			,CONCAT(M.name2 , ' ' , STR(YEAR(gb.Start_date), 4)) AS name2
			,gb.start_date AS [start_date]
			,CONVERT(VARCHAR(10), gb.start_date, 126) AS start_date_str  --yyyy-MM-dd 
			,gb.end_date
			,gb.KolDayFinPeriod
			,'' AS account_rep			
		FROM (
			SELECT fin_id, occ FROM dbo.Occupations WHERE occ=@occ
			UNION
			SELECT fin_id, occ FROM dbo.Occ_history WHERE occ=@occ
			) AS o
		JOIN dbo.GLOBAL_VALUES AS gb
			ON gb.fin_id = o.fin_id
		JOIN dbo.MONTH AS M
			ON M.id = MONTH(gb.Start_date)
		WHERE o.occ = @occ
		ORDER BY o.fin_id DESC
go

