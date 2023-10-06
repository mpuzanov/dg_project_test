CREATE   PROCEDURE [dbo].[k_counter_value_del]
(
	@id1		 INT -- код удаляемого показателя
   ,@counter_id1 INT		   = NULL
   ,@result_add	 BIT		   = 0 OUTPUT
   ,@strerror	 VARCHAR(4000) = '' OUTPUT
   ,@is_raschet_counter BIT	   = 1 -- делать расчет по ПУ после удаления
)
AS
	/*
	 Удаление показателя по счетчику
	 удалять можно только начиная с последнего показания
	
	declare @result_add bit
	exec [k_counter_value_del] @id1=717175, @counter_id1=7135, @result_add=@result_add OUT
	select @result_add
	exec [k_counter_value_del] @id1=1490669, @counter_id1=94710
	
	18/04/06
	*/
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1);
		RETURN;
	END;
	
	SELECT @result_add=0
		,@is_raschet_counter=COALESCE(@is_raschet_counter,1)
		,@strerror=COALESCE(@strerror,'')

	DECLARE @trancount INT;
	SET @trancount = @@trancount;

	DECLARE @Str1				VARCHAR(100)
		   ,@occ1				INT
		   ,@serial_number1		VARCHAR(10)
		   ,@date1				VARCHAR(10)
		   ,@value1				VARCHAR(14)
		   ,@err				INT
		   ,@tip_value			TINYINT -- тип счетчика 
		   ,@date_Del1			SMALLDATETIME -- дата закрытия счетчика
		   ,@fin_id1			SMALLINT
		   ,@fin_current		SMALLINT
		   ,@flat_id1			INT
		   ,@internal			BIT
		   ,@tip_value1			TINYINT
		   ,@build_id1			INT
		   ,@is_raschet_kvart   BIT			= 1 -- расчёт квартплаты
		   ,@ProgramInput		VARCHAR(30) = dbo.fn_app_name()

	DECLARE @id_last1 INT; -- код последнего введенного показателя

	SELECT
		@date1 = CONVERT(VARCHAR(10), inspector_date, 104)
	   ,@value1 = dbo.FSTR(inspector_value,14,6)
	   ,@tip_value = tip_value
	   ,@fin_id1 = ci.fin_id
	   ,@serial_number1 = serial_number
	   ,@date_Del1 = date_del
	   ,@counter_id1 = c.id
	   ,@fin_current = b.fin_current
	   ,@flat_id1 = c.flat_id
	   ,@internal = c.internal
	   ,@tip_value1 = ci.tip_value
	   ,@build_id1 = c.build_id
	FROM dbo.Counter_inspector AS ci 
	JOIN dbo.Counters AS c 
		ON ci.counter_id = c.id
	JOIN dbo.Buildings AS b 
		ON c.build_id = b.id
	JOIN dbo.Occupation_types AS ot 
		ON b.tip_id = ot.id
	WHERE ci.id = @id1;

	IF @date_Del1 IS NOT NULL
	BEGIN
		RAISERROR ('Счетчик закрыт! Изменять нельзя!', 16, 1);
		RETURN;
	END;

	IF SUSER_NAME() <> 'muser'
		IF dbo.Fun_AccessCounterLic(@build_id1) = 0
		BEGIN
			RAISERROR ('Для Вас работа со счетчиками запрещена!', 16, 1);
			RETURN;
		END;

	BEGIN TRY

		IF EXISTS (SELECT
					1
				FROM dbo.Counter_inspector 
				WHERE counter_id = @counter_id1
				AND id > @id1
				AND fin_id = @fin_id1
				AND @fin_id1 < @fin_current  -- ограничение не с первого только в прошедших периодах
				AND tip_value = @tip_value) -- 18/04/06  только среди своего типа
		BEGIN
			RAISERROR ('Удалять можно только начиная с последнего показания', 16, 1);
			RETURN;
		END;


		IF @trancount = 0
			BEGIN TRANSACTION
		ELSE
			SAVE TRANSACTION k_counter_value_del;

		DELETE FROM dbo.Counter_paym 
		WHERE fin_id = @fin_id1
			AND counter_id = @counter_id1
			AND kod_insp = @id1

		IF NOT EXISTS(SELECT 1 FROM dbo.Counter_inspector WHERE id = @id1)
			SET @strerror = CONCAT('код показания: ', @id1,' не найден')
		ELSE
			BEGIN
				DELETE FROM dbo.Counter_inspector
				WHERE id = @id1;
				IF @@rowcount > 0
					SET @result_add = 1
			END
			
		IF @trancount = 0
			COMMIT TRANSACTION;

		IF @ProgramInput IN ('Показания.exe', 'VvodPPU.exe')
			OR SUSER_NAME() = 'muser'
			SELECT
				@is_raschet_kvart = 0
			   ,@is_raschet_counter = 0

		IF @result_add = 1
		BEGIN
			-- сохраняем в историю изменений
			SET @Str1 = '№ ' + @serial_number1 + ' от:' + @date1 + ' знач: ' + @value1 + '. Фин.период:' + dbo.Fun_NameFinPeriod(@fin_id1);
			EXEC dbo.k_counter_write_log @counter_id1 = @counter_id1
										,@oper1 = 'счуп'
										,@comments1 = @Str1;

			IF @is_raschet_counter = 1
			BEGIN
				-- Делаем перерасчет по счётчикам
				IF @internal = 0
					EXEC dbo.k_counter_raschet_flats @flat_id1 = @flat_id1
													,@tip_value1 = @tip_value1
													,@debug = 0;
				ELSE
					EXEC dbo.k_counter_raschet_flats2 @flat_id1 = @flat_id1
													 ,@tip_value1 = 1
													 ,@debug = 0;

				-- делаем расчёт квартплаты в квартире
				IF @is_raschet_kvart = 1
					EXEC k_raschet_flat @flat_id1;
			END;
		END;

	END TRY
	BEGIN CATCH
		DECLARE @message VARCHAR(4000)
			   ,@xstate	 INT;
		SELECT
			@message = ERROR_MESSAGE()
		   ,@xstate = XACT_STATE();
		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @trancount = 0
			ROLLBACK
		IF @xstate = 1
			AND @trancount > 0
			ROLLBACK TRANSACTION k_counter_value_del;

		SET @strerror = CONCAT('Код квартиры: ', @flat_id1,', Адрес: ', dbo.Fun_GetAdresFlat(@flat_id1))

		EXECUTE k_GetErrorInfo @visible = 0
							  ,@strerror = @strerror OUT
		RAISERROR (@strerror, 16, 1);

	END CATCH
go

