-- =============================================
-- Author:		Пузанов
-- Create date: 2.05.2010
-- Description:	Возвращаем тариф по счетчику

-- dbo.Fun_GetCounterTarf(@fin_id, @counter_id, null)
-- =============================================
CREATE             FUNCTION [dbo].[Fun_GetCounterTarifMode]
(
	@fin_id				SMALLINT
	,@counter_id		INT
	,@inspector_date	SMALLDATETIME	= NULL
	,@mode_id_counter	INT				= NULL
	,@fin_id_insp		SMALLINT		= NULL
)
RETURNS DECIMAL(10, 4)
AS
/*
select [dbo].[Fun_GetCounterTarifMode](@fin_id,@counter_id,@inspector_date,@mode_id_counter,@fin_id_insp)
select [dbo].[Fun_GetCounterTarifMode](137,29126,'20130617',NULL,137)
select [dbo].[Fun_GetCounterTarifMode](145,55180,NULL,NULL,NULL)
select [dbo].[Fun_GetCounterTarifMode](167,120687,NULL,NULL,NULL)
*/
BEGIN
	DECLARE	@fin_id1				SMALLINT
			,@tarif					DECIMAL(10, 4)	= 0
			,@tip_id				SMALLINT
			,@unit_id				VARCHAR(10)
			,@mode_id				INT = @mode_id_counter
			,@source_id				INT
			,@service_id			VARCHAR(10)
			,@build_id				INT
			,@fin_current			SMALLINT
			,@is_counter_cur_tarif	BIT
			,@tip_current			SMALLINT

	-- запоминаем параметры счетчика
	SELECT
		@unit_id = c.unit_id
		,@service_id = c.service_id
		,@build_id = build_id
		,@fin_current = b.fin_current
		,@tip_current = b.tip_id
	FROM dbo.Counters AS c 
	JOIN dbo.Buildings b
		ON c.build_id = b.id
	WHERE c.id = @counter_id

	IF @fin_id_insp IS NULL
		SET @fin_id_insp = @fin_current

	-- получаем тип жилого фонда за определенный период
	SELECT
		@tip_id = t.tip_id
	FROM (SELECT
			b.fin_current AS fin_id
			,b.tip_id
		FROM Buildings b
		WHERE b.id = @build_id
		UNION ALL
		SELECT
			bh.fin_id AS fin_id
			,bh.tip_id
		FROM Buildings_history bh
		WHERE bh.bldn_id = @build_id
		AND bh.fin_id = @fin_id) AS t
	WHERE t.fin_id = @fin_id

	IF @tip_id IS NULL
		SET @tip_id = @tip_current

	IF @fin_id_insp >= @fin_current
	BEGIN
		SELECT
			@is_counter_cur_tarif = COALESCE(is_counter_cur_tarif, 0)
		FROM dbo.Occupation_Types AS OT 
		WHERE id = @tip_id
	END
	ELSE
	BEGIN
		SELECT
			@is_counter_cur_tarif = COALESCE(is_counter_cur_tarif, 0)
		FROM dbo.Occupation_Types_History AS OTH 
		WHERE id = @tip_id
		AND fin_id = @fin_id_insp
	END

	IF @inspector_date IS NOT NULL
	BEGIN -- Находим фин.период когда сняли показание
		SELECT
			@fin_id1 = g.fin_id
		FROM dbo.Global_values AS g
		WHERE @inspector_date BETWEEN g.start_date AND g.end_date
	END
	ELSE
		SET @fin_id1 = @fin_id

	IF @is_counter_cur_tarif = 1
		AND @fin_id_insp = @fin_current
		SELECT
			@fin_id1 = @fin_id_insp
			,@tip_id = @tip_current

	-- определяем режимы ========================================================
	IF (@source_id IS NULL) OR (@mode_id IS NULL) -- режимы не заданы
	BEGIN -- определяем режимы ========================================================
		IF @fin_id1 < @fin_current
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
		ELSE
		-- пробуем текущие
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


	IF @inspector_date IS NOT NULL
		AND @tarif = 0
	BEGIN
		SELECT
			@tarif = dbo.Fun_GetCounterTarf(@fin_id, @counter_id, @inspector_date) --null)
	END

	IF @tarif = 0
	BEGIN
		SELECT TOP (1)
			@tarif = COALESCE(tarif, 0)
		FROM [dbo].[Rates_counter] 
		WHERE fin_id = @fin_id1
			AND tipe_id = @tip_id
			AND service_id = @service_id
			AND unit_id = @unit_id
			AND tarif > 0
		ORDER BY tarif DESC
	END

	IF @tarif = 0
	BEGIN
		SELECT TOP (1)
			@tarif = COALESCE(tarif, 0)
		FROM [dbo].[Rates_counter] 
		WHERE fin_id = @fin_current
			AND tipe_id = @tip_id
			AND service_id = @service_id
			AND unit_id = @unit_id
			AND tarif > 0
		ORDER BY tarif DESC
	END

	RETURN COALESCE(@tarif, 0)

END
go

