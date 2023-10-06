-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	список типов фонда в форме закрытия периодов
-- =============================================
CREATE     PROCEDURE [dbo].[adm_show_period_tip] 
AS
/*
exec adm_show_period_tip

*/
BEGIN
	SET NOCOUNT ON;

	select 	
		ot.id
		,ot.Name
		,ot.payms_value
		,ot.PaymClosedData
		,ot.PaymClosed
		,ot.fin_id
		,ot.raschet_no
		,ot.state_id
		,ot.start_date
		,dbo.fn_end_month(ot.start_date) as end_date
		,dbo.Fun_NameFinPeriod(fin_id) AS fin_name
		,t.kol_occ_paym AS kol_occ		
	from dbo.Occupation_Types as ot
		OUTER APPLY
			(SELECT 
				COALESCE(COUNT(o.occ),0) as kol 
				,COALESCE(SUM(CASE WHEN b.is_paym_build = 1 THEN 1 ELSE 0 END), 0) as kol_occ_paym
			FROM dbo.Occupations o 
			JOIN dbo.Flats f ON 
				o.flat_id=f.id
			JOIN dbo.Buildings b ON 
				f.bldn_id=b.id
		   WHERE 
				o.tip_id=ot.id 
				AND o.STATUS_ID<>'закр' 
				AND o.total_sq>0
		   ) as t

END
go

