CREATE   FUNCTION [dbo].[Fun_GetCounterBlocked] (@occ1 int, @fin_id1 smallint = NULL)
RETURNS TABLE
AS
	/*
	 Выдаем список услуг по лицевому с заблокированными счетчиками
	
	дата: 12.12.2005
	
	SELECT service_id FROM Fun_GetCounterBlocked(@occ1, @fin_id1)
	
	*/
RETURN (
	SELECT
		cl.service_id
	FROM dbo.Counter_inspector AS ci
	JOIN dbo.Counter_list_all AS cl 
		ON cl.counter_id = ci.counter_id
	WHERE cl.occ = @occ1
		AND ci.blocked = 1
		AND (cl.fin_id=@fin_id1 
			OR cl.fin_id=dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1))
)
go

