CREATE   PROCEDURE [dbo].[rep_20]
--  Ведомость по лицевым счетам  "Список льготников"
( @fin_id1 SMALLINT, 
  @div_id1 SMALLINT =NULL,
  @lgota_id1 SMALLINT=NULL, 
  @tip SMALLINT=NULL
)
AS

SET NOCOUNT ON

/*
 Списки льготников 
 1) в заданном месяце
 2) по районам
 3) по шифрам льгот
*/ 

SELECT p.last_name,
       p.first_name,
       p.second_name,
       dr.occ,
       o.address,
       p.birthdate,
       dr.doc,
       dr.issued,
       dr.issued2,
       dr.lgota_id,
       dr.kol_people,
       dr.summa
FROM dbo.DSC_REP AS dr ,
 dbo.VOCC AS o  ,
 dbo.FLATS AS f  ,
 dbo.BUILDINGS AS b  ,
 dbo.PEOPLE AS p  
WHERE 
	dr.fin_id=@fin_id1
	AND dr.lgota_id=COALESCE(@lgota_id1,dr.lgota_id)
	AND dr.occ=o.occ
	AND dr.owner_id=p.id
	AND o.flat_id=f.id
	AND f.bldn_id=b.id
	AND b.div_id=COALESCE(@div_id1,b.div_id)
	AND dr.summa>0
	--AND o.status_id<>'закр'
	AND o.tip_id=COALESCE(@tip,o.tip_id)
ORDER BY p.last_name,p.first_name,p.second_name
go

