CREATE   PROCEDURE [dbo].[adm_build_mode_change2]
(
	@build_id1	 INT -- код дома
   ,@service_id1 VARCHAR(10) -- 1 услуга
   ,@kod_mode1	 INT -- режим
   ,@kod_source1 INT -- поставщик
   ,@service_id2 VARCHAR(10) -- 2 услуга
   ,@kod_mode2	 INT -- режим
   ,@kod_source2	 INT = NULL -- поставщик
   ,@kolUpdate	 INT = 0 OUTPUT
   ,@roomtypes_str VARCHAR(50) = NULL -- список типов квартир для ограничения комм,об06,об10,отдк,парк,клад
   ,@debug		 BIT = NULL
   ,@isChangeAreaEmpty BIT = 0 -- замена на лицевых где площадь = 0
)
AS
/*
	
Смена режима потребления в доме и лицевых в нем с условием
  
Если на услуге @service_id1 режим = @kod_id1 и поставщик = @kod_id11
тогда на услуге @service_id2 ставим режим = @kod_id2 где поставщик = @kod_id22

*/
	SET NOCOUNT ON

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
		JOIN @t_roomtypes as rt ON o.roomtype_id=rt.id
	WHERE f.bldn_id=@build_id1
		AND o.status_id<>'закр'
		AND ((o.total_sq <> 0) OR (@isChangeAreaEmpty=cast(1 as bit)) AND o.total_sq = 0);

	DECLARE @service_NOT INT

	SELECT
		@service_NOT = service_no * 1000
	FROM dbo.SERVICES AS S 
	WHERE id = @service_id2;

	if @debug=1 
	begin
		select * from @t_roomtypes
		select * from @t_occ
		select @service_NOT as service_NOT	
	end

	BEGIN TRAN

		-- добавляем услугу с режимами Нет на лицевые , если её там нет
		INSERT INTO dbo.Consmodes_list
		(occ
		,service_id
		,source_id
		,mode_id
		,subsid_only
		,is_counter
		,account_one
		,fin_id)
			SELECT
				o.occ
			   ,@service_id1
			   ,@service_NOT
			   ,@service_NOT
			   ,0
			   ,0
			   ,0
			   ,o.fin_id
			FROM @t_occ as o
			WHERE NOT EXISTS (SELECT
					1
				FROM dbo.Consmodes_list AS CL 
				WHERE CL.occ = o.occ
				AND CL.service_id = @service_id2);
		--******************************************************************

		IF NOT EXISTS (SELECT
					1
				FROM dbo.Build_mode 
				WHERE build_id = @build_id1
				AND service_id = @service_id2
				AND mode_id = @kod_mode2) -- если нет режима нужного на 2 услуге

			AND EXISTS (SELECT   -- и есть режим на первой услуге
						1
					FROM dbo.Build_mode t2
					WHERE t2.build_id = @build_id1
					AND t2.service_id = @service_id1
					AND t2.mode_id = @kod_mode1)
			BEGIN  -- добавляем его на дом
				INSERT INTO dbo.Build_mode
				(build_id
				,service_id
				,mode_id)
				VALUES (@build_id1
						,@service_id2
						,@kod_mode2);
			END

		-- добавляем поставщика на дом
		IF NOT EXISTS (SELECT
					1
				FROM dbo.Build_source 
				WHERE build_id = @build_id1
				AND service_id = @service_id2
				AND source_id = @kod_source2)

			AND EXISTS (SELECT
						1
					FROM dbo.BUILD_SOURCE t2 
					WHERE t2.build_id = @build_id1
					AND t2.service_id = @service_id1
					AND t2.source_id = @kod_source1)
			BEGIN
				INSERT INTO dbo.Build_source
				(build_id
				,service_id
				,source_id)
				VALUES (@build_id1
						,@service_id2
						,@kod_source2);
			END

		--
		UPDATE cl 
		SET mode_id = @kod_mode2
			,source_id = @kod_source2
		FROM dbo.Consmodes_list AS cl
			JOIN @t_occ as o ON cl.occ=o.occ
		WHERE cl.service_id = @service_id2
			AND EXISTS (SELECT
				1
			FROM dbo.CONSMODES_LIST AS cl2 
			WHERE cl2.occ = cl.occ
			AND cl2.service_id = @service_id1
			AND cl2.mode_id = @kod_mode1
			AND cl2.source_id = @kod_source1)
		SET @kolUpdate = @@rowcount

	COMMIT TRAN
go

