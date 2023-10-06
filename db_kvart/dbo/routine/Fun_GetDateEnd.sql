
CREATE FUNCTION [dbo].[Fun_GetDateEnd]
(
	@d DATETIME
)
RETURNS DATETIME
AS
BEGIN
	/*
	  Функция возвращает дату конца дня
	*/
	RETURN SMALLDATETIMEFROMPARTS(YEAR(@d), MONTH(@d), DAY(@d), 23, 59)

END
go

exec sp_addextendedproperty 'MS_Description', N'Функция возвращает дату конца дня', 'SCHEMA', 'dbo', 'FUNCTION',
     'Fun_GetDateEnd'
go

