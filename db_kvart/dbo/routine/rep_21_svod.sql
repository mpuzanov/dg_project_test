CREATE   PROCEDURE [dbo].[rep_21_svod]
(
	@fin_id1	SMALLINT
	,@tip_str1	VARCHAR(2000) -- список типов фонда через запятую
	,@law_id	SMALLINT	= NULL
)
AS
/*
Предоставление льгот за ЖКУ (по шифрам льгот)

exec rep_21_svod 200, '1,2'

*/
	SET NOCOUNT ON


	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

	--************************************************************************************
	-- Таблица значениями Типа жил.фонда
	CREATE TABLE #tip_table (tip_id SMALLINT PRIMARY KEY)
	INSERT INTO #tip_table(tip_id)
	SELECT vs.id
	FROM dbo.VOcc_types AS vs
		OUTER APPLY STRING_SPLIT(@tip_str1, ',') AS t
	WHERE @tip_str1 IS NULL OR t.value=vs.id
	--select * from #tip_table
	--************************************************************************************

		
	SELECT
		dbo.Fun_NameFinPeriod(@fin_id1) as 'Фин_пер'
		,CASE
			WHEN (GROUPING(name) = 1) THEN 'Итого:'
			ELSE coalesce(name, '????')
		END AS 'Закон'
		,CASE
			WHEN (GROUPING(lgotaall) = 1) THEN ' '
			ELSE coalesce(STR(lgotaall), '????')
		END AS 'Льгота'
		,SUM(Kol_people) AS Kol_people
		,SUM(Kol_lg) AS Kol_lg
		,SUM(summa) AS summa
	FROM (
	SELECT
				dl.name
				,dr.lgotaall
				,COUNT(DISTINCT owner_id) AS Kol_people
				,COUNT(DISTINCT owner_lgota) AS Kol_lg
				,SUM(dr.discount) AS summa
			FROM dbo.View_PAYM_LGOTA_ALL AS dr 
			JOIN dbo.View_OCC_ALL AS o 
				ON dr.occ = o.occ
			JOIN dbo.DSC_GROUPS AS dg 
				ON dr.lgotaall = dg.id
			JOIN dbo.DSC_LAWS AS dl
				ON dg.law_id = dl.id
			WHERE 
				dr.fin_id = @fin_id1
				AND dr.discount > 0
				AND o.fin_id = dr.fin_id
				AND o.STATUS_ID <> 'закр'
				AND EXISTS (SELECT
						1
					FROM #tip_table
					WHERE tip_id = o.tip_id)
				AND dl.id = coalesce(@law_id, dl.id)
			GROUP BY dl.name
					,lgotaall
	) as t
	GROUP BY name
			,lgotaall WITH ROLLUP

DROP TABLE IF EXISTS #tip_table;
go

