CREATE   PROCEDURE [dbo].[k_counter_del_occ]
(
	@id1	INT -- код счетчика
   ,@occ1   INT	= NULL -- лицевой 
   ,@fin_id SMALLINT = NULL
)
AS
	/*
		Отсоединение лицевого счета от счетчика
	*/
	SET NOCOUNT ON;
	SET XACT_ABORT ON
	DECLARE @trancount INT;
	SET @trancount = @@trancount;

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1);
		RETURN;
	END;

	DECLARE @service_id1 VARCHAR(10)
		   ,@build_id1	 INT
		   ,@err		 INT;
	DECLARE @serial_number1 VARCHAR(10)
		   ,@str1			VARCHAR(100);

	SELECT
		@service_id1 = service_id
	   ,@serial_number1 = serial_number
	   ,@build_id1 = build_id
	FROM dbo.COUNTERS 
	WHERE id = @id1;

	DECLARE @fin_current SMALLINT;
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, @build_id1, NULL, @occ1);

	IF @fin_id IS NULL
		SET @fin_id = @fin_current;

	IF dbo.Fun_AccessCounterLic(@build_id1) = 0
	BEGIN
		RAISERROR ('Для Вас работа со счетчиками запрещена!', 16, 1);
		RETURN;
	END;

	BEGIN TRY
		IF @trancount = 0
			BEGIN TRANSACTION
			ELSE
				SAVE TRANSACTION k_counter_del_occ;

			DELETE FROM dbo.Counter_list_all
			WHERE counter_id = @id1
				AND (occ = @occ1 OR @occ1 IS NULL)	-- заданного или всех
				AND fin_id = @fin_id;

			IF @fin_id = @fin_current
			BEGIN
				-- Если это последний счетчик по услуге
				-- убираем признак отдельной платы за эту услугу

				UPDATE cml
				SET is_counter = 0
				FROM dbo.Consmodes_list AS cml
				WHERE is_counter = 1
				AND cml.occ = @occ1
				AND cml.service_id = @service_id1
				AND NOT EXISTS (SELECT
						1
					FROM dbo.Counter_list_all 
					WHERE occ = cml.occ
					AND service_id = cml.service_id
					AND fin_id = @fin_current);
			END;

			IF @trancount = 0
			COMMIT TRANSACTION;

		-- сохраняем в историю изменений
		SET @str1 = CONCAT('Счетчик: ', @serial_number1,', Удалили лицевой: ', @occ1,', период: ', dbo.Fun_NameFinPeriod(@fin_id))
		EXEC k_counter_write_log @id1
								,'счре'
								,@str1;

	END TRY
	BEGIN CATCH
		DECLARE @xstate INT;
		SELECT
			@xstate = XACT_STATE();
		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @trancount = 0
			ROLLBACK;
		IF @xstate = 1
			AND @trancount > 0
			ROLLBACK TRANSACTION k_counter_del_occ;

		DECLARE @strerror VARCHAR(4000) = ''
		EXECUTE k_GetErrorInfo @visible = 0
							  ,@strerror = @strerror OUT
		RAISERROR (@strerror, 16, 1)

	END CATCH
go

