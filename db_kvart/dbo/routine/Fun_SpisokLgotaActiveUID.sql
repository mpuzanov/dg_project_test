CREATE   FUNCTION [dbo].[Fun_SpisokLgotaActiveUID] 
(@people_uid UNIQUEIDENTIFIER)  
RETURNS @TableLgota Table (id1 int)
AS  
/*
  Выдаем список льгот, которые могут быть активными
*/
BEGIN 

declare @start_date smalldatetime
select @start_date=start_date from dbo.GLOBAL_VALUES where closed=0 ORDER BY fin_id DESC

INSERT INTO @TableLgota
select do.id
from dbo.dsc_owners as do 
where people_uid=@people_uid 
 and expire_date>=@start_date 
 and DelDateLgota is null


RETURN

END
go

