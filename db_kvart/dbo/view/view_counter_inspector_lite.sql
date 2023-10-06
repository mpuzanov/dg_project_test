-- dbo.view_counter_inspector_lite source

CREATE   VIEW [dbo].[view_counter_inspector_lite]  AS 
SELECT 
	ci.counter_id
	,ci.fin_id
	,cla.occ
	,ci.id
	,ci.inspector_value
	,ci.tip_value
	,ci.inspector_date
	,ci.actual_value
	,ci.kol_day
	,ci.value_vday
	,cla.service_id
	,cla.internal
	,ci.value_paym
	,ci.tarif
	,ci.mode_id
	,ci.comments
	,ci.date_edit
	,ci.user_edit
	,ci.metod_input
	,ci.warning
	,ci.metod_rasch
	,cla.KolmesForPeriodCheck
FROM dbo.Counter_inspector AS ci
INNER JOIN dbo.Counter_list_all cla
	ON ci.counter_id = cla.counter_id
	AND ci.fin_id = cla.fin_id;
go

