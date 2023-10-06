-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[rep_ivc_pd_added]
(
	  @fin_id SMALLINT
	, @tip_id SMALLINT = NULL
	, @build_id INT = NULL
	, @sup_id INT = NULL
	, @occ INT = NULL
)
AS
/*
exec rep_ivc_pd_added @fin_id=233, @tip_id=1, @build_id = null, @sup_id = null, @occ= null
exec rep_ivc_pd_added @fin_id=233, @tip_id=1, @build_id = 6776, @sup_id = null, @occ= null
exec rep_ivc_pd_added @fin_id=233, @tip_id=1, @build_id = 6776, @sup_id = 345, @occ= null
*/
BEGIN
	SET NOCOUNT ON;

	SELECT f.bldn_id AS build_id
		 , ap.occ
		 , 'Перерасчет' AS [type]
		 , s.service_name AS usluga
		 , ap.[doc] AS osnovanie
		 , SUM(ap.value) AS summa
	FROM dbo.View_added_lite AS ap
		JOIN dbo.Added_Types at ON 
			ap.add_type = at.id
		JOIN dbo.Occupations o ON 
			ap.occ = o.occ
		JOIN dbo.Flats f ON 
			o.flat_id = f.id
		JOIN dbo.View_services_kvit AS s ON 
			ap.service_id = s.service_id
			AND o.tip_id = s.tip_id
			AND f.bldn_id = s.build_id
	WHERE ap.fin_id = @fin_id
		AND (o.tip_id = @tip_id OR @tip_id IS NULL)
		AND (ap.occ = @occ OR @occ IS NULL)
		AND ap.sup_id = COALESCE(@sup_id, 0)
		AND (f.bldn_id = @build_id OR @build_id IS NULL)
		AND ap.doc <> ''
		AND ap.value <> 0
		AND at.visible_kvit = 1
	GROUP BY f.bldn_id
		   , ap.occ
		   , s.service_name
		   , [doc]
END
go

