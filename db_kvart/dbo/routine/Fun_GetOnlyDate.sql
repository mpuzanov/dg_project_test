-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       FUNCTION [dbo].[Fun_GetOnlyDate]
(
	@d DATETIME
)
RETURNS DATETIME
AS
BEGIN
	/*
	  Функция возвращает только дату без минут и т.п.
	*/
	--RETURN dateadd(day,0,datediff(day,0,@d))
	RETURN CAST(CAST(@d AS date) AS DATETIME)

END
go

exec sp_addextendedproperty 'ms_description', N'Функция возвращает дату без минут', 'SCHEMA', 'dbo', 'FUNCTION',
     'Fun_GetOnlyDate'
go

