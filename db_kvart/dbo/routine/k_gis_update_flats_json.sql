CREATE   PROCEDURE [dbo].[k_gis_update_flats_json]
(
	@FileJson     NVARCHAR(MAX)
   ,@FileJson_out NVARCHAR(MAX) = '' OUTPUT
   ,@msg_out	  VARCHAR(200)  = '' OUTPUT
   ,@debug		  BIT		    = 0
)
AS
/*
	Загрузка информации из ГИС ЖКХ (дома или квартиры или комнаты)

	@houseguid_fias	 VARCHAR(36) -- Глобальный уникальный идентификатор дома по ФИАС
   ,@houseguid_gis	 VARCHAR(36) = '' -- Идентификационный код дома в ГИС ЖКХ
   ,@id_nom_dom_gis	 VARCHAR(15) = '' -- Уникальный номер дома в гис
   ,@CadastralNumber VARCHAR(50) = '' -- кадастровый номер
   ,@AOGUID			 VARCHAR(36) -- код улицы в гис
   ,@nom_dom		 VARCHAR(12) -- № дома в гис
   ,@nom_kvr		 VARCHAR(20) = '' -- № квартиры в гис
   ,@nom_room		 VARCHAR(12) = '' -- № комнаты в гис
   ,@id_nom_gis		 VARCHAR(15) = '' -- код квартиры в гис
   ,@id_room_gis	 VARCHAR(15) = '' -- код комнаты в гис
   ,@res_add		 INT		 = 0 OUTPUT


	*/
	SET NOCOUNT ON

	IF @debug IS NULL
		SET @debug = 0

	-- проверяем файл 
	IF @FileJson IS NULL
		OR ISJSON(@FileJson) = 0
	BEGIN
		SET @msg_out = 'Входной файл не в JSON формате'
		IF @debug = 1
			PRINT @msg_out
		RETURN 0
	END

	DECLARE @File_TMP TABLE
	(
		houseguid_fias	 VARCHAR(36) NULL -- Глобальный уникальный идентификатор дома по ФИАС
	   ,houseguid_gis	 VARCHAR(36) NULL -- Идентификационный код дома в ГИС ЖКХ
	   ,id_nom_dom_gis	 VARCHAR(15) NULL -- Уникальный номер дома в гис
	   ,CadastralNumber  VARCHAR(50) NULL -- кадастровый номер
	   ,AOGUID			 VARCHAR(36) NULL-- код улицы в гис
	   ,nom_dom			 VARCHAR(12) NULL -- № дома в гис
	   ,nom_kvr			 VARCHAR(20) NULL -- № квартиры в гис
	   ,nom_room		 VARCHAR(12) NULL -- № комнаты в гис
	   ,id_nom_gis		 VARCHAR(15) NULL -- код квартиры в гис
	   ,id_room_gis		 VARCHAR(15) NULL -- код комнаты в гис
	   ,res_add			 INT		 DEFAULT 0 
	)

	--IF @houseguid_gis<>'' AND @houseguid_fias=''
	--	SET @houseguid_fias=@houseguid_gis


	--IF @id_nom_gis = '' -- код квартиры не заполнен
	--BEGIN
	--	IF @debug = 1
	--		PRINT 'записываем код дома ГИС если его нет'

	--	UPDATE b
	--	SET kod_gis			=
	--			CASE
	--				WHEN (COALESCE(b.kod_gis, '') = '') AND
	--				@houseguid_gis <> '' THEN @houseguid_gis
	--				ELSE kod_gis
	--			END
	--	   ,id_nom_dom_gis  =
	--			CASE
	--				WHEN (COALESCE(b.id_nom_dom_gis, '') = '') AND
	--				@id_nom_dom_gis <> '' THEN @id_nom_dom_gis
	--				ELSE id_nom_dom_gis
	--			END
	--	   ,CadastralNumber =
	--			CASE
	--				WHEN (COALESCE(b.CadastralNumber, '') IN ('', 'нет')) AND
	--				(@CadastralNumber <> '') THEN @CadastralNumber
	--				ELSE CadastralNumber
	--			END
	--		,b.kod_fias = 
	--			CASE
	--				WHEN (COALESCE(b.kod_fias, '') = '') AND
	--				@houseguid_fias <> '' THEN @houseguid_fias
	--				ELSE b.kod_fias
	--			END
	--	FROM dbo.BUILDINGS b
	--	JOIN STREETS S
	--		ON b.street_id = S.id
	--	WHERE S.kod_fias = @AOGUID
	--	AND b.nom_dom = @nom_dom
	--	AND @id_nom_gis = ''
	--	SET @res_add = @@rowcount
	--END
	--ELSE
	--BEGIN
	--	IF @debug = 1
	--		PRINT 'записываем код помещения в ГИС(квартиры)'
	--	IF @debug = 1
	--		SELECT
	--			f.id_nom_gis
	--		   ,@id_nom_gis AS id_nom_gisNew
	--		   ,f.CadastralNumber
	--		   ,CASE
	--				WHEN (COALESCE(f.CadastralNumber, '') IN ('', 'нет')) AND
	--				(@CadastralNumber <> '') THEN @CadastralNumber
	--				ELSE f.CadastralNumber
	--			END AS CadastralNumberNew
	--		   ,o.address
	--		FROM dbo.OCCUPATIONS o
	--		JOIN dbo.FLATS f
	--			ON o.flat_id = f.id
	--		JOIN dbo.BUILDINGS b
	--			ON f.bldn_id = b.id
	--		JOIN dbo.STREETS S
	--			ON b.street_id = S.id
	--		WHERE b.kod_fias = @houseguid_fias
	--		AND S.kod_fias = @AOGUID
	--		AND b.nom_dom = @nom_dom
	--		AND f.nom_kvr = @nom_kvr
	--		AND @id_nom_gis <> ''
	--	--SET @res_add = @@rowcount

	--	-- изменяем в таблице квартир
	--	UPDATE f
	--	SET f.id_nom_gis	  = @id_nom_gis
	--	   ,f.CadastralNumber =
	--			CASE
	--				WHEN (COALESCE(f.CadastralNumber, '') IN ('', 'нет')) AND
	--				(@CadastralNumber <> '') THEN @CadastralNumber
	--				ELSE f.CadastralNumber
	--			END
	--	FROM dbo.OCCUPATIONS o
	--	JOIN dbo.FLATS f
	--		ON o.flat_id = f.id
	--	JOIN dbo.BUILDINGS b
	--		ON f.bldn_id = b.id
	--	JOIN dbo.STREETS S
	--		ON b.street_id = S.id
	--	WHERE b.kod_fias = @houseguid_fias
	--	AND S.kod_fias = @AOGUID
	--	AND b.nom_dom = @nom_dom
	--	AND f.nom_kvr = @nom_kvr
	--	AND @id_nom_gis <> ''
	--	SET @res_add = @@rowcount

	--	IF @res_add = 0
	--	BEGIN
	--		-- изменяем в таблице лицевых счетов
	--		UPDATE o
	--		SET o.id_nom_gis	  = @id_nom_gis
	--		   ,o.CadastralNumber =
	--				CASE
	--					WHEN (COALESCE(o.CadastralNumber, '') IN ('', 'нет')) AND
	--					(@CadastralNumber <> '') THEN @CadastralNumber
	--					ELSE o.CadastralNumber
	--				END
	--		FROM dbo.OCCUPATIONS o
	--		JOIN dbo.FLATS f
	--			ON o.flat_id = f.id
	--		JOIN dbo.BUILDINGS b
	--			ON f.bldn_id = b.id
	--		JOIN dbo.STREETS S
	--			ON b.street_id = S.id
	--		WHERE b.kod_fias = @houseguid_fias
	--		AND S.kod_fias = @AOGUID
	--		AND b.nom_dom = @nom_dom
	--		AND f.nom_kvr = @nom_kvr
	--		AND @id_nom_gis <> ''
	--		SET @res_add = @@rowcount
	--	END

	--	IF (@nom_dom <> ''
	--		AND @nom_kvr <> '')
	--		AND (@nom_room <> ''
	--		AND @id_room_gis <> '')
	--		-- изменяем в таблице комнат
	--		UPDATE r
	--		SET r.id_room_gis	  = @id_room_gis
	--		   ,r.CadastralNumber =
	--				CASE
	--					WHEN (COALESCE(r.CadastralNumber, '') IN ('', 'нет')) AND
	--					(@CadastralNumber <> '') THEN @CadastralNumber
	--					ELSE r.CadastralNumber
	--				END
	--		FROM dbo.ROOMS r
	--		JOIN dbo.FLATS f
	--			ON f.id = r.flat_id
	--		JOIN dbo.BUILDINGS b
	--			ON f.bldn_id = b.id
	--		JOIN dbo.STREETS S
	--			ON b.street_id = S.id
	--		WHERE b.kod_fias = @houseguid_fias
	--		AND S.kod_fias = @AOGUID
	--		AND b.nom_dom = @nom_dom
	--		AND f.nom_kvr = @nom_kvr
	--		AND r.name = @nom_room
	--		AND (@nom_room <> ''
	--		AND @id_room_gis <> '')
	--	--SET @res_add = @@rowcount

	--END

	--IF @res_add > 1
	--	SET @res_add = 1
go

