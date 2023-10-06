CREATE   FUNCTION [dbo].[Fun_GetSumPaymSup] (@occ1 INT, @fin_id1 SMALLINT, @sup_id INT, @Par TINYINT)  
RETURNS DECIMAL(9,2) AS  
BEGIN 
/*
ДЛЯ РАСЧЁТА ПЕНИ

дата: 03.12.11

select dbo.Fun_GetSumPaymSup (65052, 118, 300, 3) 

*/

   DECLARE @res DECIMAL(9,2)
   DECLARE @start_date SMALLDATETIME, @end_date SMALLDATETIME
 
   SELECT @start_date=start_date,  @end_date=end_date  FROM dbo.GLOBAL_VALUES WHERE fin_id=@fin_id1
 
 --Возвращаем сумму платежей за заданный фин. период  до  первого числа данного месяца
 IF @Par=1 
 BEGIN
   SELECT @res=SUM(ps.value)
   FROM dbo.PAYING_SERV AS ps 
   JOIN dbo.PAYINGS AS p ON ps.paying_id=p.id
   JOIN dbo.PAYDOC_PACKS AS pd ON p.pack_id=pd.id
   JOIN dbo.SERVICES AS s ON ps.service_id=s.id AND s.is_peny=1  -- !!! для расчёта пени
   WHERE ps.occ=@occ1          
         AND p.fin_id=@fin_id1
         AND pd.day<@start_date
         AND p.sup_id=@sup_id
 END
 
 IF @Par=2  -- Возвращаем сумму платежей за заданный фин. период
 BEGIN
	SELECT @res=SUM(ps.value)
	FROM dbo.PAYING_SERV AS ps 
	JOIN dbo.PAYINGS AS p ON ps.paying_id=p.id
	JOIN dbo.SERVICES AS s ON ps.service_id=s.id AND s.is_peny=1  -- !!! для расчёта пени
	WHERE ps.occ=@occ1          
		 AND p.fin_id=@fin_id1
		 AND p.sup_id=@sup_id
 END
 
 IF @Par=3  -- Возвращаем сумму платежей за заданный календарный месяц
 BEGIN
   SELECT @res=SUM(ps.value)
   FROM dbo.PAYING_SERV AS ps
   JOIN dbo.PAYINGS AS p ON ps.paying_id=p.id
   JOIN dbo.PAYDOC_PACKS AS pd ON pd.id=p.pack_id
   JOIN dbo.SERVICES AS s ON ps.service_id=s.id AND s.is_peny=1  -- !!! для расчёта пени
   WHERE ps.occ=@occ1          
         AND p.sup_id=@sup_id
         AND pd.day BETWEEN @start_date AND @end_date 
 END
 
  
 IF @Par=4  -- Возвращаем сумму САЛЬДО по услугам за заданный месяц
 BEGIN
   SELECT @res=SUM(p.SALDO)
   FROM dbo.View_PAYM AS p
   JOIN dbo.SERVICES AS s ON p.service_id=s.id AND s.is_peny=1  -- !!! для расчёта пени
   JOIN dbo.View_SUPPLIERS AS vs ON s.id=vs.service_id
   WHERE p.occ=@occ1          
         AND p.fin_id=@fin_id1
         AND vs.sup_id=@sup_id
 END
  
 IF @res IS NULL SET @res=0
 
RETURN @res
END
go

