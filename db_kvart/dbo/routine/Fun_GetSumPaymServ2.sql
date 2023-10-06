CREATE   FUNCTION [dbo].[Fun_GetSumPaymServ2] (@occ1 INT, @fin_id1 SMALLINT, @service_id1 VARCHAR(10))  
RETURNS DECIMAL(9,2) AS  
BEGIN 
/*
ДЛЯ РАСЧЁТА ПЕНИ

Возвращаем сумму платежей за заданный фин. период )
за заданную услугу

дата: 01.10.04
*/

   DECLARE @res DECIMAL(9,2)
 
   SELECT @res=SUM(ps.value)
   FROM dbo.PAYING_SERV AS ps 
   JOIN dbo.PAYINGS AS p ON ps.paying_id=p.id
   JOIN dbo.View_SERVICES as s ON ps.service_id=s.id AND s.is_peny=1  -- !!! для расчёта пени
   WHERE ps.occ=@occ1          
         AND p.fin_id=@fin_id1
         AND p.sup_id=0
--         and ps.service_id=@service_id1
 
 IF @res IS NULL SET @res=0
 
RETURN @res
END
go

