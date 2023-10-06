CREATE   PROCEDURE [dbo].[adm_build_mode_change]
(
	@build_id1	 INT
   ,@service_id1 VARCHAR(10)
   ,@mode_old	 INT -- старый режим
   ,@mode_new	 INT -- новый режим
   ,@source_id	 INT -- поставщик (на котором надо сменить режим)
   ,@roomtypes_str VARCHAR(50) = NULL -- список типов квартир для ограничения комм,об06,об10,отдк,парк,клад
   ,@debug		 BIT = 0
   ,@isChangeAreaEmpty BIT = 0 -- замена на лицевых где площадь = 0

)
AS
	/*
	Смена режима потребления в доме и лицевых в нем
		
	*/
	SET NOCOUNT ON

	IF @mode_old = @mode_new
		RETURN

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
		JOIN dbo.flats as f 
			ON o.flat_id=f.id
		JOIN dbo.Buildings AS b 
			ON f.bldn_id=b.id
		JOIN @t_roomtypes as rt 
			ON o.roomtype_id=rt.id
	WHERE f.bldn_id=@build_id1
		AND o.status_id<>'закр'
		AND ((o.total_sq <> 0) OR (@isChangeAreaEmpty=cast(1 as bit)) AND o.total_sq = 0);

	DECLARE @service_NOT INT  -- режим нет

	SELECT
		@service_NOT = service_no * 1000
	FROM dbo.Services AS S 
	WHERE id = @service_id1;

	if @debug=1 
	begin
		select * from @t_roomtypes
		select * from @t_occ
		select @service_NOT as service_NOT	
	end

	-- добавляем услугу с режимами Нет на лицевые , если её там нет
	DECLARE @service_no INT
	SELECT
		@service_no = service_no
	FROM dbo.SERVICES AS S 
	WHERE id = @service_id1;

	INSERT INTO dbo.CONSMODES_LIST
	(occ
	,service_id
	,source_id
	,mode_id
	,subsid_only
	,is_counter
	,account_one
	,fin_id)
		SELECT
			t.occ
		   ,@service_id1
		   ,@service_NOT
		   ,@service_NOT
		   ,0
		   ,0
		   ,0
		   ,t.fin_id
		FROM @t_occ as t
		WHERE NOT EXISTS (SELECT
				1
			FROM dbo.Consmodes_list AS CL 
			WHERE CL.occ = t.occ
				AND CL.service_id = @service_id1);
	--******************************************************************


	IF EXISTS (SELECT
				1
			FROM dbo.CONS_MODES 
			WHERE id = @mode_new
			AND service_id = @service_id1)
	BEGIN
		BEGIN TRAN

		--1 
		IF NOT EXISTS (SELECT
					1
				FROM dbo.Build_mode
				WHERE build_id = @build_id1
				AND service_id = @service_id1
				AND mode_id = @mode_new)
		BEGIN
			INSERT INTO dbo.Build_mode
			(build_id
			,service_id
			,mode_id)
			VALUES (@build_id1
				   ,@service_id1
				   ,@mode_new);
		END

		--2
		UPDATE c 
		SET mode_id = @mode_new
		FROM dbo.Consmodes_list AS c
		JOIN @t_occ as t ON 
			c.occ = t.occ
		WHERE 
			c.service_id = @service_id1
			AND c.mode_id = @mode_old
			AND c.source_id = @source_id;   -- 29.09.2016

		--3
		IF (@mode_old % 1000) <> 0
		BEGIN -- если старый режим не НЕТ то его удаляем
			DELETE FROM dbo.Build_mode 
			WHERE 
				build_id = @build_id1
				AND service_id = @service_id1
				AND mode_id = @mode_old
				AND NOT EXISTS (SELECT
						1
					FROM dbo.Consmodes_list cl
					JOIN dbo.Occupations as o
                        ON cl.occ = o.occ
					JOIN dbo.Flats as f 
						ON o.flat_id=f.id
					WHERE 
						cl.service_id = @service_id1
						AND cl.mode_id = @mode_old
					AND f.bldn_id=@build_id1
					);
		END

		COMMIT TRAN

	END
	ELSE
	BEGIN
		RAISERROR ('Данный режим потребления уже доступен в доме!', 16, 1)
	END
go

