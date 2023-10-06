-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Статистика выполнения отчетов
-- =============================================
CREATE   PROCEDURE [dbo].[rep_log_statistic]
(
	@date1	  SMALLDATETIME = NULL
   ,@date2	  SMALLDATETIME = NULL
   ,@UserName VARCHAR(30)   = NULL
)
AS
/*
rep_log_statistic @date1='20150801',@date2='20151231'
rep_log_statistic
*/
BEGIN
	SET NOCOUNT ON;

	IF @date1 IS NULL
		SET @date1 = CURRENT_TIMESTAMP
	IF @date2 IS NULL
		SET @date2 = CURRENT_TIMESTAMP

	SET @date1 = dbo.Fun_GetDateStart(@date1)
	SET @date2 = dbo.Fun_GetDateEnd(@date2)

--	PRINT @date1
--	PRINT @date2
	SELECT*
	FROM (
	SELECT
		r.FileName AS ReportName
	   ,LTRIM(STR(r.Level1)) + '.' + LTRIM(STR(r.Level2)) + '. ' + r.Name AS Name
	   ,r.APP AS APP
	   ,COUNT(rl.ID) AS Kol
	   ,AVG(COALESCE(rl.KolSec, 0)) AS AvgKolSec
	FROM dbo.REPORTS AS r 
	LEFT JOIN dbo.REPORTS_LOG AS rl
		ON r.FileName = rl.ReportName
		AND (rl.date BETWEEN @date1 AND @date2)
		--AND rl.UserName <> 'sa'
		AND (rl.UserName = @UserName
		OR @UserName IS NULL)
	WHERE r.Level2 <> 0
	AND r.NO_VISIBLE = 0
	AND r.APP IN ('DREP', 'DCARD')
	AND r.FileName <> ''
	-- (rl.date BETWEEN @date1 AND @date2)
	--AND rl.UserName <> 'sa'
	--AND (rl.UserName = @UserName  OR @UserName IS NULL)
	GROUP BY r.FileName
			,r.Level1
			,r.Level2
			,r.Name
			,r.APP
	
	UNION
	SELECT
		r.FileName AS ReportName
	   ,'OLAP '+r.Name AS Name
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
	GROUP BY r.FileName,r.Name
	) AS t
	ORDER BY kol DESC, Name
	
END;
go

