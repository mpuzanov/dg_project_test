-- =============================================
-- Author:		Пузанов
-- Create date: 22.06.2016
-- Description:	Получаем предыдущие показания по заданному счетчику и показателю
-- =============================================
CREATE          FUNCTION [dbo].[Fun_GetCounterTableValue_PredCI]
(
	  @counter_id INT -- код счётчика
	, @id INT -- код инспектора
	, @inspector_date SMALLDATETIME = NULL
	--, @metod_rasch SMALLINT = NULL 
)
RETURNS TABLE
--RETURNS @ResultTable TABLE (
--	  counter_id INT
--	, inspector_date SMALLDATETIME DEFAULT NULL
--	, inspector_value DECIMAL(14, 6) DEFAULT NULL
--	, actual_value DECIMAL(14, 6) DEFAULT NULL
--	, volume_arenda DECIMAL(14, 6) DEFAULT NULL
--	, fin_ppu SMALLINT DEFAULT NULL 
--)
/*
OUTER APPLY [dbo].Fun_GetCounterTableValue_PredCI(c.id, ci.id, null) AS ci_pred	

select * FROM [dbo].Fun_GetCounterTableValue_PredCI(83900, 2292493, null)
*/
AS
--BEGIN

--	INSERT INTO @ResultTable (counter_id
--							, inspector_date
--							, inspector_value
--							, actual_value
--							, volume_arenda
--							, fin_ppu)
RETURN (
	with cte as (
		SELECT top(1) coalesce(gv.counter_last_metod, 0) as last_metod 
		FROM dbo.Global_values as gv
		ORDER BY gv.fin_id DESC
	)
	SELECT TOP (1) C.id AS counter_id
				 , CASE
						WHEN ci.inspector_date IS NULL THEN C.date_create
						ELSE ci.inspector_date
					END AS inspector_date
				 , CASE
						WHEN ci.inspector_value IS NULL THEN C.count_value
						ELSE ci.inspector_value
					END AS inspector_value
				 , ci.actual_value AS actual_value
				 , ci.volume_arenda AS volume_arenda
				 , ci.fin_id AS fin_ppu
	FROM dbo.Counters C
	    cross join cte as gv
		LEFT JOIN dbo.Counter_inspector AS ci 
			ON ci.counter_id = C.id
				AND (ci.id < @id	 -- !!! Если созали позже показания и закинули в прошлый период - то его не будет!
				OR ci.inspector_date < @inspector_date)
				AND (ci.blocked = CAST(0 AS BIT))	-- 24.08.17
				AND (  
					(ci.tip_value = 1 AND gv.last_metod = 0) -- 1-показания квартиросьемщика для KOMP считать от последнего показания
					OR
					(ci.tip_value = 1 AND (ci.metod_rasch=3 OR ci.metod_rasch is null) and gv.last_metod = 3) -- 1 для kr1 от последнего показания где расчитали по ИПУ
					OR 
					ci.tip_value in (0,2)  -- 0-показание инспектора, 2-опу
					) -- 21.08.23  
	WHERE 
		C.id = @counter_id
	ORDER BY ci.inspector_date DESC
		   , ci.id DESC

)
go

