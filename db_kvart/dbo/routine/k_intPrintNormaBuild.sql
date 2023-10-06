-- =============================================
-- Author:		Пузанов
-- Create date: 14.04.2013
-- Description:	Выдаем нормы по услугам в квитанции в заданном доме по лицевым счетам
-- =============================================
CREATE             PROCEDURE [dbo].[k_intPrintNormaBuild]
	  @fin_id SMALLINT
	, @build_id INT
	, @occ INT = NULL
	, @sup_id INT = NULL
	, @all BIT = 0
	, @debug BIT = NULL

AS
/*
exec k_intPrintNormaBuild @fin_id=230,@build_id=6785,@occ=null,@sup_id=null,@all=1,@debug=0
exec k_intPrintNormaBuild @fin_id=230,@build_id=6785,@occ=31008,@sup_id=null,@all=1,@debug=1

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @db_name VARCHAR(20) = UPPER(DB_NAME())

	IF @build_id IS NULL
		SELECT @build_id = 0
			 , @fin_id = 0

	SELECT @occ = dbo.Fun_GetFalseOccIn(@occ)

	IF @sup_id IS NULL
		SET @sup_id = 0
	IF @all IS NULL
		SET @all = 0

	CREATE TABLE #t (
		  occ INT
		, service_id VARCHAR(10) COLLATE database_default
		, tip_id SMALLINT
		, serv_name VARCHAR(30) COLLATE database_default
		, unit_id CHAR(8) COLLATE database_default
		, kol_norma DECIMAL(12, 6)
		, value DECIMAL(9, 2)
		, sup_id INT DEFAULT 0
		, kol_norma2 DECIMAL(12, 6) DEFAULT NULL
		, service_name_gis NVARCHAR(50) COLLATE database_default DEFAULT NULL
		, source_id INT DEFAULT NULL
		, mode_id INT DEFAULT NULL
		, tarif DECIMAL(10, 4) DEFAULT NULL
		, blocked_norma_kvit BIT DEFAULT 0
	)
	IF @occ = 0
		AND @fin_id = 0
		AND @sup_id = 0
	BEGIN
		SELECT *
		FROM #t
		RETURN
	END

	INSERT INTO #t
	SELECT vp.occ
		 , vp.[service_id]
		 , o.tip_id
		 , CASE
			   WHEN vp.[service_id] IN ('гвод', 'гвс2') THEN 'Гвс'
			   WHEN vp.[service_id] IN ('хвод', 'хвс2') THEN 'Хвс'
			   WHEN vp.[service_id] IN ('элек', 'эле2') THEN 'Элек'  -- по элек другая таблица с нормативами (не будем показывать)
			   WHEN vp.[service_id] IN ('Эдом', 'элмп') THEN 'Эл.МОП'
			   WHEN vp.[service_id] IN ('отоп', 'ото2') THEN 'Отоп'
			   WHEN vp.[service_id] IN ('вотв', 'вот2') THEN 'Водоотв'
			   WHEN vp.[service_id] IN ('гвсд', 'гв2д', 'гв3д') THEN 'Гвс одн'
			   WHEN vp.[service_id] IN ('хвсд', 'хв2д', 'хв3д') THEN 'Хвс одн'
			   WHEN vp.[service_id] IN ('тепл') THEN 'Гвс нагр'
			   WHEN vp.[service_id] IN ('гГВС') THEN 'Газ для гвс'
			   WHEN vp.[service_id] IN ('гвпк', 'гпк2') THEN 'Гвс пк'
			   WHEN vp.[service_id] IN ('хвпк', 'хпк2') THEN 'Хвс пк'
			   WHEN vp.[service_id] IN ('одхж') THEN 'Хв для сод.о.и'
			   WHEN vp.[service_id] IN ('одгж') THEN 'Гв для сод.о.и'
			   WHEN vp.[service_id] IN ('одэж') THEN 'Ээ для сод.о.и'
			   WHEN vp.[service_id] IN ('одвж') THEN 'Отв.ст.в. сои'
			   WHEN vp.[service_id] IN ('одхг') THEN 'ХВ для ГВ сои'
			   WHEN vp.[service_id] IN ('одтж') THEN 'ТЭ для ГВ сои'			   
			   WHEN u.short_id = 'тонн' THEN 'ТКО'
			   ELSE vp.[service_id]
		   END AS serv_name
		 , CASE
			   WHEN (u.short_id = 'м3' AND vp.is_build = 0) THEN 'м3/чел'
			   WHEN (vp.[service_id] = 'тепл') THEN 'ГКал/м3'
			   WHEN (u.short_id = 'тонн') THEN 'тонн/чел'
			   WHEN vp.[service_id]='отоп' THEN 'ГКал'
			   ELSE u.short_id
		   END AS unit_id
		 , COALESCE(mu.q_single, 0) AS kol_norma --dbo.Fun_GetNormaSingle(vp.unit_id,vca.mode_id,0,voa.tip_id)
		 , vp.value
		 , COALESCE(vp.sup_id, 0) AS sup_id
		 , vp.kol_norma_single AS kol_norma2
		 , LTRIM(RTRIM(st.service_name_gis)) AS service_name_gis
		 , vp.source_id
		 , vp.mode_id
		 , vp.tarif
		 , CASE WHEN(st.blocked_norma_kvit=1 OR sb.blocked_norma_kvit=1) THEN 1 ELSE 0 END  AS blocked_norma_kvit
	FROM dbo.View_paym AS vp
		JOIN dbo.Occupations o ON vp.Occ = o.Occ
		JOIN dbo.Services AS S ON vp.service_id = S.id
		JOIN dbo.Units AS u  ON vp.unit_id = u.id
		LEFT JOIN dbo.Measurement_units AS mu ON mu.fin_id = vp.fin_id
			AND mu.unit_id = vp.unit_id
			AND mu.mode_id = vp.mode_id
			AND mu.tip_id = o.tip_id
			AND mu.is_counter = CASE WHEN(vp.service_id = 'гвс2') THEN 1 ELSE 0 END
		LEFT JOIN dbo.Services_types st 
			ON o.tip_id=st.tip_id AND vp.service_id=st.service_id
		LEFT JOIN dbo.Services_build sb
			ON sb.service_id=vp.service_id AND sb.build_id=vp.build_id
	WHERE vp.fin_id = @fin_id
		AND (@build_id IS NULL OR vp.build_id = @build_id)
		AND (@occ IS NULL OR vp.occ = @occ)
		AND (S.service_type = 2 OR vp.is_build = 1 OR S.id IN ('одхж', 'одгж', 'одэж', 'одвж', 'одхг', 'одтж'))
		AND vp.[service_id] NOT IN ('элек', 'эле2') -- по элек другая таблица с нормативами (не будем показывать)
	--AND ((@all = 0
	----AND COALESCE(vp.sup_id, 0) = COALESCE(@sup_id, COALESCE(vp.sup_id, 0))
	--OR (@all = 1)))
	ORDER BY S.service_no

	--UPDATE t
	--SET service_name_gis = LTRIM(RTRIM(st.service_name_gis))
	--FROM #t AS t
	--	JOIN dbo.Services_types AS st ON t.service_id = st.service_id
	--WHERE st.tip_id = @tip_id

	IF @debug = 1
	BEGIN
		SELECT '1'
			 , *
		FROM #t
	END

	--IF @db_name IN ('KR1', 'ARX_KR1')
	--	DELETE FROM #t
	--	WHERE tarif = 0
	--		OR value = 0
	--ELSE
	DELETE FROM #t
	WHERE tarif = 0
		OR (value = 0
		AND (mode_id % 1000 = 0)
		OR (source_id % 1000 = 0)
		)
		OR blocked_norma_kvit=1

	IF @debug = 1
		SELECT '2'
			 , *
		FROM #t

	UPDATE t
	SET kol_norma =
				   CASE
					   WHEN t.serv_name = 'Отоп' AND
						   t2.norma_gkal > 0 THEN t2.norma_gkal -- значение норматива по дому
					   WHEN t.serv_name = 'Отоп' AND
						   kol_norma = 0 AND
						   gb.NormaGKAL > 0 THEN gb.NormaGKAL -- глобальное значение норматива
					   WHEN t.serv_name = 'Гвс нагр' AND
						   t2.norma_gkal_gvs > 0 THEN t2.norma_gkal_gvs
					   ELSE kol_norma
				   END
	FROM #t AS t
		CROSS APPLY (
			SELECT NormaGKAL
			FROM dbo.Global_values
			WHERE fin_id = @fin_id
		) AS gb
		CROSS APPLY (
			SELECT norma_gkal
				 , norma_gkal_gvs
			FROM dbo.View_build_all_lite AS vba
			WHERE vba.fin_id = @fin_id
				AND vba.bldn_id = @build_id
		) AS t2
	WHERE t.serv_name IN ('Отоп', 'Гвс нагр')

	SELECT DISTINCT occ
				  , serv_name
				  , unit_id
				  , CASE
						WHEN unit_id = 'квтч' AND kol_norma>0  THEN kol_norma
						WHEN service_id IN ('отоп', 'одэж') AND (kol_norma=0) AND (kol_norma2>0) THEN kol_norma2
						WHEN service_id IN ('отоп', 'одэж') THEN kol_norma
						WHEN COALESCE(kol_norma2, 0) = 0 THEN kol_norma
						ELSE kol_norma2
					END
					AS kol_norma
				  , service_name_gis
	--,sup_id
	FROM #t
	WHERE (kol_norma > 0 OR kol_norma2 > 0)
		AND ((@all = 0 AND sup_id = COALESCE(@sup_id, 0)) OR (@all = 1))
	ORDER BY occ
		   , serv_name

END
go

