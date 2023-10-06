-- =============================================
-- Author:		Пузанов
-- Create date: 14.02.2011
-- Description:	Признак первого показания квартиросъёмщика при внутреннем счетчике
-- =============================================
CREATE   FUNCTION [dbo].[Fun_FirstInternalCounter]
(
	@flat_id1 INT, 
	@service_id1 CHAR(4),
	@fin_current SMALLINT
)
RETURNS BIT
-- SELECT @first_internal = [dbo].[Fun_FirstInternalCounter](@flat_id1, @service_id1, @fin_current)
AS
BEGIN
	DECLARE @first_internal BIT, @internal BIT, @kol_mes_history smallint
	
	SELECT TOP 1 @internal=internal 
	FROM dbo.Counters AS c 
	WHERE flat_id=@flat_id1 AND service_id=@service_id1
	
	  
	if @kol_mes_history is null set @kol_mes_history=0
	
	IF EXISTS(
		SELECT ci.*
		FROM dbo.COUNTERS AS c 
		  JOIN dbo.COUNTER_INSPECTOR AS ci ON c.id=ci.counter_id
		  JOIN dbo.COUNTER_LIST_ALL AS cl ON c.id=cl.counter_id AND ci.fin_id=cl.fin_id
		WHERE c.flat_id=@flat_id1
		  AND c.service_id=@service_id1
		  AND ci.fin_id<@fin_current
		  AND cl.internal=1
	)
	SET @first_internal=0
	ELSE
	begin 
		if @internal=1 and @kol_mes_history=0 
			SET @first_internal=0
		else
			SET @first_internal=1
	end
	
	RETURN @first_internal

END
go

