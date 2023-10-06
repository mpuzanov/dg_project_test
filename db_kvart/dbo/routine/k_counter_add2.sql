CREATE   PROCEDURE [dbo].[k_counter_add2]
(
	@id1	 INT -- Код ИПУ
   ,@occ1	 INT = NULL -- Лицевой, если NULL то добавляем все лицевые из помещения
   ,@fin_id1 SMALLINT = NULL
   ,@res_add BIT	  = 0 OUTPUT -- результат добавления
)
AS

	/*
	Добавление существующего счетчика @id1  на лицевой счет @occ1

	declare @res_add bit =0
	exec k_counter_add2 @id1=@id,@occ1=@occ,@fin_id1=@fin_id,@res_add=@res_add OUT
	select @res_add
	*/

	SET NOCOUNT ON
	SET XACT_ABORT ON
	DECLARE @trancount INT;
	SET @trancount = @@trancount;

	IF @res_add IS NULL
		SET @res_add = 0

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	DECLARE @serial_number1 VARCHAR(15)
		   ,@service_id1	VARCHAR(10)
		   ,@build_id1		INT
		   ,@flat_id1		INT
		   ,@internal		BIT
		   ,@date_create1   SMALLDATETIME
		   ,@end_date		SMALLDATETIME
		   ,@StrMes			VARCHAR(15)
		   ,@address		VARCHAR(100)

	SELECT
		@serial_number1 = serial_number
	   ,@service_id1 = service_id
	   ,@build_id1 = build_id
	   ,@internal = internal
	   ,@date_create1 = date_create
	   ,@flat_id1 =  flat_id
	FROM dbo.COUNTERS
	WHERE id = @id1

	IF dbo.Fun_AccessCounterLic(@build_id1) = 0
	BEGIN
		RAISERROR ('Для Вас работа со счетчиками запрещена!', 16, 1)
		RETURN
	END

	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, @build_id1, @flat_id1, @occ1)
	IF @fin_id1 IS NULL
		SET @fin_id1 = @fin_current

	SELECT
		@end_date = end_date
	   ,@StrMes = gv.StrMes
	FROM GLOBAL_VALUES gv 
	WHERE gv.fin_id = @fin_id1
	IF @end_date < @date_create1
	BEGIN
		RAISERROR ('ПУ (№ %s) в этом периоде (%s) ещё небыло!', 16, 1, @serial_number1, @StrMes)
		RETURN
	END

	BEGIN TRY
			IF @trancount = 0
				BEGIN TRANSACTION
			ELSE
				SAVE TRANSACTION k_counter_add2;

	DECLARE curs CURSOR LOCAL READ_ONLY FOR
		
		SELECT o.occ, o.address
		FROM dbo.Occupations AS o
		WHERE o.status_id<>'закр'
			AND o.flat_id=@flat_id1
			AND o.total_sq>0
			AND (@occ1 IS NULL OR o.occ=@occ1)
			AND NOT EXISTS(SELECT *
						FROM Counter_list_all as cla
						WHERE cla.occ = o.occ
						AND cla.counter_id = @id1
						AND cla.fin_id = @fin_id1)
	OPEN curs
	FETCH NEXT FROM curs INTO @occ1, @address
	WHILE (@@fetch_status = 0)
	BEGIN

		-- Проверяем есть ли режим потребления и поставщик по этой услуге
		IF EXISTS (SELECT
					*
				FROM dbo.Consmodes_list
				WHERE occ = @occ1
					AND service_id = @service_id1
					AND ((mode_id % 1000 = 0) OR (source_id % 1000 = 0)))
		BEGIN
			RAISERROR ('Нет режима потребления или поставщика!(Лицевой: %d %s)', 16, 1, @occ1, @address)
			RETURN -1
		END
		
			INSERT INTO dbo.Counter_list_all
			(fin_id
			,occ
			,counter_id
			,service_id
			,occ_counter
			,internal)
			VALUES (@fin_id1
				   ,@occ1
				   ,@id1
				   ,@service_id1
				   ,dbo.Fun_GetService_Occ(@occ1, @service_id1)
				   ,@internal)
			IF @@rowcount > 0
				SET @res_add = 1

			IF @fin_id1 = @fin_current
			BEGIN
				UPDATE dbo.Consmodes_list WITH (ROWLOCK)
				SET is_counter  =
						CASE
							WHEN @internal = 1 THEN 2
							ELSE 1
						END
				   ,subsid_only =
						CASE
							WHEN @internal = 1 THEN 0 --  убираем признак внешней услуги
							ELSE subsid_only
						END
				WHERE occ = @occ1
				AND service_id = @service_id1
			END
			ELSE
			BEGIN
				UPDATE ph
				SET is_counter  =
						CASE
							WHEN @internal = 1 THEN 1
							ELSE 0
						END
				FROM dbo.Paym_history AS ph				
				WHERE ph.occ = @occ1
					AND ph.fin_id = @fin_id1
					AND ph.service_id = @service_id1

			END

			-- сохраняем в историю изменений
			DECLARE @str1 VARCHAR(100)
			SET @str1 = CONCAT('Счетчик: ',@serial_number1,', Добавили лицевой: ',@occ1,', период: ', dbo.Fun_NameFinPeriod(@fin_id1))
			EXEC k_counter_write_log @id1
									,'счре'
									,@str1;

		FETCH NEXT FROM curs INTO @occ1, @address
	END
	CLOSE curs
	DEALLOCATE curs

	IF @trancount = 0
		COMMIT TRANSACTION;
	--===============================================================
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
			ROLLBACK TRANSACTION k_counter_add2;

		DECLARE @strerror VARCHAR(4000) = ''
		EXECUTE k_GetErrorInfo @visible = 0
							  ,@strerror = @strerror OUT
		RAISERROR (@strerror, 16, 1)

	END CATCH
go

