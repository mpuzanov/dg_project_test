-- =============================================
-- Author:		Пузанов
-- Create date: 22.09.2011
-- Description:	Загрузка данных
-- =============================================
CREATE           PROCEDURE [dbo].[adm_load_occ]
	  @street_name VARCHAR(50)
	, @nom_dom VARCHAR(12)
	, @tip_id SMALLINT
	, @nom_kvr VARCHAR(20) = '0'
	, @floor SMALLINT = NULL
	, @rooms SMALLINT = NULL
	, @occ VARCHAR(15) = NULL
	, @new_ls INT
	, @room_type VARCHAR(10) = NULL
	, @prop_type VARCHAR(10) = NULL
	, @living_sq DECIMAL(9, 2) = NULL
	, @total_sq DECIMAL(9, 2)
	, @saldo DECIMAL(9, 2) = NULL
	, @peni DECIMAL(9, 2) = NULL
	, @add_adres BIT = 0 -- Если адрес не найден (то добавлять)
	, @add_ls BIT = 0 -- Если новый лицевой не найден (то добавлять)
	, @town_name VARCHAR(20) = NULL
	, @ResultAdd BIT = 0 OUTPUT -- 0- не добавили, 1-добавили
	, @strerror VARCHAR(4000) = '' OUTPUT
	, @date_start DATE = NULL
	, @saldo_disperse BIT = NULL -- раскидать сальдо по услугам
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON

	--IF upper(db_name()) IN ('KOMP', 'KVART', 'NAIM') AND @new_ls < 99999999
	--	RETURN

	SET @ResultAdd = 0

	IF COALESCE(@new_ls, 0) = 0
		AND COALESCE(@add_ls, 0) = 0
		BEGIN
			SET @strerror='лицевой не задан'
			RETURN
		END

	IF @add_adres IS NULL
		SET @add_adres = 0

	IF @nom_kvr IS NULL
		SET @nom_kvr = '0'

	IF @saldo IS NULL
		SET @saldo = 0

	IF @total_sq IS NULL
		SET @total_sq = 0

	IF @living_sq IS NULL
		AND @total_sq IS NOT NULL
		SET @living_sq = @total_sq

	SET @street_name = RTRIM(@street_name)

	IF RTRIM(@town_name) = ''
		SET @town_name = NULL

	BEGIN TRY

	IF COALESCE(@new_ls, 0) = 0
	BEGIN
		EXEC [dbo].[k_occ_new] @tip_id = @tip_id
							 , @occ_new = @new_ls OUTPUT
							 , @rang_max = 999
		--IF @new_ls>0  --сформировали число нового лицевого			
	END

	IF COALESCE(@room_type, '') = ''
		SET @room_type = 'отдк'
	IF COALESCE(@prop_type, '') = ''
		SET @prop_type = 'прив'

	DECLARE @street_id INT
		  , @build_id INT
		  , @flat_id INT
		  , @address VARCHAR(50)
		  , @fin_current SMALLINT
		  , @town_id SMALLINT
		  , @tip_id_old SMALLINT = NULL
		  , @tip_name VARCHAR(50)

	SELECT @tip_id_old = tip_id
		 , @build_id = f.bldn_id
		 , @flat_id = f.id
	FROM dbo.Occupations AS o 
		JOIN Flats f 
			ON o.flat_id = f.id
	WHERE Occ = @new_ls

	-- наименование типа фонда куда добавляем лицевые
	SELECT @tip_name = name
	FROM dbo.Occupation_Types AS OT
	WHERE id = @tip_id

	IF @tip_id_old IS NOT NULL
		AND @tip_id_old = @tip_id
		GOTO LABEL_UPDATE

	IF @tip_id_old IS NOT NULL
		AND @tip_id_old <> @tip_id
	BEGIN
		SET @strerror = CONCAT('Лицевой: ',@new_ls,' найден в другом типе фонда')
		RAISERROR (@strerror, 16, 1)
		RETURN -1
	END

	IF @town_name IS NOT NULL
	BEGIN
		SELECT @town_id = id
		FROM dbo.Towns T
		WHERE name = RTRIM(@town_name)

		IF @town_id IS NULL
		BEGIN
			SET @strerror = CONCAT('Населённый пункт: ',@town_name,' не найден в БД')
			RAISERROR (@strerror, 16, 1)
			RETURN -1
		END

	END
	ELSE
		SET @town_id = 1

	-- проверяем улицу
	IF @add_adres = 1
		AND NOT EXISTS (
			SELECT 1
			FROM dbo.VStreets
			WHERE (name = @street_name OR short_name = @street_name)
				AND (town_id = @town_id)
		)
	BEGIN --добавляем улицу
		SELECT @street_id = COALESCE(MAX(id), 0) + 1
		FROM dbo.Streets

		INSERT INTO [dbo].[Streets]
			([id]
		   , [name]
		   , town_id)
			VALUES (@street_id
				  , @street_name
				  , @town_id)

	END
	ELSE
		SELECT @street_id = id
		FROM dbo.VStreets
		WHERE (name = @street_name OR short_name = @street_name)
			AND (town_id = @town_id)

	IF @street_id IS NULL
	BEGIN
		SET @strerror = CONCAT('Улица ',@street_name,' в ',@town_name,' не найдена в БД')
		RAISERROR (@strerror, 16, 1)
		RETURN -1
	END

	-- проверяем дом
	IF @add_adres = 1
		AND NOT EXISTS (
			SELECT 1
			FROM dbo.Buildings
			WHERE street_id = @street_id
				AND nom_dom = @nom_dom
				AND tip_id = @tip_id
				AND town_id = @town_id
		)
	BEGIN --добавляем дом
		SELECT @fin_current = fin_id
		FROM dbo.Occupation_Types 
		WHERE id = @tip_id
		INSERT INTO [dbo].[Buildings]
			([street_id]
		   , [nom_dom]
		   , [sector_id]
		   , [div_id]
		   , [tip_id]
		   , fin_current
		   , town_id)
			VALUES (@street_id
				  , @nom_dom
				  , 0
				  , 0
				  , @tip_id
				  , @fin_current
				  , @town_id)

		SELECT @build_id = SCOPE_IDENTITY()
	END
	ELSE
		SELECT @build_id = id, @fin_current=fin_current
		FROM dbo.Buildings
		WHERE street_id = @street_id
			AND nom_dom = @nom_dom
			AND tip_id = @tip_id
			AND town_id = @town_id

	IF @build_id IS NULL
	BEGIN
		SET @strerror = CONCAT('Дом ',@street_name,' ',@nom_dom,' в ',@town_name,' не найден в фонде: ', @tip_name)
		RAISERROR (@strerror, 16, 1)
		RETURN -1
	END

	-- проверяем квартиру
	IF @add_adres = 1
		AND NOT EXISTS (
			SELECT 1
			FROM dbo.Flats
			WHERE bldn_id = @build_id
				AND nom_kvr = @nom_kvr
		)
	BEGIN --добавляем квартиру

		INSERT INTO [dbo].Flats
			(bldn_id
		   , nom_kvr
		   , floor
		   , Rooms)
			VALUES (@build_id
				  , @nom_kvr
				  , @floor
				  , @rooms)

		SELECT @flat_id = SCOPE_IDENTITY()
	END
	ELSE
		SELECT @flat_id = id
		FROM dbo.Flats
		WHERE bldn_id = @build_id
			AND nom_kvr = @nom_kvr

	IF @flat_id IS NULL
	BEGIN
		SET @strerror = CONCAT('Помещение ',@street_name,' ',@nom_dom,' ',@nom_kvr,' в ',@town_name,' не найдено в БД')
		RAISERROR (@strerror, 16, 1)
		RETURN -1
	END

	-- проверяем лицевой
	IF NOT EXISTS (
			SELECT 1
			FROM dbo.Occupations
			WHERE Occ = @new_ls
		)
	BEGIN --добавляем лицевой счёт

		INSERT INTO [dbo].Occupations
			(Occ
		   , jeu
		   , schtl
		   , schtl_old
		   , flat_id
		   , tip_id
		   , roomtype_id
		   , proptype_id
		   , status_id
		   , living_sq
		   , total_sq
		   , teplo_sq
		   , SALDO
		   , fin_id
		   , date_start)
			VALUES (@new_ls
				  , 0
				  , TRY_CONVERT(INT, @occ)
				  , @occ
				  , @flat_id
				  , @tip_id
				  , @room_type
				  , @prop_type
				  , 'своб'
				  , @living_sq
				  , @total_sq
				  , @total_sq
				  , @saldo
				  , @fin_current
				  , @date_start)

	--print 'добавили лицевой: '+str(@new_ls)   
	END

