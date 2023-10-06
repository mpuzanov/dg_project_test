-- =============================================
-- Author:		Пузанов
-- Create date: 14.04.2013
-- Description:	Выдаем нормы по услугам в квитанции на заданном лицевом счете
-- =============================================
CREATE       PROCEDURE [dbo].[k_intPrintNorma]
	@fin_id		SMALLINT
	,@occ		INT
	,@sup_id	INT	= NULL
	,@all		BIT	= 0
	,@debug		BIT	= NULL

AS
/*
Устарела

exec k_intPrintNorma 166,341228,null,0,0
exec k_intPrintNorma 166,341228,null
exec k_intPrintNorma 143,910000723,null
exec k_intPrintNorma 161,700003308,null
exec k_intPrintNorma 144,700040061,null,1
exec k_intPrintNorma 174,322217,null,1,1

*/
BEGIN

EXECUTE [dbo].[k_intPrintNorma2] 
   @fin_id
  ,@occ
  ,@sup_id
  ,@all
  ,@debug
RETURN


	SET NOCOUNT ON;

	IF @occ IS NULL
		SELECT
			@occ = 0
			,@fin_id = 0

	SELECT
		@occ = dbo.Fun_GetFalseOccIn(@occ)

	IF @sup_id IS NULL
		SET @sup_id = 0
	IF @all IS NULL
		SET @all = 0
	DECLARE @t TABLE
		(
			serv_name	VARCHAR(20)
			,unit_id	CHAR(8)
			,kol_norma	DECIMAL(12, 6)
			,value		DECIMAL(9, 2)
			,sup_id		INT DEFAULT 0
		)
	IF @occ = 0
		AND @fin_id = 0
		AND @sup_id = 0
	BEGIN
		SELECT
			*
		FROM @t
		RETURN
	END

	DECLARE	@tip_id		SMALLINT
			,@build_id	INT
	SELECT
		@tip_id = tip_id
		,@build_id = bldn_id
	FROM dbo.View_OCC_ALL_LITE 
	WHERE occ = @occ
	AND fin_id = @fin_id

	INSERT
	INTO @t
		SELECT
			CASE
					WHEN vp.[service_id] IN ('гвод', 'гвс2') THEN 'Гвс'
					WHEN vp.[service_id] IN ('хвод', 'хвс2') THEN 'Хвс'
					WHEN vp.[service_id] IN ('элек', 'эле2') THEN 'Элек'
					WHEN vp.[service_id] IN ('Эдом', 'элмп') THEN 'Эл.МОП'
					WHEN vp.[service_id] IN ('отоп', 'ото2') THEN 'Отоп'
					WHEN vp.[service_id] IN ('вотв', 'вот2') THEN 'Водоотв'
					WHEN vp.[service_id] IN ('гвсд', 'гв2д', 'гв3д') THEN 'Гвс одн'
					WHEN vp.[service_id] IN ('хвсд', 'хв2д', 'хв3д') THEN 'Хвс одн'
					WHEN vp.[service_id] IN ('тепл') THEN 'Гвс нагр'
					WHEN vp.[service_id] IN ('гвпк', 'гпк2') THEN 'Гвс пк'
					WHEN vp.[service_id] in ('хвпк','хпк2') THEN 'Хвс пк'
					WHEN vp.[service_id] in ('одхж') THEN 'Хв для сод.о.и'
					WHEN vp.[service_id] in ('одгж') THEN 'Гв для сод.о.и'
					WHEN vp.[service_id] in ('одэж') THEN 'Ээ для сод.о.и'
					WHEN vp.[service_id] in ('втбо') THEN 'ТКО'
					ELSE vp.[service_id]
				END	AS serv_name
			,CASE
					WHEN (u.short_id = 'м3' AND
					vp.is_build = 0) THEN 'м3/чел'
					WHEN (vp.[service_id] = 'тепл') THEN 'ГКал/м3'
					ELSE u.short_id
			END AS unit_id
			,mu.q_single as kol_norma --dbo.Fun_GetNormaSingle(vp.unit_id,vca.mode_id,0,voa.tip_id)
			,vp.value
			,COALESCE(vp.sup_id, 0)
		FROM dbo.View_PAYM AS vp 
		JOIN dbo.SERVICES AS S 
			ON vp.service_id = S.id
		JOIN dbo.MEASUREMENT_UNITS AS mu 
			ON mu.fin_id = vp.fin_id
			AND mu.unit_id = vp.unit_id
			AND mu.mode_id = vp.mode_id
			AND mu.tip_id = @tip_id
			AND mu.is_counter =
				CASE
					WHEN (vp.service_id = 'гвс2') THEN 1
					ELSE 0
				END
		JOIN dbo.UNITS AS u 
			ON vp.unit_id = u.id
		WHERE vp.fin_id = @fin_id
		AND vp.occ = @occ
		AND (S.service_type = 2
		OR vp.is_build = 1
		OR s.id IN ('одхж','одгж','одэж'))
		--AND ((@all = 0
		----AND COALESCE(vp.sup_id, 0) = COALESCE(@sup_id, COALESCE(vp.sup_id, 0))
		--OR (@all = 1)))
		ORDER BY S.service_no

	IF @debug = 1
		SELECT
			*
		FROM @t

	
	--UPDATE t1
	--SET kol_norma =
	--	CASE
	--		WHEN t1.serv_name = 'Хвс' THEN t1.kol_norma + COALESCE((SELECT
	--				SUM(t2.kol_norma)
	--			FROM @t t2
	--			WHERE t2.serv_name in ('хвпк','хпк2') AND t2.VALUE>0 )
	--		, 0)
	--		WHEN serv_name = 'Гвс' THEN t1.kol_norma + COALESCE((SELECT
	--				t2.kol_norma
	--			FROM @t t2
	--			WHERE t2.serv_name = 'гвпк')
	--		, 0)
	--		WHEN serv_name = 'Хвс одн' THEN t1.kol_norma + COALESCE((SELECT
	--				t2.kol_norma
	--			FROM @t t2
	--			WHERE t2.serv_name = 'хдпк')
	--		, 0)
	--		WHEN serv_name = 'Гвс одн' THEN t1.kol_norma + COALESCE((SELECT
	--				t2.kol_norma
	--			FROM @t t2
	--			WHERE t2.serv_name = 'гдпк')
	--		, 0)
	--		WHEN (serv_name = 'Водоотв') AND (kol_norma=0) THEN 
	--			COALESCE((SELECT
	--				SUM(t2.kol_norma)
	--			FROM @t t2
	--			WHERE t2.serv_name IN ('гвпк','хвпк','хпк2', 'Хвс', 'Гвс')  --('вопк', 'Хвс', 'Гвс')
	--			),0)
	--		WHEN (serv_name = 'Водоотв') THEN t1.kol_norma + COALESCE((SELECT
	--				SUM(t2.kol_norma)
	--			FROM @t t2
	--			WHERE t2.serv_name in ('вопк') AND t2.VALUE>0)
	--		, 0)
	--		ELSE t1.kol_norma
	--	END
	--FROM @t t1

	--DELETE FROM @t
	--WHERE serv_name IN ('хвпк','хпк2', 'гвпк', 'хдпк', 'гдпк', 'вопк')
	--	OR value = 0

	DELETE FROM @t WHERE value = 0	--AND serv_name NOT IN ('гвс')

	UPDATE t
	SET kol_norma =
		CASE
			WHEN t.serv_name = 'Отоп' AND
			t2.norma_gkal > 0 THEN t2.norma_gkal
			WHEN t.serv_name = 'Гвс нагр' AND
			t2.norma_gkal_gvs > 0 THEN t2.norma_gkal_gvs
			ELSE kol_norma
		END
	FROM @t AS t
	CROSS APPLY (SELECT
			norma_gkal
			,norma_gkal_gvs
		FROM dbo.View_BUILD_ALL_LITE AS vba 
		WHERE vba.fin_id = @fin_id
		AND vba.bldn_id = @build_id) AS t2
	WHERE t.serv_name IN ('Отоп', 'Гвс нагр')

	SELECT
		serv_name
		,unit_id
		,kol_norma
	FROM @t
	WHERE kol_norma > 0
	AND ((@all = 0 AND sup_id = COALESCE(@sup_id,0)) OR (@all = 1)) 
	ORDER BY serv_name

END
go

