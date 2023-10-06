CREATE   PROCEDURE [dbo].[k_counter_inspector_build]
(
	@build_id1 INT -- код дома
   ,@fin_id1   SMALLINT = NULL
   ,@count_fin SMALLINT = 12 -- кол-во последних фин.периодов для показа
)
AS
	/*
	  Показываем показания ИПУ по дому
	  
	  k_counter_inspector_build 1031,156
	  k_counter_inspector_build 1031,null
	  k_counter_inspector_build 715,null
	*/
	SET NOCOUNT ON

	IF @fin_id1 = 0
		SET @fin_id1 = NULL
	IF @count_fin IS NULL
		SET @count_fin = 12

	DECLARE @fin_current  SMALLINT
		   ,@fin_id_start SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, @build_id1, NULL, NULL)
	SET @fin_id_start = @fin_current - @count_fin

	SELECT
		ci.id
	   ,ci.counter_id
	   ,ci.tip_value
	   ,CAST(ci.inspector_value AS INT) AS inspector_value
	   ,ci.inspector_value AS insp_value_decimal
	   ,ci.inspector_date
	   ,ci.blocked
	   ,ci.user_edit
	   ,ci.date_edit
	   ,ci.kol_day
	   ,CAST(ci.actual_value AS INT) AS actual_value
	   ,ci.actual_value AS actual_value_decimal
	   ,ci.value_vday
	   ,ci.comments
	   ,ci.fin_id
	   ,ci.mode_id
	   ,ci.tarif
	   ,ci.value_paym
	   ,u.Initials AS Name_user
	   ,cp.StrFinPeriod AS Fin_name
	   ,CASE
			WHEN COALESCE(ci.mode_id, 0) = 0 THEN 'Текущий'
			ELSE (SELECT
					name
				FROM dbo.Cons_modes 
				WHERE id = ci.mode_id)
		END AS mode_name
	   ,ci.volume_arenda
	   ,ci.volume_odn
	   ,ci.norma_odn
	   ,ci.volume_direct_contract
	   ,ci.is_info
	   ,C.service_id
	   ,vs.name AS serv_name
	   ,F.nom_kvr
	   ,C.is_build
	   ,CASE
			WHEN ci.tip_value = 1 THEN 'Квартиросьёмщика'
			ELSE 'Инспектора'
		END     AS tip_value_name
	   , vbl.adres + CASE
                         WHEN F.nom_kvr IS NULL THEN ''
                         ELSE concat(' кв.' , F.nom_kvr)
        END  AS adres
	FROM dbo.Counter_inspector AS ci 
	JOIN dbo.Counters C
		ON ci.counter_id = C.id
	JOIN dbo.View_services vs 
		ON C.service_id = vs.id
	LEFT JOIN dbo.Flats F 
		ON C.flat_id = F.id
	LEFT JOIN dbo.Users u 
		ON ci.user_edit = u.id
	JOIN dbo.Calendar_period cp 
		ON cp.fin_id = ci.fin_id
	JOIN View_buildings_lite vbl 
		ON C.build_id = vbl.id
	WHERE 
		C.build_id = @build_id1
		AND (ci.fin_id = @fin_id1 OR @fin_id1 IS NULL OR ci.fin_id = 0)
		AND ci.fin_id >= @fin_id_start
	ORDER BY F.nom_kvr_sort, inspector_date DESC, ci.fin_id DESC
go

