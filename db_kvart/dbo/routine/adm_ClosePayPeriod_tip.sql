CREATE PROCEDURE [dbo].[adm_ClosePayPeriod_tip]
(
	@tip_id				SMALLINT
	,@PaymClosedNewData	SMALLDATETIME	= NULL
)
AS
	/*
	
	Закрытие платежного периода по типу фонда
	
	*/
	SET NOCOUNT ON
	SET XACT_ABORT ON;

	BEGIN TRY

		DECLARE	@fin_current		INT
				,@fin_new			INT
				,@PaymClosed1		BIT
				,@LastPaym1			TINYINT
				,@msg				VARCHAR(60)
				,@start_date1		SMALLDATETIME
				,@end_date1			SMALLDATETIME
				,@LastPaymDate1		SMALLDATETIME
				,@PaymClosedData	SMALLDATETIME

		SELECT
			@PaymClosed1 = PaymClosed
			,@LastPaym1 = LastPaym
			,@PaymClosedData = PaymClosedData
			,@fin_current = fin_id
		FROM dbo.OCCUPATION_TYPES
		WHERE id = @tip_id

		SELECT
			@start_date1 = [start_date]
		FROM dbo.GLOBAL_VALUES
		WHERE fin_id = @fin_current

		IF @PaymClosed1 = 1
		BEGIN
			RAISERROR ('Платежный период уже закрыт!', 11, 1)
			RETURN 1
		END

		IF DATEDIFF(DAY, @PaymClosedData, current_timestamp) < 20
		BEGIN
			RAISERROR ('Слишком рано для закрытия платежного периода!', 11, 1)
			RETURN 1
		END


		--***********************************************************
		--  Если есть не закрытые дни то их надо закрыть
		SELECT
			@LastPaymDate1 = DATEADD(DAY, @LastPaym1 - 1, @start_date1)
			,@fin_new = @fin_current + 1

		IF EXISTS (SELECT
					1
				FROM dbo.PAYDOC_PACKS
				WHERE fin_id = @fin_current
				AND day <= @LastPaymDate1
				AND tip_id = @tip_id
				AND checked = 0)
		BEGIN
			SET @msg = 'Имеются плохие пачки, которые надо закрыть'
			RAISERROR (@msg, 11, 1)
			RETURN 1
		END

		-- Выбираем не закрытые пачки 
		IF EXISTS (SELECT
					1
				FROM dbo.PAYDOC_PACKS
				WHERE fin_id = @fin_current
				AND day <= @LastPaymDate1
				AND tip_id = @tip_id
				AND forwarded = 0)
		BEGIN
			SET @msg = 'Закройте дни по ' + CONVERT(VARCHAR(10), @LastPaymDate1, 104)
			RAISERROR (@msg, 11, 1)
			RETURN 1
		END

		IF @PaymClosedNewData is NULL SET @PaymClosedNewData=current_timestamp

		BEGIN TRAN

			PRINT 'Закрываем платежный период!'
			UPDATE dbo.OCCUPATION_TYPES
			SET	PaymClosed		= 1
				,PaymClosedData	= @PaymClosedNewData
				,LastPaymDay	=
					CASE   -- Последний день оплаты (обновляется при закрытии дней)
						WHEN LastPaymDay IS NULL THEN @start_date1
						WHEN LastPaymDay < @start_date1 THEN @start_date1
						ELSE LastPaymDay
					END
			WHERE id = @tip_id
			PRINT 'Период закрыли!'

		COMMIT TRAN

		EXEC [dbo].[adm_create_global_fin] @fin_new

	END TRY

	BEGIN CATCH

		EXEC dbo.k_err_messages

	END CATCH
go

