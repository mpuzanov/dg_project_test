-- =============================================
-- Author:		Пузанов
-- Create date: 26.11.2014
-- Description:	минимальное кол-во месяцев до периода поверки на лицевом и услуге
-- 
-- =============================================
CREATE       FUNCTION [dbo].[Fun_GetKolMonthPeriodCheck]
(
	@occ			INT
	,@fin_id		SMALLINT
	,@service_id	VARCHAR(10)
)
/*
select dbo.Fun_GetKolMonthPeriodCheck(268233,154,'хвод')
select dbo.Fun_GetKolMonthPeriodCheck(268245,154,'хвод')
select dbo.Fun_GetKolMonthPeriodCheck(268244,154,'хвод')
*/
RETURNS SMALLINT
AS
BEGIN
	RETURN COALESCE(
		(SELECT
			MIN(DATEDIFF(MONTH, cp.start_date, c.PeriodCheck))
		FROM dbo.Counter_list_all AS cl 
		JOIN dbo.Counters AS c 
			ON cl.counter_id = c.id
		LEFT JOIN dbo.Calendar_period cp
			ON cp.fin_id=cl.fin_id
		WHERE cl.occ = @occ
			AND cl.fin_id = @fin_id
			AND c.service_id = @service_id	
			AND c.PeriodCheck IS NOT NULL
			AND (c.date_del IS NULL)
			--AND ot.ras_no_counter_poverka = 1;

		), 0);
END;
go

