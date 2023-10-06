CREATE   FUNCTION [dbo].[Fun_GetProcentAgenta] (@kol_mes smallint,@dog_int int, @collector_id smallint=Null)  
RETURNS decimal(6,2)
AS 
/* 
--
-- Процент возмещения агенту (коллектору)
--
SELECT [dbo].[Fun_GetProcentAgenta] (8,10, Null)
SELECT [dbo].[Fun_GetProcentAgenta] (8,Null, Null)
*/
BEGIN 
	declare @procent decimal(6,2)=0
	IF @dog_int is null set @dog_int=0 
   
	IF @collector_id is NULL 
	BEGIN
		SELECT @procent=procent  -- находим процент по договору если есть
		FROM dbo.STAVKI_AGENTA 
		WHERE @kol_mes BETWEEN mes1 AND mes2
		AND dog_int=coalesce(@dog_int,0)
		
		IF @procent=0  -- если нет берём общий
		SELECT @procent=procent
		FROM dbo.STAVKI_AGENTA 
		WHERE @kol_mes BETWEEN mes1 AND mes2
		AND dog_int=0
	END
	ELSE
		SELECT @procent=COALESCE(procent,0)
		FROM dbo.COLLECTORS 
		WHERE id=@collector_id	
		
	return @procent

END
go

