CREATE   PROCEDURE [dbo].[k_DateList]
	@d1		DATETIME
	,@d2	DATETIME
AS
/*
Генерация календаря от даты1 до даты2

declare @d1 datetime='20150101',@d2 datetime='20251231'
exec k_DateList @d1, @d2

*/
	SELECT
		DATEADD(DAY, num, @d1) AS data1
		,YEAR(DATEADD(DAY, num, @d1)) AS y1
		,MONTH(DATEADD(DAY, num, @d1)) AS m1
		,DAY(DATEADD(DAY, num, @d1)) AS d1
		,DATENAME(MONTH, DATEADD(DAY, num, @d1)) AS month_name
		,DATENAME(QUARTER, DATEADD(DAY, num, @d1)) AS q1
		,DATENAME(DAYOFYEAR, DATEADD(DAY, num, @d1)) AS dayofyear1
		,DATENAME(WEEK, DATEADD(DAY, num, @d1)) AS week1
		,DATENAME(WEEKDAY, DATEADD(DAY, num, @d1)) AS weekday_name1
		,DATEPART(WEEKDAY, DATEADD(DAY, num, @d1)) AS weekday1
		,DATENAME(MONTH, DATEADD(DAY, num, @d1)) + ' ' + DATENAME(YEAR, DATEADD(DAY, num, @d1)) AS month_year
		,(DATENAME(DAY, DATEADD(DAY, num, @d1)) + ' ' + (SELECT
				name_rod
			FROM dbo.View_MONTH
			WHERE id = DATEPART(MONTH, DATEADD(DAY, num, @d1)))
		+ ' ' +
		DATENAME(YEAR, DATEADD(DAY, num, @d1))) AS data_full
	FROM (	
		SELECT
		a * 1000 + b * 100 + c * 10 + d num
		FROM 
		(SELECT * FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) X(a)) a
		CROSS JOIN	
		(SELECT * FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) X(b)) b
		CROSS JOIN	
		(SELECT * FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) X(c)) c
		CROSS JOIN	
		(SELECT * FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) X(d)) d	
		) a -- числовая последовательность от 0 до 9999
	WHERE DATEADD(DAY, num, @d1) <= @d2
	ORDER BY 1
go

