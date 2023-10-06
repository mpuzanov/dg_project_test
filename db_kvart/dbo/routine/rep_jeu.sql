CREATE   PROCEDURE [dbo].[rep_jeu]
(
	@fin_id1	SMALLINT
	,@tip		SMALLINT	= NULL
	,@sector_id	SMALLINT	= NULL
	,@town_id	SMALLINT	= NULL
	,@sup_id	SMALLINT	= NULL
)
AS
	/*
	Ведомость итогов по домам по участкам по единым лицевым
	
	rep_jeu 147, 28, NULL, NULL, 323
	rep_jeu 147, 50, NULL, NULL, NULL
	*/
	SET NOCOUNT ON


	DECLARE @fin_pred SMALLINT

	IF @fin_id1 IS NULL
		AND @tip IS NOT NULL
		SET @fin_id1 = dbo.Fun_GetFinCurrent(@tip, NULL, NULL, NULL)

	SET @fin_pred = @fin_id1 - 1

	SELECT
		b.id AS bldn_id
		,b.street_name AS name
		,b.nom_dom
		,b.adres
		,SUM(vp.saldo) AS saldo
		,SUM(vp.value) AS value
		,SUM(vp.added) AS added
		,SUM(vp.paid) AS paid
		,SUM(vp.paymaccount) AS paymaccount
		,SUM(vp.PaymAccount_peny) AS PaymAccount_peny
		,SUM(vp.paymaccount_serv) AS paymaccount_serv
		,SUM(vp.debt) AS debt
		,CASE
			WHEN SUM(ph.Paid) < 100 THEN 0
			ELSE ((SUM(vp.saldo) - SUM(vp.paymaccount)) / (SUM(ph.Paid + 0.1)) * 100)
		END AS procent_dolg
	FROM dbo.View_PAYM AS vp
	JOIN dbo.OCCUPATIONS AS oh 
		ON vp.occ = oh.occ
	JOIN dbo.FLATS AS f 
		ON oh.flat_id = f.id
	JOIN dbo.View_BUILDINGS AS b 
		ON f.bldn_id = b.id
	LEFT JOIN dbo.PAYM_HISTORY AS ph 
		ON vp.occ = ph.occ AND vp.service_id=ph.service_id AND ph.fin_id=@fin_pred
	WHERE vp.fin_id = @fin_id1
	AND (oh.tip_id = @tip OR @tip IS NULL)
	AND (b.sector_id = @sector_id OR @sector_id IS NULL)
	AND (b.town_id = @town_id OR @town_id IS NULL)
	AND (vp.sup_id = @sup_id OR @sup_id IS NULL)
	GROUP BY	b.id
				,b.street_name
				,b.nom_dom
				,b.adres
	ORDER BY b.street_name, MIN(b.nom_dom_sort)
go

