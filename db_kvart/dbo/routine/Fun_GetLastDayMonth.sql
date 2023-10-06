CREATE  FUNCTION [dbo].[Fun_GetLastDayMonth] (@date1 smalldatetime)  
RETURNS smalldatetime AS  
BEGIN 
--
--  Возвращаем дату с последним днем в месяце
--
   declare @date2 smalldatetime
   set @date2=dateadd(month,1,dateadd(day,1-day(@date1),@date1))-1 
   return @date2
END
go

