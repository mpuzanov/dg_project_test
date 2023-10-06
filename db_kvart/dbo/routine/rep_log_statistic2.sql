-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Статистика выполнения отчетов и квитанций
-- =============================================
CREATE     PROCEDURE [dbo].[rep_log_statistic2]
(
	@date1	  SMALLDATETIME = NULL
   ,@date2	  SMALLDATETIME = NULL
   ,@UserName VARCHAR(30)   = NULL
)
AS
/*
rep_log_statistic2 @date1='20190601',@date2='20191231'
rep_log_statistic2
*/
BEGIN
	SET NOCOUNT ON;

	IF @date1 IS NULL
		SET @date1 = current_timestamp
	IF @date2 IS NULL
		SET @date2 = current_timestamp

	SET @date1 = dbo.Fun_GetDateStart(@date1)
	SET @date2 = dbo.Fun_GetDateEnd(@date2)

	--	PRINT @date1
	--	PRINT @date2
	SELECT
		*
	FROM (SELECT
			rl.ReportName AS ReportName
		   ,LTRIM(STR(r.Level1)) + '.' + LTRIM(STR(r.Level2)) + '. ' + r.Name AS Name
		   ,r.APP AS APP
		   ,COUNT(rl.ID) AS Kol
		   ,AVG(COALESCE(rl.KolSec, 0)) AS AvgKolSec
		FROM dbo.REPORTS_LOG AS rl
		LEFT JOIN dbo.REPORTS AS r
			ON r.FileName = rl.ReportName
			AND r.Level2 <> 0
			AND r.NO_VISIBLE = 0
			AND r.APP IN ('DREP', 'DCARD')
			AND r.FileName <> ''
		WHERE (rl.date BETWEEN @date1 AND @date2)
		AND (rl.UserName = @UserName
		OR @UserName IS NULL)
		--AND rl.UserName <> 'sa'
		GROUP BY rl.ReportName
				,r.Level1
				,r.Level2
				,r.Name
				,r.APP

		UNION
		SELECT
			r.FileName AS ReportName
		   ,'OLAP ' + r.Name AS Name
		   ,'OLAP' AS APP
		   ,COUNT(rl.ID) AS Kol
		   ,AVG(COALESCE(rl.KolSec, 0)) AS AvgKolSec
		FROM dbo.REPORTS_OLAP AS r 
		JOIN dbo.REPORTS_LOG AS rl
			ON (r.FileName = rl.ReportName)
			AND (rl.date BETWEEN @date1 AND @date2)
			AND (rl.UserName = @UserName
			OR @UserName IS NULL)
		WHERE r.FileName <> ''
		GROUP BY r.FileName
				,r.Name) AS t
	ORDER BY kol DESC, Name

END
go

