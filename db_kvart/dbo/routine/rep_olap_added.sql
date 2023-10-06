-- =============================================
-- Author:		Пузанов
-- Create date: 22.04.2011
-- Description:	Перерасчеты
-- =============================================
CREATE   PROCEDURE [dbo].[rep_olap_added]
(
	@build		INT			= NULL
	,@fin_id1	SMALLINT	= NULL
	,@fin_id2	SMALLINT	= NULL
	,@tip_id	SMALLINT	= NULL
	,@sup_id	INT			= NULL
)
AS
/*
exec rep_olap_added NULL,249,250,1,345
exec rep_olap_added NULL,230,230,1,NULL
*/
BEGIN
	SET NOCOUNT ON;


	IF @build IS NULL
		AND @tip_id IS NULL
		AND @fin_id1<>@fin_id2
		AND UPPER(DB_NAME()) <> 'NAIM'
		SET @build = 0

	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, @build, NULL, NULL)

	IF @fin_id1 = 0
		OR @fin_id1 IS NULL
		SET @fin_id1 = @fin_current
	IF @fin_id2 = 0
		OR @fin_id2 IS NULL
		SET @fin_id2 = @fin_current

	-- для ограничения доступа услуг
	CREATE TABLE #s
	(	id			VARCHAR(10)	COLLATE database_default PRIMARY KEY
		,name		VARCHAR(100) COLLATE database_default
		,is_build	BIT
	)
	INSERT INTO #s	(id, name, is_build)
	SELECT id,name,is_build	FROM dbo.View_SERVICES

	SELECT
		oh.start_date AS 'Период'
		,T.name AS 'НаселенныйПункт'
		,MAX(oh.tip_name) AS 'Тип фонда'
		,MAX(d.name) AS 'Район'
		,MAX(sec.name) AS 'Участок'
		,CONCAT(st.name , ' д.' , b.nom_dom) AS 'Адрес дома'
		,st.name AS 'Улица'
		,b.nom_dom AS 'Номер дома'
		,oh.nom_kvr AS 'Квартира'
	    ,oh.occ AS 'Единый_Лицевой'
	    ,CASE WHEN (vp.sup_id>0) THEN MIN(vp.occ_sup_paym) ELSE dbo.Fun_GetFalseOccOut(oh.occ, oh.tip_id) END AS 'Лицевой'
		,s.name AS 'Услуга'
		,CAST(oh.total_sq AS DECIMAL(9,2)) AS 'Площадь'
		,oh.kol_people AS 'Кол.человек'
		,AT.name AS 'Тип разового'
		,ap.doc AS 'Документ'
		,ap.doc_date AS 'Дата док'
		,ap.doc_no AS 'Номер док'
		,MAX(ap.comments) AS 'Комментарий'
		,MIN(vs.name) AS 'Поставщик'
		,SUM(ap.Value) AS 'Разовые'
		,CASE
				WHEN SUM(ap.kol) > 0 THEN SUM(ap.kol)
				WHEN vp.tarif <= 0 THEN 0
				ELSE SUM(ap.Value) / vp.tarif
			END AS 'Кол_Разовых'
		,CASE
			WHEN vp.is_counter = 1 THEN 'Внешний'
			WHEN vp.is_counter = 2 THEN 'Внутренний'
			ELSE 'Нет'
		END AS 'Счетчик'
		,MAX(U.Initials) AS 'Пользователь'
		,oh.bldn_id AS 'Код дома'
		,MAX(cp.StrFinPeriod) AS 'Повторять по'
		,MAX(dbo.Fun_GetNameFinPeriod(ap.fin_id_paym)) AS 'за период'
		,b.nom_dom_sort
		,oh.nom_kvr_sort		
	FROM dbo.View_occ_all_lite AS oh 
	JOIN dbo.View_added_lite AS ap 
		ON oh.fin_id = ap.fin_id
		AND oh.occ = ap.occ
	JOIN #s AS s
		ON ap.service_id = s.id
	LEFT JOIN dbo.View_paym AS vp 
		ON ap.fin_id = vp.fin_id
		AND ap.occ = vp.occ
		AND ap.service_id = vp.service_id
		AND ap.sup_id = vp.sup_id
	LEFT JOIN dbo.View_suppliers AS vs 
		ON vp.source_id = vs.id
	JOIN dbo.Added_Types AS AT
		ON ap.add_type = AT.id
	JOIN dbo.Buildings AS b 
		ON oh.bldn_id = b.id
	JOIN dbo.VStreets AS st
		ON b.street_id = st.id
	JOIN dbo.Towns AS T 
		ON b.town_id = T.id	
	LEFT JOIN Calendar_period cp 
		ON ap.repeat_for_fin=cp.fin_id
	LEFT JOIN dbo.Divisions d
		ON b.div_id=d.id
	LEFT JOIN dbo.Sector sec 
		ON b.sector_id=sec.id
	LEFT JOIN dbo.Users u
		ON ap.user_edit=u.id
	WHERE 
		oh.fin_id BETWEEN @fin_id1 AND @fin_id2	
		AND (@build IS NULL OR oh.bldn_id = @build)
		AND (@tip_id IS NULL OR oh.tip_id = @tip_id)
		AND (@sup_id IS NULL OR ap.sup_id=@sup_id)
	GROUP BY	oh.start_date
				,T.name
				,oh.tip_id
				,st.name
				,oh.bldn_id
				,b.nom_dom
				,b.nom_dom_sort
				,oh.nom_kvr
				,oh.nom_kvr_sort
				,oh.occ
				,oh.total_sq
				,oh.kol_people
				,s.name
				,AT.name
				,ap.doc
				,ap.doc_date
				,ap.doc_no
				,vp.tarif
				,vp.is_counter
				,vp.sup_id
				,ap.repeat_for_fin
	OPTION (MAXDOP 1);

END
go

