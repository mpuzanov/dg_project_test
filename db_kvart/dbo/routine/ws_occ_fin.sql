-- =============================================
-- Author:		Пузанов
-- Create date: 20.10.2008
-- Description:	
-- =============================================
CREATE           PROCEDURE [dbo].[ws_occ_fin]
(
	@fin_id1	SMALLINT
	,@tip_str1	VARCHAR(2000) -- список типов фонда через запятую
	,@max_rows	INT			= 99999
	,@fin_id2	SMALLINT	= NULL
	,@build_id1 INT = NULL
)
AS
BEGIN

	SET NOCOUNT ON;


	IF @fin_id2 IS NULL
		SET @fin_id2 = @fin_id1

	IF @max_rows is NULL 
		SET @max_rows=999999

	--REGION Таблица со значениями Типа жил.фонда *********************
	DROP TABLE IF EXISTS #tip_table;
	CREATE TABLE #tip_table (tip_id SMALLINT PRIMARY KEY)
	INSERT INTO #tip_table(tip_id)
	select tip_id from dbo.fn_get_tips_tf(@tip_str1, NULL, NULL)
	--IF @debug = 1 SELECT * FROM #tip_table
	--ENDREGION ************************************************************

	-- выбираем бывшие дома ГЖУ
	DECLARE @table_bldn TABLE
		(
			bldn_id INT PRIMARY KEY
		)
	INSERT
	INTO @table_bldn
			SELECT DISTINCT
				bldn_id
			FROM dbo.BUILDINGS_HISTORY BH
			WHERE EXISTS (SELECT
					*
				FROM #tip_table AS t
				WHERE t.tip_id = BH.tip_id 
				AND bh.fin_id BETWEEN @fin_id1 AND @fin_id2)

	-- информация по лицевому
	DECLARE @xml1 XML

	SET @xml1 = (SELECT TOP (@max_rows)
			o.start_date
			,o.bldn_id
			,[occ]
			,[saldo]
			,[value]
			,[discount]
			,[added]
			,[paid]
			,[debt]
			,Penalty = [Penalty_value] + [Penalty_old_new]
			,[Whole_payment]
			,[paymaccount]  -- оплачено
			,[paymaccount_peny] -- из низ пени
		FROM dbo.View_occ_all AS o
		WHERE 
			fin_id BETWEEN @fin_id1 AND @fin_id2
			AND (o.build_id=@build_id1 OR @build_id1 IS NULL)
			AND o.STATUS_ID <> 'закр'
			AND EXISTS (SELECT
					1
				FROM #tip_table
				WHERE tip_id = o.tip_id)
			AND EXISTS (SELECT
					1
				FROM @table_bldn
				WHERE bldn_id = o.bldn_id)
			AND ([saldo] <> 0
			OR [value] <> 0
			OR [added] <> 0
			OR [paid] <> 0
			OR [debt] <> 0
			OR [paymaccount] <> 0
			OR [paymaccount_peny] <> 0
			OR ([Penalty_value] + [Penalty_old_new]) <> 0
			OR [Whole_payment] <> 0
		)
		FOR XML RAW ('OCC'), ROOT ('root'))

	SELECT
		@xml1 AS result_xml

END
go

