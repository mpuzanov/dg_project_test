-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	select * from dbo.Fun_GetAvgCounterValueTable(680004052,null)
/* 
select * from dbo.Fun_GetAvgCounterValueTable(910003297,null,null)
select * from dbo.Fun_GetAvgCounterValueTable(166031,'гвод', 2)
*/
-- =============================================
CREATE             FUNCTION [dbo].[Fun_GetAvgCounterValueTable]
(
	  @occ INT
	, @service_id VARCHAR(10) = NULL
	, @count_month INT = 100
)
RETURNS @ResultTable TABLE (
	  service_id VARCHAR(10)
	, avg_vday DECIMAL(12, 6)
)
AS
BEGIN
	IF @count_month IS NULL
		SET @count_month=100

	INSERT INTO @ResultTable
	SELECT service_id, case when avg_vday<0 THEN 0 ELSE avg_vday end FROM (
	SELECT service_id
		 , COALESCE(SUM(actual_value) / CAST(SUM(kol_day) AS DECIMAL(12, 6)), 0) AS avg_vday
	FROM (
		SELECT service_id
			 , fin_id
			 , kol_day
			 , CAST(COALESCE(SUM(actual_value), 0.0) AS DECIMAL(12, 6)) AS actual_value
		FROM (
			SELECT cla.service_id
				 , cla.counter_id
				 , cla.fin_id
				 , ROW_NUMBER() OVER (PARTITION BY cla.service_id, cla.counter_id ORDER BY cla.fin_id DESC) AS count_month
				 , COALESCE(ci.kol_day, 0) AS kol_day
				 , COALESCE(SUM(ci.actual_value), 0.0) AS actual_value
			FROM dbo.Counter_list_all cla 
			    JOIN dbo.Counters as c ON 
					cla.counter_id=c.id AND c.date_del is NULL
				JOIN dbo.Occupations AS o 
					ON cla.occ=o.Occ
				LEFT JOIN dbo.Counter_inspector ci ON 
					ci.fin_id = cla.fin_id
					AND ci.tip_value = 1
					AND ci.kol_day > 0
					AND ci.counter_id = cla.counter_id
			WHERE cla.occ = @occ
				AND (cla.service_id = @service_id OR @service_id IS NULL)
				AND cla.fin_id<o.fin_id
			GROUP BY cla.service_id
				   , cla.counter_id
				   , cla.fin_id
				   , ci.kol_day
		) AS t1
		WHERE t1.count_month<=@count_month
		AND t1.kol_day > 0
		GROUP BY service_id
			   , fin_id
			   , kol_day
	) AS t2
	GROUP BY service_id
	) AS t3
	OPTION (RECOMPILE)

	RETURN
END
go

