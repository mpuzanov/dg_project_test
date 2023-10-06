CREATE   PROCEDURE [dbo].[adm_build_source_edit]
(
	@build_id1		INT
	,@service_id1	VARCHAR(10)
    ,@source_id1	INT
    ,@Add1			BIT   -- 1 - Добавить  ,   если 0 то убрать 
    ,@roomtypes_str VARCHAR(50) = NULL -- список типов квартир для ограничения комм,об06,об10,отдк,парк,клад
    ,@debug		    BIT = 0    
	,@isChangeAreaEmpty BIT = 0 -- замена на лицевых где площадь = 0
)
AS

	DECLARE	@sup_name		VARCHAR(50)
			,@service_name	VARCHAR(100)
			,@adres			VARCHAR(100)
			,@msg			VARCHAR(400)
			,@source_no		INT
			,@mode_no		INT

	SELECT
		@sup_name = name
		,@service_name = service_name
	FROM dbo.View_suppliers
	WHERE id = @source_id1
	AND service_id = @service_id1;

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

	SELECT
		@adres = adres
	FROM dbo.View_buildings
	WHERE id = @build_id1;

	DECLARE @t_roomtypes TABLE(id VARCHAR(10))
	IF COALESCE(@roomtypes_str,'')=''
		INSERT INTO @t_roomtypes
		SELECT id FROM dbo.Room_types
	ELSE
		INSERT INTO @t_roomtypes
		SELECT value
		FROM STRING_SPLIT(@roomtypes_str, ',')
		WHERE RTRIM(value) <> '';

	DECLARE @t_occ TABLE(occ INT, build_id INT, fin_id SMALLINT, roomtype_id VARCHAR(10))
	INSERT @t_occ(occ,build_id,fin_id, roomtype_id)
	SELECT occ, f.bldn_id as build_id, b.fin_current, rt.id
	FROM dbo.Occupations as o
		JOIN dbo.flats as f ON o.flat_id=f.id
		JOIN dbo.Buildings AS b 
			ON f.bldn_id=b.id
		JOIN @t_roomtypes as rt ON o.roomtype_id=rt.id
	WHERE f.bldn_id=@build_id1
		AND o.status_id<>'закр'
		AND ((o.total_sq <> 0) OR (@isChangeAreaEmpty=cast(1 as bit)) AND o.total_sq = 0)

	IF @Add1 = 1
	BEGIN

		-- Добавить поставщика в дом
		IF NOT EXISTS (SELECT
					1
				FROM dbo.Build_source
				WHERE build_id = @build_id1
				AND service_id = @service_id1
				AND source_id = @source_id1)
		BEGIN  -- проверяем существование такого режима потребления
			IF EXISTS (SELECT
						1
					FROM dbo.View_suppliers
					WHERE id = @source_id1
					AND service_id = @service_id1)
				INSERT INTO BUILD_SOURCE
				(	build_id
					,service_id
					,source_id)
				VALUES (@build_id1
						,@service_id1
						,@source_id1);

			-- добавляем на лицевые
			INSERT INTO dbo.Consmodes_list
			(	occ
				,service_id
				,mode_id
				,source_id
				,subsid_only
				,is_counter
				,account_one
				,fin_id)
					SELECT
						o.occ
						,@service_id1
						,@mode_no
						,@source_no
						,0
						,0
						,0
						,o.fin_id
					FROM @t_occ as o
					LEFT JOIN dbo.Consmodes_list AS cl
						ON o.occ = cl.occ and cl.service_id=@service_id1
					WHERE cl.occ IS NULL;

			-- Добавляем Поставщика "нет" на дом если его там нет
			IF NOT EXISTS (SELECT
						1
					FROM dbo.Build_source
					WHERE build_id = @build_id1
					AND service_id = @service_id1
					AND source_id = @source_no)
				INSERT INTO dbo.Build_source
				(	build_id
					,service_id
					,source_id)
				VALUES (@build_id1
						,@service_id1
						,@source_no);
		END
	END
	ELSE
	BEGIN
		-- Удалить поставщика из дома
		IF (@source_id1 % 1000) = 0
		BEGIN
			--RAISERROR('Удалять режим "Нет" нельзя!',16,1)
			RETURN
		END
		IF NOT EXISTS (SELECT
					1
				FROM @t_occ as o
				JOIN dbo.Consmodes_list AS cl
					ON o.occ = cl.occ
				WHERE cl.service_id = @service_id1
				AND cl.source_id = @source_id1)
		BEGIN
			DELETE FROM dbo.Build_source
			WHERE build_id = @build_id1
				AND service_id = @service_id1
				AND source_id = @source_id1;
		END
		ELSE
		BEGIN
			SET @msg = 'Удалить нельзя!' + CHAR(13) + 'Поставщик <%s> используется' + CHAR(13) + 'в доме: %s' + CHAR(13) + 'по услуге <%s>!'
			RAISERROR (@msg, 16, 1, @sup_name, @adres, @service_name)
			RETURN
		END

	END
go

