-- dbo.view_consmodes_lite source

CREATE   VIEW [dbo].[view_consmodes_lite]
AS
SELECT
	cl.fin_id
	,cl.occ
	,cl.service_id
	,cl.sup_id
	,cl.source_id
	,cl.mode_id
	,cl.koef
	,cl.subsid_only
	,cl.is_counter
	,cl.account_one
	,cl.dog_int
FROM dbo.Consmodes_list AS cl
UNION ALL
SELECT
	ch.fin_id
	,ch.occ
	,ch.service_id
	,ch.sup_id
	,ch.source_id
	,ch.mode_id
	,ch.koef
	,ch.subsid_only
	,ch.is_counter
	,ch.account_one	
	,NULL dog_int
FROM dbo.Paym_history ch;
go

