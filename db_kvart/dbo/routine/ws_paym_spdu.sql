-- =============================================
-- Author:		Пузанов
-- Create date: 20.10.2008
-- Description:	
-- =============================================
CREATE       PROCEDURE [dbo].[ws_paym_spdu]
(
	@fin_id1	SMALLINT
	,@tip_str1	VARCHAR(2000) -- список типов фонда через запятую
	,@fin_id2	SMALLINT	= NULL
	,@xml1		VARCHAR(MAX)	= '' OUTPUT
	,@build_id1 INT = NULL
)
AS
/*
exec ws_paym_spdu 159,'27'
*/
BEGIN

	SET NOCOUNT ON;

	IF @fin_id2 IS NULL
		SET @fin_id2 = @fin_id1

	DECLARE @DB_NAME VARCHAR(20) = UPPER(DB_NAME())
	--************************************************************************************
	-- Таблица значениями Типа жил.фонда
	DECLARE @tip_table TABLE
		(
			tip_id SMALLINT DEFAULT NULL
		)

	INSERT
	INTO @tip_table
			SELECT CASE
                       WHEN value = 'Null' THEN NULL
                       ELSE value
                       END
			FROM STRING_SPLIT(@tip_str1, ',') WHERE RTRIM(value) <> ''

	IF EXISTS (SELECT
				1
			FROM @tip_table
			WHERE tip_id IS NULL)
	BEGIN  -- Заносим все типы жилого фонда
		DELETE FROM @tip_table
		INSERT
		INTO @tip_table
				SELECT
					id
				FROM dbo.VOCC_TYPES
	END

	-- Таблица значениями Типа жил.фонда
	DECLARE @sup_table TABLE
		(
			sup_id INT DEFAULT NULL
		)

	IF @DB_NAME = 'KVART'
		INSERT
		INTO @sup_table
		VALUES (316)

	--select * from @tip_table
	--************************************************************************************

	-- выбираем бывшие дома ГЖУ
	DECLARE @table_bldn TABLE
		(
			bldn_id INT PRIMARY KEY
		)
	INSERT
	INTO @table_bldn
			SELECT DISTINCT
				bldn_id
			FROM dbo.BUILDINGS_HISTORY bh
			WHERE EXISTS (SELECT
					1
				FROM @tip_table t
				WHERE t.tip_id = bh.tip_id)

		SELECT
			o.start_date
			,o.bldn_id
			,0 AS occ
			,p.service_id
			,p.mode_id -- код режима потребления
			,is_counter = 0
			,value = SUM(p.paymaccount - p.paymaccount_peny)
			,paymaccount_peny = SUM(p.paymaccount_peny)
		INTO #t
		FROM dbo.View_PAYM AS p
		JOIN dbo.View_OCC_ALL_LITE AS o
			ON p.occ = o.occ
			AND p.fin_id = o.fin_id
		LEFT JOIN @sup_table AS st
			ON p.sup_id = st.sup_id
		JOIN @tip_table AS t
			ON o.tip_id = t.tip_id
		JOIN @table_bldn AS tb
			ON tb.bldn_id = o.bldn_id
		WHERE o.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND (p.sup_id = 0
		OR st.sup_id > 0)
		AND (o.build_id=@build_id1 OR @build_id1 IS NULL)
		GROUP BY	o.start_date
					,o.bldn_id
					,p.service_id
					,p.mode_id
		HAVING SUM(p.paymaccount - p.paymaccount_peny) <> 0
		OR SUM(p.paymaccount_peny) <> 0
		--FOR XML RAW ('PAYM'), ROOT ('root'))

		-- 08/09/19 По кап.ремонту Оплату пени надо добавить к начислению
		UPDATE t SET Value=t.value+paymaccount_peny, PaymAccount_peny=0
		FROM #t AS t
		WHERE service_id='Крем'

	SET @xml1 = (SELECT
			*
		FROM #t
		FOR XML RAW ('PAYM'), ROOT ('root'))

	SELECT
		*
	FROM #t

END
go

