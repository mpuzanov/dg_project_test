-- =============================================
-- Author:		Пузанов
-- Create date: 20.10.2008
-- Description:	
-- =============================================
CREATE       PROCEDURE [dbo].[ws_paym_fin2]
(
	@fin_id1	SMALLINT
	,@tip_str1	VARCHAR(2000) -- список типов фонда через запятую
	,@max_rows	INT	= 1000
	,@sup_id	INT	= NULL
)
AS
BEGIN

	SET NOCOUNT ON;

	--REGION Таблица со значениями Типа жил.фонда *********************
	DROP TABLE IF EXISTS #tip_table;
	CREATE TABLE #tip_table (tip_id SMALLINT PRIMARY KEY)
	INSERT INTO #tip_table(tip_id)
	select tip_id from dbo.fn_get_tips_tf(@tip_str1, NULL, NULL)
	--IF @debug = 1 SELECT * FROM #tip_table
	--ENDREGION ************************************************************

	-- выбираем бывшие дома ГЖУ
	DECLARE @table_bldn TABLE(bldn_id INT PRIMARY KEY)
	INSERT INTO @table_bldn
			SELECT DISTINCT
				bldn_id
			FROM dbo.BUILDINGS_HISTORY BH
			WHERE EXISTS (SELECT
					1
				FROM #tip_table AS t
				WHERE t.tip_id = BH.tip_id)

	-- оплата
	DECLARE @xml1 XML

	SET @xml1 = (SELECT TOP (@max_rows)
			o.bldn_id
			,0 AS occ
			,p.service_id
			,0 AS is_counter
			,SUM(p.paymaccount - p.paymaccount_peny) AS value
			,SUM(p.paymaccount_peny) AS paymaccount_peny
		FROM dbo.View_paym AS p
		JOIN dbo.View_occ_all AS o ON 
			p.occ = o.occ
			AND p.fin_id = o.fin_id
		WHERE 
			p.fin_id = @fin_id1
			AND EXISTS (SELECT
					1
				FROM #tip_table
				WHERE tip_id = o.tip_id)
			AND EXISTS (SELECT
					1
				FROM @table_bldn
				WHERE bldn_id = o.bldn_id)
			--AND p.account_one=0
			AND (
			p.sup_id = @sup_id
			OR (p.sup_id IS NULL AND @sup_id IS NULL)
			)
		GROUP BY	o.bldn_id
					,p.service_id
		HAVING SUM(p.paymaccount - p.paymaccount_peny) <> 0
		OR SUM(p.paymaccount_peny) <> 0
		FOR XML RAW ('PAYM'), ROOT ('root'))
	SELECT
		@xml1 AS xml1

END
go

