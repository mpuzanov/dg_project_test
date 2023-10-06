CREATE   PROCEDURE [dbo].[k_schtl_find]
(
	  @occ1 INT = NULL
	, @jeu1 SMALLINT = NULL
	, @schtl1 INT = NULL
	, @schtl_old1 VARCHAR(15) = NULL
	, @id_els_gis VARCHAR(10) = NULL
)
AS
	/*
  Открытие лицевого счета (Поиск)
  автор: Пузанов
  exec k_schtl_find @schtl1=65, @schtl_old1='18001003022'
  exec k_schtl_find @occ1=0,@jeu1=0,@schtl1=1800100302,@schtl_old1='1800100302',@id_els_gis=''
  exec k_schtl_find @schtl1=1800100302, @schtl_old1='18001003022'
*/
	SET NOCOUNT ON

	IF @jeu1 = 0
		SET @jeu1 = NULL
	IF @schtl1 = 0
		SET @schtl1 = NULL
	IF @occ1 = 0
		SET @occ1 = NULL
	IF @id_els_gis = ''
		SET @id_els_gis = NULL
	IF @schtl_old1 = ''
		SET @schtl_old1 = NULL

	IF @id_els_gis IS NOT NULL
	BEGIN
		SELECT @occ1 = NULL
			 , @jeu1 = NULL
			 , @schtl1 = NULL

		SELECT o.Occ
			 , o.address
			 , dbo.Fun_Initials(Occ) AS FIO
			 , o.STATUS_ID
			 , o.tip_id
			 , o.flat_id
			 , o.bldn_id
			 , b.street_id
			 , b.town_id
			 , tip_name = ot.name
			 , o.id_jku_gis
			 , o.TOTAL_SQ
		FROM dbo.VOcc AS o 
			JOIN dbo.Buildings AS b 
				ON o.bldn_id = b.id
			JOIN dbo.Occupation_Types AS ot 
				ON b.tip_id = ot.id
		WHERE o.id_els_gis = @id_els_gis

		RETURN
	END

	IF @jeu1 IS NOT NULL
		OR @schtl1 IS NOT NULL
		OR @schtl_old1 IS NOT NULL
	BEGIN 
		--PRINT 'поиск по старым ЖРП и Лицевым'
		SELECT o.Occ
			 , o.address
			 , dbo.Fun_Initials(Occ) AS Initials
			 , o.STATUS_ID
			 , o.tip_id
			 , o.flat_id
			 , o.bldn_id
			 , b.street_id
			 , b.town_id
			 , tip_name = ot.name
			 , o.id_jku_gis
			 , o.TOTAL_SQ
		FROM dbo.VOcc AS o 
			JOIN dbo.Buildings AS b 
				ON o.bldn_id = b.id
			JOIN dbo.Occupation_Types AS ot 
				ON b.tip_id = ot.id
		WHERE (o.JEU = @jeu1 OR @jeu1 IS NULL)
			AND (
			(o.SCHTL = @schtl1 OR o.schtl_old = @schtl_old1)
			)
	END
	ELSE
	BEGIN -- поиск по единому лицевому

		IF EXISTS (
				SELECT 1
				FROM dbo.VOcc AS o 
				WHERE o.Occ = @occ1
			)
		BEGIN
		LABEL1:
			SELECT o.Occ
				 , o.address
				 , dbo.Fun_Initials(Occ) AS FIO
				 , o.STATUS_ID
				 , o.tip_id
				 , o.flat_id
				 , o.bldn_id
				 , b.street_id
				 , b.town_id
				 , tip_name = ot.name
				 , o.id_jku_gis
				 , o.TOTAL_SQ
			FROM dbo.VOcc AS o 
				JOIN dbo.Buildings AS b
					ON o.bldn_id = b.id
				JOIN dbo.Occupation_Types AS ot 
					ON b.tip_id = ot.id
			WHERE o.Occ = @occ1
		END
		ELSE
		BEGIN
			IF EXISTS (
					SELECT 1
					FROM dbo.Occ_Suppliers AS OS 
					WHERE occ_sup = @occ1
				)
				SELECT DISTINCT o.Occ
							  , o.address
							  , dbo.Fun_Initials(o.Occ) AS FIO
							  , o.STATUS_ID
							  , o.tip_id
							  , o.flat_id
							  , o.bldn_id
							  , b.street_id
							  , b.town_id
							  , tip_name = ot.name
							  , o.id_jku_gis
							  , o.TOTAL_SQ
				FROM dbo.VOcc AS o 
					JOIN dbo.Buildings AS b
						ON o.bldn_id = b.id
					JOIN dbo.Occupation_Types AS ot 
						ON b.tip_id = ot.id
					JOIN dbo.Occ_Suppliers AS OS 
						ON OS.Occ = o.Occ
				WHERE OS.occ_sup = @occ1

			ELSE
			BEGIN
				-- Возможно подставной лиц.счёт
				SELECT @occ1 = dbo.Fun_GetFalseOccIn(@occ1)
				GOTO LABEL1
			END

		END

	END
go

