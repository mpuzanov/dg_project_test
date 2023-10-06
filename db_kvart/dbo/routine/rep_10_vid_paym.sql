CREATE   PROCEDURE [dbo].[rep_10_vid_paym]
(
	@fin_id1	SMALLINT
	,@tip		SMALLINT
	,@build		INT	= NULL
	,@vid_pay	VARCHAR(10) --  вид платежа
)
AS
	/*
	
	ОБОРОТНАЯ ВЕДОМОСТЬ по лицевым счетам
	rep10.fr3
	
	*/

	SET NOCOUNT ON


	-- находим значение текущего фин периода
	IF @fin_id1 IS NULL
		SELECT
			@fin_id1 = dbo.Fun_GetFinCurrent(@tip, @build, NULL, NULL)

	SELECT
		oh.bldn_id
		,b.street_name AS STREETS
		,b.nom_dom AS nom_dom
		,oh.nom_kvr AS nom_kvr
		,oh.floor AS [floor]
		,dbo.Fun_LgotaStr(oh.Occ) AS Lgota
		,oh.kol_people AS KolPeople
		,oh.PROPTYPE_ID AS proptype
		,oh.STATUS_ID AS STATUS_ID
		,dbo.Fun_PersonStatusStr(oh.Occ) AS person_status
		,oh.TOTAL_SQ
		,oh.Occ
		,b.sector_id AS JEU
		,NULL AS SCHTL
		,oh.SALDO
		,oh.Value
		,oh.Added
		,oh.Discount
		,0 AS Compens
		,oh.PaymAccount
		,oh.Paid + oh.Paid_minus AS Paid
		,oh.Whole_payment
		,oh.Penalty_old -- пред. месяц
		,oh.Penalty_old_new -- изменённый с учётом оплаты
		,oh.Penalty_value -- начисленное в этом месяце
		,(oh.Penalty_old_new + oh.Penalty_value) AS penalty_itog -- итого пени
		,oh.PaymAccount_peny
		,oh.Debt
		,b.div_id
		,b.div_name AS div_name
		,b2.index_id
		,b2.index_postal
		,b.tip_id
		,dbo.Fun_Initials(oh.Occ) AS Initials
		,dbo.Fun_GetDatePaymStr(oh.Occ, oh.fin_id, NULL) AS DatePaym
		,pay.paymaccount_vid as paymaccount_vid
	FROM dbo.View_OCC_ALL AS oh 
	JOIN dbo.View_BUILD_ALL AS b 
		ON oh.bldn_id = b.bldn_id
	LEFT OUTER JOIN dbo.BUILDINGS AS b2 
		ON b2.id = b.bldn_id
	JOIN (SELECT
			p.Occ
			,SUM(p.Value) AS paymaccount_vid
		FROM dbo.View_payings AS p 
		WHERE fin_id = @fin_id1
			AND tip_paym_id = @vid_pay
			AND p.tip_id = COALESCE(@tip, p.tip_id)
		GROUP BY p.Occ
		) AS pay
		ON oh.Occ = pay.Occ
	WHERE 
		oh.fin_id = @fin_id1
		AND b.fin_id = @fin_id1
		AND (b.tip_id = @tip OR @tip IS null)
		AND (oh.bldn_id = @build OR @build IS NULL)
	ORDER BY b.street_name, b.nom_dom_sort, oh.nom_kvr_sort
go

