CREATE   PROCEDURE [dbo].[rep_21_2]
( @fin_id1 SMALLINT =NULL,
  @div_id1 SMALLINT = NULL,
  @laws_id1 SMALLINT = NULL,
  @tip SMALLINT=NULL 
)
AS
--
--  Предоставление льгот за ЖКУ (по шифрам льгот)
--
SET NOCOUNT ON


DECLARE @fin_current SMALLINT
SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip, NULL, NULL, NULL)
IF @fin_id1=NULL SET @fin_id1=@fin_current


CREATE TABLE #t1
( 
lgotaall INT 
,occ INT 
,total_sq DECIMAL(9,2)
)

INSERT INTO #t1
SELECT	DISTINCT 
	pl.lgotaall
	,pl.owner_lgota
	,o.total_sq	
FROM	
     dbo.View_PAYM_LGOTA_ALL AS pl 
	,dbo.dsc_groups AS dg
	,dbo.View_OCC_ALL AS o 
	,dbo.flats AS f 
	,dbo.View_BUILD_ALL AS b
WHERE	pl.subsid_only=0
	AND pl.fin_id=@fin_id1
	AND dg.id=pl.lgotaall
	AND o.occ=pl.occ
	AND o.fin_id=pl.fin_id
	AND o.status_id<>'закр'
	AND o.flat_id=f.id
	AND f.bldn_id=b.bldn_id
	AND o.tip_id=coalesce(@tip,o.tip_id)
	AND b.div_id=coalesce(@div_id1,b.div_id)
	AND dg.law_id=coalesce(@laws_id1,dg.law_id)
	AND b.fin_id=@fin_id1

SELECT	
    pl.lgotaall AS lgota_id
	,dg.name 
	,COUNT(DISTINCT pl.owner_lgota)AS kol_lg
	,COUNT(DISTINCT pl.owner_id)AS kol_people
	,SUM(pl.discount) AS summa
	,(SELECT SUM(#t1.total_sq) FROM #t1 WHERE pl.lgotaall=#t1.lgotaall) AS total_sq
FROM
	 dbo.View_PAYM_LGOTA_ALL AS pl 
	,dbo.dsc_groups AS dg
	,dbo.View_OCC_ALL AS o 
	,dbo.flats AS f
	,dbo.View_BUILD_ALL AS b
WHERE	pl.subsid_only=0
	AND pl.fin_id=@fin_id1
	AND dg.id=pl.lgotaall
	AND o.occ=pl.occ
	AND o.fin_id=pl.fin_id
	AND o.status_id<>'закр'
	AND o.flat_id=f.id
	AND f.bldn_id=b.bldn_id
	AND o.tip_id=coalesce(@tip,o.tip_id)
	AND b.div_id=coalesce(@div_id1,b.div_id)
	AND dg.law_id=coalesce(@laws_id1,dg.law_id)
	AND b.fin_id=@fin_id1
GROUP BY pl.lgotaall,dg.name
ORDER BY pl.lgotaall
go

