CREATE   PROCEDURE [dbo].[rep_21]
( @fin_id1 SMALLINT,
  @div_id1 SMALLINT = NULL,
  @laws_id1 SMALLINT = NULL,
  @tip SMALLINT=NULL 
)
AS
/*
Предоставление льгот за ЖКУ (по шифрам льгот)
*/
SET NOCOUNT ON


SELECT lgota_id, dg.name, 
       SUM(dr.kol_people) AS Kol_people, 
       COUNT(owner_id) AS Kol_lg,
       SUM(Summa) AS summa,
       SUM(dr.total_sq) AS total_sq
FROM dbo.dsc_rep AS dr,
     dbo.occupations AS o ,
     dbo.flats AS f ,
     dbo.buildings AS b ,
     dbo.dsc_groups AS dg 
WHERE 
	dr.fin_id=@fin_id1
	AND dr.occ=o.occ
	AND o.flat_id=f.id
	AND f.bldn_id=b.id
	AND b.div_id=COALESCE(@div_id1,b.div_id)
	AND dr.lgota_id=dg.id
	AND dg.law_id = COALESCE(@laws_id1,dg.law_id)
	AND dr.summa>0
	AND o.status_id<>'закр'
	AND o.tip_id = COALESCE(@tip,o.tip_id)
GROUP BY lgota_id, dg.name
ORDER BY lgota_id
go

