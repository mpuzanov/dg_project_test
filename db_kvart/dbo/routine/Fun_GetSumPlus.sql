CREATE   FUNCTION [dbo].[Fun_GetSumPlus] (@Sum1 decimal(15,2) )  
RETURNS decimal(15,2) AS  
BEGIN 
/*

Если входной парамтр отрицательный 
то возвращаем Ноль
иначе без изменений

дата: 01.10.04
*/

   declare @res decimal(15,2)

   if  (@Sum1<0) or (@Sum1 is Null)  set  @res=0
   ELSE set @res=@Sum1

 
RETURN @res
END
go

