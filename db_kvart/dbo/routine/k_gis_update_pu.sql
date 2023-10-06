CREATE   PROCEDURE [dbo].[k_gis_update_pu]
(
	@serial_number  VARCHAR(20) -- Серийный номер ПУ
   ,@id_pu_gis		VARCHAR(15) -- Код ПУ в ГИС
   ,@id_build_fias  VARCHAR(36) = NULL -- Код дома ФИАС
   ,@id_street_fias VARCHAR(36) = NULL -- Код улицы ФИАС
   ,@id_build_gis   VARCHAR(36) = NULL -- Код дома в ГИС
   ,@id_els_gis		VARCHAR(15) = NULL -- Единый лицевой счёт в ГИС
   ,@is_build		BIT			= 0	-- признак ОПУ
   ,@res_add		INT			= 0 OUTPUT
)
AS
	/*
	Загрузка информации из ГИС ЖКХ (Приборы учёта)
	*/
	SET NOCOUNT ON

	UPDATE b
	SET b.kod_gis = @id_build_gis
	FROM dbo.BUILDINGS b
	JOIN STREETS s
		ON b.street_id = s.id
	WHERE b.kod_fias = @id_build_fias
	AND s.kod_fias = @id_street_fias
	AND COALESCE(b.kod_gis, '') = ''

	IF COALESCE(@is_build, 0) = 0
		AND COALESCE(@id_els_gis, '') <> ''
	BEGIN
		UPDATE c
		SET id_pu_gis	  = @id_pu_gis
		   ,date_load_gis = current_timestamp
		FROM dbo.COUNTERS c
		JOIN dbo.OCCUPATIONS o
			ON o.flat_id = c.flat_id
		WHERE o.id_els_gis = @id_els_gis
		AND c.serial_number = @serial_number
		AND @id_pu_gis <> ''
		AND c.date_del IS NULL
		SET @res_add = @@rowcount
	END

	IF COALESCE(@is_build, 0) = 1
		AND COALESCE(@id_build_gis, '') <> ''
		AND (@id_pu_gis <> '')
	BEGIN
		UPDATE c
		SET id_pu_gis	  = @id_pu_gis
		   ,date_load_gis = current_timestamp
		FROM dbo.COUNTERS c
		JOIN dbo.BUILDINGS b
			ON b.id = c.build_id
		WHERE b.kod_gis = @id_build_gis
		AND c.serial_number = @serial_number
		AND c.date_del IS NULL
		SET @res_add = @@rowcount
	END
go

