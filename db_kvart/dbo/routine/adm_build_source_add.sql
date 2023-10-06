-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[adm_build_source_add]
(
	@build_id1		INT
	,@service_id1	VARCHAR(10)
	,@source_id1	INT
	,@Add1			BIT	= 1   -- 1 - Добавить  ,   если 0 то убрать 
	,@rowafected	INT	= 0 OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE	@sup_name		VARCHAR(50)
			,@service_name	VARCHAR(100)
			,@adres			VARCHAR(100)
			,@msg			VARCHAR(400)
			,@source_no		INT
			,@mode_no		INT
			,@sup_id		INT

	SELECT
		@sup_name = name
		,@service_name = service_name
		,@sup_id = sup_id
	FROM dbo.View_SUPPLIERS
	WHERE id = @source_id1
	AND service_id = @service_id1

	SELECT
		@mode_no = id
	FROM dbo.CONS_MODES
	WHERE service_id = @service_id1
	AND (id % 1000) = 0

	SELECT
		@source_no = id
	FROM dbo.View_SUPPLIERS
	WHERE service_id = @service_id1
	AND (id % 1000) = 0

	IF @Add1 = 1
	BEGIN
		-- Добавить поставщика в дом
		IF NOT EXISTS (SELECT
					1
				FROM dbo.BUILD_SOURCE
				WHERE build_id = @build_id1
				AND service_id = @service_id1
				AND source_id = @source_id1)
			IF EXISTS (SELECT
						1
					FROM dbo.View_SUPPLIERS
					WHERE id = @source_id1
					AND service_id = @service_id1)
				INSERT INTO BUILD_SOURCE
				(	build_id
					,service_id
					,source_id)
				VALUES (@build_id1
						,@service_id1
						,@source_id1)


		-- добавляем на лицевые
		INSERT INTO dbo.CONSMODES_LIST
		(	occ
			,service_id
			,sup_id
			,mode_id
			,source_id
			,subsid_only
			,is_counter
			,account_one
			,fin_id)
				SELECT
					o.occ
					,@service_id1
					,@sup_id
					,@mode_no
					,@source_id1 --@source_no
					,0
					,0
					,0
					,b.fin_current
				FROM dbo.OCCUPATIONS AS o 
				JOIN dbo.SERVICES AS s
					ON s.id = @service_id1
				JOIN dbo.FLATS AS f
					ON o.flat_id = f.id
				JOIN dbo.Buildings AS b 
					ON f.bldn_id=b.id
				LEFT JOIN dbo.CONSMODES_LIST AS cl 
					ON o.occ = cl.occ
					AND s.id = cl.service_id
					AND cl.sup_id = @sup_id
				WHERE f.bldn_id = @build_id1
				AND cl.occ IS NULL
				AND o.STATUS_ID <> 'закр'
		SET @rowafected = @@rowcount
	END
	ELSE
	BEGIN
		DELETE cl
			FROM dbo.CONSMODES_LIST cl
			JOIN dbo.OCCUPATIONS AS o 
				ON cl.occ = o.occ
			JOIN dbo.FLATS AS f 
				ON o.flat_id = f.id
		WHERE f.bldn_id = @build_id1
			AND cl.service_id = @service_id1
			AND cl.sup_id = @sup_id
		SET @rowafected = @@rowcount

		DELETE FROM dbo.BUILD_SOURCE
		WHERE build_id = @build_id1
			AND service_id = @service_id1
			AND source_id = @source_id1
	END
END
go

