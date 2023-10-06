CREATE   PROCEDURE [dbo].[k_new_schtl]
(
	  @flat_id1 INT -- код квартиры
	, @total_sq1 DECIMAL(10, 4) -- общая площадь
	, @roomtype_id1 VARCHAR(10)
	, @propertytype_id1 VARCHAR(10)
	, @schtl VARCHAR(15) = NULL -- отдельный(старый) лицевой счет
	, @occ2 INT = 0 -- лицевой-шаблон   из него берем режимы потребления и поставщиков
	, @occ3 INT OUT -- возвращаем лицевой счет <>0 если успешно добавили
	, @occ_new INT = NULL -- Пытаемся создать в начале этот лицевой счёт
)
AS
/*
Процедура добавления лицевого счета
*/
	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE @comments VARCHAR(50) = NULL
		  , @db_name NVARCHAR(128)
		  , @occ1 INT -- лицевой счет
		  , @build_id1 INT -- код дома
		  , @jeu1 SMALLINT -- участок
		  , @tip_id1 SMALLINT -- тип жилого фонда
		  , @err_str VARCHAR(400)
		  , @rang_max INT = 0
		  , @build_id2 INT -- код дома у шаблона лицевого
		  , @payms_value BIT
		  , @fin_id SMALLINT


	IF @occ_new = 0
		SET @occ_new = NULL
	IF @occ_new IS NOT NULL
		SET @comments = N'л/сч задавался пользователем'

	SELECT @db_name = DB_NAME()
		 , @occ3 = 0

	IF dbo.Fun_GetRejim() <> N'норм'
	BEGIN
		RAISERROR (N'База закрыта для редактирования!', 16, 1)
	END

	BEGIN TRY

		SELECT @build_id1 = b.id
			 , @jeu1 = b.sector_id
			 , @tip_id1 = b.tip_id
			 , @payms_value = ot.payms_value
			 , @fin_id = b.fin_current
		FROM dbo.Flats AS f 
			JOIN dbo.Buildings AS b  ON f.bldn_id = b.id
			JOIN dbo.Occupation_Types ot  ON b.tip_id = ot.id
		WHERE f.id = @flat_id1

		-- Проверяем шаблон
		-- Он должен быть из этого дома
		IF @occ2 > 0
		BEGIN
			SELECT @build_id2 = f.bldn_id
			FROM dbo.Occupations AS o 
				JOIN dbo.Flats AS f ON o.flat_id = f.id
			WHERE o.occ = @occ2

			IF @build_id1 <> @build_id2
			BEGIN
				RAISERROR (N'Лицевой шаблон %d не пренадлежит этому дому!', 16, 1, @occ2)
			END

		END
		--else 
		--BEGIN
		--	RAISERROR ('Введите лицевой счёт с которого взять услуги и режимы!',16,1,@occ2)
		--	RETURN 1
		--END

		---- @schtl -  старый лицевой нужен для внешних субсидий субсидий
		--IF (@schtl IS NOT NULL)
		--	AND (@schtl > 0)
		--	AND EXISTS (
		--		SELECT 1
		--		FROM dbo.Occupations
		--		WHERE jeu = @jeu1
		--			AND SCHTL = @schtl
		--	)
		--BEGIN
		--	RAISERROR ('Участок: %d и лицевой: %d уже существуют!', 16, 1, @jeu1, @schtl)
		--	RETURN 1
		--END

		IF @payms_value = 1
			AND NOT EXISTS (
				SELECT 1
				FROM dbo.Build_mode AS bm 
				WHERE bm.build_id = @build_id1
			)
		BEGIN
			RAISERROR (N'Задайте сначала список услуг с режимами на доме в "Администраторе"', 16, 1)
		END

		BEGIN TRAN

		IF @occ_new IS NULL
		BEGIN
			-- Создаем единый код лицевого счета автоматически
			--EXEC @occ1 = dbo.k_occ_new @tip_id1 --dbo.k_occ_next
			EXEC dbo.k_occ_new @tip_id = @tip_id1
							 , @occ_new = @occ1 OUTPUT
							 , @rang_max = @rang_max OUTPUT

			IF (@occ1 IS NULL)
				OR @occ1 = 0
			BEGIN
				ROLLBACK TRAN
				SET @err_str = N'Не удалось создать лицевой счёт! в типе фонда %d.' + CHAR(13)

				IF @rang_max = 0
					SET @err_str = @err_str + N'Закончился диапазон чисел для него!'
				RAISERROR (@err_str, 16, 1, @tip_id1)
			END

		END

		ELSE -- Будем пытаться создать заданный
			SET @occ1 = @occ_new

		IF EXISTS (
				SELECT 1
				FROM dbo.Occupations 
				WHERE occ = @occ1
			)
		BEGIN
			ROLLBACK TRAN
			RAISERROR (N'Лицевой: %d уже существует!', 16, 1, @occ1)
		END

		-- Добавляем в файл лицевых счетов
		INSERT dbo.Occupations
			(occ
		   , jeu
		   , SCHTL
		   , flat_id
		   , tip_id
		   , total_sq
		   , roomtype_id
		   , proptype_id
		   , status_id
		   , schtl_old
		   , fin_id)
			VALUES (@occ1
				  , @jeu1
				  , TRY_CONVERT(INT, @schtl)
				  , @flat_id1
				  , @tip_id1
				  , @total_sq1
				  , @roomtype_id1
				  , @propertytype_id1
				  , N'своб'
				  , @schtl
				  , @fin_id)

		IF @@error != 0
		BEGIN
			ROLLBACK TRAN
			RAISERROR (N'Ошибка добавления нового лиц.счета!', 11, 1)
		END

		DELETE FROM dbo.Consmodes_list
		WHERE occ = @occ1

		IF @occ2 > 0
			-- Добавляем записи в файл режимов потребления CONSMODES_LIST
			INSERT dbo.Consmodes_list
				(occ
			   , service_id
			   , sup_id
			   , mode_id
			   , source_id
			   , account_one
			   , fin_id)
			SELECT @occ1
				 , service_id
				 , sup_id
				 , mode_id
				 , source_id
				 , 0
				 , @fin_id
			FROM dbo.Consmodes_list 
			WHERE occ = @occ2
		ELSE
			-- берём услуги с дома
			INSERT dbo.Consmodes_list
				(occ
			   , service_id
			   , sup_id
			   , mode_id
			   , source_id
			   , account_one
			   , fin_id)
			SELECT DISTINCT @occ1
						  , bm.service_id
						  , sup_id = 0
						  , mode_id = (
								SELECT TOP (1) mode_id
								FROM dbo.Build_mode AS bm2 
								WHERE bm.build_id = bm2.build_id
									AND bm.service_id = bm2.service_id
								ORDER BY mode_id -- Нет (минимум)
								--ORDER BY mode_id DESC -- с макс значением
							)
						  , source_id = (
								SELECT TOP (1) source_id
								FROM dbo.Build_source AS bs2 
								WHERE bm.build_id = bs2.build_id
									AND bm.service_id = bs2.service_id
								ORDER BY source_id -- Нет (минимум)
								--ORDER BY source_id DESC -- с макс значением
							)
						  , 0
						  , @fin_id
			FROM dbo.Build_mode AS bm 
				JOIN dbo.Build_source AS bs ON bm.build_id = bs.build_id
					AND bm.service_id = bs.service_id
			WHERE bm.build_id = @build_id1

		SET @occ3 = @occ1 -- успешно добавили
		--
		COMMIT TRAN

		EXEC k_update_address @occ1 = @occ1

		-- сохраняем в историю изменений	
		EXEC k_write_log @occ1 = @occ1
					   , @oper1 = N'дблс'
					   , @comments1 = @comments
	END TRY
	BEGIN CATCH
		EXEC dbo.k_err_messages
	END CATCH
go

