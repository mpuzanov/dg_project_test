-- dbo.view_paym_history source

CREATE   VIEW [dbo].[view_paym_history]
AS

SELECT
	cp.start_date AS start_date
	,s.is_build
	,s.is_peny
	,ph.fin_id
	,occ
	,ph.service_id
	,s.name as serv_name
	,subsid_only
	,tarif
	,saldo
	,Value
	,Discount
	,Added
	,Compens
	,Paid
	,PaymAccount
	,PaymAccount_peny
	,(PaymAccount - PaymAccount_peny) AS Paymaccount_serv
	,Debt
	,kol
	,account_one
	,ph.is_counter
	,metod
	,unit_id
	,kol_norma
	,metod_old
	,sup_id
	,build_id
	,ph.penalty_prev
	,ph.Penalty_old
	,ph.penalty_serv
	,ph.kol_norma_single
	,ph.source_id
	,ph.mode_id
	,ph.occ_sup_paym
	,ph.koef
	,ph.kol_added
	,ph.date_start
	,ph.date_end
	,ph.koef_day
	,dbo.Fun_GetMetodText(ph.metod_old) AS metod_old_name
FROM dbo.PAYM_HISTORY AS ph 
JOIN dbo.SERVICES AS s 
	ON ph.service_id = s.id
LEFT JOIN dbo.CALENDAR_PERIOD cp 
	ON cp.fin_id = ph.fin_id;
go

