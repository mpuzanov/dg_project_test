CREATE   PROCEDURE [dbo].[adm_addrates_counter]
(
	@Fin_id1	 SMALLINT -- фин.период
   ,@tipe_id1	 SMALLINT -- тип жилого фонда
   ,@service_id1 VARCHAR(10) -- код услуги
   ,@unit_id1	 VARCHAR(10) -- Единица измерения
   ,@t1			 DECIMAL(10, 4) = 0 -- обычный тариф (tarif)
   ,@source_id1	 INT		= NULL -- Поставщик
   ,@mode_id1	 INT		= NULL -- Режим потребления
   ,@t2			 DECIMAL(10, 4) = 0 -- сверхнормативный тариф
   ,@t3			 DECIMAL(10, 4) = 0 -- 100% тариф
)
AS
	/*
	   Изменяем тарифы по счетчикам
	   
	   exec dbo.adm_addrates_counter @Fin_id1=@Fin_id1, @tipe_id1=@tipe_id1,@service_id1=@service_id1,@unit_id1=@unit_id1,@t1=@t1,@source_id1=@source_id1,@mode_id1=@mode_id1
	*/
	SET NOCOUNT ON

	BEGIN TRY

		--IF @source_id1=0 SET @source_id1 = NULL
		--IF @mode_id1=0 SET @mode_id1 = NULL
		--******************************************************
		-- находим всех поставщиков по заданной услуге и другим параметрам
		-- делаем курсор по ним 
		-- и вызываем рекурсионно эту же процедуру
		IF (@source_id1 IS NULL)
			AND (@mode_id1 IS NOT NULL)
		BEGIN
			DECLARE curs1 CURSOR FOR
				SELECT
					id
				FROM View_SUPPLIERS 
				WHERE service_id = @service_id1
				AND (id % 1000) != 0
				UNION ALL
				SELECT
					0 AS id
			OPEN curs1
			FETCH NEXT FROM curs1 INTO @source_id1

			WHILE (@@fetch_status = 0)
			BEGIN
				--print '1 '+str(@source_id1) +' '+str(@mode_id1)+' '+str(@t1,9,4)

				EXEC adm_addrates_counter @Fin_id1
										 ,@tipe_id1
										 ,@service_id1
										 ,@unit_id1
										 ,@t1
										 ,@source_id1
										 ,@mode_id1
										 ,@t2
										 ,@t3

				FETCH NEXT FROM curs1 INTO @source_id1
			END

			CLOSE curs1
			DEALLOCATE curs1
		END

		--******************************************************
		-- находим все режимы по заданной услуге и другим параметрам
		-- делаем курсор по ним 
		-- и вызываем рекурсионно эту же процедуру
		IF (@mode_id1 IS NULL)
			AND (@source_id1 IS NOT NULL)
		BEGIN
			DECLARE curs2 CURSOR FOR
				SELECT
					id
				FROM CONS_MODES
				WHERE service_id = @service_id1
				AND (id % 1000) != 0
				UNION ALL
				SELECT
					0 AS id

			OPEN curs2
			FETCH NEXT FROM curs2 INTO @mode_id1

			WHILE (@@fetch_status = 0)
			BEGIN
				--print '2 '+str(@source_id1) +' '+str(@mode_id1)+' '+str(@t1,9,4)

				EXEC adm_addrates_counter @Fin_id1
										 ,@tipe_id1
										 ,@service_id1
										 ,@unit_id1
										 ,@t1
										 ,@source_id1
										 ,@mode_id1
										 ,@t2
										 ,@t3

				FETCH NEXT FROM curs2 INTO @mode_id1
			END

			CLOSE curs2
			DEALLOCATE curs2
		END
		--******************************************************
		-- каждого поставщика соединяем каждым режимом

		IF (@source_id1 IS NULL)
			AND (@mode_id1 IS NULL)
		BEGIN
			DECLARE curs3 CURSOR FOR
				SELECT
					source_id = s.id
				   ,mode_id = cm.id
				FROM (SELECT
						0 AS id
					   ,service_id
					FROM View_SUPPLIERS
					UNION
					SELECT
						id
					   ,service_id
					FROM View_SUPPLIERS) AS s
				JOIN (SELECT
						0 AS id
					   ,service_id
					FROM CONS_MODES
					UNION
					SELECT
						id
					   ,service_id
					FROM CONS_MODES) AS cm
					ON s.service_id = cm.service_id
				WHERE s.service_id = @service_id1
				AND ((s.id % 1000) != 0
				OR s.id = 0)
				AND ((cm.id % 1000) != 0
				OR cm.id = 0)
 
			OPEN curs3
			FETCH NEXT FROM curs3 INTO @source_id1, @mode_id1

			WHILE (@@fetch_status = 0)
			BEGIN
				--print '3 '+str(@source_id1) +' '+str(@mode_id1)+' '+str(@t1,9,4)

				IF (@source_id1 <> 0
					OR @mode_id1 <> 0)
					EXEC adm_addrates_counter @Fin_id1
											 ,@tipe_id1
											 ,@service_id1
											 ,@unit_id1
											 ,@t1
											 ,@source_id1
											 ,@mode_id1
											 ,@t2
											 ,@t3
				--else print 'пропустили'

				FETCH NEXT FROM curs3 INTO @source_id1, @mode_id1
			END

			CLOSE curs3
			DEALLOCATE curs3
		END
		--******************************************************

		DECLARE @user_edit SMALLINT = dbo.Fun_GetCurrentUserId()

		-- у режима Нет или поставщика Нет - тариф не ставим
		IF (@mode_id1 % 1000) = 0 OR (@source_id1 % 1000) = 0			
			RETURN

		IF EXISTS (SELECT
					1
				FROM RATES_COUNTER
				WHERE 
					fin_id = @Fin_id1
					AND tipe_id = @tipe_id1
					AND service_id = @service_id1
					AND unit_id = @unit_id1
					AND source_id = @source_id1
					AND mode_id = @mode_id1)
		BEGIN
			--print 'update'
			--print @t1
			--print @source_id1
			--print @mode_id1
			UPDATE dbo.Rates_counter 
			SET tarif	  = @t1
				, extr_tarif = @t2
			    , full_tarif = @t3
			    , user_edit = @user_edit
			WHERE 
				fin_id = @Fin_id1
				AND tipe_id = @tipe_id1
				AND service_id = @service_id1
				AND unit_id = @unit_id1
				AND source_id = @source_id1
				AND mode_id = @mode_id1
		END
		ELSE
		BEGIN
			--print 'insert'
			INSERT INTO dbo.Rates_counter
			(fin_id
			,tipe_id
			,service_id
			,unit_id
			,tarif
			,source_id
			,mode_id
			,user_edit
			,extr_tarif
			,full_tarif)
			VALUES (@Fin_id1
				   ,@tipe_id1
				   ,@service_id1
				   ,@unit_id1
				   ,@t1
				   ,@source_id1
				   ,@mode_id1
				   ,@user_edit
				   ,@t2
				   ,@t3)

		END

	END TRY
	BEGIN CATCH
		EXEC k_err_messages
	END CATCH
go

