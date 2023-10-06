CREATE   PROCEDURE [dbo].[rep_modes_source2]
( @fin_id SMALLINT,
  @service_id1 VARCHAR(10),
  @mode_id1 INT=NULL,
  @source_id1 INT=NULL,
  @jeu_id1 SMALLINT=NULL,
  @build1 INT=NULL,
  @tip_id1 SMALLINT = NULL,
  @div_id1 SMALLINT = NULL
)
AS
/*
Выдает количество лицевых с заданными режимами потребления и поставщика

Отчет: modes_source2.fr3

изменил: 23.09.2009

*/
SET NOCOUNT ON


IF @mode_id1 IS NULL AND @source_id1 IS NULL
BEGIN
  RAISERROR('Задайте режим или поставщика!',16,1)
  RETURN
END


SELECT b.sector_id,
       c2.name AS mode_name,
       c3.name AS source_name, 
       COUNT(oh.occ) AS kol_lic,
       SUM(p.paid) AS paid,
	   SUM(p.paymaccount) AS paymaccount 
FROM dbo.View_CONSMODES_ALL AS ch 
     JOIN dbo.cons_modes AS c2 
		ON c2.id=ch.mode_id
     JOIN dbo.suppliers AS c3 
		ON c3.id=ch.source_id
     JOIN dbo.View_OCC_ALL AS oh 
		ON ch.occ=oh.occ AND ch.fin_id=oh.fin_id
     JOIN dbo.flats AS f 
		ON oh.flat_id=f.id
     JOIN dbo.View_BUILD_ALL AS b 
		ON f.bldn_id=b.bldn_id AND b.fin_id=oh.fin_id
     JOIN dbo.View_PAYM AS p 
		ON ch.occ=p.occ AND ch.fin_id=p.fin_id AND ch.service_id=p.service_id
WHERE ch.fin_id=@fin_id
	AND ch.service_id=@service_id1 
	AND oh.status_id<>'закр'
	AND ch.mode_id=COALESCE(@mode_id1,ch.mode_id)
	AND ch.source_id=COALESCE(@source_id1,ch.source_id)
	AND b.bldn_id=COALESCE(@build1,b.bldn_id)
	AND b.sector_id=COALESCE(@jeu_id1,b.sector_id)
	AND b.tip_id=COALESCE(@tip_id1,b.tip_id)
	AND b.div_id=COALESCE(@div_id1,b.div_id)
GROUP BY 
  b.sector_id, 
  c2.name,
  c3.name
ORDER BY b.sector_id
go

