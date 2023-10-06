CREATE   PROCEDURE [dbo].[rep_10_svod]
(
	@fin_id		SMALLINT	= NULL
	,@tip_id	SMALLINT	= NULL
	,@town_id	SMALLINT	= NULL
	,@sup_id	INT			= NULL
)
AS
	/*
		-- Сводная оборотно-сальдовая ведомость по городу
	*/
	SET NOCOUNT ON

	IF @fin_id IS NULL
		SET @fin_id = dbo.Fun_GetFinCurrent(@tip_id, NULL, NULL, NULL)
	--if @tip is Null set @tip=0

	SELECT
		CASE
			WHEN (GROUPING(b.town_name) = 1) THEN 'Итого по ведомости:'
			ELSE COALESCE(b.town_name, '????')
		END AS 'Населённый пункт'
		,CASE
			WHEN (GROUPING(b.div_name) = 1) THEN 'итог по ' + b.town_name + ':'
			ELSE COALESCE(b.div_name, '????')
		END AS 'Район'
		,CASE
			WHEN (GROUPING(b.sector_name) = 1) THEN ''
			ELSE COALESCE(b.sector_name, '????')
		END AS 'Участок'
		,SUM(oh.saldo + COALESCE(os.saldo, 0)) AS saldo
		,SUM(oh.VALUE + COALESCE(os.VALUE, 0)) AS VALUE
		,0 AS discount
		,SUM(oh.added + COALESCE(os.added, 0)) AS added
		,0 AS compens
		,SUM(oh.paid + oh.Paid_minus + COALESCE(os.paid, 0)) AS paid
		,SUM(oh.paymaccount + COALESCE(os.paymaccount, 0)) AS paymaccount
		,SUM(oh.PaymAccount_peny + COALESCE(os.PaymAccount_peny, 0)) AS PaymAccount_peny
		,SUM(oh.Penalty_value + COALESCE(os.Penalty_value, 0)) AS penalty_mes
		,SUM(oh.debt + COALESCE(os.debt, 0)) AS debt
		,SUM(oh.Penalty_old_new + oh.Penalty_value + COALESCE(os.Penalty_old_new, 0) + COALESCE(os.Penalty_value, 0)) AS penalty
		,SUM(oh.whole_payment + os.whole_payment) AS whole_payment
		,SUM(oh.saldo + COALESCE(os.saldo, 0) - (oh.PaymAccount_serv + COALESCE(os.PaymAccount_serv, 0))) AS dolg
	FROM dbo.View_OCC_ALL AS oh 
	JOIN dbo.View_BUILD_ALL AS b 
		ON oh.bldn_id = b.bldn_id
		AND b.fin_id = oh.fin_id
	CROSS APPLY (SELECT
					SUM(os1.saldo) AS saldo
					,SUM(os1.VALUE) AS VALUE
					,SUM(os1.added) AS added
					,SUM(os1.paid) AS paid
					,SUM(os1.PaymAccount) AS PaymAccount
					,SUM(os1.PaymAccount_peny) AS PaymAccount_peny
					,SUM(os1.debt) AS debt
					,SUM(os1.Penalty_old_new) AS Penalty_old_new
					,SUM(os1.Penalty_value) AS Penalty_value
					,SUM(os1.whole_payment) AS whole_payment
					,SUM(os1.Paymaccount_serv) AS Paymaccount_serv
				FROM dbo.VOcc_Suppliers AS os1 
				WHERE oh.fin_id = os1.fin_id
				AND oh.occ = os1.occ
				AND (os1.sup_id = @sup_id
				OR @sup_id IS NULL)
			) AS os
	WHERE 
		(b.tip_id = @tip_id	OR @tip_id IS NULL)
		AND oh.fin_id = @fin_id
		AND oh.status_id <> 'закр'
		AND (b.town_id = @town_id OR @town_id IS NULL)
	GROUP BY	b.town_name
				,b.div_name
				,b.sector_name WITH ROLLUP
go

