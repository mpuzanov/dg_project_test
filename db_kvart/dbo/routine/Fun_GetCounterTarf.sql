-- =============================================
-- Author:		Пузанов
-- Create date: 2.05.2010
-- Description:	Возвращаем тариф по счетчику

-- dbo.Fun_GetCounterTarf(@fin_id, @counter_id, null)
-- =============================================
CREATE             FUNCTION [dbo].[Fun_GetCounterTarf]
(
	@fin_id				SMALLINT
	,@counter_id		INT
	,@inspector_date	SMALLDATETIME	= NULL
)
RETURNS DECIMAL(10, 4)
AS
BEGIN
	DECLARE	@fin_id1				SMALLINT
			,@tarif					DECIMAL(10, 4)	= 0
			,@tip_id				SMALLINT
			,@unit_id				VARCHAR(10)
			,@mode_id				INT
			,@source_id				INT
			,@service_id			VARCHAR(10)
			,@build_id				INT
			,@flat_id				INT
			,@fin_current			SMALLINT
			,@is_counter_cur_tarif	BIT

	-- запоминаем параметры счетчика
	SELECT
		@unit_id = c.unit_id
		,@service_id = c.service_id
		,@build_id = build_id
		,@flat_id = c.flat_id
	FROM dbo.COUNTERS AS c 
	WHERE c.id = @counter_id

	-- получаем тип жилого фонда за определенный период
	SELECT
		@tip_id = tip_id
		,@is_counter_cur_tarif = COALESCE(is_counter_cur_tarif, 0)
	FROM dbo.View_BUILD_ALL_LITE 
	WHERE fin_id = @fin_id
	AND bldn_id = @build_id

	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip_id, @build_id, @flat_id, NULL)

	IF @tip_id IS NULL
		SELECT
			@tip_id = tip_id
		FROM dbo.BUILDINGS b 
		WHERE id = @build_id
		
	-- Перенёс ниже 07.01.2011
	IF @inspector_date IS NOT NULL
	BEGIN -- Находим фин.период когда сняли показание
		SELECT
			@fin_id1 = g.fin_id
		FROM dbo.GLOBAL_VALUES AS g
		WHERE @inspector_date BETWEEN g.start_date AND g.end_date
	END
	ELSE
		SET @fin_id1 = @fin_id

	IF @is_counter_cur_tarif = 1
		SET @fin_id1 = @fin_current


	-- определяем режимы ========================================================
	IF @fin_id1 >= @fin_current
	BEGIN
		SELECT TOP(1)
			@source_id = ch.source_id
			,@mode_id = ch.mode_id
		FROM dbo.Consmodes_list AS ch 
		JOIN dbo.Counter_list_all AS clh 
			ON clh.service_id = ch.service_id
			AND clh.occ = ch.occ
		WHERE clh.fin_id = @fin_id1
			AND clh.counter_id = @counter_id
			AND (ch.mode_id % 1000) != 0
			AND (ch.source_id % 1000) != 0
	END
	ELSE
	BEGIN
		SELECT TOP(1)
			@source_id = ch.source_id
			,@mode_id = ch.mode_id
		FROM dbo.Paym_history AS ch 
		JOIN dbo.Counter_list_all AS clh 
			ON clh.service_id = ch.service_id
			AND clh.occ = ch.occ
		WHERE ch.fin_id = @fin_id1
			AND clh.fin_id = @fin_id1
			AND clh.counter_id = @counter_id
			AND (ch.mode_id % 1000) != 0
			AND (ch.source_id % 1000) != 0

		-- если режимов в истории нет пробуем текущие
		IF @source_id IS NULL
			AND @mode_id IS NULL
		BEGIN
			SELECT TOP(1)
				@source_id = ch.source_id
				,@mode_id = ch.mode_id
			FROM dbo.Consmodes_list AS ch 
			JOIN dbo.Counter_list_all AS clh 
				ON clh.service_id = ch.service_id
				AND clh.occ = ch.occ
			WHERE clh.fin_id = @fin_id1
				AND clh.counter_id = @counter_id
				AND (ch.mode_id % 1000) != 0
			AND (ch.source_id % 1000) != 0

			-- Если поставщика на лиц.счёте нет тариф будет 0
			IF @source_id IS NULL
				RETURN 0
		END

	END
	--============================================================================
	if @mode_id>0 AND (@mode_id % 1000 = 0)  -- если режим Нет то тарифа не будет  15.05.2023
	BEGIN
		SET @tarif=0
		RETURN @tarif
	END

	SELECT
		@tarif = COALESCE(tarif, 0)
	FROM [dbo].[Rates_counter] 
	WHERE fin_id = @fin_id1
		AND tipe_id = @tip_id
		AND service_id = @service_id
		AND unit_id = @unit_id
		AND (mode_id = @mode_id	OR mode_id = 0)
		AND (source_id = @source_id	OR source_id = 0)
		AND tarif > 0
	OPTION(RECOMPILE)

	IF @tarif = 0
	BEGIN
		SELECT TOP 1
			@tarif = COALESCE(tarif, 0)
		FROM [dbo].[Rates_counter] 
		WHERE fin_id = @fin_id1
			AND tipe_id = @tip_id
			AND service_id = @service_id
			AND unit_id = @unit_id
			AND tarif > 0
		ORDER BY tarif DESC
	END

	IF @tarif IS NULL
		SET @tarif = 0

	RETURN @tarif

END
go

