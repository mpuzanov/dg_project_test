CREATE   FUNCTION [dbo].[Fun_NameFinPeriodDate]
(
	@date1 SMALLDATETIME
)
RETURNS VARCHAR(15)
WITH SCHEMABINDING
AS
BEGIN
	/*
	Выдаем название заданного финансовому периода

	select dbo.Fun_NameFinPeriodDate('20150323')
	select dbo.Fun_NameFinPeriodDate('20150901')
	*/
		
	RETURN CAST(CONCAT(DATENAME(MONTH, @date1),' ',DATENAME(YEAR, @date1)) AS VARCHAR(15))
END
go

