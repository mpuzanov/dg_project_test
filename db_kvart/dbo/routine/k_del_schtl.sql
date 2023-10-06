CREATE   PROCEDURE [dbo].[k_del_schtl]
(
	@occ1	   INT
   ,@dbo	   BIT		   = 0 -- закрыть даже если есть долги и люди
   ,@comments1 VARCHAR(50) = NULL -- причина закрытия
)
AS
	/*
	
	  Процедура закрытия лицевого счета
	  
	*/
	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @trancount INT;
	SET @trancount = @@trancount;

	IF @dbo IS NULL
		SET @dbo = 0

	IF dbo.Fun_AccessDelLic(@occ1) = 0
	BEGIN
		RAISERROR ('Вам запрещено удалять этот лицевой счет', 16, 1)
		RETURN
	END

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	DECLARE @saldo			DECIMAL(15, 2)
		   ,@KolPeople		SMALLINT
		   ,@status_id		VARCHAR(10)
		   ,@paymaccount1   DECIMAL(15, 2)
		   ,@added1			DECIMAL(15, 2)
		   ,@penalty_value1 DECIMAL(15, 2)
		   ,@fin_current	SMALLINT

	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	SELECT
		@saldo = SALDO
	   ,@status_id = STATUS_ID
	   ,@paymaccount1 = PaymAccount
	   ,@added1 = Added
	   ,@penalty_value1 = Penalty_value + Penalty_old_new
	FROM dbo.OCCUPATIONS 
	WHERE Occ = @occ1

	SELECT
		@KolPeople = COUNT(id)
	FROM dbo.PEOPLE
	WHERE Occ = @occ1
	AND Del = 0

	IF @saldo IS NULL
		SET @saldo = 0

	IF @KolPeople IS NULL
		SET @KolPeople = 0

	IF (@status_id = 'закр')
	BEGIN
		IF @dbo = 0
			RAISERROR ('Ошибка! Лицевой %d уже закрыт!', 16, 1, @occ1)
		RETURN
	END

	IF @dbo = 0
	BEGIN

		IF (@saldo <> 0)
			OR (@KolPeople > 0)
			OR (@paymaccount1 > 0)
			OR (@added1 > 0)
			OR (@penalty_value1 > 0)
		BEGIN
			RAISERROR ('Закрыть лицевой счет %d нельзя! есть долг или люди.', 16, 1, @occ1)
			RETURN
		END

		IF EXISTS (SELECT
					1
				FROM dbo.OCC_SUPPLIERS 
				WHERE Occ = @occ1
				AND fin_id = @fin_current
				AND (SALDO <> 0
				OR Debt <> 0))
		BEGIN
			RAISERROR ('Закрыть лицевой счет %d нельзя! есть суммы по поставщику', 16, 1, @occ1)
			RETURN
		END

	END

	BEGIN TRY

		IF EXISTS (SELECT
					1
				FROM dbo.OCC_HISTORY 
				WHERE Occ = @occ1)
		BEGIN -- если лицевой есть в истории то его просто закрываем

			IF @trancount = 0
				BEGIN TRANSACTION
				ELSE
					SAVE TRANSACTION k_del_schtl;

				DELETE FROM dbo.PAYM_LIST 
				WHERE Occ = @occ1

				DELETE FROM dbo.PAYM_COUNTER_ALL 
				WHERE Occ = @occ1
					AND fin_id = @fin_current

				DELETE dbo.COUNTER_LIST_ALL 
				WHERE Occ = @occ1
					AND fin_id = @fin_current

				DELETE FROM dbo.OCC_SUPPLIERS 
				WHERE Occ = @occ1
					AND fin_id = @fin_current

				-- Устанвливем режим НЕТ
				-- и поставщика НЕТ
				UPDATE cl
				SET mode_id	  = s.service_no * 1000
				   ,source_id = s.service_no * 1000
				FROM dbo.CONSMODES_LIST AS cl
				JOIN dbo.SERVICES AS s
					ON cl.service_id = s.id
				WHERE cl.Occ = @occ1

				UPDATE dbo.OCCUPATIONS
				SET STATUS_ID		 = 'закр'
				   ,TOTAL_SQ		 = 0
				   ,Value			 = 0
				   ,Discount		 = 0
				   ,Compens			 = 0
				   ,Compens_ext		 = 0
				   ,Added			 = 0
				   ,Added_ext		 = 0
				   ,PaymAccount		 = 0
				   ,PaymAccount_peny = 0
				   ,Paid			 = 0
				   ,Paid_minus		 = 0
				   ,Paid_old		 = 0
				WHERE Occ = @occ1

				UPDATE dbo.PAYM_LGOTA_ALL 
				SET Discount = 0
				WHERE Occ = @occ1
				AND fin_id = @fin_current


				IF @trancount = 0
				COMMIT TRANSACTION;

			-- сохраняем в историю изменений
			EXEC k_write_log @occ1 = @occ1
							,@oper1 = 'удлс'
							,@comments1 = @comments1

		END
		ELSE
		BEGIN -- если лицевого нет в истории то удаляем

			DECLARE @msg VARCHAR(80)
			SET @msg = 'Ошибка удаления лиц.счета! Таблица: '

			DELETE dbo.OCC_SUPPLIERS 
			WHERE Occ = @occ1
				AND fin_id = @fin_current

			DELETE dbo.OP_LOG 
			WHERE Occ = @occ1

			DELETE dbo.COUNTER_LIST_ALL 
			WHERE Occ = @occ1

			DELETE dbo.OCCUPATIONS
			WHERE Occ = @occ1

			DELETE dbo.PEOPLE 
			WHERE Occ = @occ1

			DELETE dbo.CONSMODES_LIST 
			WHERE Occ = @occ1

			DELETE dbo.PAYM_LIST 
			WHERE Occ = @occ1

			DELETE dbo.ADDED_PAYMENTS 
			WHERE Occ = @occ1

			DELETE dbo.CESSIA 
			WHERE Occ = @occ1

			DELETE dbo.PAYING_SERV 
			WHERE Occ = @occ1

			DELETE dbo.PAYINGS 
			WHERE Occ = @occ1

			DELETE dbo.PAYM_HISTORY
			WHERE Occ = @occ1

			DELETE dbo.COMPENSAC_ALL 
			WHERE Occ = @occ1
				AND fin_id = @fin_current

			DELETE dbo.PAYM_OCC_BUILD 
			WHERE Occ = @occ1

		END -- if exists -- if exists

	END TRY
	BEGIN CATCH
		DECLARE @xstate INT;
		SELECT
			@xstate = XACT_STATE();
		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @trancount = 0
			ROLLBACK
		IF @xstate = 1
			AND @trancount > 0
			ROLLBACK TRANSACTION k_del_schtl;

		EXEC dbo.k_err_messages
	END CATCH
go

