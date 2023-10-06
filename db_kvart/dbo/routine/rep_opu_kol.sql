-- =============================================
-- Author:		Пузанов
-- Create date: 12.09.2013
-- Description:	для отчёта: Объём общедомовых уcлуг
-- =============================================
CREATE         PROCEDURE [dbo].[rep_opu_kol]
(
	@fin_id			SMALLINT
	,@tip_id		SMALLINT
	,@service_id	VARCHAR(10)	= NULL
)
/*
rep_opu_kol 244,4,'хвод'
*/
AS
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #s
	(
		id				VARCHAR(10)	 COLLATE database_default PRIMARY KEY	
		,name			VARCHAR(100) COLLATE database_default
		,is_build_serv	VARCHAR(10)	 COLLATE database_default
		,is_build		BIT
	)
	IF @service_id IS NULL
		INSERT
		INTO #s
		(	id
			,name
			,is_build_serv
			,is_build)
			SELECT
				id
				,short_name
				,is_build_serv
				,is_build
			FROM dbo.View_SERVICES
	ELSE
		INSERT
		INTO #s
		(	id
			,name
			,is_build_serv
			,is_build)
			SELECT
				id
				,short_name
				,is_build_serv
				,is_build
			FROM dbo.View_SERVICES AS vs
			WHERE vs.id = @service_id
			OR vs.is_build_serv = @service_id

	--SELECT * FROM #s

	CREATE TABLE #t
	(
		build_id	INT
		,service_id	VARCHAR(10) COLLATE database_default
		,kol		DECIMAL(12, 6)
	)

	INSERT
	INTO #t
	(	build_id
		,service_id
		,kol)
		SELECT
			voa.bldn_id
			,vp.service_id
			,SUM(vp.kol)
		FROM dbo.View_PAYM vp 
		JOIN #s S 
			ON vp.service_id = S.id
		JOIN dbo.View_OCC_ALL voa 
			ON voa.fin_id = vp.fin_id
			AND voa.occ = vp.occ
		WHERE S.is_build = 1
		AND (tip_id = @tip_id OR @tip_id IS NULL)
		AND vp.fin_id = @fin_id
		--AND vp.service_id = COALESCE(@service_id, vp.service_id)
		AND NOT EXISTS (SELECT 1
			FROM dbo.BUILD_SOURCE_VALUE AS bs 
			WHERE bs.fin_id = vp.fin_id
			AND bs.build_id = voa.bldn_id
			AND bs.service_id = S.is_build_serv)
		GROUP BY	voa.bldn_id
					,vp.service_id

	CREATE TABLE #t_excess
	(
		build_id		INT
		,service_id		VARCHAR(10) COLLATE database_default
		,kol_excess		DECIMAL(9, 4)
		,norma_single	DECIMAL(9, 4)
	)
	INSERT
	INTO #t_excess
	(	build_id
		,service_id
		,kol_excess
		,norma_single)
		SELECT
			voa.bldn_id
			,vp.service_in
			,SUM(vp.kol_excess)
			,norma_single = 0
		FROM dbo.PAYM_OCC_BUILD vp 
		JOIN #s S 
			ON vp.service_id = S.id
		JOIN dbo.View_OCC_ALL voa 
			ON voa.fin_id = vp.fin_id
			AND voa.occ = vp.occ
		WHERE S.is_build = 1
		AND (tip_id = @tip_id OR @tip_id IS NULL)
		AND vp.fin_id = @fin_id
		--AND vp.service_id = COALESCE(@service_id, vp.service_id)
		--AND COALESCE(kol_excess, 0) <> 0
		GROUP BY	voa.bldn_id
					,vp.service_in


	UPDATE #t_excess
	SET norma_single = (SELECT TOP 1
			[dbo].[Fun_GetNormaSingle](vp1.unit_id, vca.mode_id, 0, voa1.tip_id, vp1.fin_id)
		FROM dbo.PAYM_OCC_BUILD vp1 
		JOIN #s S 
			ON vp1.service_id = S.id
		JOIN dbo.View_OCC_ALL voa1
			ON voa1.fin_id = vp1.fin_id
			AND voa1.occ = vp1.occ
		JOIN dbo.View_CONSMODES_ALL AS vca 
			ON vp1.fin_id = vca.fin_id
			AND vp1.occ = vca.occ
			AND vp1.service_id = vca.service_id
		WHERE S.is_build = 1
		AND (tip_id = @tip_id OR @tip_id IS NULL)
		AND vp1.fin_id = @fin_id
		AND voa1.bldn_id = #t_excess.build_id)

	--SELECT * FROM #t_excess

	SELECT
		t1.*
		,v_itog-value_raspred AS kol_excess
	FROM (SELECT
			b.street_name
			,b.nom_dom			
			,b.id
			,s.name AS [service_name]
			,t.S_arenda
			,t.total_sq
			,b.opu_sq
			,v_itog = v_itog --+ t.value_arenda
			--,t.value_raspred
			,CASE
					WHEN v_itog > (te.norma_single * b.opu_sq) THEN (te.norma_single * b.opu_sq)
					ELSE t.value_raspred
			END AS value_raspred
			,CASE
					WHEN ((S_arenda + t.total_sq) = 0) OR (t.value_raspred = 0) THEN 0
					WHEN v_itog > (te.norma_single * b.opu_sq) 
						THEN (te.norma_single * b.opu_sq)/(S_arenda + t.total_sq)
					ELSE (t.value_raspred) / (S_arenda + t.total_sq)
			END AS v1
			,1 AS p354
			,t.value_start
			,t.value_source
			,t.value_arenda
			,t.value_norma
			,t.value_ipu
			,t.value_gvs
			--,kol_excess = COALESCE(te.kol_excess, 0)
			,b.nom_dom_sort
		FROM dbo.View_BUILDINGS AS b 
		JOIN dbo.BUILD_SOURCE_VALUE AS t 
			ON t.build_id = b.id
		JOIN #s AS s 
			ON t.service_id = s.id
		LEFT JOIN #t_excess AS te
			ON te.build_id = t.build_id
			AND te.service_id = t.service_id
		WHERE (tip_id = @tip_id OR @tip_id IS NULL)
		AND t.fin_id = @fin_id
		--AND t.service_id = COALESCE(@service_id, t.service_id)
		UNION ALL
		SELECT
			b.street_name
			,b.nom_dom
			,b.id
			,s.short_name AS service_name
			,COALESCE(b.arenda_sq, 0)
			,b.total_sq
			,b.opu_sq
			,kol
			,0 AS value_raspred
			,CASE
					WHEN (COALESCE(arenda_sq, 0) + COALESCE(total_sq, 0)) = 0 THEN 0
					ELSE kol / (COALESCE(arenda_sq, 0) + COALESCE(total_sq, 0))
			END AS v1
			,0 AS p354
			,0
			,0
			,0
			,0
			,0
			,0
			--,0
			,b.nom_dom_sort
		FROM dbo.View_BUILDINGS AS b 
		JOIN #t AS t
			ON t.build_id = b.id
		JOIN dbo.View_SERVICES AS s
			ON t.service_id = s.id
		WHERE t.kol <> 0) AS t1
	ORDER BY street_name, nom_dom_sort

END
go

