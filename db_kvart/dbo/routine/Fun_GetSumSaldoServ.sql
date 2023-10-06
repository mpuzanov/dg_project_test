CREATE   FUNCTION [dbo].[Fun_GetSumSaldoServ] (@occ1 INT, @fin_id1 SMALLINT, @service_id1 VARCHAR(10))  
RETURNS DECIMAL(9,2) AS  
BEGIN 
/*
ДЛЯ РАСЧЁТА ПЕНИ

Возвращаем сумму САЛЬДО за заданный календарный месяц
за заданную услугу

дата: 01.10.04
*/

   DECLARE @res DECIMAL(9,2)
 
   SELECT @res=SUM(p.SALDO)
   FROM dbo.View_PAYM AS p 
   JOIN dbo.View_SERVICES AS s 
	ON p.service_id=s.id 
	AND s.is_peny=1  -- !!! для расчёта пени
   WHERE p.occ=@occ1          
         AND p.fin_id=@fin_id1
         AND (p.account_one=cast(0 as bit)) -- OR p.account_one IS NULL)
         AND p.service_id=COALESCE(@service_id1,p.service_id)
 
   IF @res IS NULL SET @res=0
 
RETURN @res
END
go

