CREATE   PROCEDURE  [dbo].[ka_show_vinovnik] 
( @occ1 INT,
  @service_id1 VARCHAR(10),
  @tip1 SMALLINT =1 -- тип виновника участок или поставщик
)
AS
--
--  Показываем возможных виновников
--
SET NOCOUNT ON

 
IF @tip1=1
BEGIN

 SELECT Cast(s.id as INT) as id, CAST(s.name as VARCHAR(30)) as name
 FROM  dbo.SECTOR AS s

END
 
IF @tip1=2
BEGIN

 SELECT Cast(s.id as INT) as id, CAST(s.name as VARCHAR(30)) as name
 FROM  dbo.View_SUPPLIERS AS s
 WHERE s.service_id=@service_id1


END
go

