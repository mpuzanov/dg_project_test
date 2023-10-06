CREATE   FUNCTION [dbo].[Fun_SpisokLgotaPeople] ()  
RETURNS @TableLgota Table (occ int, lgota_id int, Kol int) 
AS  
--  SELECT lg.* FROM dbo.Fun_SpisokLgotaPeople() as lg WHERE lg.occ=99981
--  Выдаем список льгот по базе
--
BEGIN 

INSERT INTO @TableLgota
select distinct occ, lgota_id, count(occ)
from dbo.PEOPLE 
where  lgota_id>0 and Del=0
group by occ, lgota_id

RETURN

END
go

