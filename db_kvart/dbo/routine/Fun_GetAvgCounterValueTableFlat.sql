-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	
/* 
select * from dbo.Fun_GetAvgCounterValueTableFlat(80279)
select * from dbo.Fun_GetAvgCounterValueTableFlat(82405)
select * from dbo.Fun_GetAvgCounterValueTableFlat(79620)
*/
-- =============================================
CREATE    FUNCTION [dbo].[Fun_GetAvgCounterValueTableFlat]
(
	  @flat_id1 INT
)
RETURNS @ResultTable TABLE (
	  service_id VARCHAR(10)
	, avg_vday DECIMAL(12, 6)
)
AS
BEGIN
	INSERT INTO @ResultTable
	SELECT service_id, case when avg_vday<0 THEN 0 ELSE avg_vday end FROM (
	SELECT service_id
		 , COALESCE(SUM(actual_value) /  CAST(SUM(kol_day) AS DECIMAL(12, 6)), 0) AS avg_vday
	FROM (
		SELECT service_id
			 , fin_id
			 , kol_day
			 , CAST(SUM(actual_value) AS DECIMAL(12, 6)) AS actual_value
		FROM (
			SELECT cla.service_id
				 , cla.counter_id
				 , cla.fin_id
				 , ot.count_month_avg_counter AS count_month_avg_counter
				 , ROW_NUMBER() OVER (PARTITION BY cla.service_id, cla.counter_id ORDER BY cla.fin_id DESC) AS count_month
				 , COALESCE(ci.kol_day, 0) AS kol_day
				 , SUM(COALESCE(ci.actual_value,0.0)) AS actual_value
			FROM dbo.Counters as c
			    JOIN dbo.Counter_list_all cla ON 
					cla.counter_id=c.id
				JOIN dbo.Occupations AS o ON 
					cla.occ=o.Occ
				JOIN dbo.Occupation_Types ot ON 
					o.tip_id=ot.id
				LEFT JOIN dbo.Counter_inspector ci ON 
					ci.fin_id = cla.fin_id 
					AND ci.counter_id = cla.counter_id
					AND ci.tip_value = 1
					AND ci.kol_day > 0					
			WHERE c.flat_id = @flat_id1
				--AND c.date_del is NULL  -- пусть все считает 25.07.22
				AND cla.fin_id<o.fin_id
			GROUP BY cla.service_id
				   , cla.counter_id
				   , cla.fin_id
				   , ci.kol_day
				   , ot.count_month_avg_counter
		) AS t1
		WHERE t1.count_month<=t1.count_month_avg_counter
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

