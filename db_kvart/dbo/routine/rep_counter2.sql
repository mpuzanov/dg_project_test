CREATE   PROCEDURE [dbo].[rep_counter2]
(
	@fin_id1		SMALLINT	= NULL
	,@tip_id1		SMALLINT	= NULL
	,@div_id1		SMALLINT	= NULL
	,@build_id1		INT			= NULL
	,@service_id1	VARCHAR(10)	= NULL
	,@tip_value1	SMALLINT	= 0     -- 0 - по показаниям инспектора, 1 - квартиросъемщика
	,@internal		BIT			= NULL
)

/*
начисления по счетчикам

автор:		    Пузанов
дата создания:	09.04.09
дата изменеия:	
автор изменеия:	

используется в:	отчёт № ""
файл отчета:	Counter2.fr3
*/
AS

	SET NOCOUNT ON


	IF @fin_id1 IS NULL
		SET @fin_id1 = dbo.Fun_GetFinCurrent(@tip_id1, @build_id1, NULL, NULL)


	SELECT
		cp.occ
		,s.name
		,CONCAT(b.adres , ' кв.' , o.nom_kvr) as address
		,b.adres AS adres_build
		,cp.service_id
		,cp.saldo AS saldo
		,cp.Value as Value
		,cp.Discount AS Discount
		,cp.Added as Added
		,cp.PaymAccount AS PaymAccount
		,cp.Paid AS Paid
		,cp.Debt AS Debt
		,cp.kol AS kol
		,cp.tarif AS tarif
	FROM dbo.COUNTER_PAYM2 AS cp 
		JOIN dbo.View_OCC_ALL_LITE AS o 
			ON cp.occ = o.occ
			AND cp.fin_id=o.fin_id
		JOIN dbo.View_BUILD_ALL AS b 
			ON o.bldn_id = b.bldn_id
			AND b.fin_id = cp.fin_id
		JOIN dbo.VSTREETS AS s
			ON b.street_id = s.id
	WHERE 1=1
		AND (b.bldn_id = @build_id1 OR @build_id1 IS NULL)
		AND (b.div_id = @div_id1 OR @div_id1 IS NULL)
		AND (b.tip_id = @tip_id1 OR @tip_id1 IS NULL)
		AND (cp.service_id = @service_id1 OR @service_id1 IS NULL)
		AND cp.fin_id = @fin_id1
		AND tip_value = @tip_value1
		--AND cl.internal = COALESCE(@internal, cl.internal)
		AND o.total_sq>0

	ORDER BY s.name, b.nom_dom_sort, o.nom_kvr_sort
	OPTION(RECOMPILE)
go

