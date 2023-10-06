-- =============================================
-- Author:		Пузанов
-- Create date: 13.04.2010
-- Description:	Получаем предыдущие показания квартиросъемщика по заданному счетчику
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetCounterValue_pred]
(
	@counter_id	INT -- код счетчика
	,@fin_id	SMALLINT-- текущий фин.период
)
RETURNS DECIMAL(14, 6)
/*

select [dbo].[Fun_GetCounterValue_pred](100743,254)
select [dbo].[Fun_GetCounterValue_pred](55384,254)
*/
AS
BEGIN

	RETURN (
		SELECT TOP (1)
				CASE
					WHEN ci.inspector_value IS NULL THEN C.count_value
					ELSE ci.inspector_value
				END
		FROM dbo.Counters C
		LEFT JOIN dbo.Counter_inspector AS ci 
			ON ci.counter_id = C.id
			AND ci.fin_id < @fin_id
			AND ci.tip_value =
				CASE
					WHEN C.is_build = 1 THEN 2
					ELSE 1 --  квартиросъемщика
				END
		WHERE C.id = @counter_id
		ORDER BY 1 DESC
)

END
go

