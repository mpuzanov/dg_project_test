CREATE   PROCEDURE [dbo].[rep_rates_dynamic]
(
	  @tipe_id1 SMALLINT = NULL
	, @service_id1 VARCHAR(10) = NULL
	, @fin_count SMALLINT = 12
	, @debug BIT = 0
)
AS
	/*
	Динамика изменения тарифов
	EXEC rep_rates_dynamic @tipe_id1=1, @debug=1
	EXEC rep_rates_dynamic @tipe_id1=1,@service_id1='вотв', @debug=1
	EXEC rep_rates_dynamic @tipe_id1=1,@service_id1='врег', @debug=1
		
	*/
	SET NOCOUNT ON
	
	IF @service_id1 = ''
		OR @service_id1 = '0'
		SET @service_id1 = NULL
	IF @fin_count IS NULL
		SET @fin_count = 12

	DROP TABLE IF EXISTS #temp

	CREATE TABLE #temp (
		  tipe_name VARCHAR(50) COLLATE database_default
		, service_name VARCHAR(100) COLLATE database_default
		, status_id VARCHAR(10) COLLATE database_default
		, proptype_id VARCHAR(10) COLLATE database_default
		, modes_name VARCHAR(50) COLLATE database_default
		, suppliers_name VARCHAR(50) COLLATE database_default
		, yyyymm VARCHAR(15) COLLATE database_default
		, fin_id SMALLINT
		, tarif DECIMAL(15, 4)
		, diff DECIMAL(9, 2) DEFAULT 0
		, tarif_s VARCHAR(30) COLLATE database_default DEFAULT ''
	)

	--вставляем данные в таблицу
	INSERT INTO #temp
	SELECT t.tipe_name
		 , t.service_name
		 , t.status_id
		 , t.proptype_id
		 , t.modes_name
		 , t.suppliers_name
		 , t.yyyymm
		 , t.finperiod
		 , t.tarif
		 , t.diff
		 , dbo.NSTR(t.tarif) + CASE WHEN t.diff > 0 THEN CONCAT(' (' , dbo.NSTR(t.diff) , '%)') ELSE '' END
	FROM (
		SELECT ot.Name AS tipe_name
			 , s.Name AS service_name
			 , r.status_id
			 , r.proptype_id
			 , cm.Name AS modes_name
			 , su.Name AS suppliers_name
			 , CONVERT(VARCHAR(7), cp.start_date, 126) AS yyyymm
			 , r.finperiod
			 , r.value AS tarif
			 --, ROUND(
			 --  (((r.value / LAG(r.value, 1) OVER (
			 --  PARTITION BY ot.Name, s.Name, cm.Name, su.Name, r.status_id, r.proptype_id
			 --  ORDER BY r.finperiod)) - 1) * 100.0)
			 --  , 2) AS diff  -- разность в % (r.value-всегда больше)
			 , ROUND(
			   (((r.value / FIRST_VALUE(r.value) OVER (
			   PARTITION BY ot.Name, s.Name, cm.Name, su.Name, r.status_id, r.proptype_id
			   ORDER BY r.finperiod
			   ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
			   )) - 1) * 100.0)
			   , 2) AS diff  -- разность в % (r.value-всегда больше)
		FROM dbo.Rates AS r
			JOIN dbo.VOcc_types AS ot ON 
				r.tipe_id = ot.id
			JOIN dbo.Calendar_period AS cp ON 
				r.finperiod = cp.fin_id
			JOIN dbo.Services AS s ON 
				r.service_id = s.id
			JOIN dbo.Cons_modes AS cm ON 
				r.mode_id = cm.id
			JOIN dbo.View_suppliers AS su ON 
				r.source_id = su.id
		WHERE 
			(r.tipe_id = @tipe_id1 OR @tipe_id1 IS NULL)
			AND cp.fin_id > (ot.fin_id - @fin_count)
			AND (r.value <> 0)
			AND (r.service_id = @service_id1 OR @service_id1 IS NULL)
	) AS t

	IF NOT EXISTS (SELECT * FROM #temp)
	BEGIN
		SELECT *
		FROM #temp
		RETURN
	END
	IF @debug = 1
		SELECT *
		FROM #temp

	--создаем переменную для хранения строки с заголовками столбцов 

	DECLARE @columns VARCHAR(8000)
		  , @columns_diff VARCHAR(8000)
	
	SET @columns = STUFF( (SELECT CONCAT(',' , '[' , yyyymm , ']')
            FROM #temp
			GROUP BY yyyymm	ORDER BY yyyymm
			FOR XML PATH ('')
            ), 1, 1, '')

	DECLARE @query NVARCHAR(4000)
	--динамически конструируем текст запроса
	SET @query = 'select * from (select 
				tipe_name,service_name,status_id,proptype_id,modes_name,suppliers_name,yyyymm,tarif_s from #temp
				) AS SourceTable
				Pivot(MAX([tarif_s]) for [yyyymm] IN (' + @columns + ') ) AS PVT
				;'

	--выполнение запроса с помощью хранимой процедуры
	PRINT @query
	EXECUTE (@query);
go

