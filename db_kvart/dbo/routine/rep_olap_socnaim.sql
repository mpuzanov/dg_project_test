CREATE   PROCEDURE [dbo].[rep_olap_socnaim]
(
	@tip_id		SMALLINT
	,@fin_id1	SMALLINT	= NULL
	,@fin_id2	SMALLINT	= NULL
	,@build		INT			= NULL
	,@debug		BIT			= NULL
)
AS
	/*
	
	аналитика по договорам соц.найма
	
	rep_olap_socnaim 5,179,179
	rep_olap_socnaim null,179,179	
	
	*/
	SET NOCOUNT ON


	--IF @tip_id IS NULL
	--	SET @tip_id = 0

	IF @fin_id1 IS NULL
		SET @fin_id1 = 0

	IF @fin_id2 IS NULL
		AND @fin_id1 IS NOT NULL
		SET @fin_id2 = @fin_id1

	IF @fin_id1 = 0
		SET @fin_id2 = 0

	IF @fin_id1 > @fin_id2
		SET @fin_id2 = @fin_id1

	IF @build = 0
		SET @build = NULL


	SELECT
		oh.start_date AS 'Период'
		,oh.occ AS 'Лицевой'
		,T.name AS 'Населенный пункт'
		,d.name AS 'Район'
		,oh.tip_name AS 'Тип фонда'
		,st.short_name AS 'Улица'
		,b.nom_dom AS 'Номер дома'
		,(st.short_name + ' д.' + b.nom_dom) AS 'Адрес дома'
		,oh.nom_kvr AS 'Квартира'
		,dbo.Fun_Initials(oh.occ) AS 'ФИО'
		,CAST(oh.total_sq AS DECIMAL(9,2)) AS 'Площадь'
		,oh.kol_people AS 'Кол-во граждан'
		,PT.name AS 'Тип собственности'							
		,oh.nom_kvr_sort
		,b.nom_dom_sort
		,CONCAT(st.short_name, b.nom_dom_sort) AS sort_dom
		,oh.flat_id AS 'Код квартиры'
		,b.id AS 'Код дома'
		,MIN(o2.dogovor_num) AS 'Номер договора'
		,MIN(o2.dogovor_date) AS 'Дата договора'
	FROM dbo.View_OCC_ALL AS oh 
	JOIN dbo.BUILDINGS AS b 
		ON oh.bldn_id = b.id
	JOIN dbo.VSTREETS AS st
		ON b.street_id = st.id
	JOIN dbo.TOWNS AS T 
		ON b.town_id = T.id
	LEFT JOIN dbo.DIVISIONS AS d 
		ON b.div_id = d.id
	JOIN dbo.PROPERTY_TYPES AS PT 
		ON oh.proptype_id = PT.id
	JOIN dbo.OCCUPATIONS o2 
		ON oh.occ = o2.occ
	WHERE 
		(oh.tip_id = @tip_id OR @tip_id IS NULL)
		AND oh.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND (oh.bldn_id = @build OR @build IS NULL)
		AND oh.status_id <> 'закр'
		AND oh.socnaim=1
	GROUP BY	oh.start_date
				,oh.fin_id
				,T.name
				,d.name
				,oh.tip_name
				,st.short_name
				,b.nom_dom
				,b.id
				,oh.nom_kvr
				,oh.flat_id
				,oh.occ
				,oh.total_sq
				,oh.kol_people
				,PT.name
				,oh.nom_kvr_sort
				,b.nom_dom_sort
go

