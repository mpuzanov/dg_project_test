-- =============================================
-- Author:		Пузанов
-- Create date: 14.04.2016
-- Description:	Текущий период поверки по периодам
-- =============================================
CREATE FUNCTION [dbo].[Fun_getPeriodCheckCounter_table]
(
	@counter_id INT
	,@fin_id SMALLINT = NULL
)
RETURNS @t TABLE
(
	fin_id smallint
	,counter_id INT
	,PeriodCheck SMALLDATETIME
	,start_date SMALLDATETIME
	,KolmesForPeriodCheck SMALLINT
)
AS
/*

SELECT * FROM Fun_getPeriodCheckCounter_table(36210,169)

*/
BEGIN
	INSERT INTO @t
	SELECT *, KolmesForPeriodCheck=DATEDIFF(MONTH,start_date, PeriodCheck) FROM (
	SELECT
		fin_id
		,id AS counter_id
		,PeriodCheck =
			CASE
				WHEN (gv.end_date < PeriodCheckOld) THEN PeriodCheckOld
				ELSE PeriodCheck
			END
		,gv.start_date	
	FROM	dbo.GLOBAL_VALUES gv
			,COUNTERS c
	WHERE gv.fin_id > 150
	AND gv.fin_id = COALESCE(@fin_id,gv.fin_id)
	AND c.id=@counter_id
	AND c.PeriodCheck IS NOT NULL
	) AS t
	
	RETURN 
END
go

