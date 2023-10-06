-- dbo.view_occ_and_sup source

CREATE   VIEW [dbo].[view_occ_and_sup]
AS
	SELECT *
	FROM (
		SELECT t1.fin_id
			 , t1.Occ
			 , t1.sup_id
			 , CASE
				   WHEN t1.tip_id IS NULL THEN o.tip_id
				   ELSE t1.tip_id
			   END AS tip_id
			 , t1.SALDO
			 , t1.value
			 , t1.Added
			 , t1.Paid
			 , t1.PaymAccount
			 , t1.PaymAccount_peny
			 , t1.Debt
			 , t1.Penalty_value
			 , t1.Penalty_added
			 , t1.Penalty_old_new
			 , t1.Penalty_old
			 , t1.Penalty_old_edit
			 , t1.Penalty_itog
			 , t1.Paid_old
			 , t1.Whole_payment
			 , t1.Debt + t1.Penalty_itog AS SumPaymDebt
			 , t1.Paymaccount_Serv
			 , o.address
			 , o.flat_id
			 , o.id_els_gis
			 , t1.id_jku_gis
			 , t1.occ_address
		FROM (
			SELECT t.fin_id
				 , t.occ
				 , 0 as sup_id
				 , t.tip_id
				 , t.saldo
				 , t.value
				 , t.added
				 , t.paid
				 , t.paymaccount
				 , t.paymaccount_peny
				 , t.debt
				 , t.penalty_value
				 , t.penalty_added
				 , t.penalty_old_new
				 , t.penalty_old
				 , t.penalty_old_edit
				 , t.penalty_itog as penalty_itog
				 , t.paid_old
				 , t.whole_payment
				 , (t.paymaccount - t.paymaccount_peny) as paymaccount_serv
				 , t.occ as occ_address
				 , t.id_jku_gis
			FROM dbo.View_occ_all_lite AS t
			UNION ALL
			SELECT t.fin_id
				 , t.occ_sup AS occ
				 , t.sup_id AS sup_id
				 , NULL AS tip_id
				 , t.SALDO
				 , t.value
				 , t.Added
				 , t.Paid
				 , t.PaymAccount
				 , t.PaymAccount_peny
				 , t.Debt
				 , t.Penalty_value
				 , t.Penalty_added
				 , t.Penalty_old_new
				 , t.Penalty_old
				 , t.Penalty_old_edit
				 , t.debt_peny AS Penalty_itog
				 , t.Paid_old
				 , t.Whole_payment
				 , t.Paymaccount_Serv
				 , t.occ AS occ_address
				 , t.id_jku_gis
			FROM [dbo].VOcc_Suppliers AS t
		) AS t1
			LEFT JOIN dbo.Occupations o 
				ON t1.occ_address = o.Occ
	) AS t2;
go

