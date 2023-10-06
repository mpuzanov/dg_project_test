CREATE   PROCEDURE [dbo].[rep_rates_dynamic_counter]
(
	@tipe_id1		SMALLINT	= NULL
	,@service_id1	VARCHAR(10)	= NULL
	,@fin_count		SMALLINT	= 12
)
AS
/*
	Динамика изменения тарифов
	EXEC rep_rates_dynamic_counter 1
	EXEC rep_rates_dynamic_counter 1,'вотв'
	EXEC rep_rates_dynamic_counter 1,'врег'	
	
*/
	SET NOCOUNT ON


	IF @service_id1 = ''
		OR @service_id1 = '0'
		SET @service_id1 = NULL
	IF @fin_count IS NULL
		SET @fin_count = 12

	DROP TABLE IF EXISTS #temp
	
	CREATE TABLE #temp
    (
    	tipe_name VARCHAR(50) COLLATE database_default
    	,service_name VARCHAR(100) COLLATE database_default
		,unit_id VARCHAR(10) COLLATE database_default
		,modes_name VARCHAR(50) COLLATE database_default
		,suppliers_name VARCHAR(50) COLLATE database_default
		,yyyymm VARCHAR(15) COLLATE database_default
		,tarif DECIMAL(15,4)
    )
    

	--вставляем данные в таблицу
	INSERT INTO #temp
	SELECT
		ot.name AS tipe_name
		,s.name AS service_name
		,r.unit_id
		,cm.name AS modes_name
		,su.name AS suppliers_name
		,CONVERT(VARCHAR(7), gb.start_date, 126) AS yyyymm
		,r.tarif AS tarif
	FROM dbo.Rates_counter AS r 
	JOIN dbo.VOcc_types AS ot
		ON r.tipe_id = ot.id
	JOIN dbo.Calendar_period AS gb 
		ON r.fin_id = gb.fin_id
	JOIN dbo.SERVICES AS s
		ON r.service_id = s.id
	JOIN dbo.CONS_MODES AS cm 
		ON r.mode_id = cm.id
	JOIN dbo.View_SUPPLIERS AS su 
		ON r.source_id = su.id
	WHERE 
		r.tipe_id = COALESCE(@tipe_id1, r.tipe_id)
		AND gb.fin_id > (ot.fin_id - @fin_count)
		AND (r.tarif <> 0)
		AND (r.service_id = @service_id1 OR @service_id1 IS NULL)

	IF NOT EXISTS(SELECT * FROM  #temp)
	BEGIN
		SELECT * FROM  #temp
    	RETURN
    END

	--создаем переменную для хранения строки с заголовками столбцов 

	DECLARE @columns VARCHAR(8000)

	SET @columns = STUFF( (SELECT CONCAT(',' , '[' , yyyymm , ']')
        FROM #temp
		GROUP BY yyyymm	ORDER BY yyyymm
		FOR XML PATH ('')
        ), 1, 1, '')

	DECLARE @query NVARCHAR(4000)
	--динамически конструируем текст запроса
	SET @query = 'select * from (select 
	tipe_name,service_name,unit_id,modes_name,suppliers_name,yyyymm,tarif from #temp
	)AS SourceTable
	Pivot(sum([tarif]) for [yyyymm] IN (' + @columns + ')) AS PVT;'

	--выполнение запроса с помощью хранимой процедуры
	PRINT @query
	EXECUTE (@query);
go

