CREATE   PROCEDURE [dbo].[rep_10_sub12]
(
	@fin_id		SMALLINT
	,@tip_id	SMALLINT
	,@build_id1	INT = NULL
)
AS
	SET NOCOUNT ON

	-- находим значение текущего фин периода
	IF @fin_id IS NULL
		SELECT
			@fin_id = dbo.Fun_GetFinCurrent(@tip_id, NULL, NULL, NULL)

	SELECT
		oh.bldn_id
		,b.street_name AS streets
		,b.nom_dom AS nom_dom
		,oh.nom_kvr AS nom_kvr
		,oh.occ
		,oh.PaidAll - COALESCE(AddedAll, 0) AS valueAll
		,COALESCE(oh.AddedAll, 0) - dbo.Fun_GetSubsidia12(@fin_id, oh.occ, NULL, NULL) AS AddedAll
		,dbo.Fun_GetSubsidia12(@fin_id, oh.occ, NULL, NULL) AS sub12
		,oh.PaidAll
	FROM dbo.View_OCC_ALL AS oh 
	JOIN dbo.View_BUILD_ALL AS b 
		ON oh.bldn_id = b.bldn_id
	WHERE 
		oh.fin_id = @fin_id
		AND oh.STATUS_ID <> 'закр'
		AND b.fin_id = @fin_id
		AND (b.tip_id = @tip_id OR @tip_id IS NULL)
		AND (b.build_id = @build_id1 OR @build_id1 IS NULL)
		AND EXISTS (SELECT 1
					FROM dbo.SUBSIDIA12 AS S1
					WHERE S1.fin_id = @fin_id
						AND S1.occ = oh.occ
			)
	ORDER BY b.street_name, b.nom_dom_sort, oh.nom_kvr_sort
go

