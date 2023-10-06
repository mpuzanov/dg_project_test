-- =============================================
-- Author:		Пузанов
-- Create date: 22.09.2011
-- Description:	Загрузка данных
-- =============================================
CREATE         PROCEDURE [dbo].[adm_load_occ_sup]
	  @tip_id SMALLINT
	, @occ_old INT = NULL  -- лицевой счет поставщика
	, @town_name VARCHAR(20) = NULL
	, @street_name VARCHAR(50)
	, @nom_dom VARCHAR(12)
	, @nom_kvr VARCHAR(20) = '0'
	, @saldo DECIMAL(9, 2) = 0
	, @peny DECIMAL(9, 2) = 0
	, @dog_int INT
	, @add_adres BIT = 0
	, @occ_not_create BIT = 1 -- единые лицевые не создавать
	, @occ INT = NULL -- единый лицевой счёт
	, @schtl_old VARCHAR(15) = NULL -- старый лицевой счет поставщика
	, @debug BIT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @tip_old SMALLINT = NULL
		  , @mode_id INT
		  , @source_id INT
		  , @service_id1 VARCHAR(10)
		  , @occ_sup INT
		  , @occ_sup_str VARCHAR(9)
		  , @i INT = 0
		  , @y INT = 0
		  , @street_id INT
		  , @fin_current SMALLINT
		  , @build_id INT
		  , @town_id SMALLINT
		  , @sup_id INT = NULL
		  , @first_occ SMALLINT = NULL;  -- первые цифры в договоре(будут в новом лицевом)

	IF @occ_not_create IS NULL
		SET @occ_not_create = 1;

	IF @nom_kvr IS NULL
		SET @nom_kvr = '0';

	IF @saldo IS NULL
		SET @saldo = 0;

	SELECT TOP (1) @sup_id = sup_id
				 , @first_occ = first_occ
	FROM dbo.Dog_sup AS DS
	WHERE id = @dog_int;

	IF @sup_id IS NULL
	BEGIN
		RAISERROR ('Поставщика по договору %i нет!', 16, 1, @dog_int);
		RETURN -1;
	END;

	IF @town_name IS NOT NULL
		IF LTRIM(RTRIM(@town_name)) = ''
			SET @town_name = NULL;


	IF @town_name IS NOT NULL
	BEGIN
		SELECT TOP (1) @town_id = id
		FROM dbo.Towns T
		WHERE name = RTRIM(@town_name);
	END;
	ELSE
		SELECT @town_id = id
			 , @town_name = name
		FROM dbo.Towns AS T
		WHERE id = 1;

	IF @town_id IS NULL
	BEGIN
		RAISERROR ('Город: %s не найден в базе', 16, 1, @town_name);
		RETURN -1;
	END;

	SELECT TOP (1) @street_id = id
	FROM dbo.VStreets
	WHERE (name = @street_name)
		AND (town_id = @town_id)

	IF @street_id IS NULL
		SELECT TOP (1) @street_id = id
		FROM dbo.VStreets
		WHERE (name = @street_name OR short_name = @street_name)
			AND (town_id = @town_id)
		ORDER BY id


	IF @street_id IS NULL
	BEGIN
		RAISERROR ('Улица %s в городе %s не найдена в базе', 16, 1, @street_name, @town_name);
		RETURN -1;
	END;

	-- находим лицевой счёт
	SELECT TOP (1) @occ = occ
				 , @tip_old = b.tip_id
				 , @fin_current = b.fin_current
				 , @build_id = f.bldn_id
	FROM dbo.Occupations AS o
		JOIN dbo.Flats AS f ON o.flat_id = f.id
		JOIN dbo.Buildings AS b ON f.bldn_id = b.id
	WHERE street_id = @street_id
		AND b.nom_dom = @nom_dom
		AND f.nom_kvr = @nom_kvr
		AND b.tip_id = @tip_id
		AND b.town_id = @town_id
		AND o.occ = COALESCE(@occ, o.occ);

	IF @debug = 1
		PRINT 'Ед.лицевой: ' + STR(@occ);

	IF (@tip_old <> @tip_id)
		AND (@debug = 1)
	BEGIN
		PRINT '*************** Лицевой уже в другом типе фонда ****************************';
	END;

	IF @occ IS NULL
	BEGIN
		RAISERROR ('НЕ нашли лицевой по адресу: %s %s д.%s кв.%s', 16, 1, @town_name, @street_name, @nom_dom, @nom_kvr);
		RETURN -1;
	END;


	IF @occ_old IS NULL
	BEGIN
		-- Формируем лицевой поставщика
		DECLARE @str_first_occ VARCHAR(5)
			  , @len_end TINYINT;

		IF @first_occ IS NULL
		BEGIN
			RAISERROR ('НЕ могу создать лицевой поставщика! Нет префикса в договоре!', 16, 1);
			RETURN -1;
		END;

		SET @str_first_occ = LTRIM(RTRIM(STR(@first_occ)));
		SET @len_end = LEN(@str_first_occ);
		SET @len_end = 9 - @len_end;
		SELECT @occ_sup_str = @str_first_occ + dbo.Fun_AddLeftZero(STR(@occ), @len_end);
		PRINT @occ_sup_str;
		SELECT @occ_sup = CONVERT(INT, @occ_sup_str);
	END;
	ELSE
	BEGIN
		--SET @occ_sup=@occ_old

		SELECT TOP (1) @occ_sup = occ_sup
		FROM dbo.Occ_Suppliers
		WHERE occ = @occ
			AND sup_id = @sup_id
			AND fin_id = @fin_current
			AND occ_sup <> 0;

		IF @occ_sup IS NULL
			SET @occ_sup = @occ_old;

	END;

	-- Создаём лицевой поставщика
	EXEC dbo.k_occ_sup_new @occ = @occ
						 , @dog_int = @dog_int
						 , @occ_sup = @occ_sup
						 , @group_add = 1
						 , @saldo = @saldo
						 , @add_cessia = 0
						 , @dolg_mes_start = 0;

	IF NOT EXISTS (
			SELECT 1
			FROM dbo.Occ_Suppliers
			WHERE occ_sup = @occ_sup
		)
	BEGIN
		RAISERROR ('Лицевой счёт у поставщика не создался!', 16, 1);
		RETURN -1;
	END;

	UPDATE dbo.Occ_Suppliers
	SET saldo = @saldo
	  , Penalty_old = @peny
	  , Penalty_old_edit = 1
	  , schtl_old = COALESCE(@schtl_old, schtl_old)
	WHERE fin_id = @fin_current
		AND occ_sup = @occ_sup;

	UPDATE dbo.Occupations
	SET saldo_edit = 1
	WHERE occ = @occ;

	---- добавляем услуги по поставщику

	DECLARE cursor_name CURSOR FOR
		SELECT id AS source_id
			 , service_id
			 , ((
				   SELECT TOP (1) id
				   FROM dbo.Cons_modes AS cm
				   WHERE cm.service_id = S.service_id
					   AND id % 1000 <> 0
			   )   -- 30/03/2016
			   ) AS mode_id
		FROM dbo.Suppliers AS S
		WHERE sup_id = @sup_id;

	OPEN cursor_name;

	FETCH NEXT FROM cursor_name INTO @source_id, @service_id1, @mode_id;

	WHILE @@fetch_status = 0
	BEGIN

		IF EXISTS (
				SELECT 1
				FROM dbo.Paym_list
				WHERE occ = @occ
					AND service_id = @service_id1
			)
			UPDATE dbo.Paym_list
			SET saldo = @saldo
			  , account_one = 1
			WHERE occ = @occ
				AND service_id = @service_id1;
		ELSE
			INSERT INTO dbo.Paym_list (occ
									 , service_id
									 , saldo
									 , account_one
									 , fin_id)
			VALUES(@occ
				 , @service_id1
				 , @saldo
				 , 1
				 , @fin_current);

		-- добавляем режим потребления и поставщика на лицевой по услуге 
		IF EXISTS (
				SELECT 1
				FROM dbo.Consmodes_list
				WHERE occ = @occ
					AND service_id = @service_id1
			)
			UPDATE dbo.Consmodes_list
			SET mode_id = @mode_id
			  , source_id = @source_id
			  , account_one = 1
			  , sup_id = @sup_id
			WHERE occ = @occ
				AND service_id = @service_id1;
		ELSE
			INSERT INTO dbo.Consmodes_list (occ
										  , service_id
										  , mode_id
										  , source_id
										  , account_one
										  , sup_id
										  , fin_id)
			VALUES(@occ
				 , @service_id1
				 , @mode_id
				 , @source_id
				 , 1
				 , @sup_id
				 , @fin_current);

		-- Проверяем есть ли такой режим на доме
		IF NOT EXISTS (
				SELECT 1
				FROM dbo.Build_mode
				WHERE build_id = @build_id
					AND service_id = @service_id1
					AND mode_id = @mode_id
			)
			INSERT INTO dbo.Build_mode (build_id
									  , service_id
									  , mode_id)
			VALUES(@build_id
				 , @service_id1
				 , @mode_id);

		-- Проверяем есть ли такой поставщик на доме
		IF NOT EXISTS (
				SELECT 1
				FROM dbo.Build_source
				WHERE build_id = @build_id
					AND service_id = @service_id1
					AND source_id = @source_id
			)
			INSERT INTO dbo.Build_source (build_id
										, service_id
										, source_id)
			VALUES(@build_id
				 , @service_id1
				 , @source_id);


		FETCH NEXT FROM cursor_name INTO @source_id, @service_id1, @mode_id;

	END;

	CLOSE cursor_name;
	DEALLOCATE cursor_name;


END;
go

