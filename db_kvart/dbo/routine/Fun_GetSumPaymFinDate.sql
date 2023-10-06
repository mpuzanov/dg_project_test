CREATE   FUNCTION [dbo].[Fun_GetSumPaymFinDate] (@occ1 int, @fin_id1 smallint)  
RETURNS decimal(9,2) AS  
BEGIN 
--
--  Возвращаем сумму платежей за заданный фин. период (с 1 по последнее число)
--
   declare @res decimal(9,2)
   declare @start_date smalldatetime, @end_date smalldatetime
 
   select @start_date=start_date,
          @end_date=end_date
   from dbo.GLOBAL_VALUES where fin_id=@fin_id1
 
   select @res=sum(p.value)
   from dbo.PAYINGS as p
        JOIN dbo.PAYDOC_PACKS as pd ON p.pack_id=pd.id
   where p.occ=@occ1 
         and pd.day between @start_date and @end_date
 
 
if @res is Null set @res=0
 
RETURN @res
END
go

