-- =============================================
-- Author:		Пузанов
-- Create date: 14.05.14
-- Description:	Выборка за период по домам(сальдо от первого месяца, а дебет от последнего, остальные поля суммируються)
-- =============================================

CREATE       PROCEDURE [dbo].[rep_svod_period_dom]
	@fin_id1		SMALLINT
	,@fin_id2		SMALLINT
	,@tip_id		SMALLINT
	,@build_id		INT		= NULL
	,@service_id	VARCHAR(10)	= NULL
AS
/*
exec rep_svod_period_dom 147, 150, 28
*/
BEGIN
	SET NOCOUNT ON;

	-- для ограничения доступа услуг
	CREATE TABLE #s
	(
		id			VARCHAR(10) COLLATE database_default PRIMARY KEY
		,[name]		VARCHAR(100) COLLATE database_default
		,is_build	BIT
	)
	
	INSERT
	INTO #s
	(	id
		,name
		,is_build)
		SELECT
			id
			,name
			,is_build
		FROM dbo.View_SERVICES

	;WITH cte
	AS (SELECT
			voa.bldn_id AS build_id
			,vp.occ
			,vp.service_id
			,vp.sup_id
			,COALESCE((SELECT
					SUM(vp1.saldo)
				FROM dbo.PAYM_HISTORY AS vp1
				WHERE vp1.fin_id = @fin_id1
				AND vp1.occ = vp.occ
				AND vp.service_id = vp1.service_id)
			, 0) as saldo
			,SUM(vp.value) AS value
			,SUM(vp.added) AS added
			,SUM(vp.paid) AS paid
			,SUM(vp.paymaccount_serv) AS paymaccount
			,COALESCE((SELECT
					SUM(vp1.debt)
				FROM dbo.View_PAYM AS vp1
				WHERE vp1.fin_id = @fin_id2
				AND vp1.occ = vp.occ
				AND vp.service_id = vp1.service_id)
			, 0) AS debt
		FROM dbo.View_PAYM AS vp
		JOIN dbo.View_OCC_ALL_LITE AS voa
			ON voa.fin_id = vp.fin_id
			AND voa.occ = vp.occ
		WHERE vp.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND voa.tip_id = @tip_id
		AND (voa.bldn_id = @build_id OR @build_id IS NULL)
		AND (vp.service_id = @service_id OR @service_id IS NULL)
		AND (vp.saldo <> 0
		OR vp.value <> 0
		OR vp.debt <> 0
		OR vp.added <> 0)
		GROUP BY	voa.bldn_id
					,vp.occ
					,vp.service_id
					,vp.sup_id)
	SELECT
		street_name
		,nom_dom
		,S.name AS serv_name
		,vs.name AS sup_name
		,SUM(t.saldo) AS saldo
		,SUM(t.value) AS value
		,SUM(t.added) AS added
		,SUM(t.paid) AS paid
		,SUM(t.paymaccount) AS paymaccount
		,SUM(t.debt) AS debt
		,(SUM(t.paid)-SUM(t.paymaccount)) AS dif_saldo
	FROM cte AS t
	JOIN #s AS S
		ON t.service_id = S.id
	JOIN dbo.View_BUILDINGS AS vb
		ON t.build_id = vb.id
	LEFT JOIN dbo.View_SUPPLIERS AS vs
		ON t.sup_id = vs.sup_id
		AND t.service_id = vs.service_id
	GROUP BY	street_name
				,nom_dom
				,S.name
				,vs.name
	ORDER BY street_name, MIN(nom_dom_sort)

END
go

