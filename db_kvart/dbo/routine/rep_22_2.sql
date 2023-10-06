CREATE   PROCEDURE [dbo].[rep_22_2] 
( @fin_id1 SMALLINT=NULL,
  @div_id1 SMALLINT = NULL,
  @laws_id1 SMALLINT = NULL,
  @tip SMALLINT=NULL 
)
AS
--
-- Предоставление лгот по ЖКУ(по  шифрам с разбивкой по услугам)
--
SET NOCOUNT ON


DECLARE @fin_current SMALLINT
SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip, NULL, NULL, NULL)
IF @fin_id1 IS NULL SET @fin_id1=@fin_current

SELECT 
	pl.lgotaAll AS lgota_id,
	dg.name,
	pl.service_id,
	SUM(pl.discount) AS VALUE
FROM
	dbo.View_PAYM_LGOTA_ALL AS pl,
	dbo.View_OCC_ALL AS o ,
	dbo.flats AS f ,
	dbo.buildings AS b ,
	dbo.dsc_groups AS dg 
WHERE pl.subsid_only=0
	AND f.bldn_id=b.id
	AND o.tip_id=coalesce(@tip,o.tip_id)
	AND b.div_id=coalesce(@div_id1,b.div_id)
	AND pl.lgotaall=dg.id
	AND dg.law_id=coalesce(@laws_id1,dg.law_id)
	AND pl.fin_id=@fin_id1
	AND o.fin_id=pl.fin_id
	AND pl.occ=o.occ
	AND o.flat_id=f.id
	AND o.status_id<>'закр'
GROUP BY pl.lgotaAll,dg.name,pl.service_id
ORDER BY pl.lgotaAll
go

