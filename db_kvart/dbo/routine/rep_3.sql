CREATE   PROCEDURE [dbo].[rep_3]
( @Fin_id1 SMALLINT,
  @service_id1 VARCHAR(10),
  @jeu1 SMALLINT = NULL,
  @tip SMALLINT=NULL 
)
AS
--
--  Начисления по режимам потребления
--
SET NOCOUNT ON


IF @Fin_id1 IS NULL
	-- находим значение текущего фин периода
	SELECT @Fin_id1 = dbo.Fun_GetFinCurrent(@tip, NULL, NULL, NULL) 

  SELECT sp.name, 
       SUM(pl.value) AS VALUE, 
       SUM(pl.added) AS added, 
       SUM(pl.discount) AS discount, 
       SUM(pl.compens) AS compens, 
       SUM(pl.paid) AS paid
  FROM dbo.View_PAYM AS pl 
       JOIN dbo.cons_modes AS sp ON pl.mode_id=sp.id
       JOIN dbo.View_OCC_ALL AS o 
			ON pl.occ=o.occ AND o.fin_id=pl.fin_id
       JOIN dbo.View_BUILD_ALL AS b 
			ON b.fin_id=pl.fin_id AND o.bldn_id=b.bldn_id
  WHERE 1=1
      AND pl.fin_id=@fin_id1
      AND o.tip_id=COALESCE(@tip,o.tip_id) 
      AND pl.service_id=@service_id1
      AND b.sector_id = COALESCE(@jeu1,b.sector_id)
      AND pl.subsid_only=0
  GROUP BY sp.name
go

