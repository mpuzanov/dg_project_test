CREATE   FUNCTION [dbo].[Fun_NameFinPeriod]
(
	@fin_id1 SMALLINT
)
RETURNS VARCHAR(15)
WITH SCHEMABINDING
AS
BEGIN
	/*
		select [dbo].[Fun_NameFinPeriod](170)
		select [dbo].[Fun_NameFinPeriod](null)
		select [dbo].[Fun_NameFinPeriod](190)
		
		Выдаем название заданного финансового периода по формату:   август 2001
	*/

	RETURN (SELECT
			StrFinPeriod
		FROM dbo.Calendar_period cp
		WHERE fin_id = @fin_id1)

END
go

