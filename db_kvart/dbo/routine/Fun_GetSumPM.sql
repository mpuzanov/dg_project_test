CREATE   FUNCTION [dbo].[Fun_GetSumPM] (@status_id1 smallint, @data_pm1 smalldatetime)  
RETURNS decimal(15,2) AS  
BEGIN 
/*
Возращаем прожиточный минимум по заданному соц.статусу на определеннную дату

дата: 20.07.06
*/

declare @res decimal(15,2)

select top 1 @res=summa_pm
from LIVING_WAGE
where status_id=@status_id1
and data_pm<=@data_pm1
order by data_pm desc

if @res is Null  set  @res=0
 
RETURN @res
END
go

