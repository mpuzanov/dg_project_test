CREATE   PROCEDURE [dbo].[k_new_schtl_lite]
--
--   Процедура добавления лицевого счета
--
(
	@flat_id1	  INT -- код квартиры
   ,@total_sq1	  DECIMAL(10, 4) -- общая площадь
   ,@roomtype_id1 VARCHAR(10)
   ,@proptype_id1 VARCHAR(10)
   ,@occ_out	  INT OUT -- возвращаем лицевой счет <>0 если успешно добавили
   ,@debug BIT = NULL
)
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE @comments VARCHAR(50)   = NULL
		   ,@db_name  NVARCHAR(128) = DB_NAME()


	SELECT
		@occ_out = 0

	DECLARE @occ1	   INT -- лицевой счет
		   ,@build_id1 INT -- код дома
		   ,@jeu1	   SMALLINT -- участок
		   ,@tip_id1   SMALLINT -- тип жилого фонда
		   ,@err_str   VARCHAR(400)
		   ,@rang_max  INT = 0
		   ,@strjeu	   VARCHAR(3)
		   ,@strschtl  VARCHAR(6)
		   ,@i		   INT
		   ,@build_id2 INT -- код дома у шаблона лицевого
		   ,@fin_id SMALLINT

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

		SELECT
			@build_id1 = b.id
		   ,@jeu1 = b.sector_id
		   ,@tip_id1 = b.tip_id
		   ,@fin_id = b.fin_current
		FROM dbo.FLATS AS f
		JOIN dbo.BUILDINGS AS b
			ON f.bldn_id = b.id
		WHERE f.id = @flat_id1
		
		if @debug=1
			SELECT @build_id1 as build_id1, @jeu1 as jeu1, @tip_id1 as tip_id1, @fin_id as fin_id
	
	DECLARE @trancount INT;
	SET @trancount = @@trancount;

	BEGIN TRY

		IF @trancount = 0
			BEGIN TRANSACTION
		ELSE
			SAVE TRANSACTION k_new_schtl_lite;

			-- Создаем единый код лицевого счета автоматически
			--EXEC @occ1 = dbo.k_occ_new @tip_id1 --dbo.k_occ_next
			EXEC dbo.k_occ_new @tip_id=@tip_id1
							  ,@occ_new = @occ1 OUTPUT
							  ,@rang_max = @rang_max OUTPUT
							  ,@debug = @debug
			if @debug=1
				SELECT @occ1 AS occ1

			IF COALESCE(@occ1,0) = 0
			BEGIN
				SET @err_str = 'Не удалось создать лицевой счёт! в типе фонда %d.' + CHAR(13)
				IF @rang_max = 0
					SET @err_str = @err_str + 'Закончился диапазон чисел для него!'

				RAISERROR (@err_str, 16, 1, @tip_id1)
				RETURN -1
			END

			IF EXISTS (SELECT
						1
					FROM dbo.OCCUPATIONS 
					WHERE occ = @occ1)
			BEGIN
				RAISERROR ('Лицевой: %d уже существует!', 16, 1, @occ1)
				RETURN 1
			END

			-- Добавляем в файл лицевых счетов
			INSERT dbo.OCCUPATIONS
			(occ
			,jeu
			,SCHTL
			,flat_id
			,tip_id
			,total_sq
			,roomtype_id
			,proptype_id
			,status_id
			,fin_id)
			VALUES (@occ1
				   ,@jeu1
				   ,NULL
				   ,@flat_id1
				   ,@tip_id1
				   ,@total_sq1
				   ,@roomtype_id1
				   ,@proptype_id1
				   ,'своб'
				   ,@fin_id)

			IF @@error != 0
			BEGIN
				RAISERROR ('Ошибка добавления нового лиц.счета!', 11, 1)
				RETURN 1
			END

			SET @occ_out = @occ1 -- успешно добавили
		--
		IF @trancount = 0
			COMMIT TRANSACTION;

		EXEC k_update_address @occ1=@occ1

		-- сохраняем в историю изменений	
		EXEC k_write_log @occ1 = @occ1
						,@oper1 = 'дблс'
						,@comments1 = @comments

	END TRY
	BEGIN CATCH
		DECLARE @strerror VARCHAR(4000)
			   ,@xstate	 INT;
		SELECT
		   @xstate = XACT_STATE();

		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @trancount = 0
			ROLLBACK
		IF @xstate = 1
			AND @trancount > 0
			ROLLBACK TRANSACTION k_new_schtl_lite;

		SET @strerror = CONCAT('Код квартиры: ', @flat_id1,', Адрес: ', dbo.Fun_GetAdresFlat(@flat_id1))

		EXECUTE k_GetErrorInfo @visible = 0
							  ,@strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1);
	END CATCH
go

