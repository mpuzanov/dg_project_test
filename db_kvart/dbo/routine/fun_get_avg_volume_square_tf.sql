-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	расчет средних объёмов по дому по услуге - отопление
-- =============================================
CREATE     FUNCTION [dbo].[fun_get_avg_volume_square_tf]
(
@fin_id SMALLINT,
@build_id INT
)
RETURNS TABLE
--@ResultTable TABLE (
--	  service_id VARCHAR(10)
--	, avg_volume DECIMAL(12, 6)
--)
AS
/*
select * from dbo.fun_get_avg_volume_square_tf(250,6806)
*/

/*
	SELECT ph.service_id, sum(ph.kol_norma)/sum(o.total_sq)  AS avg_volume
	FROM dbo.View_paym AS ph
		JOIN dbo.Occupations AS o ON ph.Occ=o.Occ
	WHERE 
		ph.fin_id=@fin_id
		AND ph.build_id=@build_id
		AND ph.metod_old=3
		AND o.total_sq>0
	GROUP BY ph.service_id
*/
RETURN
	(
	SELECT 
		t_ci.service_id AS service_id
		, sum(t_ci.actual_value)/sum(o.total_sq) AS avg_volume
	FROM dbo.Occupations AS o
		JOIN dbo.Flats as f ON 
			o.flat_id=f.id
		CROSS APPLY (SELECT 
						cli.service_id
						, sum(ci.actual_value) AS actual_value
					FROM dbo.Counter_list_all cli
					JOIN dbo.Counter_inspector ci ON 
						cli.counter_id=ci.counter_id 
						AND cli.fin_id=ci.fin_id 
					WHERE cli.occ=o.occ AND cli.fin_id=@fin_id
					GROUP BY cli.service_id, cli.occ
					) as t_ci
	WHERE 
		f.bldn_id=@build_id	
		AND o.total_sq>0
	GROUP BY t_ci.service_id
	)
go

