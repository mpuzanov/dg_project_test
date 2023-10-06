CREATE   PROCEDURE [dbo].[rep_rates_schtl_counter]
(
	@occ		INT
	,@fin_id1	SMALLINT
	,@debug		BIT = NULL
)
AS
	/*
	  Список тарифов по счетчикам по заданному лицевому счету
	
	rep_rates_schtl_counter @occ=102828, @fin_id1=245, @debug=0

	*/

	SET NOCOUNT ON

	DECLARE	@status_id		VARCHAR(10)
			,@proptype_id1	VARCHAR(10)
			,@tipe_id1		SMALLINT
			,@fin_current	SMALLINT
			,@address		VARCHAR(100)

	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ)

	-- Находим статус квартиры и тип фонда за тот месяц
	SELECT
		@status_id = status_id
		,@proptype_id1 = proptype_id
		,@tipe_id1 = tip_id
		,@address = o.[address]
	FROM dbo.View_OCC_ALL_LITE o
	WHERE occ = @occ
		AND fin_id = @fin_id1


	DECLARE @t TABLE
		(
			service_id	VARCHAR(10)
			,source_id	INT
			,mode_id	INT
			,unit_id	VARCHAR(10)
		)

	-- определяем режимы ========================================================
	INSERT INTO @t
	(	service_id
		,source_id
		,mode_id
		,unit_id)
			SELECT
				ch.service_id
				,ch.source_id AS source_id
				,ch.mode_id AS mode_id
				,clh.unit_id
			FROM dbo.View_COUNTER_ALL AS clh 
			LEFT JOIN dbo.View_CONSMODES_LITE AS ch
				ON clh.fin_id = ch.fin_id
				AND clh.service_id = ch.service_id
				AND clh.occ = ch.occ
			WHERE clh.occ = @occ
			AND clh.fin_id = @fin_id1
	--AND (ch.MODE_ID % 1000) != 0

	-- если режимов в истории нет пробуем текущие
		INSERT INTO @t
		(	service_id
			,source_id
			,mode_id
			,unit_id)
				SELECT
					ch.service_id
					,ch.source_id AS source_id
					,ch.mode_id AS mode_id
					,c.unit_id
				FROM dbo.COUNTER_LIST_ALL AS clh 
				LEFT JOIN dbo.CONSMODES_LIST AS ch
					ON clh.service_id = ch.service_id
					AND clh.occ = ch.occ
				JOIN dbo.COUNTERS AS c
					ON clh.counter_id = c.id
				WHERE clh.occ = @occ
					AND clh.fin_id = @fin_current
					AND NOT EXISTS(SELECT * from @t AS t WHERE t.mode_id=ch.mode_id OR t.source_id=ch.source_id)
	

		INSERT INTO @t
		(	service_id
			,source_id
			,mode_id
			,unit_id)
				SELECT
					c.service_id
					,ch.source_id AS source_id
					,c.mode_id AS mode_id
					,c.unit_id
				FROM dbo.COUNTER_LIST_ALL AS clh
				JOIN dbo.COUNTERS AS c
					ON clh.counter_id = c.id
				LEFT JOIN dbo.CONSMODES_LIST AS ch
					ON clh.service_id = ch.service_id
					AND clh.occ = ch.occ
				WHERE clh.occ = @occ
					AND clh.fin_id = @fin_id1
					AND c.mode_id>0
					AND NOT EXISTS(SELECT * from @t AS t 
					WHERE t.service_id=c.service_id AND t.mode_id=c.mode_id AND t.source_id=ch.source_id AND t.unit_id=c.unit_id)

	--============================================================================

	IF @debug=1
		select * from @t    

	SELECT DISTINCT
		@address AS [address]
		,ot.name AS tip_name
		,s.short_name
		,cm.name AS mode_name
		,sup.name AS source_name
		,r.unit_id
		,r.tarif
		,r.*
	FROM [dbo].[RATES_COUNTER] AS r
	--JOIN @t AS t ON (r.mode_id=t.mode_id or r.mode_id=0) AND r.source_id=t.source_id 
	LEFT JOIN @t AS t
		ON r.mode_id = t.mode_id
		AND r.source_id = t.source_id
		AND r.service_id = t.service_id
		AND r.unit_id = t.unit_id
	JOIN dbo.View_SERVICES AS s 
		ON t.service_id = s.id
	JOIN dbo.CONS_MODES cm 
		ON t.mode_id = cm.id
	JOIN dbo.View_SUPPLIERS AS sup 
		ON t.source_id = sup.id
	JOIN dbo.VOCC_TYPES AS ot 
		ON r.tipe_id = ot.id
	WHERE r.fin_id = @fin_id1
	AND r.tipe_id = @tipe_id1
go

