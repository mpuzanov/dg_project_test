CREATE   PROCEDURE [dbo].[rep_rates_schtl]
(
	@occ		INT
	,@fin_id1	SMALLINT = NULL
)
AS
	/*
	
	Список тарифов по заданному лицевому счету
	
	rep_schtl.fr3
	
	rep_rates_schtl @occ=33001, @fin_id1=244

	*/

	SET NOCOUNT ON

	if @fin_id1 IS NULL
		SELECT @fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ)

	SELECT DISTINCT
		  o.[address] AS [address]
		, ot.Name AS tipes
		, s.short_name
		, r.mode_id
		, r.source_id
		, cm.Name
		, sup.Name
		, r.status_id
		, r.PROPTYPE_ID
		, r.value
		, r.extr_value
		, r.full_value
	FROM dbo.View_occ_all_lite o 
	JOIN dbo.Rates AS r 
		ON o.fin_id=r.finperiod 
		AND r.PROPTYPE_ID=o.PROPTYPE_ID
		AND r.tipe_id = o.tip_id
		AND r.status_id = o.status_id
	JOIN dbo.View_consmodes_lite AS cl 
		ON r.service_id = cl.service_id
		AND r.mode_id = cl.mode_id
		AND r.source_id = cl.source_id
		AND cl.fin_id = o.fin_id
		AND cl.occ=o.occ
	JOIN dbo.View_services AS s 
		ON cl.service_id = s.id
	JOIN dbo.Cons_modes cm 
		ON cl.mode_id = cm.id
	JOIN dbo.View_suppliers AS sup 
		ON cl.source_id = sup.id
	JOIN dbo.VOcc_types AS ot 
		ON r.tipe_id = ot.id	  
	WHERE 1=1
		AND o.occ = @occ
		AND o.fin_id = @fin_id1
go

