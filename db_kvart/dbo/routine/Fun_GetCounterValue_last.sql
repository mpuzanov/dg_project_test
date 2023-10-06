-- =============================================
-- Author:		Пузанов
-- Create date: 1.04.2023
-- Description:	Получаем последние показания по заданному счетчику
-- =============================================
CREATE      FUNCTION [dbo].[Fun_GetCounterValue_last]
(
	  @counter_id INT -- код счетчика
	, @fin_id SMALLINT-- текущий фин.период
)
RETURNS TABLE
/*
select * FROM [dbo].[Fun_GetCounterValue_last](26905,250)
OUTER APPLY [dbo].Fun_GetCounterValue_last(c.id, @fin_id) AS ci_last
*/
AS
RETURN (
	SELECT TOP (1) c.id
				 , CASE
					   WHEN ci.inspector_date IS NULL THEN c.date_create
					   ELSE ci.inspector_date
				   END AS inspector_date
				 , CASE
					   WHEN ci.inspector_value IS NULL THEN c.count_value
					   ELSE ci.inspector_value
				   END AS inspector_value
				 , ci.actual_value
				 , ci.volume_arenda
				 , ci.tarif
	FROM dbo.Counters c 
		LEFT JOIN dbo.Counter_inspector AS ci ON ci.counter_id = c.id
			AND ci.fin_id <= @fin_id
	WHERE c.id = @counter_id
	ORDER BY ci.inspector_date DESC
		   , ci.id DESC
)
go

