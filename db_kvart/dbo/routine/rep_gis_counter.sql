-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE                 PROCEDURE [dbo].[rep_gis_counter]
(
	@tip_id			   SMALLINT
   ,@build_id		   INT		= NULL
   ,@sup_id			   INT		= NULL
   ,@fin_id			   SMALLINT = NULL
   ,@tip_counter_build SMALLINT = NULL  -- 1-только ОПУ, 2-только ИПУ, иначе все
   ,@only_new		   BIT		= 0
)
AS
/*
exec rep_gis_counter 28,1031,323,186,1,0
exec rep_gis_counter 28,1031,323,186,2,1
exec rep_gis_counter 233,7791,null,191,2,1
exec rep_gis_counter 8,3255,null,186,2,0
*/
BEGIN
	SET NOCOUNT ON;

	--IF @build_id IS NULL
	--  AND system_user <> 'sa'
	--BEGIN
	--	RAISERROR ('Данные формируются только по дому!', 16, 1);
	--	RETURN
	--END

	IF @build_id IS NULL
		AND @sup_id IS NULL
		AND @tip_id IS NULL
		SELECT
			@build_id = 0
		   ,@sup_id = 0
		   ,@fin_id = 0
		   ,@tip_id = 0

	IF @only_new IS NULL
		SET @only_new = 0

	IF @fin_id IS NULL
		SELECT
			@fin_id = [dbo].[Fun_GetFinCurrent](@tip_id, @build_id, NULL, NULL)

	SELECT
		*
	FROM (SELECT
			c.id
		   ,vb.adres
		   ,f.nom_kvr
		   ,c.is_build
		   ,c.serial_number
		   ,COALESCE(c.id_pu_gis, '') AS id_pu_gis
		   ,CASE
				WHEN c.is_build = 1 THEN 'Коллективный (общедомовой)'
				WHEN dbo.Fun_GetCounter_occ(c.id, @fin_id) > 1 THEN 'Общий (квартирный)'
				--WHEN c.is_build=0 THEN 'Индивидуальный'
				ELSE 'Индивидуальный'
			END AS VidPU
		   ,c.type AS markaPU
		   ,c.type AS modelPU
		   ,CASE
				WHEN c.is_build = 1 THEN COALESCE(vb.kod_gis, vb.kod_fias)
				ELSE ''
			END AS id_build_gis
		   ,f.id_nom_gis AS id_nom_gis
		   ,CASE
				WHEN c.is_build = 1 THEN ''
				WHEN (COALESCE(t.id_jku_gis, '') <> '') THEN t.id_jku_gis
				--WHEN (COALESCE(t.id_els_gis, '') <> '') THEN t.id_els_gis
				ELSE LTRIM(STR(t.Occ))
			END AS id_els_gis
		   ,CASE c.service_id
				WHEN 'хвод' THEN 'Холодная вода'
				WHEN 'гвод' THEN 'Горячая вода'
				WHEN 'элек' THEN 'Электрическая энергия'
				WHEN 'пгаз' THEN 'Газ'
				WHEN 'отоп' THEN 'Тепловая энергия'
				ELSE c.service_id
			END                                     AS VidService
		   ,c.PeriodLastCheck
		   ,c.PeriodInterval
		   ,c.PeriodCheck
		   ,'Однотарифный'                          AS KolTarif
		   ,c.count_value                           AS T1
		   ,NULL                                    AS T2
		   ,NULL                                    AS T3
		   ,c.date_create                           AS data_vvoda
		   ,c.date_create    AS data_vvoda_work
		   , CASE
                 WHEN c.is_remot_reading = 1 THEN 'да'
                 ELSE 'нет'
            END              AS DistSnimok
		   ,''               AS DistSnimok2
		   , CASE
                 WHEN c.is_sensor_temp = 1 THEN 'да'
                 ELSE 'нет'
            END              AS datch_temp
		   , CASE
                 WHEN c.is_sensor_press = 1 THEN 'да'
                 ELSE 'нет'
            END              AS datch_davl
			-- Список других лиц.счетов по ПУ 
		   ,CAST(COALESCE((SELECT
					LTRIM(CASE
						WHEN os.occ_sup IS NOT NULL AND
						COALESCE(os.id_jku_gis, '') <> '' THEN os.id_jku_gis --
						WHEN os.occ_sup IS NOT NULL AND
						COALESCE(os.id_jku_gis, '') = '' THEN LTRIM(STR(os.occ_sup))
						WHEN (COALESCE(o.id_jku_gis, '') <> '') THEN o.id_jku_gis
						--WHEN (COALESCE(o.id_els_gis, '') <> '') THEN o.id_els_gis
						ELSE LTRIM(STR(o.Occ))
					END) + ';'
				FROM dbo.COUNTER_LIST_ALL cla
				JOIN dbo.OCCUPATIONS o 
					ON cla.Occ = o.Occ
				LEFT JOIN OCC_SUPPLIERS os 
					ON o.Occ = os.Occ
					AND os.fin_id = @fin_id
					AND os.sup_id = @sup_id
				WHERE cla.counter_id = c.id
				AND cla.fin_id = @fin_id
				--o.flat_id = f.id
				AND o.STATUS_ID <> 'закр'
				AND o.TOTAL_SQ > 0
				AND (CASE
					WHEN os.occ_sup IS NOT NULL THEN os.occ_sup
					ELSE o.Occ
				END) <> t.Occ
				FOR XML PATH (''))
			, '')
			AS VARCHAR(100)) AS occ_flat
		   ,vb.kod_fias
		   ,vb.street_name
		   ,vb.nom_dom_sort
		   ,f.nom_kvr_sort
		   ,CASE
				WHEN c.unit_id = 'квтч' THEN 'Киловатт-час'
				WHEN c.unit_id = 'кубм' THEN 'Кубический метр'
				WHEN c.unit_id = 'ггкл' THEN 'Гигакалория'
				ELSE c.unit_id
			END AS unit_id
		   ,t.Occ
		   ,t_stc.tip_is_export_gis AS tip_is_export_gis
		   ,coalesce(t_sb.build_is_export_gis, 1) AS build_is_export_gis
		   ,CASE 
                          	WHEN t_sb.build_is_export_gis IN (1,0) THEN t_sb.build_is_export_gis
                          	WHEN t_stc.tip_is_export_gis=0  THEN CAST(0 AS BIT)
                          	ELSE CAST(1 AS BIT)
                          END as is_export_gis
			,c.date_load_gis
			,c.date_edit
			,rooms.count_room_gis
		FROM dbo.Counters c 
		JOIN dbo.View_buildings vb
			ON c.build_id = vb.id
		LEFT JOIN dbo.Flats f
			ON c.flat_id = f.id
		OUTER APPLY (SELECT count(*) AS count_room_gis FROM dbo.Rooms as r WHERE r.flat_id=f.id AND r.id_room_gis IS NOT NULL) AS rooms			
		OUTER APPLY (SELECT TOP 1
				CASE
					WHEN os.occ_sup IS NOT NULL THEN os.occ_sup
					ELSE o.occ
				END AS occ
			   ,o.id_els_gis
			   ,CASE
					WHEN os.occ_sup IS NOT NULL THEN os.id_jku_gis
					ELSE o.id_jku_gis
				END AS id_jku_gis
			   ,o.CadastralNumber
			FROM dbo.Counter_list_all cla 
			JOIN dbo.Occupations o 
				ON cla.occ = o.occ
			LEFT JOIN dbo.Occ_suppliers os 
				ON o.occ = os.occ
				AND os.fin_id = @fin_id
				AND os.sup_id = @sup_id
			WHERE cla.counter_id = c.id
			AND cla.fin_id = @fin_id
			--o.flat_id = f.id
			AND o.STATUS_ID <> 'закр'
			AND o.TOTAL_SQ > 0
			ORDER BY id_jku_gis) t
		OUTER APPLY  (SELECT
				CAST(CASE
                         WHEN stc.no_export_gis = 1 THEN 0
                         ELSE 1
                    END AS BIT) AS tip_is_export_gis
			FROM dbo.Services_type_counters stc
			WHERE stc.tip_id = vb.tip_id
			AND stc.service_id = c.service_id
			AND stc.no_export_gis = 1) AS t_stc
		OUTER APPLY  (SELECT
				sb.is_export_gis AS build_is_export_gis
			FROM dbo.Services_build sb 
			WHERE sb.build_id = vb.id
			AND sb.service_id = c.service_id
			--AND sb.is_export_gis = 1
			) AS t_sb
		WHERE vb.tip_id = @tip_id
		AND vb.is_paym_build = CAST(1 AS BIT)  -- дома, которым начисляем 
		AND (@build_id IS NULL OR c.build_id = @build_id)
		AND c.is_build = CAST(
			CASE
				WHEN @tip_counter_build = 1 THEN 1
				WHEN @tip_counter_build = 2 THEN 0
				ELSE c.is_build
			END AS BIT)
		AND c.date_del IS NULL
		AND (c.PeriodCheck IS NULL
		OR c.PeriodCheck > current_timestamp)
		AND (@sup_id IS NULL
		OR (c.is_build = CAST(1 AS BIT)
		AND @tip_counter_build <> 2)
		OR EXISTS (SELECT
				1
			FROM dbo.Occ_suppliers os 
			JOIN dbo.Occupations o1 
				ON os.Occ = o1.Occ
			WHERE os.fin_id = vb.fin_current
			AND o1.flat_id = f.id
			AND os.sup_id = @sup_id
			AND c.is_build = 0)
		)) AS t
	WHERE (id_pu_gis =
		CASE @only_new
			WHEN 1 THEN ''
			ELSE id_pu_gis
		END
		OR 	t.date_load_gis<t.date_edit
		)
	AND ((t.is_build = 0
	AND id_nom_gis <> '')
	OR (t.is_build = 1
	AND id_build_gis <> '')
	)
	AND (is_export_gis=1)
	AND id_els_gis IS NOT NULL
	ORDER BY street_name, nom_dom_sort, nom_kvr_sort

END
go

