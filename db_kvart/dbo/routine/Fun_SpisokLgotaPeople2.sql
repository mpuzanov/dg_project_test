CREATE   FUNCTION [dbo].[Fun_SpisokLgotaPeople2] (@occ1 int)  
RETURNS @TableLgota Table (occ int, lgota_id int, Kol int) 
AS  
--
--  Выдаем список льгот по лицевому счету
--
BEGIN 

INSERT INTO @TableLgota
select distinct occ, lgota_id, count(occ)
from dbo.PEOPLE 
where  occ=@occ1 and lgota_id>0 and Del=0
group by occ, lgota_id

RETURN

END
go

