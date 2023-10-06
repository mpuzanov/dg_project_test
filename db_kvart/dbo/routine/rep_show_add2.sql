CREATE   PROCEDURE [dbo].[rep_show_add2]
(
	@fin_id			SMALLINT
	,@sector_id		INT			= NULL
	,@build_id		INT			= NULL -- код дома
	,@service_id	VARCHAR(10)	= NULL
	,@vin1			INT			= NULL
	,@vin2			INT			= NULL
	,@tip_id		SMALLINT
	,@div_id		SMALLINT	= NULL
	,@Type_id1		INT			= NULL
	,@fin_id2		SMALLINT	= NULL
	,@doc_no		VARCHAR(10)	= NULL
	,@sup_id		INT			= NULL
)
AS
	/*
	дата изменения:	7.04.11
	автор изменеия:	Пузанов
		
	используется в:	отчёт №9.3 "Список перерасчетов по лицевым"
	файл отчета:	
	
	rep_show_add2 @fin_id=171, @tip_id=28

	*/
	SET NOCOUNT ON

	IF (@fin_id IS NULL)
		AND (@fin_id2 IS NULL)
		AND @tip_id IS NULL
		AND @service_id IS NULL
		SELECT
			@fin_id = 0
			,@fin_id2 = 0
			,@tip_id = 0
			,@service_id = ''  -- при разработки отчёта чтобы не думал долго

	IF (@fin_id IS NULL)
		SET @fin_id = [dbo].[Fun_GetFinCurrent](@tip_id, @build_id, NULL, NULL)
	IF @fin_id2 IS NULL
		SET @fin_id2 = @fin_id
	IF @doc_no = ''
		SET @doc_no = NULL

	SELECT
		o.bldn_id
		,ap.start_date
		,b.street_name AS name
		,b.nom_dom
		,o.nom_kvr
		,ap.Occ
		,doc
		,ap.doc_no AS doc_no
		,ap.doc_date AS doc_date
		,ap.data1 AS data1
		,ap.data2 AS data2
		,s1.name AS Vin1
		,s2.name AS Vin2
		,ap.Hours
		,ap.tnorm2
		,o.total_sq
		,o.kol_people
		,CAST(SUM(ap.Value) AS MONEY) AS Summa
		,(SELECT TOP 1
				start_date
			FROM dbo.Global_values 
			WHERE ap.data1 BETWEEN start_date AND end_date)
		AS fin_paym
	FROM dbo.View_ADDED AS ap 
		JOIN dbo.View_OCC_ALL AS o 
			ON o.Occ = ap.Occ
			AND o.fin_id = ap.fin_id
		JOIN dbo.View_services vs 
			ON ap.service_id = vs.id
		JOIN dbo.View_BUILDINGS AS b 
			ON b.id = o.bldn_id
		LEFT JOIN dbo.SECTOR AS s1
			ON ap.Vin1 = s1.id
		LEFT JOIN dbo.View_SUPPLIERS AS s2 
			ON ap.Vin2 = s2.id
	WHERE 
		ap.fin_id BETWEEN @fin_id AND @fin_id2
		AND (ap.service_id = @service_id OR @service_id IS NULL)
		AND (ap.add_type = @Type_id1 OR @Type_id1 IS NULL)
		AND (b.sector_id = @sector_id OR @sector_id IS NULL)
		AND (o.bldn_id = @build_id OR @build_id IS NULL)
		AND COALESCE(ap.Vin1, 0) = COALESCE(@vin1, COALESCE(ap.Vin1, 0))
		AND COALESCE(ap.Vin2, 0) = COALESCE(@vin2, COALESCE(ap.Vin2, 0))
		AND (b.tip_id = @tip_id	OR @tip_id IS NULL)
		AND (b.div_id = @div_id	OR @div_id IS NULL)
		AND COALESCE(ap.doc_no, '') = COALESCE(@doc_no, COALESCE(ap.doc_no, ''))
		AND (ap.sup_id = @sup_id OR @sup_id IS NULL)
	GROUP BY	o.bldn_id
				,ap.start_date
				,b.street_name
				,b.nom_dom
				,b.nom_dom_sort
				,o.nom_kvr
				,o.nom_kvr_sort
				,ap.Occ
				,ap.doc
				,ap.doc_no
				,ap.doc_date
				,ap.data1
				,ap.data2
				,s1.name
				,s2.name
				,ap.Hours
				,ap.tnorm2
				,o.total_sq
				,o.kol_people
	ORDER BY ap.start_date, b.street_name, b.nom_dom_sort, o.nom_kvr_sort
	OPTION (MAXDOP 1, FAST 10);
go

