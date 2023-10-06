CREATE   FUNCTION [dbo].[Fun_GetLastDayFin]
(
	@fin_id1 SMALLINT
)
RETURNS SMALLDATETIME
AS
BEGIN
	/*
	--  Возвращаем дату с последним днем в месяце заданного фин. периода
	*/
	DECLARE @date1 SMALLDATETIME
	
	SELECT
		@date1 = end_date
	FROM dbo.Global_values
	WHERE fin_id = @fin_id1;
	
	IF @date1 IS NULL
	BEGIN
		SELECT TOP 1
			@date1 = DATEADD(MINUTE, -1, DATEADD(MONTH, 2, start_date))
		FROM dbo.Global_values
		ORDER BY fin_id DESC;
	END

	RETURN @date1
END
go

