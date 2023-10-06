-- =============================================
-- Author:		Пузанов
-- Create date: 04.08.2013
-- Description:	Начисления ХВС по сельхоз. постройкам и животным
-- =============================================

CREATE     PROCEDURE [dbo].[rep_olap_agri]
(
	@tip_id		SMALLINT	= NULL
	,@fin_id1	SMALLINT	= NULL
	,@fin_id2	SMALLINT	= NULL
	,@build		INT			= NULL
)
AS
BEGIN
	SET NOCOUNT ON;


	IF @tip_id IS NULL
		SET @tip_id = 0


	IF @fin_id1 = 0
		OR @fin_id1 IS NULL
		SET @fin_id1 = dbo.Fun_GetFinCurrent(@tip_id, NULL, NULL, NULL)

	IF @fin_id2 = 0
		OR @fin_id2 IS NULL
		SET @fin_id2 = @fin_id1

	SELECT
		oh.start_date AS 'Период'
		,b.id AS 'Код дома'
		,T.name AS 'Населенный пункт'
		,b.tip_name AS 'Тип фонда'
		,st.name AS 'Улица'
		,b.nom_dom AS 'Номер дома'
		,b.nom_dom_sort
		,oh.nom_kvr AS 'Квартира'
		,oh.nom_kvr_sort
		,oh.total_sq AS 'Площадь'
		,oh.occ AS 'Лицевой'
		,AV.name AS 'Вид'
		,st.name + ' д.' + b.nom_dom AS 'Адрес дома'
		,CONCAT(st.name, b.nom_dom_sort) AS sort_dom
		,SUM(AO.kol) AS 'Количество'
		,SUM(AO.kol_day) AS 'Количество дней'
		,SUM(AO.kol * AV.kol_norma) AS 'Объём'
		,SUM(AO.Value) AS 'Начисленно'
	FROM dbo.AGRICULTURE_OCC AS AO
	JOIN dbo.AGRICULTURE_VID AS AV
		ON AO.ani_vid = AV.id
	JOIN dbo.View_OCC_ALL AS oh 
		ON oh.occ = AO.occ
		AND oh.fin_id = AO.fin_id
	JOIN dbo.View_BUILDINGS AS b
		ON oh.bldn_id = b.id
	JOIN dbo.VSTREETS AS st 
		ON b.street_id = st.id
	JOIN dbo.TOWNS AS T 
		ON b.town_id = T.id
	WHERE 
		oh.tip_id = COALESCE(@tip_id, oh.tip_id)
		AND AO.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND oh.bldn_id = COALESCE(@build, oh.bldn_id)
	GROUP BY	oh.start_date
				,b.id
				,b.tip_name
				,T.name
				,st.name
				,b.nom_dom
				,b.nom_dom_sort
				,oh.nom_kvr
				,oh.nom_kvr_sort
				,oh.flat_id
				,oh.total_sq
				,oh.occ
				,AV.name
	OPTION (MAXDOP 1)


END
go

