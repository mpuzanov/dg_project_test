-- =============================================
-- Author:		Пузанов
-- Create date: 20.10.2008
-- Description:	
-- =============================================
CREATE         PROCEDURE [dbo].[ws_paym_fin]
(
	  @fin_id1 SMALLINT
	, @tip_str1 VARCHAR(2000) -- список типов фонда через запятую
	, @max_rows INT = 1000
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

	SET @xml1 = (
		SELECT TOP (@max_rows) o.bldn_id
							 , ps.Occ
							 , ps.service_id
							 , pd.day
							 , ps.Value
							 , ps.PaymAccount_peny
		FROM dbo.Paydoc_packs AS pd
			JOIN dbo.Payings AS p ON pd.id = p.pack_id
			JOIN dbo.Paying_serv AS ps ON p.id = ps.paying_id
			JOIN dbo.View_occ_all AS o ON p.Occ = o.Occ
				AND pd.fin_id = o.fin_id
		WHERE pd.fin_id = @fin_id1
			AND EXISTS (
				SELECT 1
				FROM #tip_table
				WHERE tip_id = o.tip_id
			)
			AND EXISTS (
				SELECT 1
				FROM @table_bldn
				WHERE bldn_id = o.bldn_id
			)
		ORDER BY ps.Occ
		FOR XML RAW ('PAYM'), ROOT ('root')
	)
	SELECT @xml1 AS xml1

END
go

