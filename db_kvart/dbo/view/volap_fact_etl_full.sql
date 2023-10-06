-- dbo.volap_fact_etl_full source

CREATE   VIEW [dbo].[volap_fact_etl_full]
AS
	SELECT ph.fin_id
		 , cp.start_date
		 , ph.occ
		 , CASE WHEN(ph.sup_id > 0) THEN ph.occ_sup_paym ELSE 0 END AS occ_sup_paym
		 , ph.service_id
		 , s.name as serv_name
		 , ph.sup_id
		 , sup.name as sup_name
		 , vb.tip_id
		 , ot.name as tip_name
		 , vb.bldn_id as build_id
		 , vb.street_name
		 , vb.nom_dom
		 , vb.nom_dom_sort
		 , f.id as flat_id
		 , f.nom_kvr
		 , coalesce(f.nom_kvr_sort,'') AS nom_kvr_sort
		 , oh.roomtype_id
		 , rt.name as roomtype_name
		 , oh.proptype_id
		 , pt.name as proptype_name
		 , oh.total_sq
		 , ph.tarif
 		 
		 , ph.SALDO as saldo
		 , ph.SALDO + ph.penalty_prev AS SaldoWithPeny

		 , ph.Value as value
		 , (ph.Added - coalesce(t_sub.value,0))  as added
		 , ph.Compens as compens
		 , ph.Paid as paid
		 , ph.Paid + ph.penalty_serv  AS PaidWithPeny

		 , ph.PaymAccount
		 , ph.PaymAccount_peny
		 , ph.PaymAccount - ph.PaymAccount_peny AS PaymAccount_serv

		 , ph.Debt
		 , ph.Debt + ph.Penalty_old + ph.penalty_serv  AS DebtWithPeny

		 , ph.mode_id
		 , cm.name as mode_name
		 , ph.source_id
		 , sp.name as source_name		 
		 
		 , oh.status_id

		 , COALESCE(ph.kol,0) as kol
		 , (COALESCE(ph.kol_added,0) - coalesce(t_sub.kol,0)) as kol_added

		 , CASE
			   WHEN (COALESCE(ph.metod, 1) NOT IN (3,
				   4)) AND
				   (s.is_build = 0) THEN COALESCE(ph.kol,0)
			   ELSE 0
		   END AS kol_norma
		 , CASE
			   WHEN ph.metod = 3 THEN COALESCE(ph.kol,0)
			   ELSE 0
		   END AS kol_ipu
		 , CASE
			   WHEN (ph.metod = 4) OR
				   (s.is_build = 1) THEN COALESCE(ph.kol,0)
			   ELSE 0
		   END AS kol_opu
		 
		 , ph.penalty_prev AS 'penalty_old'
		 --, ph.penalty_old + ph.PaymAccount_peny AS 'penalty_old'
		 , ph.penalty_old AS 'penalty_old_new'
		 , ph.penalty_serv
		 , ph.penalty_old + ph.penalty_serv AS 'penalty_itog'
		 
		 , ph.metod
		 , dbo.Fun_GetMetodText(ph.metod) as metod_name
		 , CASE WHEN(ph.is_counter>0) THEN 1 ELSE 0 END as is_counter

		 , coalesce(t_sub.value,0) AS sub_value
		 , coalesce(t_sub.kol,0) AS sub_kol
	FROM dbo.Paym_history AS ph 
		JOIN dbo.Calendar_period AS cp 
			ON ph.fin_id = cp.fin_id
		JOIN dbo.Services AS s
			ON ph.service_id = s.id
		JOIN dbo.Occ_history AS oh 
			ON oh.occ = ph.occ
			AND ph.fin_id = oh.fin_id
		JOIN dbo.Occupation_Types ot 
			ON oh.tip_id=ot.id
		JOIN dbo.Flats AS f 
			ON oh.flat_id = f.id
		JOIN dbo.View_build_all AS vb 
			ON f.bldn_id = vb.bldn_id
			AND oh.fin_id = vb.fin_id
		JOIN dbo.Property_types as pt 
			ON oh.proptype_id=pt.id 
		JOIN dbo.Room_types as rt  
			ON oh.roomtype_id=rt.id 
		LEFT JOIN dbo.Suppliers_all as sup 
			ON ph.sup_id=sup.id		
		LEFT JOIN dbo.Cons_modes as cm
			ON ph.mode_id=cm.id
		LEFT JOIN dbo.Suppliers as sp 
			ON ph.source_id=sp.id
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
	WHERE oh.status_id<>'закр';
go

