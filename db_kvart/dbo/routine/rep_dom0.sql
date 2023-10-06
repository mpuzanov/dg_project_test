CREATE   PROCEDURE [dbo].[rep_dom0]
(
	@fin_id1		SMALLINT
	,@tip_id1		SMALLINT
	,@div_id1		SMALLINT	= NULL
	,@jeu_id1		SMALLINT	= NULL
	,@proptype_id1	VARCHAR(10)	= NULL
	,@build_id		INT			= NULL
	,@sup_id1		INT			= NULL
	,@only_dolg		BIT			= 0
)
AS
	/*
	используется в:	отчёт №10.16 "Списки пустующих квартир"
	файл отчета:	rep_dom0.fr3
		
	rep_dom0 @fin_id1=249,@tip_id1=1
	rep_dom0 @fin_id1=160,@tip_id1=28
	rep_dom0 @fin_id1=188,@tip_id1=27

	*/
	SET NOCOUNT ON



	IF @only_dolg IS NULL
		SET @only_dolg = 0

	DECLARE	@fin_current	SMALLINT
			,@fin_pred		SMALLINT

	IF @fin_id1 IS NULL
	BEGIN
		SELECT
			@fin_current = dbo.Fun_GetFinCurrent(@tip_id1, NULL, NULL, NULL)
		SELECT
			@fin_id1 = @fin_current
			,@fin_pred = @fin_current - 1
	END

	SELECT
		t1.*
	FROM (SELECT
			CASE
				WHEN @sup_id1 > 0 THEN os.occ_sup
				ELSE oh.occ
			END AS occ
			,os.occ_sup
			,b.street_name
			,b.nom_dom
			,oh.nom_kvr
			,oh.proptype_id
			,CASE
				WHEN @sup_id1 > 0 THEN COALESCE(os.value, 0)
				WHEN @sup_id1=0 THEN oh.value
				ELSE (oh.value + COALESCE(os.value, 0))
			END AS value
			,CASE
				WHEN @sup_id1 > 0 THEN COALESCE(os.saldo, 0) - COALESCE(os.PaymAccount_serv, 0)
				WHEN @sup_id1=0 THEN COALESCE(oh.saldo, 0) - COALESCE(oh.PaymAccount_serv, 0)
				ELSE (oh.SaldoAll - oh.Paymaccount_ServAll)
			END AS dolg
			,CASE
				WHEN @sup_id1 > 0 THEN COALESCE(os.Paid, 0)
				WHEN @sup_id1=0 THEN oh.Paid
				ELSE (oh.PaidAll)
			END AS Paid
			,CASE 
         		WHEN @sup_id1 = 0 THEN i.KolMesDolg
         		WHEN @sup_id1 > 0 THEN os.KolMesDolg			
         		ELSE i.KolMesDolgAll
			END AS kol_mes
			,b.div_id
			,t.dolg AS Dolg0
			,t.Paid AS Paid0
			,t.paymaccount AS Paymaccount0
			,oh.total_sq
			,cl.count_counters
			,b.nom_dom_sort
			,oh.nom_kvr_sort
		FROM dbo.View_OCC_ALL_LITE AS oh 
		JOIN dbo.View_BUILD_ALL AS b
			ON oh.build_id = b.bldn_id
			AND oh.fin_id = b.fin_id
		LEFT JOIN dbo.INTPRINT I 
			ON oh.occ = I.occ
			AND oh.fin_id = i.fin_id
		CROSS APPLY dbo.Fun_SumSvobFlats(oh.fin_id, oh.occ, @sup_id1) AS t
		CROSS APPLY (SELECT
				COUNT(1) AS count_counters
			FROM dbo.COUNTER_LIST_ALL cl 
			WHERE cl.occ = oh.occ
			AND cl.fin_id = oh.fin_id) AS cl
		CROSS APPLY (SELECT
				SUM(os.Saldo) AS Saldo
				,SUM(os.paymaccount-os.paymaccount_peny) AS PaymAccount_serv
				,SUM(os.paid) AS paid
				,SUM(os.value) AS value
				,MAX(os.occ_sup) AS occ_sup
				,MAX(os.KolMesDolg) AS KolMesDolg
			FROM dbo.Occ_Suppliers os
			WHERE 
				os.occ = oh.occ
				AND os.fin_id = oh.fin_id
				AND (os.sup_id = @sup_id1 OR @sup_id1 IS NULL)
				) AS os
		WHERE 
			oh.fin_id = @fin_id1
			AND oh.status_id = 'своб'
			--AND oh.total_sq>0  -- ведётся учёт
			AND (oh.proptype_id = @proptype_id1 OR @proptype_id1 IS NULL)
			AND (b.div_id = @div_id1 OR @div_id1 IS NULL)
			AND (b.sector_id = @jeu_id1 OR @jeu_id1 IS NULL)
			AND (b.tip_id = @tip_id1 OR @tip_id1 IS NULL)
			AND (b.bldn_id = @build_id OR @build_id IS NULL)
			) AS t1	
	WHERE t1.occ > 0
	AND t1.dolg>CASE 
                	WHEN @only_dolg=1 THEN 0
                	ELSE -999999
                END
	ORDER BY t1.street_name
			, t1.nom_dom_sort
			, t1.nom_kvr_sort
go

