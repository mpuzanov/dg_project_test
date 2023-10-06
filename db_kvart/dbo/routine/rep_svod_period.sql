-- =============================================
-- Author:		Пузанов
-- Create date: 04.04.13
-- Description:	Выборка за период (сальдо от первого месяца, а дебет от последнего, остальные поля суммируються)
-- =============================================

CREATE     PROCEDURE [dbo].[rep_svod_period]
	@fin_id1		SMALLINT
	,@fin_id2		SMALLINT
	,@tip_id		SMALLINT
	,@build_id		INT		= NULL
	,@service_id	VARCHAR(10)	= NULL
AS
-- rep_svod_period 141, 147, 28
BEGIN
	SET NOCOUNT ON;

	;
	WITH cte
	AS
	(SELECT
			voa.bldn_id AS build_id
			,vp.occ
			,vp.service_id
			,vp.sup_id
			,OS.occ_sup
			,COALESCE((SELECT
					vp1.saldo
				FROM dbo.View_PAYM AS vp1
				WHERE vp1.fin_id = @fin_id1
				AND vp.occ = vp1.occ
				AND vp.service_id = vp1.service_id)
			, 0) AS saldo
			,SUM(vp.value) AS value
			,SUM(vp.added) AS added
			,SUM(vp.paid) AS paid
			,SUM(vp.PaymAccount_serv) AS paymaccount
			,COALESCE((SELECT
					vp1.debt
				FROM dbo.View_PAYM AS vp1
				WHERE vp1.fin_id = @fin_id2
				AND vp.occ = vp1.occ
				AND vp.service_id = vp1.service_id)
			, 0) AS debt
		FROM dbo.View_PAYM AS vp
		JOIN dbo.View_OCC_ALL_LITE AS voa
			ON voa.fin_id = vp.fin_id
			AND voa.occ = vp.occ
		LEFT JOIN dbo.OCC_SUPPLIERS AS OS
			ON vp.sup_id = OS.sup_id
			AND vp.occ = OS.occ
			AND vp.fin_id = OS.fin_id
		WHERE vp.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND voa.tip_id = @tip_id
		AND voa.bldn_id = COALESCE(@build_id, voa.bldn_id)
		AND vp.service_id = COALESCE(@service_id, vp.service_id)
		AND (vp.saldo <> 0
		OR vp.value <> 0
		OR vp.debt <> 0
		OR vp.added <> 0)
		GROUP BY	voa.bldn_id
					,vp.occ
					,vp.service_id
					,vp.sup_id
					,OS.occ_sup)
	SELECT
		t.*
		,S.name AS serv_name
		,street_name
		,nom_dom
		,vs.name AS sup_name
	FROM cte AS t
	JOIN dbo.View_SERVICES AS S
		ON t.service_id = S.id
	JOIN dbo.View_BUILDINGS AS vb 
		ON t.build_id = vb.id
	LEFT JOIN dbo.View_SUPPLIERS AS vs
		ON t.sup_id = vs.sup_id
		AND t.service_id = vs.service_id
	ORDER BY street_name, vb.nom_dom_sort, occ

END
go

