/* volap_fact*/
CREATE   VIEW [dbo].[volap_fact_etl]
AS
	SELECT ph.fin_id
		 , ph.occ
		 , ph.service_id
		 , ph.sup_id
		 , cp.start_date
		 , vb.bldn_id as build_id
		 , vb.tip_id
		 , oh.flat_id
		 , oh.roomtype_id
		 , oh.proptype_id
		 , oh.total_sq
		 , ph.tarif
 		 
		 , ph.SALDO
		 , ph.SALDO + ph.penalty_prev AS SaldoWithPeny

		 , ph.Value
		 , (ph.Added - coalesce(t_sub.value,0))  as Added
		 , ph.Compens
		 , ph.Paid
		 , ph.Paid + ph.penalty_serv  AS PaidWithPeny

		 , ph.PaymAccount
		 , ph.PaymAccount_peny
		 , ph.PaymAccount - ph.PaymAccount_peny AS PaymAccount_serv

		 , ph.Debt
		 , ph.Debt + ph.Penalty_old + ph.penalty_serv  AS DebtWithPeny

		 , ph.mode_id
		 , ph.source_id
		 
		 , ph.SALDO - (ph.PaymAccount - ph.PaymAccount_peny) AS saldo_paymaccount
		 , oh.status_id
		 
		 , ph.kol
		 , (COALESCE(ph.kol_added,0) - coalesce(t_sub.kol,0)) as kol_added
		 		 		 
		 , CASE WHEN(ph.sup_id > 0) THEN ph.occ_sup_paym ELSE 0 END AS occ_sup_paym

		 , CASE
			   WHEN (COALESCE(ph.metod, 1) NOT IN (3,
				   4)) AND
				   (s.is_build = 0) THEN ph.kol
			   ELSE 0
		   END AS kol_norma
		 , CASE
			   WHEN ph.metod = 3 THEN ph.kol
			   ELSE 0
		   END AS kol_ipu
		 , CASE
			   WHEN (ph.metod = 4) OR
				   (s.is_build = 1) THEN ph.kol
			   ELSE 0
		   END AS kol_opu
		 
		 , ph.penalty_old + ph.PaymAccount_peny AS 'penalty_old'
		 , ph.penalty_serv AS 'penalty_serv'
		 , ph.penalty_old + ph.penalty_serv AS 'penalty_itog'
		 
		 , ph.metod
		 , ph.is_counter
		 , coalesce(t_sub.value,0) AS sub_value
		 , coalesce(t_sub.kol,0) AS sub_kol
	FROM dbo.Paym_history AS ph 
		INNER JOIN dbo.Calendar_period AS cp 
			ON ph.fin_id = cp.fin_id
		INNER JOIN dbo.Services AS s 
			ON ph.service_id = s.id
		INNER JOIN dbo.Occ_history AS oh 
			ON oh.occ = ph.occ
			AND ph.fin_id = oh.fin_id
		INNER JOIN dbo.Flats AS f 
			ON oh.flat_id = f.id
		LEFT OUTER JOIN dbo.Buildings_history AS vb 
			ON f.bldn_id = vb.bldn_id
			AND oh.fin_id = vb.fin_id
		CROSS APPLY (
			SELECT SUM(va.Value) AS value
				,SUM(va.kol) AS kol
			FROM dbo.Added_Payments_History va
			WHERE va.fin_id = ph.fin_id
				AND va.Occ = ph.Occ
				AND va.service_id = ph.service_id
				AND va.sup_id = ph.sup_id
				AND va.add_type = 15
		) AS t_sub
go

