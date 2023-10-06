-- =============================================
-- Author:		Пузанов
-- Create date: 20.04.2020
-- Description:	минимальное кол-во месяцев до периода поверки на лицевом и услуге
-- В связи с короновирусом приостановили работу с датой поверки с 03.04.2020
-- у них функция будет возвращать 888
-- =============================================
CREATE       FUNCTION [dbo].[Fun_GetKolMonthPeriodCheck2020]
(
	@occ		INT
   ,@fin_id		SMALLINT
   ,@service_id VARCHAR(10)
)
/*
select dbo.Fun_GetKolMonthPeriodCheck2020(291684,218,'хвод')
select dbo.Fun_GetKolMonthPeriodCheck2020(291684,219,'хвод')
select dbo.Fun_GetKolMonthPeriodCheck2020(315430,219,'гвод')
select dbo.Fun_GetKolMonthPeriodCheck2020(288551,219,'хвод')
*/
RETURNS SMALLINT
AS
BEGIN

	RETURN COALESCE(

	(SELECT		
			CASE
				WHEN MIN(cp.start_date)>MIN(c.PeriodCheck) 
				--AND MIN(c.PeriodCheck)>='20200401' THEN 888
				-- делаем как будто дата поверки закончилась '20201231'
				AND MIN(c.PeriodCheck) BETWEEN '20200406' AND '20201231' THEN MIN(DATEDIFF(MONTH, cp.start_date, '20201231'))
				ELSE MIN(DATEDIFF(MONTH, cp.start_date, c.PeriodCheck))
			END
	FROM dbo.Counter_list_all AS cl 
	JOIN dbo.Counters AS c 
		ON cl.counter_id = c.id
	LEFT JOIN dbo.Calendar_period cp
		ON cp.fin_id = cl.fin_id
	WHERE 1=1
		AND cl.Occ = @occ
		AND cl.fin_id = @fin_id
		AND c.service_id = @service_id
		AND c.PeriodCheck IS NOT NULL	
		AND (c.date_del IS NULL)
		--AND ot.ras_no_counter_poverka = 1;

	), 0);

END;
go

