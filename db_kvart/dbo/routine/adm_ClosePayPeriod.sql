CREATE PROCEDURE [dbo].[adm_ClosePayPeriod]
AS
	--
	--  Закрытие платежного периода 
	--
	--  В процедуре должен быть расчет пени

	/*
	Debt= Вх.сальдо на начало месяца - платежи по день закрытия платежгого периода
	заданного в глобальных значениях
	*/
	SET NOCOUNT ON
	SET XACT_ABORT ON;
	
	BEGIN TRY

		DECLARE	@fin_current		INT
				,@fin_id2			INT
				,@PaymClosed1		BIT
				,@LastPaym1			TINYINT
				,@msg				VARCHAR(60)
				,@start_date1		SMALLDATETIME
				,@end_date1			SMALLDATETIME
				,@LastPaymDate1		SMALLDATETIME
				,@PaymClosedData	SMALLDATETIME

		SELECT
			@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

		SELECT
			@start_date1 = [start_date]
			,@end_date1 = end_date
			,@PaymClosed1 = PaymClosed
			,@LastPaym1 = LastPaym
			,@PaymClosedData = PaymClosedData
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
		IF EXISTS (SELECT
					id
				FROM dbo.PAYDOC_PACKS
				WHERE fin_id = @fin_current
				AND day <= @LastPaymDate1
				AND checked = 0)
		BEGIN
			SET @msg = 'Имеются плохие пачки, которые надо закрыть'
			RAISERROR (@msg, 11, 1)
			RETURN 1
		END
		-- Выбираем не закрытые пачки 
		IF EXISTS (SELECT
					id
				FROM dbo.PAYDOC_PACKS
				WHERE fin_id = @fin_current
				AND day <= @LastPaymDate1
				AND forwarded = 0)
		BEGIN
			SET @msg = 'Закройте дни по ' + CONVERT(VARCHAR(10), @LastPaymDate1, 104)
			RAISERROR (@msg, 11, 1)
			RETURN 1
		END

		BEGIN TRAN

			PRINT 'Закрываем платежный период!'
			UPDATE dbo.GLOBAL_VALUES
			SET	PaymClosed		= 1
				,PaymClosedData	= current_timestamp
			WHERE fin_id = @fin_current
			PRINT 'Период закрыли!'

		COMMIT TRAN

	END TRY

	BEGIN CATCH

		EXEC dbo.k_err_messages

	END CATCH
go

