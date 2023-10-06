CREATE FUNCTION [dbo].[Fun_GetFirstDayMonth]
(
	@date1 SMALLDATETIME
)
RETURNS SMALLDATETIME
AS
BEGIN
	/*
	--  Возвращаем дату с первым денем месяца
	*/
	RETURN DATEADD(DAY, 1 - DAY(@date1), @date1)
END
go

