CREATE   PROCEDURE [dbo].[k_gis_update_flats]
(
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
   ,@debug			 BIT		 = 0
)
AS
	/*
	Загрузка информации из ГИС ЖКХ (дома или квартиры или комнаты)


DECLARE	@return_value int,
		@res_add int

EXEC	@return_value = [dbo].[k_gis_update_flats]
		@houseguid_fias = N'01d501ed-7227-4e94-809f-341ba027cdc7',
		@houseguid_gis = N'01d501ed-7227-4e94-809f-341ba027cdc7',
		@id_nom_dom_gis = N'KAK00075',
		@CadastralNumber = N'18:26:010099:121',
		@AOGUID = N'2f6e0d97-cd46-4f8e-98cd-7ccc60078c48',
		@nom_dom = N'17',
		@nom_kvr = N'1',
		@id_nom_gis = N'9KAK0007500001',
		@res_add = @res_add OUTPUT
		,@debug=0

SELECT	@res_add as N'@res_add'

SELECT	'Return Value' = @return_value

	*/
	SET NOCOUNT ON
	IF @debug IS NULL
		SET @debug = 0

	IF @houseguid_gis<>'' AND @houseguid_fias=''
		SET @houseguid_fias=@houseguid_gis


	IF @id_nom_gis = '' -- код квартиры не заполнен
	BEGIN
		IF @debug = 1
			PRINT 'записываем код дома ГИС если его нет'

		UPDATE b
		SET kod_gis			=
				CASE
					WHEN (COALESCE(b.kod_gis, '') = '') AND
					@houseguid_gis <> '' THEN @houseguid_gis
					ELSE kod_gis
				END
		   ,id_nom_dom_gis  =
				CASE
					WHEN (COALESCE(b.id_nom_dom_gis, '') = '') AND
					@id_nom_dom_gis <> '' THEN @id_nom_dom_gis
					ELSE id_nom_dom_gis
				END
		   ,CadastralNumber =
				CASE
					WHEN (COALESCE(b.CadastralNumber, '') IN ('', 'нет')) AND
					(@CadastralNumber <> '') THEN @CadastralNumber
					ELSE CadastralNumber
				END
			,b.kod_fias = 
				CASE
					WHEN (COALESCE(b.kod_fias, '') = '') AND
					@houseguid_fias <> '' THEN @houseguid_fias
					ELSE b.kod_fias
				END
		FROM dbo.BUILDINGS b
		JOIN STREETS S
			ON b.street_id = S.id
		WHERE S.kod_fias = @AOGUID
		AND b.nom_dom = @nom_dom
		AND @id_nom_gis = ''
		SET @res_add = @@rowcount
	END
	ELSE
	BEGIN
		IF @debug = 1
			PRINT 'записываем код помещения в ГИС(квартиры)'
		IF @debug = 1
			SELECT
				f.id_nom_gis
			   ,@id_nom_gis AS id_nom_gisNew
			   ,f.CadastralNumber
			   ,CASE
					WHEN (COALESCE(f.CadastralNumber, '') IN ('', 'нет')) AND
					(@CadastralNumber <> '') THEN @CadastralNumber
					ELSE f.CadastralNumber
				END AS CadastralNumberNew
			   ,o.address
			FROM dbo.OCCUPATIONS o
			JOIN dbo.FLATS f
				ON o.flat_id = f.id
			JOIN dbo.BUILDINGS b
				ON f.bldn_id = b.id
			WHERE b.kod_fias = @houseguid_fias
			AND f.nom_kvr = @nom_kvr
			AND @id_nom_gis <> ''
		--SET @res_add = @@rowcount

		-- изменяем в таблице квартир
		UPDATE f
		SET f.id_nom_gis	  = @id_nom_gis
		   ,f.CadastralNumber =
				CASE
					WHEN (COALESCE(f.CadastralNumber, '') IN ('', 'нет')) AND
					(@CadastralNumber <> '') THEN @CadastralNumber
					ELSE f.CadastralNumber
				END
		FROM dbo.OCCUPATIONS o
		JOIN dbo.FLATS f
			ON o.flat_id = f.id
		JOIN dbo.BUILDINGS b
			ON f.bldn_id = b.id
		WHERE b.kod_fias = @houseguid_fias
		AND f.nom_kvr = @nom_kvr
		AND @id_nom_gis <> ''
		SET @res_add = @@rowcount

		IF @res_add = 0
		BEGIN
			-- изменяем в таблице лицевых счетов
			UPDATE o
			SET o.id_nom_gis	  = @id_nom_gis
			   ,o.CadastralNumber =
					CASE
						WHEN (COALESCE(o.CadastralNumber, '') IN ('', 'нет')) AND
						(@CadastralNumber <> '') THEN @CadastralNumber
						ELSE o.CadastralNumber
					END
			FROM dbo.OCCUPATIONS o
			JOIN dbo.FLATS f
				ON o.flat_id = f.id
			JOIN dbo.BUILDINGS b
				ON f.bldn_id = b.id
			WHERE b.kod_fias = @houseguid_fias
			AND f.nom_kvr = @nom_kvr
			AND @id_nom_gis <> ''
			SET @res_add = @@rowcount
		END

		IF (@nom_dom <> ''
			AND @nom_kvr <> '')
			AND (@nom_room <> ''
			AND @id_room_gis <> '')
		BEGIN
			IF @debug = 1
				PRINT 'изменяем в таблице комнат'

			DECLARE @flat_id1 INT

			SELECT @flat_id1=f.id
			FROM dbo.FLATS f 
			JOIN dbo.BUILDINGS b 
				ON f.bldn_id = b.id
			WHERE b.kod_fias = @houseguid_fias
				AND f.nom_kvr = @nom_kvr

			IF @flat_id1 IS NOT NULL
			BEGIN
				
				MERGE dbo.ROOMS AS target  
				USING (SELECT @flat_id1, @nom_room, @id_room_gis, COALESCE(@CadastralNumber,'')) AS source (flat_id, nom_room, id_room_gis, CadastralNumber)  
				ON (target.flat_id = source.flat_id AND target.[name]=source.nom_room)  
				WHEN MATCHED THEN   
					UPDATE SET id_room_gis = source.id_room_gis
						, CadastralNumber =
							CASE
								WHEN (COALESCE(target.CadastralNumber, '') IN ('', 'нет')) AND
								(source.CadastralNumber <> '') THEN source.CadastralNumber
								ELSE target.CadastralNumber
							END
				WHEN NOT MATCHED THEN  
					INSERT (flat_id, name, id_room_gis, CadastralNumber)  
					VALUES (source.flat_id, source.nom_room, source.id_room_gis, source.CadastralNumber)  
				;
				IF @debug = 1
					PRINT '@@rowcount= '+STR(@@rowcount)
			END
		--SET @res_add = @@rowcount
		END

	END

	IF @res_add > 1
		SET @res_add = 1
go

