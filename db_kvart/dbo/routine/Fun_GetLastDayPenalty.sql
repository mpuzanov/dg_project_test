CREATE  FUNCTION [dbo].[Fun_GetLastDayPenalty] (@fin_id1 smallint)  
RETURNS smalldatetime AS  
BEGIN 
--
--  Возвращаем дату, по которою можно заплатить без пени
--  за  заданный фин.период
--
   declare @date1 smalldatetime, 
              @LastDay1 tinyint, 
              @LastDayDate1 smalldatetime, 
              @fin_current smallint
 
   SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)
   if @fin_id1>@fin_current set @fin_id1=@fin_current
 
   select  @date1=start_date, @LastDay1=LastPaym  from dbo.GLOBAL_VALUES where fin_id=@fin_id1
  
   select  @date1=DateAdd(Month,1,@date1)
   --
   select @LastDayDate1=DateAdd(Day,@LastDay1-1,@date1)
 
   -- если месяца не совпадают то 
   if DATEPART(Month,@LastDayDate1)<>DATEPART(Month,@Date1)
   begin
     --последний день следущего месяца
      select @LastDayDate1=dateadd(month,1,dateadd(day,1-day(@date1),@date1))-1
   end
   return @LastDayDate1
 
END
go

