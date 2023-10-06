CREATE   PROCEDURE [dbo].[adm_services_add]
(
	  @id1 VARCHAR(10)
	, @name1 VARCHAR(100)
	, @short_name1 VARCHAR(20)
	, @service_type1 INT = 1
	, @is_koef1 BIT = 0
	, @is_subsid1 BIT = 1
	, @is_norma1 BIT = 1
	, @is_counter1 BIT = 0
	, @sort_no1 INT = 0
	, @debug BIT = 0
	, @num_colon1 SMALLINT = 1 -- номер колонки в квитанции
	, @is_paym1 BIT = 1 -- начислять на услугу
	, @is_peny1 BIT = 1 -- расчёт пени на услугу
	, @serv_from VARCHAR(100) = NULL
	, @is_build1 BIT = 0 -- для общедомовых нужд (используется совместно с serv_from)
	, @sort_paym SMALLINT = 0
	, @is_koef_up BIT = 0
	, @no_export_volume_gis BIT = 0
	, @unit_id_default VARCHAR(10) = NULL
)
AS
	/*
	добавление новой услуги
	Пузанов М.А. 
	
	================================================
	5.10.09
	Пузанов М.А. 
	Убрал добавление в PAYM_LIST
	оптимизировал добавление в CONSMODES_LIST
	добавил обработку ошибок BEGIN TRY ..
	================================================
	
	dbo.adm_add_services 'ремт', 'Ремонт жилья','Ремонт'
	*/
	SET NOCOUNT ON
	SET XACT_ABORT ON

	SELECT @id1 = LTRIM(RTRIM(@id1))

	IF LEN(@id1) < 4
	BEGIN
		RAISERROR ('Код услуги не должен быть меньше 4 знаков', 16, 1)
	END

	SELECT @name1 = LTRIM(RTRIM(@name1))
		 , @short_name1 = LTRIM(RTRIM(@short_name1))

	IF (@name1 = '')
		OR (@short_name1 = '')
	BEGIN
		RAISERROR ('Ошибка! Заполните наименование услуги!', 16, 1)
	END

	IF @is_build1 = 1
		AND @serv_from = ''
	BEGIN
		RAISERROR ('Если услуга общедомовая - заведите услугу от которой она зависит!', 16, 1)
		RETURN 1
	END

	DECLARE @err INT
		  , @occ1 INT
		  , @service_no1 INT

	BEGIN TRY

		BEGIN TRAN

		SELECT @service_no1 = MAX(service_no) + 1
		FROM dbo.Services --08.04.2005 

		IF @debug = 1
			PRINT 'Добавляем услугу'

		INSERT INTO dbo.Services WITH (ROWLOCK)
			(id
		   , name
		   , short_name
		   , service_no
		   , service_type
		   , is_koef
		   , is_subsid
		   , is_norma
		   , is_counter
		   , sort_no
		   , num_colon
		   , is_paym
		   , is_peny
		   , serv_from
		   , is_build
		   , is_build_serv
		   , sort_paym
		   , is_koef_up
		   , no_export_volume_gis
		   , unit_id_default)
			VALUES (@id1
				  , @name1
				  , @short_name1
				  , @service_no1
				  , @service_type1
				  , @is_koef1
				  , @is_subsid1
				  , @is_norma1
				  , @is_counter1
				  , @sort_no1
				  , @num_colon1
				  , @is_paym1
				  , @is_peny1
				  , @serv_from
				  , @is_build1
				  , @serv_from
				  , COALESCE(@sort_paym, 0)
				  , @is_koef_up
				  , @no_export_volume_gis
				  , @unit_id_default)

		UPDATE dbo.Services
		SET sort_no = service_no
		WHERE id = @id1
			AND sort_no = 0

		IF @debug = 1
			SELECT *
			FROM dbo.Services

		IF @debug = 1
			PRINT 'Добавляем Режим потребления "Нет"'

		EXEC @err = dbo.adm_addmodes @service_id1 = @id1
								   , @name1 = 'Нет'
								   , @debug = @debug
		IF @err <> 0
		BEGIN
			ROLLBACK TRAN
			RAISERROR ('Ошибка добавления режима у новой услуги', 16, 1)
			RETURN @err
		END
		IF @debug = 1
			PRINT 'добавили Режим потребления'

		DECLARE @sup_id INT
		SELECT @sup_id = id
		FROM dbo.Suppliers_all
		WHERE name = 'Нет'
		IF @debug = 1
			PRINT @sup_id

		IF @debug = 1
			PRINT 'добавляем SUPPLIERS по услуге'
		INSERT INTO dbo.Suppliers
			(service_id
		   , sup_id)
			VALUES (@id1
				  , @sup_id)
		IF @debug = 1
			PRINT 'добавили SUPPLIERS по услуге'

		IF @debug = 1
			SELECT *
			FROM dbo.Suppliers
			WHERE service_id = @id1;


		IF @debug = 1
			PRINT 'Добавляем Режим потребления и Поставщика "Нет" в дома'

		DECLARE @build1 INT
			  , @mode_id1 INT
			  , @source_id1 INT

		SELECT @mode_id1 = id
		FROM dbo.Cons_modes
		WHERE service_id = @id1
			AND (id % 1000) = 0

		IF @debug = 1
			SELECT id AS mode_id1
			FROM dbo.Cons_modes
			WHERE service_id = @id1
				AND (id % 1000) = 0;

		SELECT @source_id1 = id
		FROM dbo.View_suppliers
		WHERE service_id = @id1
			AND (id % 1000) = 0;

		IF @debug = 1
			SELECT id AS source_id1
			FROM dbo.View_suppliers
			WHERE service_id = @id1
				AND (id % 1000) = 0

		IF @debug = 1
			PRINT 'Код услуги поставщика: ' + STR(@source_id1)


		DECLARE curs1 CURSOR FOR
			SELECT id
			FROM dbo.Buildings 
		OPEN curs1
		FETCH NEXT FROM curs1 INTO @build1

		WHILE (@@fetch_status = 0)
		BEGIN
			IF NOT EXISTS (
					SELECT *
					FROM dbo.Build_mode
					WHERE service_id = @id1
						AND build_id = @build1
				)
			BEGIN
				INSERT INTO dbo.Build_mode
					(build_id
				   , service_id
				   , mode_id)
					VALUES (@build1
						  , @id1
						  , @mode_id1)

			END

			IF NOT EXISTS (
					SELECT *
					FROM dbo.Build_source
					WHERE service_id = @id1
						AND build_id = @build1
				)
			BEGIN
				INSERT INTO dbo.Build_source
					(build_id
				   , service_id
				   , source_id)
					VALUES (@build1
						  , @id1
						  , @source_id1)
			END

			IF @debug = 1
				PRINT ' Дом: ' + STR(@build1)

			FETCH NEXT FROM curs1 INTO @build1
		END

		CLOSE curs1
		DEALLOCATE curs1

		IF @debug = 1
			PRINT 'Услуга добавлена!'

		COMMIT TRAN

	END TRY
	BEGIN CATCH

		EXEC dbo.k_err_messages

	END CATCH
go

