CREATE   FUNCTION [dbo].[Fun_GetSumPaymFin] (@occ1 int, @fin_id1 smallint)  
RETURNS decimal(9,2) AS  
BEGIN 
--
--  Возвращаем сумму платежей за заданный фин. период
--
    declare @res decimal(9,2)
    declare @fin_current smallint 
 
    SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)
 
if @fin_id1=@fin_current
begin
   select @res=paymaccount
   from dbo.occupations
   where occ=@occ1
end
else
begin
   select @res=paymaccount
   from dbo.occ_history
   where occ=@occ1 and fin_id=@fin_id1
end
 
if @res is Null set @res=0
 
RETURN @res
END
go

