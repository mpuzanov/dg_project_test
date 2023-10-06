CREATE   PROCEDURE [dbo].[adm_build_mode_edit]
(
	@build_id1		INT
	,@service_id1	VARCHAR(10)
	,@mode_id1		INT
	,@Add1			BIT  -- Добавить  ,   если 0 то убрать 
    ,@roomtypes_str VARCHAR(50) = NULL
	,@isChangeAreaEmpty BIT = NULL -- замена на лицевых где площадь = 0
)
AS
	SET NOCOUNT ON;

	SET @isChangeAreaEmpty=COALESCE(@isChangeAreaEmpty, 0)

	DECLARE	@mode_name		VARCHAR(50)
			,@service_name	VARCHAR(100)
			,@adres			VARCHAR(50)
			,@msg			VARCHAR(400)

	SELECT
		@mode_name = cm.name
		,@service_name = s.name
	FROM dbo.Cons_modes AS cm 
	JOIN dbo.Services AS s 
		ON cm.service_id = s.id
	WHERE cm.id = @mode_id1
	AND service_id = @service_id1;

	SELECT
		@adres = adres
	FROM dbo.View_buildings
	WHERE id = @build_id1;

	DECLARE	@mode_no	INT
			,@source_no	INT

	SELECT
		@mode_no = id
	FROM dbo.Cons_modes 
	WHERE service_id = @service_id1
	AND (id % 1000) = 0;

	SELECT
		@source_no = id
	FROM dbo.View_suppliers 
	WHERE service_id = @service_id1
	AND (id % 1000) = 0;

	DECLARE @t_roomtypes TABLE(id VARCHAR(10))
	IF COALESCE(@roomtypes_str,'')=''
		INSERT INTO @t_roomtypes
		SELECT id FROM dbo.Room_types
	ELSE
		INSERT INTO @t_roomtypes
		SELECT value
		FROM STRING_SPLIT(@roomtypes_str, ',')
		WHERE RTRIM(value) <> ''

	DECLARE @t_occ TABLE(occ INT, build_id INT, fin_id SMALLINT, roomtype_id VARCHAR(10))
	INSERT @t_occ(occ,build_id,fin_id, roomtype_id)
	SELECT occ, f.bldn_id as build_id, b.fin_current, rt.id
	FROM dbo.Occupations as o
		JOIN dbo.flats as f 
			ON o.flat_id=f.id
		JOIN dbo.Buildings AS b 
			ON f.bldn_id=b.id
		JOIN @t_roomtypes as rt 
			ON o.roomtype_id=rt.id
	WHERE f.bldn_id=@build_id1
		AND o.status_id<>'закр'
		AND ((o.total_sq <> 0) OR (@isChangeAreaEmpty=cast(1 as bit)) AND o.total_sq = 0)

	IF @Add1 = 1
	BEGIN
		-- Добавить режим потребления в дом
		IF NOT EXISTS (SELECT 
					1
				FROM dbo.Build_mode 
				WHERE build_id = @build_id1
				AND service_id = @service_id1
				AND mode_id = @mode_id1)
		BEGIN  -- проверяем существование такого режима потребления
			IF EXISTS (SELECT 
						1
					FROM dbo.Cons_modes  
					WHERE id = @mode_id1
					AND service_id = @service_id1)
			BEGIN
				INSERT INTO dbo.Build_mode
				(	build_id
					,service_id
					,mode_id)
				VALUES (@build_id1
						,@service_id1
						,@mode_id1)

				-- добавляем на лицевые
				INSERT INTO dbo.Consmodes_list
				(	Occ
					,service_id
					,source_id
					,mode_id
					,subsid_only
					,is_counter
					,account_one
					,fin_id)
						SELECT
							o.Occ
							,@service_id1
							,@mode_no
							,@source_no
							,0
							,0
							,0
							,o.fin_id
						FROM @t_occ as o
						LEFT JOIN dbo.Consmodes_list AS cl 
							ON o.Occ = cl.Occ and cl.service_id=@service_id1
						WHERE cl.occ is null

				-- Добавляем режим нет на дом если его там нет
				IF NOT EXISTS (SELECT 
							1
						FROM dbo.Build_mode 
						WHERE build_id = @build_id1
						AND service_id = @service_id1
						AND mode_id = @mode_no)
					INSERT INTO dbo.BUILD_MODE
					(	build_id
						,service_id
						,mode_id)
					VALUES (@build_id1
							,@service_id1
							,@mode_no)

			END
		END
	--ELSE
	--BEGIN
	--  SET @msg='Режим <%s> уже доступен'+CHAR(13)+'в доме: %s'+CHAR(13)+'по услуге <%s>!'
	--  RAISERROR(@msg,16,1,@mode_name,@adres,@service_name)
	--END

	END
	ELSE
	BEGIN
		-- Удалить режим потребления из дома
		IF (@mode_id1 % 1000) = 0
		BEGIN
			-- удаляем если он последний
			--RAISERROR('Удалять режим "Нет" нельзя!',16,1)
			RETURN	
		END

		IF NOT EXISTS (SELECT 
					1
				FROM @t_occ as o
				JOIN dbo.Consmodes_list AS cl 
					ON o.Occ = cl.Occ
				WHERE cl.service_id = @service_id1
				AND cl.mode_id = @mode_id1)
		BEGIN
			DELETE FROM dbo.Build_mode
			WHERE build_id = @build_id1
				AND service_id = @service_id1
				AND mode_id = @mode_id1
		END
		ELSE
		BEGIN
			SET @msg = CONCAT('Удалить нельзя!' , CHAR(13) , 'Режим <%s> используется' , CHAR(13) , 'в доме: %s' , CHAR(13) , 'по услуге <%s>!')
			RAISERROR (@msg, 16, 1, @mode_name, @adres, @service_name)
		END

	END
go

