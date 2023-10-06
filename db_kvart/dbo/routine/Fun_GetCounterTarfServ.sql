-- =============================================
-- Author:		Пузанов
-- Create date: 2.05.2010
-- Description:	Возвращаем тариф по лицевому и услуге

-- select dbo.Fun_GetCounterTarfServ(@fin_id, @occ, @service_id, @unit_id)
-- 
-- =============================================
CREATE         FUNCTION [dbo].[Fun_GetCounterTarfServ]
(
	@fin_id			SMALLINT
	,@occ			INT
	,@service_id	VARCHAR(10)
	,@unit_id		VARCHAR(10)	= NULL
)
RETURNS DECIMAL(10, 4)
AS
BEGIN
	/*
	Пример использования
	SELECT [dbo].[Fun_GetCounterTarfServ] (109,40101,'вотв','кубм')
	select dbo.Fun_GetCounterTarfServ(113, 214386, 'элек', null)
	*/
	DECLARE	@tarif					DECIMAL(10, 4)	= 0
			,@tip_id				SMALLINT
			,@mode_id				INT
			,@source_id				INT
			,@build_id				INT
			,@fin_current			SMALLINT
			,@unit_occ				VARCHAR(10)
			,@is_counter_cur_tarif	BIT

	SELECT @is_counter_cur_tarif=coalesce(ot.is_counter_cur_tarif,0), @tip_id=o.tip_id, @fin_current =o.fin_id
	FROM dbo.OCCUPATIONS o
	JOIN dbo.OCCUPATION_TYPES ot
		ON o.tip_id=ot.id
	WHERE o.occ=@occ

	IF @is_counter_cur_tarif=1 SET @fin_id=@fin_current
	
	-- определяем режимы ========================================================
	IF @fin_id >= @fin_current
	BEGIN
		SELECT
			@source_id = ch.source_id
			,@mode_id = ch.mode_id
		FROM dbo.CONSMODES_LIST AS ch
		WHERE ch.occ = @occ
		AND ch.service_id = @service_id
		AND (ch.mode_id % 1000) != 0
	END
	ELSE
	BEGIN
		SELECT
			@source_id = ch.source_id
			,@mode_id = ch.mode_id
		FROM dbo.PAYM_HISTORY AS ch
		WHERE ch.occ = @occ
		AND ch.fin_id = @fin_id
		AND ch.service_id = @service_id
		AND (ch.mode_id % 1000) != 0

		-- если режимов в истории нет пробуем текущие
		IF @source_id IS NULL
			AND @mode_id IS NULL
		BEGIN
			SELECT
				@source_id = ch.source_id
				,@mode_id = ch.mode_id
			FROM dbo.CONSMODES_LIST AS ch
			WHERE ch.occ = @occ
			AND ch.service_id = @service_id
			AND (ch.mode_id % 1000) != 0

			-- Если поставщика на лиц.счёте нет тариф будет 0
			IF @source_id IS NULL
				RETURN 0
		END
	END

	--============================================================================
	IF @unit_id IS NULL
		SELECT
			@unit_id = unit_id
		FROM dbo.View_COUNTER_ALL_LITE
		WHERE fin_id = @fin_id
		AND occ = @occ
		AND service_id = @service_id


	SELECT TOP 1
		@tarif = COALESCE(tarif, 0)
	FROM [dbo].[RATES_COUNTER]
	WHERE fin_id = @fin_id
	AND tipe_id = @tip_id
	AND service_id = @service_id
	AND (unit_id = @unit_id OR @unit_id IS NULL)
	AND (mode_id = @mode_id) --OR mode_id=0)
	AND (source_id = @source_id)--OR source_id=0)
	AND tarif > 0

		
	RETURN COALESCE(@tarif,0)

END
go

