

CREATE FUNCTION [dbo].[Fun_GetDateStart]
(
	@d DATETIME
)
RETURNS DATETIME
AS
BEGIN
	/*
	  Функция возвращает дату начала дня
	*/
	RETURN SMALLDATETIMEFROMPARTS(YEAR(@d), MONTH(@d), DAY(@d), 0, 0)

END
go

exec sp_addextendedproperty 'MS_Description', N'Функция возвращает дату начала дня', 'SCHEMA', 'dbo', 'FUNCTION',
     'Fun_GetDateStart'
go

