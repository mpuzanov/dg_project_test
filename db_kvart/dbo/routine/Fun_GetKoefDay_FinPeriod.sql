-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE   FUNCTION [dbo].[Fun_GetKoefDay_FinPeriod]
(
	@data1		SMALLDATETIME
	,@data2		SMALLDATETIME
	,@fin_id	SMALLINT
)
RETURNS DECIMAL(10, 4)
/*
select dbo.Fun_GetKoefDay_FinPeriod('20141001','20150215',156)
select dbo.Fun_GetKoefDay_FinPeriod('20141002','20150215',153)
select dbo.Fun_GetKoefDay_FinPeriod('20150513','20150520',160)
*/
AS
BEGIN
	DECLARE	@koef				DECIMAL(10, 4)	= 1
			,@kolDay			SMALLINT
			,@KolDayFinPeriod	TINYINT
			,@Start_date		SMALLDATETIME
			,@End_date			SMALLDATETIME

	SELECT
		@Start_date = start_date
		,@End_date = end_date
		,@KolDayFinPeriod = KolDayFinPeriod
	FROM dbo.Global_values 
	WHERE fin_id = @fin_id

	SET @kolDay = @KolDayFinPeriod

	IF @data1 BETWEEN @Start_date AND @End_date
		SELECT
			@kolDay = DATEDIFF(DAY, @data1, @End_date) + 1

	IF @data2 BETWEEN @Start_date AND @End_date
		SELECT
			@kolDay = DATEDIFF(DAY, @Start_date, @data2) + 1

	IF (@data1 BETWEEN @Start_date AND @End_date)
		AND (@data2 BETWEEN @Start_date AND @End_date)
		SELECT
			@kolDay = DATEDIFF(DAY, @data1, @data2) + 1

	SET @koef = CAST(@kolDay AS DECIMAL(10, 4)) / @KolDayFinPeriod

	RETURN @koef

END
go

