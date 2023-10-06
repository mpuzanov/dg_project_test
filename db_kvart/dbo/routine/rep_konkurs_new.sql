CREATE   PROCEDURE [dbo].[rep_konkurs_new]
(
	@year		SMALLINT	= 2013 -- год
	,@tip_id	SMALLINT
	,@div_id	SMALLINT	= NULL -- код района
	,@build_id	INT			= NULL -- код дома	
	,@day		SMALLINT	= 10    -- последний день оплаты
)
AS
	/*
	лучший плательщик
	
	автор:		Пузанов
	дата создания:  19.05.2008
	
	добавлен 05/11/2008
	@build_id int    = null, -- код дома
	@day smallint     = 10    -- последний день оплаты
	
	*/
	SET NOCOUNT ON

	IF (@day IS NULL)
		OR (@day > 29)
		SET @day = 10
	-----------------------------------------------------------------------------------------
	DECLARE	@fin_id			SMALLINT -- первый месяц года
			,@fin_current	SMALLINT   -- текущий месяц
			,@num_month		TINYINT

	SELECT TOP 1
		@fin_id = fin_id
	FROM dbo.GLOBAL_VALUES
	WHERE YEAR(start_date) = @year
	ORDER BY fin_id

	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, NULL)

	SELECT
		@num_month = MONTH(start_date)
	FROM dbo.GLOBAL_VALUES
	WHERE fin_id = @fin_current

	DECLARE @t1 TABLE
		(
			occ				INT
			,Initials		VARCHAR(50)
			,div_name		VARCHAR(50)
			,street_name	VARCHAR(50)
			,nom_dom		VARCHAR(7)
			,nom_kvr		VARCHAR(7)
		)

	INSERT
	INTO @t1
	(	occ
		,Initials
		,div_name
		,street_name
		,nom_dom
		,nom_kvr)
		SELECT
			o.occ
			,dbo.Fun_InitialsFull(o.occ)
			,d.name
			,s.name
			,b.nom_dom
			,f.nom_kvr
		FROM dbo.OCCUPATIONS AS o 
		JOIN dbo.FLATS AS f
			ON o.flat_id = f.id
		JOIN dbo.BUILDINGS AS b 
			ON f.bldn_id = b.id
		JOIN dbo.VSTREETS AS s 
			ON b.street_id = s.id
		JOIN dbo.DIVISIONS AS d 
			ON b.div_id = d.id
		WHERE o.STATUS_ID <> 'закр'
		AND b.div_id = COALESCE(@div_id, b.div_id)
		AND o.TOTAL_SQ > 0
		AND (b.tip_id = @tip_id)
		AND b.id = COALESCE(@build_id, b.id)
		AND dbo.Fun_SumDolg10(@fin_id, occ, 1) = 0
		AND dbo.Fun_SumDolg10(@fin_id + 1, occ, @day) = 0
		AND dbo.Fun_SumDolg10(@fin_id + 2, occ, @day) = 0
		AND dbo.Fun_SumDolg10(@fin_id + 3, occ, @day) = 0
		AND dbo.Fun_SumDolg10(@fin_id + 4, occ, @day) = 0
		AND dbo.Fun_SumDolg10(@fin_id + 5, occ, @day) = 0
		AND dbo.Fun_SumDolg10(@fin_id + 6, occ, @day) = 0
		AND dbo.Fun_SumDolg10(@fin_id + 7, occ, @day) = 0
		AND dbo.Fun_SumDolg10(@fin_id + 8, occ, @day) = 0
		AND dbo.Fun_SumDolg10(@fin_id + 9, occ, @day) = 0
		AND dbo.Fun_SumDolg10(@fin_id + 10, occ, @day) = 0
		AND dbo.Fun_SumDolg10(@fin_id + 11, occ, @day) = 0
		AND dbo.Fun_SumDolg10(@fin_id + 12, occ, 10) = 0


	SELECT
		t.occ AS 'Лицевой'
		,t.occ
		,t.Initials AS 'Квартиросъемщик'
		,t.div_name AS 'Район'
		,t.street_name AS 'Улица'
		,t.nom_dom AS 'Дом'
		,t.nom_kvr AS 'Кв.'
		,'Банк' = (SELECT
				dbo.Fun_GetBankOplata(t.occ, @year))
	FROM @t1 AS t
	ORDER BY t.[street_name], dbo.Fun_SortDom(t.[nom_dom]), dbo.Fun_SortDom(t.[nom_kvr])
go

