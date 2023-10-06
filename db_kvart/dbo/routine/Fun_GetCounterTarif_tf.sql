-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       FUNCTION [dbo].[Fun_GetCounterTarif_tf]
(
	@fin_id				SMALLINT
	,@counter_id		INT
	,@inspector_date	SMALLDATETIME	= NULL	
	,@fin_id_insp		SMALLINT		= NULL
	,@mode_id			INT				= NULL
	,@source_id			INT				= NULL
)
RETURNS @tbl TABLE
(
t1 DECIMAL(9,2) default 0
,t2 DECIMAL(9,2) default 0
,t3 DECIMAL(9,2) default 0
)
AS
/*
select * from Fun_GetCounterTarif_tf(254,100729,'20230315',254,null,null)
select * from Fun_GetCounterTarif_tf(254,100729,'20230315', 254, 11001, 11013)
*/
BEGIN
	DECLARE	@fin_id1				SMALLINT
			,@tarif					DECIMAL(10, 4) = 0
			,@extr_tarif			DECIMAL(9,2) = 0
			,@full_tarif			DECIMAL(9,2) = 0
			,@tip_id				SMALLINT
			,@unit_id				VARCHAR(10)
			,@service_id			VARCHAR(10)
			,@build_id				INT
			,@fin_current			SMALLINT
			,@is_counter_cur_tarif	BIT
			
	-- запоминаем параметры счетчика
	SELECT
		@unit_id = c.unit_id
		,@service_id = c.service_id
		,@build_id = build_id
		,@fin_current = b.fin_current
		,@tip_id = b.tip_id
	FROM dbo.Counters AS c
	JOIN dbo.Buildings b
		ON c.build_id = b.id
	WHERE c.id = @counter_id
	
	SET @fin_id_insp = COALESCE(@fin_id_insp, @fin_current)

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

	--IF (@source_id % 1000 = 0) OR (@mode_id % 1000 = 0) -- режимы не заданы
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
		BEGIN -- пробуем текущие режимы
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

			-- Если поставщика на лиц.счёте нет тарифы будут 0
			IF @source_id IS NULL
			BEGIN
				INSERT INTO @tbl(t1,t2,t3) VALUES(0,0,0)
				RETURN
			END
		END
	END	--IF (@source_id%1000=0) OR (@mode_id%1000=0)
	--============================================================================
		
	if @mode_id>0 AND (@mode_id % 1000 = 0)  -- если режим Нет то тарифа не будет  15.05.2023
	BEGIN
		INSERT INTO @tbl(t1,t2,t3) VALUES(0,0,0)
		RETURN
	END

	SELECT
		@tarif = COALESCE(tarif, 0)
		,@extr_tarif = COALESCE(extr_tarif, 0)
		,@full_tarif = COALESCE(full_tarif, 0)
	FROM [dbo].[Rates_counter] 
	WHERE fin_id = @fin_id1
		AND tipe_id = @tip_id
		AND service_id = @service_id
		AND unit_id = @unit_id
		AND (mode_id = @mode_id	OR mode_id = 0)
		AND (source_id = @source_id	OR source_id = 0)
		AND tarif > 0

	IF @tarif = 0
	BEGIN
		SELECT TOP (1)
			@tarif = COALESCE(tarif, 0)
			,@extr_tarif = COALESCE(extr_tarif, 0)
			,@full_tarif = COALESCE(full_tarif, 0)
		FROM dbo.Rates_counter 
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
			,@extr_tarif = COALESCE(extr_tarif, 0)
			,@full_tarif = COALESCE(full_tarif, 0)
		FROM [dbo].[Rates_counter] 
		WHERE fin_id = @fin_current
			AND tipe_id = @tip_id
			AND service_id = @service_id
			AND unit_id = @unit_id
			AND tarif > 0
		ORDER BY tarif DESC
	END

	INSERT INTO @tbl(t1,t2,t3) values( COALESCE(@tarif,0), COALESCE(@extr_tarif,0),  COALESCE(@full_tarif,0))

	RETURN
END
go

