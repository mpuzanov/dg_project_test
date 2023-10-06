-- =============================================
-- Author:		Пузанов
-- Create date: 13.01.2009
-- Description:	
-- =============================================
CREATE       PROCEDURE [dbo].[ws_discount_fin]
(
	@fin_id1	SMALLINT
	,@tip_str1	VARCHAR(2000) -- список типов фонда через запятую
	,@max_rows	INT			= 1000
	,@fin_id2	SMALLINT	= NULL
)
AS
BEGIN

	SET NOCOUNT ON;

	IF @fin_id2 IS NULL
		SET @fin_id2 = @fin_id1

	--************************************************************************************
	-- Таблица значениями Типа жил.фонда
	CREATE TABLE #tip_table (tip_id SMALLINT PRIMARY KEY)
	INSERT INTO #tip_table(tip_id)
	SELECT vs.id
	FROM dbo.VOcc_types AS vs
		OUTER APPLY STRING_SPLIT(@tip_str1, ',') AS t
	WHERE @tip_str1 IS NULL OR t.value=vs.id
	--select * from #tip_table
	--************************************************************************************

	-- выбираем бывшие дома ГЖУ
	DECLARE @table_bldn TABLE(bldn_id INT PRIMARY KEY)
	INSERT INTO @table_bldn
		SELECT DISTINCT
			bldn_id
		FROM dbo.Buildings_history bh
		WHERE fin_id BETWEEN @fin_id1 AND @fin_id2
			AND EXISTS(SELECT 1	FROM #tip_table as t WHERE t.tip_id=bh.tip_id)

	DECLARE @xml1 XML

	SET @xml1 = (SELECT TOP (@max_rows)
			o.start_date
			,f.bldn_id
			,o.occ
			,dr.lgotaall AS 'lgota'
			,dr.service_id
			,cl.mode_id
			,CAST(SUM(dr.Discount) AS DECIMAL(12, 2)) AS 'value'
		FROM dbo.View_PAYM_LGOTA_ALL AS dr 
		JOIN dbo.View_OCC_ALL AS o
			ON dr.occ = o.occ
			AND dr.fin_id = o.fin_id
		JOIN dbo.View_CONSMODES_ALL AS cl 
			ON dr.occ = cl.occ
			AND dr.service_id = cl.service_id
			AND dr.fin_id = cl.fin_id
		JOIN dbo.View_SERVICES AS s 
			ON dr.service_id = s.Id
		JOIN dbo.FLATS AS f 
			ON o.flat_id = f.Id
		WHERE dr.fin_id = @fin_id1
		AND o.status_id <> 'закр'
		AND EXISTS (SELECT
				1
			FROM #tip_table
			WHERE tip_id = o.tip_id)
		AND EXISTS (SELECT
				bldn_id
			FROM @table_bldn
			WHERE bldn_id = f.bldn_id)
		GROUP BY	o.start_date
					,f.bldn_id
					,o.occ
					,dr.lgotaall
					,dr.service_id
					,cl.mode_id
					,s.service_no
		ORDER BY f.bldn_id, o.occ, dr.lgotaall, s.service_no
		FOR XML RAW ('discount'), ROOT ('root'))
	SELECT
		@xml1 AS xml1

END
go

