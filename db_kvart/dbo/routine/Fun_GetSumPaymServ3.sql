CREATE   FUNCTION [dbo].[Fun_GetSumPaymServ3] (@occ1 INT, @fin_id1 SMALLINT, @service_id1 VARCHAR(10))  
RETURNS DECIMAL(9,2) AS  
BEGIN 
/*
ДЛЯ РАСЧЁТА ПЕНИ

Возвращаем сумму платежей за заданный календарный месяц
за заданную услугу

дата: 01.10.04
*/

   DECLARE @res DECIMAL(9,2), @start_date SMALLDATETIME, @end_date SMALLDATETIME   
   
   SELECT @start_date=start_date,  @end_date=end_date  FROM dbo.GLOBAL_VALUES  WHERE fin_id=@fin_id1
   
   IF @start_date IS NULL
   BEGIN
      DECLARE @fin_current SMALLINT
      SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)
      SELECT @start_date=start_date, @end_date=end_date FROM dbo.GLOBAL_VALUES WHERE fin_id=@fin_current
   END
 
   SELECT @res=SUM(ps.value)
   FROM dbo.PAYING_SERV AS ps 
   JOIN dbo.PAYINGS AS p 
	ON ps.paying_id=p.id
   JOIN dbo.PAYDOC_PACKS AS pd 
	ON pd.id=p.pack_id
   JOIN dbo.View_SERVICES as s 
	ON ps.service_id=s.id AND s.is_peny=1  -- !!! для расчёта пени
   WHERE ps.occ=@occ1          
         AND p.sup_id=0
         AND pd.day BETWEEN @start_date AND @end_date
--         and ps.service_id=@service_id1
 
 IF @res IS NULL SET @res=0
 
RETURN @res
END
go

