-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[rep_gis_occ_del]
(
	@tip_id	  SMALLINT = NULL
   ,@fin_id	  SMALLINT = NULL -- закрыты только в этом периоде
   ,@build_id INT	   = NULL -- дом
   ,@sup_id	  INT	   = NULL --поставщик
)
AS
BEGIN
	/*
	закрытые лицевые счета (для гис жкх)
	
	exec rep_gis_occ_del @tip_id=28, @fin_id=193,@build_id=null,@sup_id=NULL
	exec rep_gis_occ_del @tip_id=195, @fin_id=248,@build_id=null,@sup_id=365
	
	exec rep_gis_occ_del

	Возможные причины когда не задана при закрытии:
		Ошибка ввода
		Изменение реквизитов лицевого счета

	*/
	SET NOCOUNT ON;
	
	IF @sup_id IS NULL
		SELECT
			dbo.Fun_GetFalseOccOut(o.occ, o.tip_id) AS occ
			--o.occ
		   ,o.id_jku_gis
		   ,o.address
		   ,ol.done AS date_del
		   ,COALESCE(ol.comments, 'Изменение реквизитов лицевого счета') AS ReasonDel
		--,o.STATUS_ID
		--,ol.op_id
		FROM dbo.OCCUPATIONS o
		JOIN dbo.OP_LOG ol
			ON o.occ = ol.occ
			AND ol.op_id = 'удлс'
		JOIN dbo.FLATS f
			ON o.flat_id = f.id
		JOIN dbo.GLOBAL_VALUES gv
			ON ol.done BETWEEN gv.start_date AND gv.end_date
		WHERE o.status_id = 'закр'
		AND COALESCE(o.id_jku_gis, '') <> ''
		AND (o.tip_id = @tip_id
		OR @tip_id IS NULL)
		AND (gv.fin_id = @fin_id
		OR @fin_id IS NULL)
		AND (f.bldn_id = @build_id
		OR @build_id IS NULL)
	ELSE
		SELECT DISTINCT
			os.occ_sup AS occ
		   ,os.id_jku_gis
		   ,o.address
		   ,ol.done AS date_del
		   ,COALESCE(ol.comments, 'Изменение реквизитов лицевого счета') AS ReasonDel
		--,o.STATUS_ID
		--,ol.op_id		
		FROM OCC_SUPPLIERS os
		JOIN dbo.OCCUPATIONS o
			ON os.occ = o.occ
		JOIN dbo.OP_LOG ol
			ON o.occ = ol.occ
			AND ol.op_id = 'удлс'
		JOIN dbo.FLATS f
			ON o.flat_id = f.id
		JOIN dbo.GLOBAL_VALUES gv
			ON ol.done BETWEEN gv.start_date AND gv.end_date
			 --AND os.fin_id=gv.fin_id
		WHERE o.status_id = 'закр'
		AND COALESCE(os.id_jku_gis, '') <> ''
		AND (o.tip_id = @tip_id
		OR @tip_id IS NULL)
		AND (gv.fin_id = @fin_id
		OR @fin_id IS NULL)
		AND (f.bldn_id = @build_id
		OR @build_id IS NULL)
		AND os.sup_id=@sup_id


END
go

