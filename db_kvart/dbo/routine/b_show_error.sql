CREATE   PROCEDURE [dbo].[b_show_error]
(
	@day1 SMALLINT
)
AS
/*
Паказать ошибки импорта электронных платежей за последние @day1 дней
*/
SET NOCOUNT ON

DECLARE @date1 SMALLDATETIME
		,@date2 SMALLDATETIME

SET @date1 = DATEADD(DAY, -1 * @day1, current_timestamp)
SET @date2 = current_timestamp

SELECT
	CONVERT(CHAR(20), data_error, 113) AS 'Дата'
	,error AS 'Описание ошибки'
FROM dbo.BANK_ERROR
WHERE 
	data_error BETWEEN @date1 AND @date2
ORDER BY data_error DESC
go

