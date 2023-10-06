CREATE   FUNCTION [dbo].[Fun_NameFinPeriodStart_date]
(
	@fin_id1 SMALLINT
)
RETURNS DATE
WITH SCHEMABINDING
AS
BEGIN
	/*
	select [dbo].[Fun_NameFinPeriodStart_date](175)
	select [dbo].[Fun_NameFinPeriodStart_date](200)
	
	Выдаем дату(первое число) заданного финансового периода
	
	*/

	RETURN (SELECT
			cp.start_date
		FROM dbo.CALENDAR_PERIOD cp
		WHERE fin_id = @fin_id1)

END
go

