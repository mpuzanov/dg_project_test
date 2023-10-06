-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description>
-- =============================================
CREATE     PROCEDURE [dbo].[rep_sub12_kol]
(
	@fin_id		SMALLINT
	,@tip_id	SMALLINT
	,@build_id1	INT = NULL
)
AS
/*
exec rep_sub12_kol 141,27
*/
BEGIN
	SET NOCOUNT ON;

	SELECT
		vp.occ
		,vp.service_id
		,vp.kol
		,COALESCE(vb.kol,0) AS kol_odn
		,vp.Value
	INTO #t_paym1
	FROM dbo.View_PAYM AS vp 
	JOIN dbo.OCCUPATIONS o 
		ON vp.occ = o.occ
	JOIN dbo.SUBSIDIA12 S
		ON S.fin_id = vp.fin_id
		AND S.occ = vp.occ
		AND S.service_id = vp.service_id
	LEFT JOIN dbo.View_PAYM_BUILD AS vb
		ON vp.fin_id = vb.fin_id
		AND vp.occ = vb.occ
		AND vp.service_id = vb.id
	WHERE vp.fin_id = @fin_id
	AND S.service_id IN ('хвод', 'вотв', 'отоп', 'гвод', 'гвс2', 'тепл', 'элек', 'эле2')
	--AND S.service_id IN ('хвод')
	AND o.tip_id = @tip_id
	AND (vb.build_id = @build_id1 OR @build_id1 IS NULL)

	CREATE UNIQUE INDEX Idx1 ON #t_paym1 (occ, service_id);

	SELECT
		voa.occ
		,vb.street_name
		,vb.nom_dom
		,voa.nom_kvr
		,voa.kol_people
		,K1_kol12 =
			CASE
				WHEN COALESCE(K1.tarif12, 0) > 0 THEN CAST(K1.value12 / K1.tarif12 AS DECIMAL(12, 4))
				ELSE 0
			END
		,K2_kol12 =
			CASE
				WHEN COALESCE(K2.tarif12, 0) > 0 THEN CAST(K2.value12 / K2.tarif12 AS DECIMAL(12, 4))
				ELSE 0
			END
		,K5_kol12 =
			CASE
				WHEN COALESCE(K5.tarif12, 0) > 0 THEN CAST(K5.value12 / K5.tarif12 AS DECIMAL(12, 4))
				ELSE 0
			END
		,K4_kol12 =
			CASE
				WHEN COALESCE(K4.tarif12, 0) > 0 THEN CAST(K4.value12 / K4.tarif12 AS DECIMAL(12, 4))
				ELSE 0
			END
		,K6_kol12 =
			CASE
				WHEN COALESCE(K6.tarif12, 0) > 0 THEN CAST(K6.value12 / K6.tarif12 AS DECIMAL(12, 4))
				ELSE 0
			END
		,P1_kol = COALESCE(P1.kol, 0)
		,D1_kol = COALESCE(P1.kol_odn, 0)
		,P2_kol = COALESCE(P2.kol, 0)
		,D2_kol = COALESCE(P2.kol_odn, 0)
		,P5_kol = COALESCE(P5.kol, 0)
		,D5_kol = COALESCE(P5.kol_odn, 0)
		,P4_kol = COALESCE(P4.kol, 0)
		,D4_kol = COALESCE(P4.kol_odn, 0)
		,P6_kol = COALESCE(P6.kol, 0)
		,D6_kol = COALESCE(P6.kol_odn, 0)
		,value = (COALESCE(K1.Paid, 0) + COALESCE(K2.Paid, 0) + COALESCE(K4.Paid, 0) + COALESCE(K5.Paid, 0) + COALESCE(K6.Paid, 0))
		,sub12 = (COALESCE(K1.sub12, 0) + COALESCE(K2.sub12, 0) + COALESCE(K4.sub12, 0) + COALESCE(K5.sub12, 0) + COALESCE(K6.sub12, 0))
	FROM dbo.View_OCC_ALL voa
	JOIN dbo.View_BUILDINGS vb 
		ON voa.bldn_id = vb.id
	LEFT JOIN (SELECT
			occ
			,service_id
			,value_max
			,value
			,value12
			,Paid
			,sub12
			,tarif12
			,tarif
			,norma12
			,norma
		FROM dbo.SUBSIDIA12 
		WHERE fin_id = @fin_id
		AND service_id = 'хвод') AS K1
		ON voa.occ = K1.occ
	LEFT JOIN (SELECT
			vp.occ
			,vp.service_id
			,vp.kol
			,vp.kol_odn
		FROM #t_paym1 AS vp 
		WHERE vp.service_id = 'хвод') AS P1
		ON voa.occ = P1.occ
	LEFT JOIN (SELECT
			vp.occ
			,vp.id
			,vp.service_id
			,vp.kol
		FROM dbo.View_PAYM_BUILD AS vp 
		JOIN dbo.SUBSIDIA12 S 
			ON S.fin_id = vp.fin_id
			AND S.occ = vp.occ
			AND S.service_id = vp.id
		WHERE vp.fin_id = @fin_id
		AND vp.id = 'хвод') AS D1
		ON voa.occ = D1.occ
	LEFT JOIN (SELECT
			occ
			,service_id
			,value_max
			,value
			,value12
			,Paid
			,sub12
			,tarif12
			,tarif
			,norma12
			,norma
		FROM dbo.SUBSIDIA12 
		WHERE fin_id = @fin_id
		AND service_id = 'вотв') AS K2
		ON voa.occ = K2.occ

	LEFT JOIN (SELECT
			vp.occ
			,vp.service_id
			,vp.kol
			,vp.kol_odn
		FROM #t_paym1 AS vp 
		WHERE service_id = 'вотв') P2
		ON voa.occ = P2.occ

	LEFT JOIN (SELECT
			vp.occ
			,vp.id
			,vp.service_id
			,vp.kol
		FROM dbo.View_PAYM_BUILD AS vp 
		JOIN dbo.SUBSIDIA12 S 
			ON S.fin_id = vp.fin_id
			AND S.occ = vp.occ
			AND S.service_id = vp.id
		WHERE vp.fin_id = @fin_id
		AND vp.id = 'вотв') AS D2
		ON voa.occ = D2.occ
	LEFT JOIN (SELECT
			occ
			,service_id
			,value_max
			,value
			,value12
			,Paid
			,sub12
			,tarif12
			,tarif
			,norma12
			,norma
		FROM dbo.SUBSIDIA12 
		WHERE fin_id = @fin_id
		AND service_id = 'отоп') AS K5
		ON voa.occ = K5.occ
	LEFT JOIN (SELECT
			vp.occ
			,vp.service_id
			,vp.kol
			,vp.kol_odn
		FROM #t_paym1 AS vp 
		WHERE vp.service_id = 'отоп') AS P5
		ON voa.occ = P5.occ

	LEFT JOIN (SELECT
			occ
			,service_id
			,value_max
			,value
			,value12
			,Paid
			,sub12
			,tarif12
			,tarif
			,norma12
			,norma
		FROM dbo.SUBSIDIA12 
		WHERE fin_id = @fin_id
		AND service_id IN ('гвод', 'гвс2')) AS K4
		ON voa.occ = K4.occ
	LEFT JOIN (SELECT
			vp.occ
			,vp.service_id
			,vp.kol
			,vp.kol_odn
		FROM #t_paym1 AS vp 
		WHERE vp.service_id IN ('гвод', 'гвс2')) AS P4
		ON voa.occ = P4.occ
	LEFT JOIN (SELECT
			occ
			,service_id
			,value_max
			,value
			,value12
			,Paid
			,sub12
			,tarif12
			,tarif
			,norma12
			,norma
		FROM dbo.SUBSIDIA12 
		WHERE fin_id = @fin_id
		AND service_id = 'тепл') AS K6
		ON voa.occ = K6.occ
	LEFT JOIN (SELECT
			vp.occ
			,vp.service_id
			,vp.kol
			,vp.kol_odn
		FROM #t_paym1 AS vp 
		WHERE vp.service_id = 'тепл') AS P6
		ON voa.occ = P6.occ
	WHERE voa.tip_id = @tip_id
	AND voa.fin_id = @fin_id
	AND (vb.id = @build_id1 OR @build_id1 IS NULL)
	AND (K1.sub12 <> 0
	OR K2.sub12 <> 0
	OR K5.sub12 <> 0
	OR K4.sub12 <> 0
	OR K6.sub12 <> 0)
	ORDER BY vb.street_name, vb.nom_dom_sort, voa.nom_kvr_sort
END
go

