CREATE   FUNCTION [dbo].[Fun_NameFinPeriod_YYYYMMDD]
(
	@fin_id1 SMALLINT
)
RETURNS VARCHAR(8)
WITH SCHEMABINDING
AS
BEGIN
	/*
	select dbo.Fun_NameFinPeriod_YYYYMMDD(181)
	Выдаем название заданного финансового периода   20170201 
	*/

	--RETURN (
	--	SELECT CONVERT(VARCHAR(8), start_date, 112)
	--	FROM dbo.Global_values AS gb 
	--	WHERE fin_id = @fin_id1
	--)

	RETURN (SELECT
		cp.yyyymmdd
		FROM dbo.Calendar_period AS cp
		WHERE fin_id = @fin_id1
	)

END
go

