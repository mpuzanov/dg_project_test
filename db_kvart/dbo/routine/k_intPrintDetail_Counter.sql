CREATE   PROCEDURE [dbo].[k_intPrintDetail_Counter]
( @occ1 INT,
  @service_id1 VARCHAR(10)
)
AS
--
--
--
SET NOCOUNT ON

DECLARE @fin_id1 SMALLINT,@source_id1 INT

SELECT @fin_id1=o.fin_id, @source_id1=source_id
FROM dbo.OCCUPATIONS as o 
JOIN dbo.CONSMODES_LIST as cl ON o.Occ=cl.occ
WHERE o.occ=@occ1 
	AND cl.service_id=@service_id1


SELECT cl.*, 
c.*,
s.short_name,
tarif=dbo.Fun_GetCounterTarf(@fin_id1,c.id,NULL)
FROM 
	dbo.View_COUNTER_ALL AS cl 
	JOIN dbo.COUNTERS AS c ON cl.counter_id=c.id 
	JOIN dbo.SERVICES AS s ON cl.service_id=s.id
WHERE cl.occ=@occ1 
AND cl.fin_id=@fin_id1
AND cl.service_id=@service_id1
AND c.Date_del IS NULL
go

