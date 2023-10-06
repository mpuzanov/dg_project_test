CREATE   PROCEDURE [dbo].[rep_suppliers_all]
(
	@service_id VARCHAR(10) = NULL
)
AS
	/*
	
	Список поставщиков со списком их услуг
	
	rep_suppliers_all

	*/
	SET NOCOUNT ON


	DECLARE @Str VARCHAR(4000)

	SELECT
		id
		,name
		,adres
		,fio
		,account_one
		,REPLICATE(' ', 4000) AS StrServises
	INTO #Temp
	FROM dbo.SUPPLIERS_ALL

	IF @service_id IS NOT NULL
	BEGIN
		DELETE t
			FROM #Temp AS t
		WHERE NOT EXISTS (SELECT
					1
				FROM dbo.SUPPLIERS
				WHERE sup_id = t.id
				AND service_id = @service_id)
			OR id = 0
	END

	DECLARE @id1 INT
	DECLARE table_curs CURSOR FOR
		SELECT
			id
		FROM #Temp
	OPEN table_curs
	FETCH NEXT FROM table_curs INTO @id1
	WHILE (@@fetch_status = 0)
	BEGIN

		SET @Str = ''
		SELECT
			@Str = STUFF((SELECT
					';' + LTRIM(s.short_name) + '(' + LTRIM(STR(sup.id)) + ')'
				FROM dbo.SUPPLIERS AS sup
				JOIN dbo.View_SERVICES AS s
					ON sup.service_id = s.id
				WHERE sup.sup_id = @id1
				ORDER BY s.sort_no
				FOR XML PATH (''))
			, 1, 2, '')

		UPDATE #Temp
		SET StrServises = @Str
		WHERE id = @id1

		FETCH NEXT FROM table_curs INTO @id1
	END
	CLOSE table_curs
	DEALLOCATE table_curs

	SELECT
		*
	FROM #Temp
	ORDER BY name

	DROP TABLE #Temp
go