LABEL_UPDATE:

	--RAISERROR ('Переменные %d %d %d', 16, 1, @build_id, @flat_id, @new_ls)

	-- обновляем сальдо
	UPDATE [dbo].Occupations
	SET SALDO = @saldo
	  , address = [dbo].[Fun_GetAdres](@build_id, flat_id, Occ)
	  , total_sq = @total_sq
	  , living_sq = @living_sq
	  , teplo_sq = @total_sq
	  , Penalty_old = COALESCE(@peni, Penalty_old)
	  , schtl = TRY_CONVERT(INT, @occ)
	  , schtl_old = @occ
	  , Rooms = @rooms
	WHERE Occ = @new_ls
		AND status_id <> 'закр'

	IF @@rowcount > 0
		SET @ResultAdd = 1

	IF @floor > 0
		UPDATE dbo.Flats
		SET [floor] = @floor
		WHERE id = @flat_id

	-- раскидать сальдо по услугам
	IF @saldo_disperse=1
		EXEC dbo.k_raschet_saldo @occ1 = @new_ls, @debug = 0

	END TRY

	BEGIN CATCH

		EXECUTE k_GetErrorInfo @visible = 0 --@debug
							 , @strerror = @strerror OUT
		SET @strerror = @strerror + N'Лицевой: ' + LTRIM(STR(@new_ls))

		RAISERROR (@strerror, 16, 1)

	END CATCH

END
go

