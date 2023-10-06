-- =============================================
-- Author:		Пузанов
-- Create date: 1.04.2023
-- Description:	Получаем предпоследние показания по заданному счетчику в заданном месяце
-- =============================================
CREATE            FUNCTION [dbo].[Fun_GetCounterTableValue_Pred]
(
	@counter_id	INT -- код счетчика
	,@fin_id	SMALLINT-- фин.период
)
RETURNS TABLE
/*
OUTER APPLY [dbo].Fun_GetCounterTableValue_Pred(c.id, t.fin_id) AS ci_pred	

-- опу
select * from [dbo].Fun_GetCounterTableValue_Pred(101799, 260) AS ci_pred
*/
AS
RETURN (
	with cte as (
		SELECT top(1) coalesce(gv.counter_last_metod, 0) as last_metod 
		FROM dbo.Global_values as gv
		ORDER BY gv.fin_id DESC
	)
	SELECT TOP (1)
		C.id AS counter_id
		,CASE
				WHEN ci.inspector_date IS NULL THEN C.date_create
				ELSE ci.inspector_date
			END AS inspector_date
		,CASE
				WHEN ci.inspector_value IS NULL THEN C.count_value
				ELSE ci.inspector_value
			END AS inspector_value
		,ci.actual_value
		,ci.volume_arenda
		,ci.tarif
		,ci.volume_odn
		,ci.volume_direct_contract
		,ci.norma_odn
	FROM dbo.Counters C 
	cross join cte as gv
	LEFT JOIN dbo.Counter_inspector AS ci 
		ON ci.counter_id = C.id
		AND ci.fin_id < @fin_id
		AND (ci.blocked=CAST(0 AS BIT)) -- 24.08.17
		AND (  
			(ci.tip_value = 1 AND gv.last_metod = 0) -- 1-показания квартиросьемщика для KOMP считать от последнего показания
			OR
			(ci.tip_value = 1 AND (ci.metod_rasch=3 OR ci.metod_rasch is null) and gv.last_metod = 3) -- 1 для kr1 от последнего показания где расчитали по ИПУ
			OR 
			ci.tip_value in (0,2)  -- 0-показание инспектора, 2-опу
			) -- 21.08.23  
	WHERE C.id = @counter_id
	ORDER BY ci.fin_id DESC, ci.inspector_date DESC, ci.id DESC
)
go

