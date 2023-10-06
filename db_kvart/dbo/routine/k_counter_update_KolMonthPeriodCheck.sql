-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[k_counter_update_KolMonthPeriodCheck]
(
	@flat_id1 INT
)
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE cl
	SET KolmesForPeriodCheck = KolmesForPeriodCheck2
	FROM dbo.Occupations AS o 
	JOIN dbo.Occupation_Types ot ON 
		o.tip_id = ot.id
	JOIN dbo.Counter_list_all AS cl ON 
		o.Occ = cl.Occ
	JOIN dbo.Counters c ON 
		cl.counter_id = c.id
	CROSS APPLY (SELECT KolmesForPeriodCheck2 = dbo.Fun_GetKolMonthPeriodCheck(cl.Occ, cl.fin_id, cl.service_id)) AS t
	WHERE 
		cl.fin_id < o.fin_id
		AND o.status_id <> 'закр'
		AND c.PeriodCheck IS NOT NULL
		AND o.flat_id = @flat_id1
		AND c.date_del IS NULL
		AND cl.fin_id >= (ot.fin_id-12*3)
		AND ot.payms_value = CAST(1 AS BIT)	
		AND KolmesForPeriodCheck <> t.KolmesForPeriodCheck2

	--UPDATE T
	--SET KolmesForPeriodCheck = KolmesForPeriodCheck2
	--FROM (
	--	SELECT cl.Occ
	--		 , cl.service_id
	--		 , cl.KolmesForPeriodCheck
	--		 , KolmesForPeriodCheck2 = dbo.Fun_GetKolMonthPeriodCheck(cl.Occ, cl.fin_id, cl.service_id)
	--		 , cl.fin_id
	--	FROM dbo.Occupations AS o 
	--		JOIN dbo.Occupation_Types ot 
	--			ON o.tip_id = ot.id
	--		JOIN dbo.Counter_list_all AS cl 
	--			ON o.Occ = cl.Occ
	--		JOIN dbo.Counters c 
	--			ON cl.counter_id = c.id
	--	WHERE 
	--		cl.fin_id < o.fin_id
	--		AND o.status_id <> 'закр'
	--		AND c.PeriodCheck IS NOT NULL
	--		AND o.flat_id = @flat_id1
	--		AND c.date_del IS NULL
	--		AND cl.fin_id >= 180
	--		AND ot.payms_value = cast(1 as bit)
	--) AS T
	--WHERE KolmesForPeriodCheck <> KolmesForPeriodCheck2

END
go

