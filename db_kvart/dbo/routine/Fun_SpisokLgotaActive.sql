CREATE   FUNCTION [dbo].[Fun_SpisokLgotaActive] (@owner_id1 int)  
RETURNS @TableLgota Table (id1 int)
AS  
--
--  Выдаем список льгот, которые могут быть активными
--
BEGIN 
declare @start_date smalldatetime
select @start_date=start_date from GLOBAL_VALUES  where closed=0

INSERT INTO @TableLgota
select do.id
from dsc_owners as do
where owner_id=@owner_id1 
 and expire_date>=@start_date 
 and DelDateLgota is null


RETURN

END
go

