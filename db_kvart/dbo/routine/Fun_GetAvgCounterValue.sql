-- =============================================
-- Author:		Пузанов
-- Create date: 19.11.14
-- Description:	вычисляем средние значений показание счётчиков в ДЕНЬ
-- select @kol=dbo.Fun_GetAvgCounterValue(@occ,@service_id)
-- =============================================
CREATE       FUNCTION [dbo].[Fun_GetAvgCounterValue]
(
	@occ			INT
	,@service_id	VARCHAR(10)
)
RETURNS DECIMAL(12, 6)
AS
BEGIN
	DECLARE @kol DECIMAL(12, 6) = 0

	SELECT
		@kol = COALESCE(SUM(actual_value) / SUM(kol_day), 0)
	FROM (SELECT
			fin_id
			,kol_day
			,COALESCE(SUM(actual_value), 0.0) AS actual_value
		FROM (SELECT
				ci.fin_id
				,ci.counter_id
				,ci.kol_day
				,COALESCE(SUM(ci.actual_value), 0.0) AS actual_value
			FROM dbo.Counter_inspector ci 
			JOIN dbo.Counter_list_all cla 
				ON ci.fin_id = cla.fin_id
				AND ci.counter_id = cla.counter_id
			WHERE cla.occ = @occ
			AND cla.service_id = @service_id
			AND ci.tip_value = 1
			AND ci.kol_day > 0
			GROUP BY	ci.fin_id
						,ci.counter_id
						,ci.kol_day) AS t1
		GROUP BY	fin_id
					,kol_day) AS t2
		OPTION(RECOMPILE)


	RETURN COALESCE(@kol, 0)

END
go

