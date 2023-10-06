-- =============================================
-- Author:		Пузанов
-- Create date: 1.09.2013
-- Description:	Получаем показания по заданному счетчику в заданном месяце
-- =============================================
CREATE        FUNCTION [dbo].[Fun_GetCounterTableValue_Current]
(
	@counter_id INT -- код счетчика
   ,@fin_id		SMALLINT-- текущий фин.период
)
RETURNS TABLE
/*
OUTER APPLY [dbo].Fun_GetCounterTableValue_Current(c.id, t.fin_id) AS ci
*/
AS

RETURN (
		SELECT TOP (1)
			ci.counter_id
		   ,ci.inspector_date
		   ,ci.inspector_value
		   ,ci.actual_value
		   ,ci.tarif
		   ,ci.volume_arenda
		   ,ci.value_vday
		   ,ci.is_info
		   ,ci.kol_day
		   ,ci.volume_odn
		   ,ci.volume_direct_contract
		   ,ci.norma_odn
		FROM dbo.Counter_inspector as ci
		JOIN dbo.Counters c
			ON ci.counter_id = C.id
		WHERE ci.counter_id = @counter_id
			AND ci.fin_id = @fin_id
		ORDER BY ci.inspector_date DESC, ci.id DESC
)
go

