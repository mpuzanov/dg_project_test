CREATE   FUNCTION [dbo].[Fun_GetSumPlus2] (@Sum1 decimal(15,2), @Sum2 decimal(15,2), @Sum3 decimal(15,2))  
RETURNS decimal(15,2) AS  
BEGIN 
/*

Возвращаем первый положительный входной параметр
если все отрицательные то  возвращаем Ноль

дата: 07.10.04
*/

   declare @res decimal(15,2)
   set @res=0

   if  (@Sum1>0) RETURN @Sum1
   if  (@Sum2>0) RETURN @Sum2
   if  (@Sum3>0) RETURN @Sum3


RETURN @res

END
go

