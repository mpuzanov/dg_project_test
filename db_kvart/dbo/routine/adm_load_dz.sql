-- =============================================
-- Author:		Пузанов
-- Create date: 22.09.2011
-- Description:	Загрузка дебиторской задолженности (ЦЕССИИ
-- Лицевой, Улица, Дом, Квартира, Долг, Глубина, Фамилия, Имя, Отчество)
-- =============================================
CREATE       PROCEDURE [dbo].[adm_load_dz]
	  @tip_id SMALLINT
	, @occ_old INT = NULL
	, @town_name VARCHAR(20) = NULL
	, @street_name VARCHAR(50)
	, @nom_dom VARCHAR(7)
	, @nom_kvr VARCHAR(20) = '0'
	, @LAST_NAME VARCHAR(25) = NULL
	, @FIRST_NAME VARCHAR(20) = NULL
	, @SECOND_NAME VARCHAR(25) = NULL
	, @saldo DECIMAL(9, 2)
	, @KOL_MES SMALLINT
	, @dog_int INT
	, @add_adres BIT = 0
	, @occ_not_create BIT = 1
	, -- единые лицевые не создавать
	  @is_occ_old_ces BIT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON

	IF @is_occ_old_ces IS NULL
		SET @is_occ_old_ces = 0

	IF @is_occ_old_ces = 1
		AND @occ_old IS NULL
	BEGIN
		RAISERROR ('Лицевой счёт не заполнен!', 16, 1)
		RETURN -1
	END

	DECLARE @tip_old SMALLINT = NULL
		  , @mode_id INT = 46001
		  , @source_id INT = 46001
		  , @service_id1 VARCHAR(10) = 'цеся'
		  , @occ_sup INT
		  , @occ_sup_str VARCHAR(9)
		  , @i INT = 0
		  , @y INT = 0
		  , @OCC INT
		  , @street_id INT
		  , @fin_current SMALLINT
		  , @build_id INT
		  , @town_id SMALLINT
		  , @sup_id INT
		  , @err_str VARCHAR(400)
		  , @rang_max INT = 0


	IF @occ_not_create IS NULL
		SET @occ_not_create = 1

	IF @nom_kvr IS NULL
		SET @nom_kvr = '0'

	IF @saldo IS NULL
		SET @saldo = 0

	SELECT @sup_id = sup_id
	FROM dbo.Dog_sup AS DS 
	WHERE id = @dog_int

	IF @sup_id IS NULL
		SET @sup_id = 315 -- в базе kr1 "укс цессия"

	IF @town_name IS NOT NULL
		IF LTRIM(RTRIM(@town_name)) = ''
			SET @town_name = NULL

	IF @town_name IS NOT NULL
	BEGIN
		SELECT @town_id = id
		FROM dbo.Towns T 
		WHERE name = RTRIM(@town_name)
	END
	ELSE
		SELECT @town_id = id
			 , @town_name = name
		FROM dbo.Towns AS T 
		WHERE id = 1

	IF @town_id IS NULL
	BEGIN
		RAISERROR ('Населённый пункт: %s не найден!', 16, 1, @town_name)
		RETURN -1
	END

	-- проверяем улицу
	IF @add_adres = 1
		AND NOT EXISTS (
			SELECT *
			FROM dbo.Streets 
			WHERE name = @street_name
				AND COALESCE(town_id, 1) = @town_id
		)
	BEGIN --добавляем улицу
		SELECT @street_id = COALESCE(MAX(id), 0) + 1
		FROM dbo.Streets 

		INSERT INTO [dbo].[Streets] ([id]
								   , [name]
								   , town_id)
		VALUES(@street_id
			 , @street_name
			 , @town_id)

	END

	SELECT @street_id = id
	FROM dbo.Streets 
	WHERE name = LTRIM(RTRIM(@street_name))
		AND COALESCE(town_id, 1) = @town_id

	IF @street_id IS NULL
	BEGIN
		RAISERROR ('Улица %s в населённом пункте %s не найдена!', 16, 1, @street_name, @town_name)
		RETURN -1
	END

	-- находим лицевой счёт
	SELECT @OCC = occ
		 , @tip_old = b.tip_id
	FROM dbo.Occupations AS o 
		JOIN dbo.Flats AS f 
			ON o.flat_id = f.id
		JOIN dbo.Buildings AS b 
			ON f.bldn_id = b.id
	WHERE street_id = @street_id
		AND b.nom_dom = @nom_dom
		AND (f.nom_kvr = @nom_kvr OR f.nom_kvr = '-')
		AND
		   CASE
			   WHEN (o.occ = o.schtl) OR
				   o.schtl IS NULL THEN @occ_old
			   ELSE o.schtl
		   END = @occ_old
		AND b.tip_id = @tip_id
		AND COALESCE(town_id, 1) = @town_id

	--IF @OCC_OLD IS NULL OR @occ_not_create = 1
	IF @OCC IS NULL
		SELECT @OCC = occ
			 , @tip_old = b.tip_id
		FROM dbo.Occupations AS o 
			JOIN dbo.Flats AS f 
				ON o.flat_id = f.id
			JOIN dbo.Buildings AS b 
				ON f.bldn_id = b.id
		WHERE street_id = @street_id
			AND b.nom_dom = @nom_dom
			AND f.nom_kvr = @nom_kvr
			AND b.tip_id = @tip_id
			AND b.town_id = @town_id


	PRINT @OCC

	IF @tip_old <> @tip_id
	BEGIN
		PRINT '*************** Лицевой уже в другом типе фонда ****************************'
	END

	IF @OCC IS NULL
		AND @occ_not_create = 0
	BEGIN
		PRINT 'НЕ нашли лицевой по адресу: '
		PRINT '      ' + @town_name + ' ' + @street_name + ' ' + @nom_dom + ' ' + @nom_kvr

		-- Создаем единый код лицевого счета  
		--EXEC @occ = dbo.k_occ_new @tip_id
		EXEC dbo.k_occ_new @tip_id
						 , @occ_new = @OCC OUTPUT
						 , @rang_max = @rang_max OUTPUT

		IF (@OCC IS NULL)
			OR @OCC = 0
		BEGIN
			SET @err_str = 'Не удалось создать лицевой счёт! в типе фонда %d.' + CHAR(13)

			IF @rang_max = 0
				SET @err_str = @err_str + 'Закончился диапазон чисел для него!'

			RAISERROR (@err_str, 16, 1, @tip_id)
			RETURN -1
		END

		--PRINT @occ

		EXEC [dbo].[adm_load_occ] @town_name = @town_name
								, @street_name = @street_name
								, @nom_dom = @nom_dom
								, @tip_id = @tip_id
								, @nom_kvr = @nom_kvr
								, @floor = NULL
								, @rooms = NULL
								, @OCC = @occ_old
								, @new_ls = @OCC
								, @room_type = 'отдк'
								, @prop_type = 'прив'
								, @living_sq = 0
								, @total_sq = 0
								, @saldo = @saldo
								, @peni = 0
								, @add_adres = @add_adres -- Если адрес не найден (то добавлять)		
	END

	IF @OCC IS NULL
	BEGIN
		RAISERROR ('НЕ нашли лицевой по адресу: %s %s д.%s кв.%s', 16, 1, @town_name, @street_name, @nom_dom, @nom_kvr)
		RETURN -1
	END

	SELECT @FIRST_NAME = REPLACE(@FIRST_NAME, '.', '');
	SELECT @SECOND_NAME = REPLACE(@SECOND_NAME, '.', '');
	--print @FIRST_NAME
	-- Проверяем есть ли люди на лицевом счёте

	IF @LAST_NAME IS NOT NULL
		AND NOT EXISTS (
			SELECT *
			FROM dbo.People 
			WHERE occ = @OCC
		)
	BEGIN
		PRINT '-- Добавляем гражданина'

		EXEC [dbo].[adm_load_people] @OCC
								   , @LAST_NAME
								   , @FIRST_NAME
								   , @SECOND_NAME
								   , @STATUS2_ID = 'пост'
								   , @FAM_ID = 'отвл'
								   , @BIRTHDATE = NULL
								   , @DATEREG = NULL
								   , @DateEnd = NULL
								   , @DOLA_PRIV1 = NULL
								   , @DOLA_PRIV2 = NULL
								   , @SEX = NULL
								   , @DOCTYPE_ID = NULL
								   , @DOC_NO = NULL
								   , @PASSSER_NO = NULL
								   , @ISSUED = NULL
								   , @DOCORG = NULL
								   , @KOD_PVS = NULL
	END

	SELECT @fin_current = b.fin_current
		 , @build_id = F.bldn_id
	FROM dbo.Occupations O
		JOIN dbo.Flats F 
			ON F.id = O.flat_id
		JOIN dbo.Buildings AS b
			ON f.bldn_id=b.id
	WHERE O.occ = @OCC

	IF @occ_not_create = 0
		OR @occ_old IS NULL
	BEGIN
		--SELECT @occ_sup_str = '970' + dbo.Fun_AddLeftZero(str(@occ), 6)
		--PRINT @occ_sup_str
		--SELECT @occ_sup = convert(INT, @occ_sup_str)

		IF @is_occ_old_ces = 0
		BEGIN
			-- Формируем лицевой поставщика
			DECLARE @first_occ SMALLINT = NULL
				  , @str_first_occ VARCHAR(5)
				  , @len_end TINYINT
			SELECT TOP 1 @first_occ = first_occ
			FROM dbo.Dog_sup AS DS
			WHERE id = @dog_int

			IF @first_occ IS NULL
			BEGIN
				RAISERROR ('НЕ могу создать лицевой поставщика! Нет префикса в договоре!', 16, 1)
				RETURN -1
			END

			SET @str_first_occ = LTRIM(RTRIM(STR(@first_occ)))
			SET @len_end = LEN(@str_first_occ)
			SET @len_end = 9 - @len_end
			SELECT @occ_sup_str = @str_first_occ + dbo.Fun_AddLeftZero(STR(@OCC), @len_end)
			PRINT @occ_sup_str
			SELECT @occ_sup = CONVERT(INT, @occ_sup_str)
		END
		ELSE
		BEGIN -- входной лицевой является требованием создать такой по цессии
			SELECT @occ_sup = @occ_old
		END

	END
	ELSE
	BEGIN
		IF @is_occ_old_ces = 1
			SET @occ_sup = @occ_old
		ELSE
		BEGIN
			IF @occ_not_create = 1
				SELECT TOP 1 @occ_sup = occ_sup
				FROM dbo.Occ_Suppliers
				WHERE occ = @OCC
					AND sup_id = @sup_id
					AND fin_id = @fin_current

			IF @occ_sup IS NULL
				SET @occ_sup = @occ_old

		END

	END

	-- Создаём лицевой поставщика
	EXEC dbo.k_occ_sup_new @OCC = @OCC
						 , @dog_int = @dog_int
						 , @occ_sup = @occ_sup
						 , @group_add = 1
						 , @saldo = @saldo
						 , @add_cessia = 1
						 , @dolg_mes_start = @KOL_MES

	IF NOT EXISTS (
			SELECT occ_sup
			FROM dbo.Occ_Suppliers
			WHERE occ_sup = @occ_sup
		)
		RAISERROR ('Лицевой счёт %i у поставщика не создался!', 16, 1, @occ_sup) WITH NOWAIT;

	UPDATE dbo.Occ_Suppliers
	SET SALDO = @saldo
	WHERE fin_id = @fin_current
		AND occ_sup = @occ_sup

	-- добавляем сальдо на услугу 'цеся'
	IF EXISTS (
			SELECT *
			FROM dbo.Paym_list
			WHERE occ = @OCC
				AND service_id = @service_id1
		)
		UPDATE dbo.Paym_list
		SET SALDO = @saldo
		  , account_one = 1
		WHERE occ = @OCC
			AND service_id = @service_id1
	ELSE
		INSERT INTO dbo.Paym_list (occ
								 , service_id
								 , SALDO
								 , account_one
								 , fin_id)
		VALUES(@OCC
			 , @service_id1
			 , @saldo
			 , 1
			 , @fin_current)

	-- добавляем режим потребления и поставщика на лицевой по услуге 'цеся'
	IF EXISTS (
			SELECT *
			FROM dbo.Consmodes_list
			WHERE occ = @OCC
				AND service_id = @service_id1
		)
		UPDATE dbo.Consmodes_list
		SET mode_id = @mode_id
		  , source_id = @source_id
		  , account_one = 1
		  , sup_id = @sup_id
		WHERE occ = @OCC
			AND service_id = @service_id1
	ELSE
		INSERT INTO dbo.Consmodes_list (occ
									  , service_id
									  , mode_id
									  , source_id
									  , account_one
									  , sup_id)
		VALUES(@OCC
			 , @service_id1
			 , @mode_id
			 , @source_id
			 , 1
			 , @sup_id)

	-- Проверяем есть ли такой режим на доме
	IF NOT EXISTS (
			SELECT *
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
			 , @mode_id)

	-- Проверяем есть ли такой поставщик на доме
	IF NOT EXISTS (
			SELECT *
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
			 , @source_id)


END
go

