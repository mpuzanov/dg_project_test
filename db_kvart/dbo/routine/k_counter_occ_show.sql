-- =============================================
-- Author:		Пузанов
-- Create date: 04.03.2011
-- Description:	
-- =============================================
CREATE   PROCEDURE [dbo].[k_counter_occ_show]
	@flat_id1		INT
	,@occ1			INT			= NULL
	,@tip_value1	SMALLINT	= 1
AS
/*

k_counter_occ_show 74158,126174

*/
BEGIN

	SET NOCOUNT ON;

	SELECT
		flat_id
		,cpo.fin_id
		,occ
		,service_id
		,tip_value
		,kol
		,value
		,gb.StrMes AS fin_name
		,s.short_name AS serv_name
		,YEAR(gb.start_date) AS 'Год'
		,DATEPART(qq, gb.start_date) AS 'Квартал'
	FROM dbo.COUNTER_PAYM_OCC AS cpo 
	JOIN dbo.View_SERVICES AS s
		ON cpo.service_id = s.id
	JOIN dbo.GLOBAL_VALUES AS gb 
		ON cpo.fin_id = gb.fin_id
	WHERE flat_id = @flat_id1
	AND (occ = @occ1
	OR @occ1 IS NULL)
	AND (tip_value = @tip_value1
	OR tip_value = 1)
	ORDER BY cpo.fin_id DESC


END
go

