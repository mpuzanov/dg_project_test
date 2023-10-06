CREATE   PROCEDURE [dbo].[k_gis_update_occ]
(
	@occ1			INT
   ,@id_jku_gis		VARCHAR(15)
   ,@id_els_gis		VARCHAR(15)
   ,@id_nom_gis		VARCHAR(15) = NULL  -- код помещения в гис
   ,@id_room_gis	VARCHAR(15) = '' -- код комнаты в гис
   ,@res_add		INT			= 0 OUTPUT
   ,@debug			BIT			= 0
)
AS
	/*
	Загрузка информации из ГИС ЖКХ по л/счетам

DECLARE @res_add INT= 0
EXEC k_gis_update_occ @occ1=85000398,@id_jku_gis='40ЕТ107614-01',@id_els_gis='40ЕТ107614',@id_nom_gis='9TKO0057700015', @res_add=@res_add OUTPUT, @debug=1
SELECT @res_add

	*/
	SET NOCOUNT ON
	
	SELECT @id_nom_gis = COALESCE(@id_nom_gis, ''), @id_room_gis=COALESCE(@id_room_gis,'')

	SELECT @occ1=dbo.Fun_GetFalseOccIn(@occ1)

	UPDATE o 
	SET id_jku_gis =
			CASE
				WHEN @id_jku_gis <> '' THEN @id_jku_gis
				ELSE id_jku_gis
			END
	   ,id_els_gis =
			CASE
				WHEN @id_els_gis <> '' THEN @id_els_gis
				ELSE id_els_gis
			END
		,room_id = CASE
				WHEN @id_room_gis<> '' THEN (SELECT r.id FROM dbo.Rooms AS r WHERE r.flat_id=o.flat_id AND r.id_room_gis=@id_room_gis)
				ELSE room_id
			END
	FROM dbo.OCCUPATIONS o
	JOIN dbo.OCCUPATION_TYPES ot 
		ON o.tip_id = ot.id	
	WHERE (occ = @occ1)
	OR (ot.occ_prefix_tip <> ''
	AND SCHTL = @occ1)
	SET @res_add = @@rowcount

	IF @debug = 1
		PRINT '@res_add: ' + STR(@res_add)

	IF @res_add = 0
	BEGIN
		-- Ищем в поставщиках    возможно @occ1 - это occ_sup
		DECLARE @fin_id_start SMALLINT = 192 -- январь 2018
			   ,@occ_sup	  INT

		-- берём последнюю запись
		SELECT TOP 1
			@occ_sup = occ_sup
		   ,@occ1 = occ
		FROM dbo.OCC_SUPPLIERS os 
		WHERE occ_sup = @occ1
		ORDER BY os.fin_id DESC

		IF @occ_sup IS NULL
			RETURN 0

		IF @debug = 1
			PRINT '@occ_sup: ' + STR(@occ_sup) + ' @fin_id_start:' + STR(@fin_id_start)

		UPDATE os
		SET id_jku_gis = @id_jku_gis
		FROM dbo.OCC_SUPPLIERS os
		WHERE occ_sup = @occ_sup
		AND os.fin_id >= @fin_id_start    --РЕШИЛ ОБНОВЛЯТЬ И В ИСТОРИИ с января 2018 г.
		--AND @id_jku_gis <> ''
		SET @res_add = @@rowcount

		IF @debug = 1
			PRINT '@res_add: ' + STR(@res_add)

		IF @res_add > 0
		BEGIN
			-- проверяем установлен ли ЕЛС
			IF EXISTS (SELECT
						1
					FROM dbo.OCCUPATIONS o
					WHERE occ = @occ1
					AND (o.id_els_gis = ''
					OR o.id_els_gis IS NULL))
			BEGIN
				IF @debug = 1
					PRINT 'ЕЛС не установлен'
				UPDATE o
				SET id_els_gis = @id_els_gis
				FROM dbo.OCCUPATIONS o
				WHERE occ = @occ1
			END
			ELSE
			IF @debug = 1
				PRINT 'ЕЛС установлен'
		END

	END
go

