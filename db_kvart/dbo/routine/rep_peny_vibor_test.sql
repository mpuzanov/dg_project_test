CREATE   PROCEDURE [dbo].[rep_peny_vibor_test]
(
	@fin_id1			SMALLINT = NULL
   ,@tip_id1			SMALLINT = NULL
   ,@build_id1			INT		 = NULL
   ,@isPenalty_old		BIT		 = NULL -- 1 - Penalty_old<>0, 0 - Penalty_old=0, NULL - Penalty_old - любое значение
   ,@isPaymaccount		BIT		 = NULL
   ,@isPaymaccount_peny BIT		 = NULL
   ,@isPenalty_old_new  BIT		 = NULL
   ,@isPenalty_value	BIT		 = NULL
   ,@isItogoPenalty		BIT		 = NULL
   ,@isPenalty_add		BIT		 = NULL
)
AS
	/*
		Выборка различных адресов для тестирования и проверки расчёта пени
	
	rep_peny_vibor_test @tip_id1=28,@build_id1=null
	rep_peny_vibor_test @tip_id1=28,@build_id1=null,@isPaymaccount=1
	rep_peny_vibor_test @tip_id1=28,@build_id1=null,@isPaymaccount=0
	rep_peny_vibor_test @tip_id1=28,@build_id1=null,@isPaymaccount=Null

	*/
	SET NOCOUNT ON


	IF @fin_id1 IS NULL
		SET @fin_id1 = dbo.Fun_GetFinCurrent(@tip_id1, @build_id1, NULL, NULL)

	SELECT
		*
	FROM (SELECT
			oh.fin_id
		   ,s.name AS street_name
		   ,b.nom_dom AS nom_dom
		   ,oh.nom_kvr
		   ,b.nom_dom_sort
		   ,oh.nom_kvr_sort
		   ,oh.Occ
		   ,o.address
		   ,oh.SALDO
		   ,oh.Penalty_calc
		   ,oh.Penalty_old
		   ,oh.PaymAccount
		   ,oh.PaymAccount_peny
		   ,oh.Penalty_old_new
		   ,oh.Penalty_value
		   ,oh.Penalty_value + oh.Penalty_old_new AS ItogoPenalty
		   ,pl.penalty_add AS penalty_add
		   ,dbo.Fun_GetDatePaymStr(oh.Occ, oh.fin_id, NULL) AS DatePaym
		   ,vp.dolg_peny
		   ,vp.StavkaCB
		   ,COALESCE(pm.name, '') AS metod_str
		   ,'Последний день оплаты:' + LTRIM(STR(COALESCE(ot.LastPaym, 0))) AS penalty_str
		   ,ot.paym_order_metod AS paym_order_metod
		 --  ,CAST(CASE
			--	WHEN ot.paym_order_metod = 'пени1' THEN 'Погашение пени, затем услуг'
			--	WHEN ot.paym_order_metod = 'пени2' THEN 'Первоочередная оплата услуг, затем пени'
			--	ELSE ''
			--END AS NVARCHAR(50)) AS paym_order
		FROM dbo.View_OCC_ALL AS oh 
		JOIN dbo.OCCUPATIONS AS o 
			ON oh.Occ = o.Occ
		JOIN dbo.BUILDINGS AS b 
			ON oh.bldn_id = b.id
		JOIN dbo.VSTREETS AS s 
			ON b.street_id = s.id
		JOIN dbo.VOCC_TYPES AS ot 
			ON b.tip_id = ot.id
		LEFT JOIN (SELECT
				fin_id
			   ,Occ
			   ,SUM(sum_new - sum_old) AS penalty_add
			FROM dbo.PENALTY_LOG 
			WHERE fin_id = @fin_id1
			GROUP BY fin_id
					,Occ) AS pl
			ON oh.Occ = pl.Occ
			AND oh.fin_id = pl.fin_id
		LEFT JOIN dbo.View_PENY_ALL AS vp
			ON oh.fin_id = vp.fin_id
			AND oh.Occ = vp.Occ
		LEFT JOIN dbo.PENY_METOD pm 
			ON vp.metod = pm.id
		WHERE oh.fin_id = @fin_id1
		AND (b.tip_id = @tip_id1
		OR @tip_id1 IS NULL)
		AND (oh.bldn_id = @build_id1
		OR @build_id1 IS NULL)
		AND (oh.Penalty_old <> 0
		OR oh.PaymAccount_peny <> 0
		OR oh.Penalty_value <> 0
		OR oh.Penalty_old_new <> 0
		OR pl.penalty_add IS NOT NULL) --
		UNION ALL
		SELECT
			oh.fin_id
		   ,s.name AS street_name
		   ,b.nom_dom AS nom_dom
		   ,o.nom_kvr
		   ,b.nom_dom_sort
		   ,o.nom_kvr_sort
		   ,oh.occ_sup
		   ,o.address
		   ,oh.SALDO
		   ,o.Penalty_calc
		   ,oh.Penalty_old
		   ,oh.PaymAccount
		   ,oh.PaymAccount_peny
		   ,oh.Penalty_old_new
		   ,oh.Penalty_value
		   ,oh.Penalty_value + oh.Penalty_old_new AS ItogoPenalty
		   ,pl.penalty_add AS penalty_add
		   ,dbo.Fun_GetDatePaymStr(oh.Occ, oh.fin_id, oh.sup_id) AS DatePaym
		   ,vp.dolg_peny
		   ,vp.StavkaCB
		   ,COALESCE(pm.name, '') AS metod_str
		   ,'Последний день оплаты:' + LTRIM(STR(COALESCE(ot.LastPaym, 0))) AS penalty_str
		   ,ot.paym_order_metod AS paym_order_metod
		FROM dbo.OCC_SUPPLIERS AS oh 
		JOIN dbo.VOCC AS o 
			ON oh.Occ = o.Occ
		JOIN dbo.BUILDINGS AS b 
			ON o.build_id = b.id
		JOIN dbo.VSTREETS AS s 
			ON b.street_id = s.id
		JOIN dbo.VOCC_TYPES AS ot 
			ON b.tip_id = ot.id
		LEFT JOIN (SELECT
				fin_id
			   ,Occ
			   ,SUM(sum_new - sum_old) AS penalty_add
			FROM dbo.PENALTY_LOG 
			WHERE fin_id = @fin_id1
			GROUP BY fin_id
					,Occ) AS pl
			ON oh.occ_sup = pl.Occ
			AND oh.fin_id = pl.fin_id
		LEFT JOIN dbo.View_PENY_ALL AS vp
			ON oh.fin_id = vp.fin_id
			AND oh.occ_sup = vp.Occ
		LEFT JOIN dbo.PENY_METOD pm 
			ON vp.metod = pm.id
		WHERE oh.fin_id = @fin_id1
		AND (b.tip_id = @tip_id1
		OR @tip_id1 IS NULL)
		AND (o.bldn_id = @build_id1
		OR @build_id1 IS NULL)
		AND (oh.Penalty_old <> 0
		OR oh.PaymAccount_peny <> 0
		OR oh.Penalty_value <> 0
		OR oh.Penalty_old_new <> 0
		OR pl.penalty_add IS NOT NULL)) AS t
	WHERE 1 = 1
	AND (
	((@isPenalty_old = 1
	AND Penalty_old <> 0)
	OR (@isPenalty_old = 0
	AND Penalty_old = 0)
	OR @isPenalty_old IS NULL)
	AND ((@isPaymaccount = 1
	AND PaymAccount <> 0)
	OR (@isPaymaccount = 0
	AND PaymAccount = 0)
	OR @isPaymaccount IS NULL)
	AND ((@isPaymaccount_peny = 1
	AND PaymAccount_peny <> 0)
	OR (@isPaymaccount_peny = 0
	AND PaymAccount_peny = 0)
	OR @isPaymaccount_peny IS NULL)
	AND ((@isPenalty_old_new = 1
	AND Penalty_old_new <> 0)
	OR (@isPenalty_old_new = 0
	AND Penalty_old_new = 0)
	OR @isPenalty_old_new IS NULL)
	AND ((@isPenalty_value = 1
	AND Penalty_value <> 0)
	OR (@isPenalty_value = 0
	AND Penalty_value = 0)
	OR @isPenalty_value IS NULL)
	AND ((@isItogoPenalty = 1
	AND ItogoPenalty <> 0)
	OR (@isItogoPenalty = 0
	AND ItogoPenalty = 0)
	OR @isItogoPenalty IS NULL)
	AND ((@isPenalty_add = 1
	AND Penalty_add <> 0)
	OR (@isPenalty_add = 0
	AND Penalty_add = 0)
	OR @isPenalty_add IS NULL))
	ORDER BY street_name, nom_dom_sort, nom_kvr_sort
	OPTION (RECOMPILE)

	--AND (
	--((@isPenalty_old = 1 AND Penalty_old <> 0) OR (@isPenalty_old = 0 AND Penalty_old = 0) OR @isPenalty_old IS Null)
	--AND 
	--((@isPaymaccount = 1 AND PaymAccount <> 0) OR (@isPaymaccount = 0 AND PaymAccount = 0) OR @isPaymaccount IS Null)
	--AND
	-- ((@isPaymaccount_peny = 1 AND PaymAccount_peny <> 0) OR (@isPaymaccount_peny = 0 AND PaymAccount_peny = 0) OR @isPaymaccount_peny IS Null)
	--AND 
	--((@isPenalty_old_new = 1 AND Penalty_old_new <> 0) OR (@isPenalty_old_new = 0 AND Penalty_old_new = 0) OR @isPenalty_old_new IS Null)
	--AND 
	--((@isPenalty_value = 1 AND Penalty_value <> 0) OR (@isPenalty_value = 0 AND Penalty_value = 0) OR @isPenalty_value IS Null)
	--AND
	-- ((@isItogoPenalty = 1 AND ItogoPenalty <> 0) OR (@isItogoPenalty = 0 AND ItogoPenalty = 0) OR @isItogoPenalty IS Null)
	--AND
	-- ((@isPenalty_add = 1 AND Penalty_add <> 0) OR (@isPenalty_add = 0 AND Penalty_add = 0) OR @isPenalty_add IS Null))
go

