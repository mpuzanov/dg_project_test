-- dbo.view_occ_all_lite source

CREATE   VIEW [dbo].[view_occ_all_lite]
AS
	SELECT *
	FROM (
		SELECT c.[start_date]
			 , t1.*			 
			 , t1.Debt + ((t1.penalty_old_new+t1.penalty_added)+t1.penalty_value) AS SumPaymDebt -- к оплате (может быть отрицательной)
			 , f.bldn_id
			 , f.bldn_id AS build_id
			 , f.nom_kvr
			 , f.nom_kvr_sort
			 , f.floor
			 , o.occ_uid
			 , o.address
			 , CASE
				WHEN LEFT(o.prefix, 1) = '&' THEN REPLACE(o.prefix, '&', '')				
				ELSE f.nom_kvr + COALESCE(o.prefix,'')
			 END AS nom_kvr_prefix
			 , f.id_nom_gis

			, (t1.paymaccount-t1.paymaccount_peny) AS paymaccount_serv
			, ((t1.penalty_old_new+t1.penalty_added)+t1.penalty_value) AS penalty_itog

			, case when ((((t1.saldo+t1.paid)+t1.paid_minus)-(t1.paymaccount-t1.paymaccount_peny))+((t1.penalty_value+t1.penalty_added)+t1.penalty_old_new))<0 
				then 0 
				else (((t1.saldo+t1.paid)+t1.paid_minus)-(t1.paymaccount-t1.paymaccount_peny))+((t1.penalty_value+t1.penalty_added)+t1.penalty_old_new) 
			  end
			 as whole_payment

			, case when ((((t1.saldo+t1.paid)+t1.paid_minus)-(t1.paymaccount-t1.paymaccount_peny))+((t1.penalty_value+t1.penalty_added)+t1.penalty_old_new))>=0
				then 0
				else (((t1.saldo+t1.paid)+t1.paid_minus)-(t1.paymaccount-t1.paymaccount_peny))+((t1.penalty_value+t1.penalty_added)+t1.penalty_old_new)
			  end
			  as whole_payment_minus

		FROM (
			SELECT t.fin_id
				 , t.occ
				 , t.tip_id
				 , t.flat_id
				 , ot.name as tip_name
				 , t.roomtype_id
				 , t.proptype_id
				 , t.status_id
				 , t.living_sq
				 , t.total_sq
				 , t.kol_people
				 , t.socnaim
				 , t.jeu
				 , t.saldoall
				 , t.paymaccount_servall
				 , t.paidall
				 , t.addedall
				 , t.saldo_edit
				 , t.saldo
				 , t.value
				 , t.discount
				 , t.added
				 , t.paymaccount
				 , t.paymaccount_peny
				 , t.paid + t.paid_minus as paiditog
				 , t.penalty_old
				 , t.penalty_old_new
				 , t.penalty_added
				 , t.penalty_value
				 , t.penalty_old_edit
				 , t.debt
				 , t.paid
				 , t.paid_old
				 , t.paid_minus
				 , t.id_jku_gis
				 , t.kolmesdolg
				 , t.kol_people_reg
				 , t.kol_people_all
				 , t.id_els_gis
				 , t.kol_people_owner
				 , t.data_rascheta
				 , t.date_start
				 , t.date_end
				 , t.comments_print
			FROM dbo.Occ_history AS t
				JOIN dbo.Occupation_Types_History AS ot 
					ON t.tip_id = ot.id
					AND t.fin_id = ot.fin_id
			UNION

			SELECT t.fin_id AS fin_id
				 , t.occ
				 , t.tip_id
				 , t.flat_id
				 , OT.name AS tip_name
				 , t.roomtype_id
				 , t.proptype_id
				 , t.status_id
				 , t.living_sq
				 , t.total_sq
				 , t.kol_people
				 , t.socnaim
				 , t.jeu
				 , t.SaldoAll
				 , t.Paymaccount_ServAll
				 , t.PaidAll
				 , t.AddedAll
				 , t.saldo_edit
				 , t.saldo
				 , t.Value
				 , t.Discount
				 , t.Added
				 , t.PaymAccount
				 , t.PaymAccount_peny
				 , t.Paid + t.Paid_minus AS PaidItog
				 , t.Penalty_old
				 , t.Penalty_old_new
				 , t.Penalty_added
				 , t.Penalty_value
				 , t.Penalty_old_edit
				 , t.Debt
				 , t.Paid
				 , t.Paid_old
				 , t.Paid_minus
				 , t.id_jku_gis
				 , t.KolMesDolg
				 , t.kol_people_reg
				 , t.kol_people_all
				 , t.id_els_gis
				 , t.kol_people_owner
				 , t.Data_rascheta
				 , t.date_start
				 , t.date_end
				 , t.comments_print
			FROM dbo.Occupations AS t
				JOIN dbo.Occupation_Types AS OT ON 
					t.tip_id = OT.id
		) AS t1
			JOIN dbo.Flats AS f ON 
				t1.flat_id = f.id
			JOIN dbo.Occupations AS o ON 
				t1.occ = o.occ
			JOIN dbo.Calendar_period AS c ON 
				t1.fin_id=c.fin_id
	) AS t2;
go

