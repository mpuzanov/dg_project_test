CREATE   PROCEDURE [dbo].[k_show_koef]
(
	@occ1		 INT
   ,@service_id1 VARCHAR(10)
   ,@is_build1	 BIT = 0
)
AS
	/*
	EXEC k_show_koef @occ1=6122751, @service_id1='наем'
	EXEC k_show_koef @occ1=6122751, @service_id1='наем',@is_build1=1
	*/
	SET NOCOUNT ON

	IF @is_build1 IS NULL
		SET @is_build1 = 0

	IF @is_build1=0
	BEGIN
		IF NOT EXISTS (SELECT
					1
				FROM dbo.KOEF_OCC
				WHERE occ = @occ1
				AND service_id = @service_id1)
		BEGIN
			-- вставляем коэффициенты по умолчанию
			INSERT INTO KOEF_OCC
				SELECT DISTINCT
					@occ1
				   ,@service_id1
				   ,level1
				   ,NULL
				FROM dbo.KOEF
				WHERE service_id = @service_id1
				AND level2 != 0
				AND is_build = @is_build1
		END

		SELECT
			ko.occ
		   ,ko.service_id
		   ,k.name
		   ,ko.level1
		   ,ko.koef_id
		   ,value_name =(SELECT concat(k2.name,' /',LTRIM(STR(k2.value,6,4)), '/')
						From dbo.KOEF AS k2 WHERE ko.koef_id=k2.id)
		   ,NULL AS itog
		FROM dbo.KOEF_OCC AS ko
		JOIN dbo.KOEF AS k
			ON ko.service_id = k.service_id
			AND ko.level1 = k.level1
		WHERE ko.occ = @occ1
		AND ko.service_id = @service_id1
		AND k.level2 = 0
		AND k.is_use = 1
		AND k.is_build = 0

	END
	ELSE
	BEGIN
		DECLARE @build_id INT 
		SELECT @build_id=build_id From dbo.VOcc WHERE occ=@occ1

		SELECT @occ1 as occ
			  ,k.service_id			  			  
			  ,k.[name]
			  ,k.level1
			  ,NULL as koef_id
			  --,[level2]
			  -- надо получить текущее значение в уровне
			  ,CASE
				WHEN level1=10 THEN
					(SELECT TOP(1) concat(k2.name,' /',LTRIM(STR(k2.value,6,4)), '/')
					FROM dbo.Koef as k2
					JOIN dbo.Koef_build as kb2 ON kb2.service_id=k2.service_id AND k2.name=kb2.material
					WHERE kb2.service_id=k.service_id AND kb2.build_id=kb.build_id AND k2.level1 = k.level1
					)
				WHEN level1=9 THEN
					(SELECT TOP(1) concat(k2.name,' /',LTRIM(STR(k2.value,6,4)), '/')
					FROM dbo.Koef as k2
					JOIN dbo.Koef_build as kb2 ON kb2.service_id=k2.service_id AND k2.name=kb2.div_name
					WHERE kb2.service_id=k.service_id AND kb2.build_id=kb.build_id AND k2.level1 = k.level1
					)
				WHEN level1=12 THEN
					(SELECT TOP(1) concat(k2.name,' /',LTRIM(STR(k2.value,6,4)), '/')
					FROM dbo.Koef as k2
					JOIN dbo.Koef_build as kb2 ON kb2.service_id=k2.service_id AND k2.name=kb2.garbage
					WHERE kb2.service_id=k.service_id AND kb2.build_id=kb.build_id AND k2.level1 = k.level1
					)
				WHEN level1=11 THEN
					(SELECT TOP(1) concat(k2.name,' /',LTRIM(STR(k2.value,6,4)), '/')
					FROM dbo.Koef as k2
					JOIN dbo.Koef_build as kb2 ON kb2.service_id=k2.service_id AND k2.name=kb2.lift
					WHERE kb2.service_id=k.service_id AND kb2.build_id=kb.build_id AND k2.level1 = k.level1
					)
				WHEN level1=13 THEN
					(SELECT TOP(1) concat(k2.name,' /',LTRIM(STR(k2.value,6,4)), '/')
					FROM dbo.Koef as k2
					JOIN dbo.Koef_build as kb2 ON kb2.service_id=k2.service_id AND k2.name=kb2.central_heating
					WHERE kb2.service_id=k.service_id AND kb2.build_id=kb.build_id AND k2.level1 = k.level1
					)
			  ELSE ''
			  END AS value_name
			  ,kb.value AS itog
		  FROM dbo.Koef as k 
		  JOIN dbo.Koef_build as kb 
			ON kb.service_id=k.service_id
		  WHERE k.is_build=1
		  AND k.id_parent=0
		  AND k.is_use=1
		  AND kb.build_id=@build_id

	END
go

