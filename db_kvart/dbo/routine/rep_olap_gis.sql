-- =============================================
-- Author:		Пузанов
-- Create date: 11.02.2011
-- Description:	Аналитика по ГИС заполненность
-- =============================================
CREATE       PROCEDURE [dbo].[rep_olap_gis]
(
	@tip_id	 SMALLINT = NULL
   ,@build	 INT	  = NULL
   ,@fin_id1 SMALLINT = NULL
   ,@fin_id2 SMALLINT = NULL
   ,@sup_id	 INT	  = NULL
)
AS
/*

exec rep_olap_gis 27,null,177, 177
exec rep_olap_gis 57, NULL, 200, 200
exec rep_olap_gis 50, NULL, 200, 200
exec rep_olap_gis 50, 4095, 200, 200
exec rep_olap_gis 28, NULL, 176, 176, 323

*/
BEGIN
	SET NOCOUNT ON;


	IF @fin_id1 = 0
		SET @fin_id2 = 0

	IF @fin_id2 IS NULL
		SET @fin_id2 = dbo.Fun_GetFinCurrent(@tip_id, @build, NULL, NULL)

	IF @tip_id IS NOT NULL
		AND @build > 0
		SELECT
			@tip_id = NULL

	-- Заполненность ГИС ЖКХ
	SELECT
		t.[Тип фонда]
	   ,t.[Адрес дома]
	   ,'-' AS 'Поставщик'
	   ,t.kol_occ AS 'Лицевых'
	   ,t.kol_lic_gis AS 'Лицевых в ГИС ЖКХ'
	   ,CASE WHEN(t.kol_pu = 0) THEN NULL ELSE t.kol_pu END AS 'Кол-во ПУ'
	   ,t.kol_pu_gis AS 'Кол-во ПУ в ГИС ЖКХ'
		--,'% заполнения л/сч' = CAST(kol_lic_gis * 100 / kol_occ AS DECIMAL(5, 2))
	   ,t.[Кадастровый номер]
	   ,t.email_subscribe AS 'Email'
	   ,t.telefon AS 'Телефон'
	   ,CASE
			WHEN (t.kol_occ > 0) AND
			(t.kol_lic_gis = 0) THEN 'Не в ГИС'
			WHEN (t.kol_occ > 0) AND
			(t.kol_lic_gis > 0) AND
			((t.kol_lic_gis * 100 / t.kol_occ) BETWEEN 0 AND 50) THEN 'Отстающие'
			WHEN (t.kol_occ > 0) AND
			(t.kol_lic_gis > 0) AND
			((t.kol_lic_gis * 100 / t.kol_occ) BETWEEN 51 AND 97) THEN 'Не полностью'
			WHEN (t.kol_occ > 0) AND
			(t.kol_lic_gis > 0) AND
			((t.kol_lic_gis * 100 / t.kol_occ) BETWEEN 98 AND 100) THEN 'Лидеры'
			ELSE ''
		END AS Группа
	   ,t.bldn_id AS 'Код дома'
	FROM (SELECT
			ot.name AS 'Тип фонда'
		   ,vb.adres AS 'Адрес дома'
		   ,vb.CadastralNumber AS 'Кадастровый номер'
		   ,COUNT(o.Occ) AS kol_occ
		   ,(SELECT
					COUNT(o1.Occ)
				FROM dbo.OCCUPATIONS o1 
				JOIN dbo.FLATS f1 
					ON o1.flat_id = f1.id
				WHERE o1.tip_id = o.tip_id
				AND f1.bldn_id = o.bldn_id
				AND o1.STATUS_ID <> 'закр'
				AND o1.TOTAL_SQ > 0
				AND o1.id_els_gis IS NOT NULL)
			AS kol_lic_gis
		   ,(SELECT
					COUNT(DISTINCT c.id)
				FROM dbo.COUNTERS c 
				JOIN dbo.View_BUILDINGS vb1 
					ON c.build_id = vb1.id
				JOIN dbo.COUNTER_LIST_ALL cla 
					ON cla.counter_id = c.id
					AND cla.fin_id = vb1.fin_current
				JOIN dbo.OCCUPATIONS o1 
					ON cla.Occ = o1.Occ
				WHERE vb1.tip_id = o.tip_id
				AND vb1.id = o.bldn_id
				AND o1.STATUS_ID <> 'закр'
				AND o1.TOTAL_SQ > 0
				AND c.is_build = 0
				AND c.date_del IS NULL
				AND (c.PeriodCheck IS NULL
				OR c.PeriodCheck > current_timestamp)
				AND NOT EXISTS (SELECT
						1
					FROM dbo.SERVICES_TYPE_COUNTERS stc 
					WHERE stc.tip_id = vb1.tip_id
					AND stc.service_id = c.service_id
					AND stc.no_export_gis = 1))
			AS kol_pu
		   ,(SELECT
					COUNT(DISTINCT c.id)
				FROM dbo.COUNTERS c 
				JOIN dbo.View_BUILDINGS vb1 
					ON c.build_id = vb1.id
				JOIN dbo.COUNTER_LIST_ALL cla 
					ON cla.counter_id = c.id
					AND cla.fin_id = vb1.fin_current
				JOIN dbo.OCCUPATIONS o1 
					ON cla.Occ = o1.Occ
				WHERE vb1.tip_id = o.tip_id
				AND vb1.id = o.bldn_id
				AND o1.STATUS_ID <> 'закр'
				AND o1.TOTAL_SQ > 0
				AND c.is_build = 0
				AND c.date_del IS NULL
				AND (c.PeriodCheck IS NULL
				OR c.PeriodCheck > current_timestamp)
				AND c.id_pu_gis IS NOT NULL
				AND NOT EXISTS (SELECT
						1
					FROM dbo.SERVICES_TYPE_COUNTERS stc 
					WHERE stc.tip_id = vb1.tip_id
					AND stc.service_id = c.service_id
					AND stc.no_export_gis = 1))
			AS kol_pu_gis
		   ,MAX(COALESCE(ot.email_subscribe, '')) AS email_subscribe
		   ,MAX(COALESCE(ot.telefon, '')) AS telefon
		   ,o.bldn_id
		FROM dbo.VOCC o 
		JOIN dbo.VOCC_TYPES ot 
			ON o.tip_id = ot.id
		JOIN dbo.View_BUILDINGS_LITE vb 
			ON o.bldn_id = vb.id
		WHERE ot.payms_value = 1
		AND vb.is_paym_build = 1
		AND ot.export_gis = 1
		AND (ot.id = @tip_id
		OR @tip_id IS NULL)
		AND o.STATUS_ID <> 'закр'
		AND o.TOTAL_SQ > 0
		AND (vb.id = @build
		OR @build IS NULL)
		GROUP BY o.tip_id
				,ot.name
				,vb.adres
				,vb.CadastralNumber
				,o.bldn_id
				,vb.fin_current) AS t

	UNION ALL

	-- Заполненность ГИС ЖКХ поставщиков
	SELECT
		t.[Тип фонда]
	   ,t.[Адрес дома]
	   ,t.Поставщик
	   ,t.kol_occ
	   ,t.kol_lic_gis
	   ,CASE WHEN(t.kol_pu = 0) THEN NULL ELSE t.kol_pu END
	   ,CASE WHEN(t.kol_pu_gis = 0) THEN NULL ELSE t.kol_pu_gis END
	   ,t.[Кадастровый номер]
	   ,t.email_subscribe
	   ,t.telefon
		--,Procent = CAST(kol_lic_gis * 100 / kol_occ AS DECIMAL(5, 2))
	   ,CASE
			WHEN (t.kol_occ > 0) AND
			(t.kol_lic_gis = 0) THEN 'Не в ГИС'
			WHEN (t.kol_occ > 0) AND
			(t.kol_lic_gis > 0) AND
			((t.kol_lic_gis * 100 / t.kol_occ) BETWEEN 0 AND 50) THEN 'Отстающие'
			WHEN (t.kol_occ > 0) AND
			(t.kol_lic_gis > 0) AND
			((t.kol_lic_gis * 100 / t.kol_occ) BETWEEN 51 AND 97) THEN 'Не полностью'
			WHEN (t.kol_occ > 0) AND
			(t.kol_lic_gis > 0) AND
			((t.kol_lic_gis * 100 / t.kol_occ) BETWEEN 98 AND 100) THEN 'Лидеры'

			ELSE ''
		END AS Группа
	   ,t.bldn_id AS 'Код дома'
	FROM (SELECT
			ot.name AS 'Тип фонда'
		   ,vb.adres AS 'Адрес дома'
		   ,vb.CadastralNumber AS 'Кадастровый номер'
		   ,sa.name AS 'Поставщик'
		   ,kol_occ = COUNT(os.occ_sup)
		   ,kol_lic_gis = (SELECT
					COUNT(os1.occ_sup)
				FROM dbo.OCC_SUPPLIERS os1 
				JOIN dbo.VOCC o1 
					ON os1.Occ = o1.Occ
				JOIN dbo.OCCUPATION_TYPES ot1 
					ON o1.tip_id = ot1.id
					AND os1.fin_id = ot1.fin_id
				WHERE os1.sup_id = os.sup_id
				AND ot1.id = ot.id
				AND o1.bldn_id = o.bldn_id
				AND o1.STATUS_ID <> 'закр'
				AND o1.TOTAL_SQ > 0
				AND os1.id_jku_gis IS NOT NULL)
		   ,(SELECT
					COUNT(c.id)
				FROM dbo.COUNTERS c 
				JOIN dbo.View_BUILDINGS_LITE vb1 
					ON c.build_id = vb1.id
				JOIN dbo.COUNTER_LIST_ALL cla 
					ON cla.counter_id = c.id
					AND cla.fin_id = os.fin_id
				JOIN dbo.OCCUPATIONS o1
					ON cla.Occ = o1.Occ
				JOIN dbo.BUILD_SOURCE AS bs1 
					ON vb1.id = bs1.build_id
					AND c.service_id = bs1.service_id
				JOIN dbo.SUPPLIERS AS sup1 
					ON bs1.source_id = sup1.id
					AND sup1.sup_id = os.sup_id
				WHERE vb1.tip_id = ot.id
				AND vb1.id = o.bldn_id
				AND o1.STATUS_ID <> 'закр'
				AND o1.TOTAL_SQ > 0
				AND c.is_build = 0
				AND c.date_del IS NULL
				AND (c.PeriodCheck IS NULL
				OR c.PeriodCheck > current_timestamp)
				AND NOT EXISTS (SELECT
						1
					FROM dbo.SERVICES_TYPE_COUNTERS stc 
					WHERE stc.tip_id = vb1.tip_id
					AND stc.service_id = c.service_id
					AND stc.no_export_gis = 1))
			AS kol_pu
		   ,(SELECT
					COUNT(c.id)
				FROM dbo.COUNTERS c 
				JOIN dbo.View_BUILDINGS_LITE vb1 
					ON c.build_id = vb1.id
				JOIN dbo.COUNTER_LIST_ALL cla 
					ON cla.counter_id = c.id
					AND cla.fin_id = os.fin_id
				JOIN dbo.OCCUPATIONS o1 
					ON cla.Occ = o1.Occ
				JOIN dbo.BUILD_SOURCE AS bs1 
					ON vb1.id = bs1.build_id
					AND c.service_id = bs1.service_id
				JOIN dbo.SUPPLIERS AS sup1 
					ON bs1.source_id = sup1.id
					AND sup1.sup_id = os.sup_id
				WHERE vb1.tip_id = ot.id
				AND vb1.id = o.bldn_id
				AND o1.STATUS_ID <> 'закр'
				AND o1.TOTAL_SQ > 0
				AND c.is_build = 0
				AND c.date_del IS NULL
				AND (c.PeriodCheck IS NULL
				OR c.PeriodCheck > current_timestamp)
				AND c.id_pu_gis IS NOT NULL
				AND NOT EXISTS (SELECT
						1
					FROM dbo.SERVICES_TYPE_COUNTERS stc 
					WHERE stc.tip_id = vb1.tip_id
					AND stc.service_id = c.service_id
					AND stc.no_export_gis = 1))
			AS kol_pu_gis
		   ,MAX(COALESCE(ot.email_subscribe, '')) AS email_subscribe
		   ,MAX(COALESCE(ot.telefon, '')) AS telefon
		   ,o.bldn_id
		FROM dbo.OCC_SUPPLIERS os 
		JOIN dbo.VOCC o 
			ON os.Occ = o.Occ AND os.fin_id = o.fin_id
		JOIN dbo.VOCC_TYPES ot 
			ON o.tip_id = ot.id			
		JOIN dbo.SUPPLIERS_ALL sa 
			ON os.sup_id = sa.id
		JOIN dbo.View_BUILDINGS_LITE vb 
			ON o.bldn_id = vb.id
		WHERE ot.payms_value = 1
		AND (ot.id = @tip_id
		OR @tip_id IS NULL)
		AND (sa.id = @sup_id
		OR @sup_id IS NULL)
		AND o.STATUS_ID <> 'закр'
		AND o.TOTAL_SQ > 0
		AND (vb.id = @build
		OR @build IS NULL)
		AND NOT EXISTS (SELECT
				1
			FROM SUPPLIERS_TYPES st
			WHERE st.tip_id = ot.id
			AND st.sup_id = os.sup_id
			AND st.export_gis = 0)
		GROUP BY ot.id
				,ot.name
				,vb.adres
				,vb.CadastralNumber
				,o.bldn_id
				,os.fin_id
				,os.sup_id
				,os.dog_int
				,sa.name) AS t
	--ORDER BY 'Тип фонда', 'Адрес дома' --, t.kol_occ DESC	
	OPTION (MAXDOP 1, RECOMPILE)

END
go

