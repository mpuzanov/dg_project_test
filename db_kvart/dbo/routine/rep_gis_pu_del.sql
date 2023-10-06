-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[rep_gis_pu_del]
(
	@tip_id SMALLINT = NULL
	,@fin_id SMALLINT = NULL -- закрыты только в этом периоде
	,@build_id INT = NULL -- дом
)
AS
BEGIN
/*
закрытые ПУ (для гис жкх)

rep_gis_pu_del 28, 193

*/
	SET NOCOUNT ON;

	SELECT
		c.id_pu_gis
	   ,COALESCE(c.ReasonDel, 'Замена по иной причине') AS ReasonDel
	   ,c.date_del
	   ,c.serial_number
	   ,[dbo].[Fun_GetAdres](c.build_id,c.flat_id,NULL) AS address
	   ,c.service_id
	FROM dbo.Counters c
	JOIN dbo.Buildings b
		ON c.build_id = b.id
	JOIN dbo.Global_values gv ON c.date_edit BETWEEN gv.start_date AND gv.end_date
	WHERE c.date_del IS NOT NULL
	AND COALESCE(c.id_pu_gis, '') <> ''
	AND (@tip_id IS NULL OR b.tip_id = @tip_id)
	AND (@fin_id IS NULL OR gv.fin_id=@fin_id)
	AND (@build_id IS NULL OR c.build_id=@build_id)
	AND c.is_build=CAST(0 AS BIT)
	ORDER BY b.street_id, b.nom_dom_sort

END
go

