CREATE   PROCEDURE [dbo].[rep_svod_dom_mode]
(
	@fin_id1		SMALLINT
	,@tip_id1		SMALLINT	= NULL	 -- тип жилого фонда
	,@mode			SMALLINT	= 3
	,@jeu1			SMALLINT	= NULL
	,@service_id1	VARCHAR(10)	= NULL
	,@dom			INT			= NULL
	,@source		INT			= NULL

)
/*

rep_svod_dom_mode 187,28,2

2/03/2009
Заменил таблицы DOM_SVOD_MODE и DOM_SVOD_SOURCE 
на DOM_SVOD_ALL

*/

AS
	SET NOCOUNT ON;


	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip_id1, @dom, NULL, NULL)


	IF @mode = 3 -- Выдаем сводный отчет по участкам без поставщиков='НЕТ'
	BEGIN
		SELECT
			st.name AS streets_name
			,s.short_name
			,cm.name
			,ds.*
			,b.nom_dom AS dom
			,b.sector_id AS Jeu
			,m.name AS modes_name
			,b.tip_id
		FROM	dbo.View_SUPPLIERS AS cm 
				,dbo.DOM_SVOD_ALL AS ds 
				,dbo.View_SERVICES AS s
				,dbo.VSTREETS AS st 
				,dbo.BUILD_MODE AS bm 
				,dbo.CONS_MODES AS m 
				,dbo.View_BUILD_ALL AS b 
				JOIN dbo.VOCC_TYPES AS ot
					ON b.tip_id = ot.id  -- для ограничения типов по доступу
		WHERE cm.id = ds.source_id
		AND s.id = COALESCE(@service_id1, s.id)
		AND s.id = cm.service_id
		AND ds.fin_id = @fin_id1
		AND b.fin_id = @fin_id1
		AND ds.build_id = b.bldn_id
		AND b.tip_id = COALESCE(@tip_id1, b.tip_id)
		AND b.street_id = st.id
		AND b.sector_id = COALESCE(@jeu1, b.sector_id)
		AND b.bldn_id = COALESCE(@dom, b.bldn_id)
		AND cm.name <> 'нет'
		AND b.bldn_id = bm.build_id
		AND s.id = bm.service_id
		AND bm.mode_id = m.id
		AND m.name <> 'нет'
		AND cm.id = COALESCE(@source, cm.id)
		ORDER BY b.sector_id, st.name, b.nom_dom_sort, s.service_no
	END

	IF @mode = 1  -- Выдаем сводный отчет по участкам 
	BEGIN
		SELECT
			st.name AS streets_name
			,s.short_name
			,cm.name
			,ds.*
			,b.nom_dom AS dom
			,b.sector_id AS Jeu
			,'' AS modes_name
			,b.tip_id
		FROM	dbo.CONS_MODES AS cm 
				,dbo.DOM_SVOD_ALL AS ds 
				,dbo.View_SERVICES AS s 
				,dbo.VSTREETS AS st 
				,dbo.View_BUILD_ALL AS b 
				JOIN dbo.VOCC_TYPES AS ot
					ON b.tip_id = ot.id  -- для ограничения типов по доступу
		WHERE cm.id = ds.mode_id
		AND s.id = COALESCE(@service_id1, s.id)
		AND s.id = cm.service_id
		AND ds.fin_id = @fin_id1
		AND b.fin_id = @fin_id1
		AND ds.build_id = b.bldn_id
		AND b.tip_id = COALESCE(@tip_id1, b.tip_id)
		AND b.street_id = st.id
		AND b.sector_id = COALESCE(@jeu1, b.sector_id)
		AND b.bldn_id BETWEEN COALESCE(@dom, 0) AND COALESCE(@dom, 9999)
		ORDER BY st.name, nom_dom_sort, s.service_no--6,

	END

	IF @mode = 2 -- Выдаем сводный отчет по участкам 
	BEGIN

		SELECT
			st.name AS streets_name
			,s.short_name
			,cm.name
			,ds.*
			,b.nom_dom AS dom
			,b.sector_id AS Jeu
			,m.name AS modes_name
			,j.name AS sector_name
		FROM dbo.DOM_SVOD_ALL AS ds 
		JOIN dbo.View_SUPPLIERS AS cm 
			ON cm.id = ds.source_id
		JOIN dbo.View_SERVICES AS s 
			ON s.id = cm.service_id
		JOIN dbo.View_BUILD_ALL AS b 
			ON ds.build_id = b.bldn_id
		JOIN dbo.VSTREETS AS st 
			ON b.street_id = st.id
		JOIN dbo.SECTOR AS j
			ON b.sector_id = j.id
		JOIN dbo.VOCC_TYPES AS ot
			ON b.tip_id = ot.id  -- для ограничения типов по доступу	
		JOIN dbo.CONS_MODES AS m
			ON ds.mode_id = m.id
		WHERE s.id = COALESCE(@service_id1, s.id)
		AND ds.fin_id = @fin_id1
		AND b.fin_id = @fin_id1
		AND b.tip_id = COALESCE(@tip_id1, b.tip_id)
		AND b.sector_id = COALESCE(@jeu1, b.sector_id)
		AND b.bldn_id BETWEEN COALESCE(@dom, 0) AND COALESCE(@dom, 9999)
		AND cm.id BETWEEN COALESCE(@source, 0) AND COALESCE(@source, 999999)
		ORDER BY st.name, nom_dom_sort, s.service_no

	END

	IF @mode = 5
	/*	Выдаем сводный отчет по участкам на базе таблицы  
		без поставщиков='НЕТ'
		дополнение к отчету 6.9 общие данные(на основе @mode=3)
	*/
	BEGIN

		SELECT
			s.short_name
			,s.service_no
			,cm.name
			,m.name AS modes_name
			,SUM(ds.countpeople) AS countpeople
			,SUM(ds.countlic) AS countlic
			,SUM(ds.SQUARE) AS SQUARE
		FROM	dbo.View_SUPPLIERS AS cm 
				,dbo.DOM_SVOD_ALL AS ds 
				,dbo.View_SERVICES AS s 
				,dbo.VSTREETS AS st 
				,dbo.BUILD_MODE AS bm
				,dbo.CONS_MODES AS m
				,dbo.View_BUILD_ALL AS b 
				JOIN dbo.VOCC_TYPES AS ot
					ON b.tip_id = ot.id  -- для ограничения типов по доступу			
		WHERE cm.id = ds.source_id
		AND s.id = COALESCE(@service_id1, s.id)
		AND s.id = cm.service_id
		AND ds.fin_id = @fin_id1
		AND b.fin_id = @fin_id1
		AND ds.build_id = b.bldn_id
		AND b.tip_id = COALESCE(@tip_id1, b.tip_id)
		AND b.street_id = st.id
		AND b.sector_id = COALESCE(@jeu1, b.sector_id)
		AND b.bldn_id = COALESCE(@dom, b.bldn_id)
		AND cm.name <> 'нет'
		AND b.bldn_id = bm.build_id
		AND s.id = bm.service_id
		AND bm.mode_id = m.id
		AND m.name <> 'нет'
		AND cm.id = COALESCE(@source, cm.id)
		GROUP BY	s.short_name
					,cm.name
					,s.service_no
					,m.name
		ORDER BY s.service_no

	END
go

