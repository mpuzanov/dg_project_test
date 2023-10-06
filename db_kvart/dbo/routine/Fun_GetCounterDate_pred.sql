-- =============================================
-- Author:		Пузанов
-- Create date: 13.04.2010
-- Description:	Получаем дату предыдущего показания квартиросъемщика по заданному счетчику
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetCounterDate_pred]
(
	@counter_id	INT -- код счетчика
	,@fin_id	SMALLINT   -- текущий фин.период
)
RETURNS SMALLDATETIME
AS
/*
select * FROM dbo.Counters AS C where not exists(select * from Counter_inspector as ci where ci.counter_id=c.id)

select dbo.Fun_GetCounterDate_pred(100743,254)
select dbo.Fun_GetCounterDate_pred(55384,254)

*/
BEGIN

	RETURN (SELECT TOP (1)
			COALESCE(ci.inspector_date, c.date_create)  AS inspector_date
		FROM dbo.Counters AS C 
		LEFT JOIN dbo.Counter_inspector AS ci ON c.id=ci.counter_id
			AND ci.fin_id < @fin_id
			AND ci.tip_value = 1  --  квартиросъемщика
		WHERE c.id = @counter_id			
		ORDER BY 1 DESC
	)

END
go

