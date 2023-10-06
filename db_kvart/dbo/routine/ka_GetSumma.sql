CREATE   PROCEDURE [dbo].[ka_GetSumma]
(
	@occ1			INT
	,@service_id1	VARCHAR(10)
	,@day_count1	SMALLINT
	,@people_count1	SMALLINT
)
AS
	--
	--  Получение суммы  суммы ввода разовых
	--
	SET NOCOUNT ON

	DECLARE	@Start_date		SMALLDATETIME
			,@End_date		SMALLDATETIME
			,@day_diff		SMALLINT
			,@fin_current	SMALLINT
			,@mode1			INT -- ключ режима потребления
			,@source1		INT -- ключ поставщика  
			,@tar1			DECIMAL(10, 4)

	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)
	SELECT
		@Start_date = start_date
		,@End_date = end_date
	FROM dbo.GLOBAL_VALUES
	WHERE fin_id = @fin_current

	SELECT
		@day_diff = DATEDIFF(DAY, @Start_date, @End_date) + 1

	SELECT
		@mode1 = mode_id
		,@source1 = source_id
	FROM dbo.CONSMODES_LIST
	WHERE (occ = @occ1)
	AND (service_id = @service_id1)

	SELECT
		@tar1 = value
	FROM dbo.RATES
	WHERE (finperiod = @fin_current)
	AND (service_id = @service_id1)
	AND (mode_id = @mode1)
	AND (source_id = @source1)
	AND (status_id = 'откр')

	--SELECT  @day_diff, @tar1
	SELECT
		'summa' = ROUND(@tar1 / @day_diff * @day_count1 * @people_count1, 2)
go

