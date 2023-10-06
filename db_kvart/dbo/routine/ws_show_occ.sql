-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	для веб-сервисов
-- =============================================
CREATE         PROCEDURE [dbo].[ws_show_occ] 
(
	@occ INT
)
/*
 exec ws_show_occ 111038
 exec ws_show_occ 350111038
 exec ws_show_occ 33100
 exec ws_show_occ 350033100
*/
AS
BEGIN
	SET NOCOUNT ON;

	select @occ= dbo.Fun_GetFalseOccIn(@occ)

	SELECT 
		dbo.Fun_GetFalseOccOut(o.occ, o.tip_id) AS occ
		,o.address
		,REPLACE(ot.name, '"', '') AS tip_name
		,o.total_sq
		,o.fin_id
		,gb.StrMes AS fin_current_str
		,o.kol_people
		,gb.CounterValue1 as CV1
		,gb.CounterValue2 as CV2
		,ot.state_id AS Rejim
	FROM dbo.Occupations o
		JOIN dbo.Occupation_Types as ot ON ot.id=o.tip_id
		JOIN dbo.Global_values as gb ON gb.fin_id=o.fin_id
	WHERE o.occ=@occ

END
go

