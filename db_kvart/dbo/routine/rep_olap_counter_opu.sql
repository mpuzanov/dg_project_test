-- =============================================
-- Author:		Пузанов
-- Create date: 23.02.2013
-- Description:	Счётчики
-- =============================================
CREATE               PROCEDURE [dbo].[rep_olap_counter_opu]
(
	  @build INT = NULL
	, @fin_id1 SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
	, @tip_id SMALLINT = NULL
	, @is_sort BIT = NULL
	, @sector_id INT = NULL
	, @service_id VARCHAR(10) = NULL
)
AS
/*
exec rep_olap_counter_opu null, 250,250,1
exec rep_olap_counter_opu null, 171,171,28,1
*/
BEGIN
	SET NOCOUNT ON;


	IF @build IS NULL
		AND @tip_id IS NULL
		SET @build = 0
	--print @fin_start

	DECLARE @fin_current SMALLINT
	SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip_id, @build, NULL, NULL)

	IF @fin_id1 = 0
		OR @fin_id1 IS NULL
		SET @fin_id1 = @fin_current
	IF @fin_id2 = 0
		OR @fin_id2 IS NULL
		SET @fin_id2 = @fin_current

	-- для ограничения доступа услуг
	CREATE TABLE #s (
		  id VARCHAR(10) COLLATE database_default PRIMARY KEY
		, [name] VARCHAR(100) COLLATE database_default
	)
	INSERT INTO #s (id, name) SELECT id, name FROM dbo.View_services

	SELECT b.start_date AS 'Период'
		 , C.build_id AS 'Код дома'
		 , b.sector_name AS 'Участок'
		 , b.town_name AS 'Населенный пункт'
		 , b.adres AS 'Адрес дома'
		 , b.street_name AS 'Улица'
		 , b.nom_dom AS 'Номер дома'
		   --,s.name AS 'Услуга'
		 , CASE 
			 WHEN(COALESCE(servt.service_name_full,'')='') THEN s.[name]
			 ELSE servt.service_name_full
		   END AS 'Услуга' -- заменяем наименования услуг по типам фонда
		 , C.unit_id AS 'Ед.измерения'
		 , C.date_create AS 'Дата установки'
		 , C.date_del AS 'Дата закрытия'
		 , C.PeriodCheck AS 'Период поверки'
		 , C.date_edit AS 'Дата редактирования'
		 , b.tip_name AS 'Тип фонда'
		 , C.serial_number AS 'Серийный номер'
		 , C.id AS 'Код счётчика'		 
		 , C.max_value AS 'Разрядность'
		 , C.[type] AS 'Тип прибора'
		 , C.count_value AS 'Нач.значение'
		 , ci.inspector_date AS 'Дата посл.значения'
		 , COALESCE(ci.inspector_value, 0) AS 'Послед.значение'
		 , COALESCE(ci.volume_odn, 0) AS 'Объём ОДН'
		 , COALESCE(ci.volume_direct_contract, 0) AS 'Объём РСО'
		 , COALESCE(ci.norma_odn, 0) AS 'Норматив ОДН'
		 , ci_pred.inspector_date AS 'Дата пред.значения'
		 , COALESCE(ci_pred.inspector_value, 0) AS 'Пред.значение'
		 , COALESCE(ci_pred.volume_odn, 0) AS 'Пред.Объём ОДН'
		 , COALESCE(ci_pred.volume_direct_contract, 0) AS 'Пред.Объём РСО'
		 , COALESCE(ci.volume_arenda, 0) AS 'Объём по нежилым'
		 , COALESCE(ci.actual_value, 0) AS 'Объём'
		 , COALESCE(ci.volume_arenda, 0) + COALESCE(ci.actual_value, 0) AS 'Объём общий'
		 , CASE WHEN(sb.is_direct_contract=1) THEN 'Да' ELSE 'Нет' END AS 'Прямой договор'
		 , b.nom_dom AS 'Дом'
		 , b1.kod_fias AS 'Дом по ФИАС'
		 , b1.id_nom_dom_gis AS 'Код дома в ГИС ЖКХ'
		 , b1.is_boiler AS 'Наличие бойлера'
		 , CONCAT(b.street_name, b.nom_dom_sort) AS sort_dom
		 , b.nom_dom_sort
		 , c.counter_uid AS 'УИД счётчика'
	FROM dbo.Counters AS C 
		JOIN #s AS s ON 
			C.service_id = s.id
		JOIN dbo.View_build_all AS b ON 
			C.build_id = b.build_id
		JOIN dbo.Buildings AS b1 ON 
			b1.id = C.build_id
		LEFT JOIN dbo.Services_build AS sb ON 
			sb.service_id = s.id
			AND sb.build_id = b1.id
		LEFT JOIN dbo.Services_types AS servt ON 
			servt.service_id = s.id
			AND servt.tip_id = b.tip_id
		OUTER APPLY [dbo].Fun_GetCounterTableValue_Current(C.id, b.fin_id) AS ci
		OUTER APPLY [dbo].Fun_GetCounterTableValue_Pred(C.id, b.fin_id) AS ci_pred
	WHERE 
		b.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND (@build IS NULL OR C.build_id = @build)
		AND (@tip_id IS NULL OR b.tip_id = @tip_id)
		AND (@sector_id IS NULL OR b.sector_id = @sector_id)
		AND (@service_id IS NULL OR c.service_id=@service_id)
		AND C.is_build = CAST(1 AS BIT)
		AND b.is_paym_build=CAST(1 AS BIT)
	ORDER BY CASE
				 WHEN @is_sort = CAST(1 AS BIT) THEN b.street_name
			 END
		   , CASE
				 WHEN @is_sort = CAST(1 AS BIT) THEN b.nom_dom_sort
			 END
	OPTION (MAXDOP 1);

END
go

