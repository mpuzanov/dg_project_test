-- =============================================
-- Author:		Пузанов
-- Create date: 15.10.2018
-- Description:	Смена периода поверки ПУ
-- =============================================
CREATE   PROCEDURE [dbo].[k_counter_period_edit]
(
	@counter_id1	  INT
   ,@PeriodCheckNew	  SMALLDATETIME	 = NULL	-- плановая дата поверки
   ,@PeriodLastCheck  SMALLDATETIME	 = NULL  -- последняя дата поверки
   ,@inspector_value1 DECIMAL(14, 6) = NULL  -- показание ПУ при поверке
   ,@result_add		  BIT			 = 0 OUTPUT
   ,@PeriodInterval	  SMALLINT		 = NULL -- Межповерочный интервал ПУ
   ,@debug			  BIT			 = 0
)
AS
BEGIN
	/*
	
	select DATEADD(YEAR,-1*6,'20220101') as '@PeriodLastCheck'
	select DATEDIFF(YEAR,'20160101','20220101') as '@PeriodInterval'
	select DATEADD(YEAR,6,'20160101') as '@PeriodCheckNew'
	
	*/
	SET NOCOUNT ON;

	IF @PeriodCheckNew IS NOT NULL
		AND @PeriodLastCheck IS NULL
		AND @PeriodInterval > 0
		SET @PeriodLastCheck = DATEADD(YEAR, -1 * @PeriodInterval, @PeriodCheckNew)

	IF @PeriodInterval IS NULL
		AND @PeriodCheckNew IS NOT NULL
		AND @PeriodLastCheck IS NOT NULL
		SET @PeriodInterval = DATEDIFF(YEAR, @PeriodLastCheck, @PeriodCheckNew)

	IF @PeriodCheckNew IS NULL
		AND @PeriodLastCheck IS NOT NULL
		AND @PeriodInterval > 0
		SET @PeriodCheckNew = DATEADD(YEAR, @PeriodInterval, @PeriodLastCheck)

	IF @debug = 1
		SELECT
			@PeriodLastCheck
		   ,@PeriodInterval
		   ,@PeriodCheckNew

	UPDATE c
	SET PeriodCheck		= @PeriodCheckNew
	   ,PeriodLastCheck = @PeriodLastCheck	
	   ,PeriodInterval  = @PeriodInterval --COALESCE(@PeriodInterval, PeriodInterval)
	FROM dbo.COUNTERS c
	WHERE id = @counter_id1
	SET @result_add = @@rowcount

	IF @debug = 1
		SELECT
			*
		FROM dbo.COUNTERS c
		WHERE id = @counter_id1

	IF @inspector_value1 IS NOT NULL
		AND @PeriodLastCheck < current_timestamp
		AND (DATEDIFF(MONTH, @PeriodLastCheck, current_timestamp) < 6)
	BEGIN
		DECLARE @id_new INT

		EXEC k_counter_value_add2 @counter_id1 = @counter_id1
								 ,@inspector_value1 = @inspector_value1
								 ,@inspector_date1 = @PeriodLastCheck
								 ,@tip_value1 = 0 -- 0-инспектор
								 ,@debug = 0
								 ,@result_add = @result_add OUT
								 ,@id_new = @id_new OUT
	END

END
go

