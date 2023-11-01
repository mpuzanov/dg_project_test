CREATE   PROCEDURE [dbo].[k_people_delete]
(
	  @owner_id1 INT
	, @MarkDel BIT -- Выписать человека или удалить из тек.фин.периода
	, @KraiNew VARCHAR(50) = NULL -- Край, республика
	, @RaionNew VARCHAR(30) = NULL -- Район
	, @TownNew VARCHAR(30) = NULL --  Город, пгт
	, @VillageNew VARCHAR(30) = NULL -- Село, деревня
	, @StreetNew VARCHAR(30) = NULL -- Улица
	, @Nom_DomNew VARCHAR(12) = NULL -- Новый дом
	, @Nom_kvrNew VARCHAR(20) = NULL -- Новая кваритра
	, @Reason SMALLINT = 0 -- Код причины выписки
	, @DateDel1 SMALLDATETIME = NULL -- Дата выписки
	, @DateDeath1 SMALLDATETIME = NULL-- Дата смерти
	, @is_job BIT = 0 -- не проверять права доступа
	, @comments_log VARCHAR(100) = NULL
)
AS
	-- Процедура удаления человека

	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	SET QUOTED_IDENTIFIER ON

	IF COALESCE(@is_job, 0) = 0
		IF NOT EXISTS (SELECT 1 FROM dbo.AccessAddPeople)
		BEGIN
			RAISERROR ('У вас нет прав прописки-выписки граждан', 16, 1)
			RETURN
		END

	DECLARE @tran_count INT
		  , @tran_name VARCHAR(50) = 'k_people_delete'
	SET @tran_count = @@trancount;

	DECLARE @Fam_id1 VARCHAR(10) -- Родств. отношения удаляемого человека
		  , @occ1 INT
		  , @err INT
		  , @KolP SMALLINT
		  , @DateReg1 SMALLDATETIME
		  , @DateDelFin SMALLDATETIME -- последнее число предыдущего фин.периода
		  , @lgota_id1 SMALLINT
		  , @Initials VARCHAR(30)
		  , @msg VARCHAR(50)
		  , @strerror VARCHAR(4000)

	IF @DateDel1 IS NULL
		SET @DateDel1 = current_timestamp
	IF (@DateDeath1 IS NOT NULL)
		AND (@DateDeath1 > current_timestamp)
	BEGIN
		SET @strerror = CONCAT(N'Дата смерти(', CONVERT(VARCHAR(10), @DateDeath1, 104),') не должна быть больше текущей(', CONVERT(VARCHAR(10), current_timestamp, 104),')')		
		RAISERROR (@strerror, 16, 1)
	END

	SELECT @occ1 = Occ
		 , @DateReg1 = DateReg
		 , @lgota_id1 = lgota_id
		 , @Initials = CONCAT(RTRIM(Last_name),' ',LEFT(First_name,1),'. ',LEFT(Second_name,1),'.')
	FROM dbo.People 
	WHERE id = @owner_id1
	IF dbo.Fun_GetRejimOcc(@occ1) <> N'норм'
	BEGIN
		RAISERROR (N'База закрыта для редактирования!', 16, 1)
	END

	BEGIN TRY

		SELECT @KolP = COUNT(id)
		FROM dbo.People
		WHERE Occ = @occ1
			AND Del = 0

		IF (@Fam_id1 = N'отвл')
			AND (@KolP > 1)
		BEGIN
			RAISERROR (N'Нельзя выписать ответственное лицо если на л/сч есть ещё люди!', 16, 1)
		END

		IF @DateReg1 IS NULL
			SELECT @DateReg1 = CONVERT(SMALLDATETIME, '19000101')

		IF (@DateDel1 < @DateReg1)
			AND (@MarkDel = 1)
		BEGIN
			SET @strerror =
			CONCAT(N'Нельзя выписать человека! Так как Дата выписки(',CONVERT(VARCHAR(10), @DateReg1, 104),') ранее Даты регистрации(',CONVERT(VARCHAR(10), @DateDel1, 104),')')			
			RAISERROR (@strerror, 16, 1)
		END

		DECLARE @fin_current SMALLINT = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

		SELECT @DateDelFin = DATEADD(DAY, -1, start_date)
		FROM dbo.Global_values
		WHERE fin_id = @fin_current

		--- Начинаем транзакцию
		IF @tran_count = 0
			BEGIN TRANSACTION
		ELSE
			SAVE TRANSACTION @tran_name;

		IF @MarkDel = 1 -- Помечаем запись как удаленную для истории
		BEGIN
			UPDATE dbo.People 
			SET Del = 1
			  , DateDel = @DateDel1
			  , date_del_fact = current_timestamp
			  , DateDeath = CAST(@DateDeath1 AS DATE)
			  , Reason_extract = @Reason
			  , DateEnd =
						 CASE
							 WHEN DateEnd IS NOT NULL AND
								 @DateDel1 < DateEnd THEN @DateDel1
							 ELSE DateEnd
						 END
			WHERE id = @owner_id1


			MERGE dbo.People_2 AS target USING (
				SELECT @owner_id1
					 , @KraiNew
					 , @RaionNew
					 , @TownNew
					 , @VillageNew
					 , @StreetNew
					 , @Nom_DomNew
					 , @Nom_kvrNew
			) AS source
			(owner_id, KraiNew, RaionNew, TownNew, VillageNew, StreetNew, Nom_DomNew, Nom_kvrNew)
			ON (target.owner_id = source.owner_id)
			WHEN MATCHED
				THEN UPDATE
					SET KraiNew = source.KraiNew
					  , RaionNew = source.RaionNew
					  , TownNew = source.TownNew
					  , VillageNew = source.VillageNew
					  , StreetNew = source.StreetNew
					  , Nom_DomNew = source.Nom_DomNew
					  , Nom_kvrNew = source.Nom_kvrNew
			WHEN NOT MATCHED
				THEN INSERT
						(owner_id
					   , KraiNew
					   , RaionNew
					   , TownNew
					   , VillageNew
					   , StreetNew
					   , Nom_DomNew
					   , Nom_kvrNew)
						VALUES (source.owner_id
							  , source.KraiNew
							  , source.RaionNew
							  , source.TownNew
							  , source.VillageNew
							  , source.StreetNew
							  , source.Nom_DomNew
							  , source.Nom_kvrNew);

			IF @lgota_id1 <> 0
			BEGIN
				-- заносим льготу в историю
				DECLARE @id1 INT
				SELECT @id1 = id
				FROM dbo.Dsc_owners
				WHERE owner_id = @owner_id1
					AND active = 1

				IF @id1 IS NOT NULL
					EXEC dbo.k_dsc_delete @id1
			END
			-- сохраняем в историю изменений
			SET @msg = RTRIM(@Initials + N' (Код:' + LTRIM(STR(@owner_id1)) + ') ' + COALESCE(@comments_log,''))
			EXEC dbo.k_write_log @occ1 = @occ1
						   , @oper1 = N'удчл'
						   , @comments1 = @msg

		END
		ELSE
		BEGIN
			IF EXISTS (
					SELECT 1
					FROM dbo.People_history
					WHERE owner_id = @owner_id1
				)
			BEGIN
				-- Если человек есть в истории
				UPDATE dbo.People -- удаляем из этого фин.периода
				SET Del = 1
				  , DateDel = @DateDelFin
				WHERE id = @owner_id1

				-- сохраняем в историю изменений
				SET @msg = RTRIM(@Initials + ' ' + COALESCE(@comments_log,''))
				EXEC dbo.k_write_log @occ1 = @occ1
							   , @oper1 = N'удч2'
							   , @comments1 = @msg
			END
			ELSE -- Удаляем на всегда
			BEGIN
				DELETE FROM dbo.People 
				WHERE id = @owner_id1

				SET @msg = RTRIM(@Initials + N' - без истории ' + COALESCE(@comments_log,''))
				EXEC dbo.k_write_log @occ1 = @occ1
							   , @oper1 = N'удч2'
							   , @comments1 = @msg
			END

			-- удаляем документы(паспорт) если есть
			DELETE FROM dbo.Iddoc 
			WHERE owner_id = @owner_id1

		END


		IF @tran_count = 0
			COMMIT TRANSACTION;

		EXEC k_occ_status @occ1

	END TRY
	BEGIN CATCH
		DECLARE @xstate INT;
		SELECT @xstate = XACT_STATE();
		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @tran_count = 0
			ROLLBACK;
		IF @xstate = 1
			AND @tran_count > 0
			ROLLBACK TRANSACTION @tran_name;

		EXECUTE k_GetErrorInfo @visible = 0
							 , @strerror = @strerror OUT
		RAISERROR (@strerror, 16, 1)

	END CATCH
go

