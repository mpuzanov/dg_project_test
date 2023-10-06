-- dbo.view_payings_lite source

CREATE   VIEW [dbo].[view_payings_lite]
AS
SELECT
	p.id
	,p.pack_id
	,p.occ
	,p.service_id
	,p.value
	,pd.fin_id
	,pd.day
	,pd.forwarded
	,pd.date_edit
	,cp.StrFinPeriod AS fin_name
	,p.paymaccount_peny
	,p.sup_id
	,pd.tip_id
	,p.dog_int
	,p.commission
	,p.occ_sup
	,p.paying_vozvrat
	,p.scan
	,pd.checked
	,P.paying_manual
	,p.paying_uid
	,pd.pack_uid
	,p.filedbf_id
FROM dbo.Payings AS p 
INNER JOIN dbo.Paydoc_packs AS pd 
	ON p.pack_id = pd.id
INNER JOIN dbo.Calendar_period cp
	ON cp.fin_id = pd.fin_id;
go

