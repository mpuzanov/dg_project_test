CREATE   PROCEDURE [dbo].[k_gis_find_adres]
(
	@occ		INT			= NULL
   ,@id_jku_gis VARCHAR(15) = NULL
   ,@id_els_gis VARCHAR(15) = NULL
   ,@debug		BIT			= 0
)
AS
	/*
	Загрузка информации из ГИС ЖКХ по л/счетам

EXEC k_gis_find_adres @occ=85000398
EXEC k_gis_find_adres @occ=NULL,@id_jku_gis='40ЕТ107614-01', @debug=1
EXEC k_gis_find_adres @occ=85000398,@id_jku_gis='40ЕТ107614-01',@id_els_gis='40ЕТ107614', @debug=1
EXEC k_gis_find_adres @occ=NULL,@id_jku_gis='40ЕТ107614-01',@id_els_gis='40ЕТ107614', @debug=1

	*/
	SET NOCOUNT ON

	IF @occ IS NULL
		AND @id_jku_gis IS NULL
		AND @id_els_gis IS NULL
		GOTO LABAL_END

	DECLARE @flat_id INT
		   ,@adres	 VARCHAR(100)

	SELECT
		@flat_id = flat_id
	   ,@occ = o.occ
	FROM dbo.OCCUPATIONS AS o
	JOIN dbo.OCCUPATION_TYPES ot
		ON o.tip_id = ot.id
	WHERE o.occ = @occ
	OR id_jku_gis = @id_jku_gis
	OR id_els_gis = @id_els_gis
	OR (ot.occ_prefix_tip <> ''
	AND SCHTL = @occ)

	IF @flat_id IS NULL
	BEGIN
		-- Проверяем у поставщика
		SELECT TOP 1
			@flat_id = flat_id
		   ,@occ = os.occ_sup
		FROM dbo.OCC_SUPPLIERS os 
		JOIN dbo.OCCUPATIONS o 
			ON os.occ = o.occ
		WHERE os.occ_sup = @occ
		OR os.id_jku_gis = @id_jku_gis
	--OR o.id_els_gis=@id_els_gis		
	END

LABAL_END:

	-- Выдаём адреса	
	SELECT
		@occ AS occ
	   ,f.id_nom_gis
	   ,CONCAT(s.name , ' д.' , b.nom_dom) AS adres_build
	   ,CONCAT(s.name , ' д.' , b.nom_dom , ' кв.' , f.nom_kvr) AS address
	FROM dbo.FLATS f 
	JOIN dbo.BUILDINGS b 
		ON f.bldn_id = b.id
	JOIN dbo.STREETS s
		ON b.street_id = s.id
	WHERE f.id = @flat_id
go

