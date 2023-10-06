-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetTimeStr]
(
	@date1 DATETIME
)
/*
SELECT dbo.Fun_GetTimeStr('20161014 13:00')
SELECT dbo.Fun_GetTimeStr('20161014 14:00')
SELECT dbo.Fun_GetTimeStr('20161014 14:46')

DECLARE @t TIME ='14:46:32'
select CONVERT(VARCHAR(10), @t, 108)  AS 'time hh:mi:ss'
SELECT CONCAT(DATEPART(HOUR, @t),' час. ', DATEPART(MINUTE, @t),' мин. ',DATEPART(SECOND, @t),' сек.')  AS 'time Result'

*/
RETURNS VARCHAR(100)
AS
BEGIN
	DECLARE	@kolSecond	INT
			,@msg		VARCHAR(100)
			,@date_temp	DATETIME

	SET @date_temp = current_timestamp - @date1
	SELECT
		@kolSecond = DATEDIFF(SECOND, @date1, current_timestamp)

	IF @kolSecond < 60
		SET @msg = concat(@kolSecond , ' сек.')
	ELSE
	IF @kolSecond < 3600
		SET @msg = concat(DATEPART(MINUTE, @date_temp) , ' мин. ' , DATEPART(SECOND, @date_temp) , ' сек.')
	ELSE
		SET @msg = concat(DATEPART(HOUR, @date_temp) , ' час. ' , DATEPART(MINUTE, @date_temp) , ' мин. ' , DATEPART(SECOND, @date_temp) , ' сек.')

	RETURN @msg

END
go

