CREATE   PROCEDURE [dbo].[k_intPrintDetail_occ_all_sup2]
(
	  @Fin_Id1 SMALLINT -- Фин.период
	, @build_id INT = NULL	-- дом
	, @Occ1 INT = NULL	-- лицевой
	, @Tip_Id SMALLINT = NULL --жилой фонд
	, @Sup_Id INT = 0
	, @Debug BIT = 0
)
/*
Выдаем информацию по услугам для единой квитанции с общедомовыми услугами

exec k_intPrintDetail_occ_all_sup2 @Fin_Id1=229,@Occ1=910010016
exec k_intPrintDetail_occ_all_sup2 176,1054,NULL,28,323,1 
exec k_intPrintDetail_occ_all_sup2 @Fin_Id1=234,@build_id=NULL,@Occ1=314678,@Tip_Id=NULL,@Sup_Id=null,@Debug=1 
exec k_intPrintDetail_occ_all_sup2 @Fin_Id1=231,@build_id=6785

*/
AS
	SET NOCOUNT ON

	DECLARE @Fin_Current1 SMALLINT
		  , @NamesOdeRhoUsing VARCHAR(30)
		  , @Service_Id1 VARCHAR(10)
		  , @Serv_From VARCHAR(20)
		  , @Total_sq DECIMAL(9, 2) = 0
		  , @Db_Name VARCHAR(20) = UPPER(DB_NAME())
		  , @strerror VARCHAR(300)

	--****************************************************************        
	BEGIN TRY
		IF @Occ1 IS NOT NULL
			SELECT @Occ1 = dbo.Fun_GetFalseOccIn(@Occ1)

		SELECT @Fin_Current1 = dbo.Fun_GetFinCurrent(@Tip_Id, @build_id, NULL, @Occ1)

		IF @Sup_Id IS NULL
			SET @Sup_Id = 0
		--***********************************************************************

		DECLARE @T_Serv_From TABLE (
			  service_id VARCHAR(10)
			, serv_from VARCHAR(10)
		)
		INSERT INTO @T_Serv_From
			(service_id
		   , serv_from)
		SELECT s.id
			   --,s.serv_from
			 , sf.value
		FROM dbo.Services s
			CROSS APPLY (
				SELECT s.id
					 , SUBSTRING(value, 1, 4) AS value
				FROM STRING_SPLIT(serv_from, ';')
				WHERE RTRIM(value) <> ''
			) AS sf
		WHERE serv_from IS NOT NULL
			AND serv_from <> ''

		-- Табличная переменная немного выигрывает над временной таблицей
		DECLARE @T TABLE (
			  build_id INT
			, occ INT
			, short_name VARCHAR(50)
			, short_id VARCHAR(6)
			, service_id VARCHAR(10)
			, tarif DECIMAL(10, 4) DEFAULT 0
			, kol DECIMAL(12, 6) DEFAULT 0
			, kol_dom DECIMAL(12, 6) DEFAULT 0
			, koef DECIMAL(10, 4) DEFAULT 1
			, saldo DECIMAL(15, 4) DEFAULT 0
			, value DECIMAL(15, 4) DEFAULT 0
			, value_dom DECIMAL(15, 4) DEFAULT 0
			, value_itog AS (value + value_dom)
			, added1 DECIMAL(15, 4) DEFAULT 0
			, added12 DECIMAL(15, 4) DEFAULT 0
			, added AS (added1 - added12)
			, paid DECIMAL(15, 4) DEFAULT 0
			, paid_dom DECIMAL(15, 4) DEFAULT 0
			, paid_koef_up DECIMAL(15, 4) DEFAULT 0
			, paid_itog AS (paid + paid_dom + paid_koef_up)
			, debt DECIMAL(15, 4) DEFAULT 0
			, sort_no INT DEFAULT 100
			, mode_id INT DEFAULT NULL
			, unit_id VARCHAR(10) DEFAULT NULL
			, is_build BIT DEFAULT 0
			, service_id_from VARCHAR(10) DEFAULT NULL
			, sup_id INT DEFAULT 0
			, account_one BIT DEFAULT 0
			, is_sum BIT DEFAULT 1
			, subsid_only BIT DEFAULT 0
			, tip_id SMALLINT DEFAULT 0
			, VSODER BIT DEFAULT 0
			, VYDEL BIT DEFAULT 0
			, owner_id INT DEFAULT 0
			, [service_name] VARCHAR(50) DEFAULT ''
			, OWNER_ID_BUILD INT DEFAULT 0
			, metod SMALLINT DEFAULT 0
			, service_name_gis NVARCHAR(100) DEFAULT NULL
			, service_type SMALLINT DEFAULT 1
			, is_counter SMALLINT DEFAULT 0
			, reason_added VARCHAR(800) DEFAULT NULL -- причина перерасчёта по услугам
			, is_koef_up BIT DEFAULT 0
			, no_export_volume_gis BIT DEFAULT 0
			, koef_up DECIMAL(9, 4) DEFAULT NULL
			, total_sq DECIMAL(9, 2) DEFAULT 0
			, group_name_kvit VARCHAR(100) DEFAULT ''
			, group_sort_id SMALLINT DEFAULT 0
			, blocked_kvit BIT DEFAULT 0
			, penalty_serv DECIMAL(15, 4) DEFAULT 0
		)

		IF @Fin_Id1 >= @Fin_Current1
		BEGIN

			INSERT INTO @T
				(build_id
			   , occ
			   , short_name
			   , short_id
			   , service_id
			   , tarif
			   , kol
			   , koef
			   , saldo
			   , value
			   , added1
			   , paid
			   , debt
			   , sort_no
			   , mode_id
			   , unit_id
			   , service_id_from
			   , is_build
			   , sup_id
			   , account_one
			   , subsid_only
			  , tip_id
			   , VSODER
			   , VYDEL
			   , owner_id
			   , [service_name]
			   , metod
			   , service_type
			   , is_counter
			   , is_koef_up
			   , no_export_volume_gis
			   , total_sq
			   , blocked_kvit
			   , penalty_serv)
			SELECT f.bldn_id
				 , p.occ
				 , s.short_name
				 , CASE
                       WHEN LEN(st.short_id) > 0 THEN st.short_id
                       ELSE u.short_id
                END                                AS short_id
				 , p.service_id
				 , COALESCE(p.tarif, 0)            AS tarif
				 , COALESCE(ROUND(p.kol, CASE
                                             WHEN u.precision = 0 THEN 4
                                             ELSE u.precision
                END), 0)                           AS kol
				 , p.koef
				 , p.saldo
				 , p.value
				 , p.added
				 , p.paid
				 , p.debt
				 , COALESCE(st.sort_no, s.sort_no) AS sort_no
				 , NULL
				 , p.unit_id
				 , CASE
					   WHEN serv_from IS NULL THEN NULL
					   ELSE SUBSTRING(serv_from, 1, 4)
				   END
				 , is_build
				 , cl.sup_id
				 , p.account_one
				 , p.subsid_only
				 , o.tip_id
				 , COALESCE(st.VSODER, 0)
				 , COALESCE(st.VYDEL, 0)
				 , COALESCE(st.owner_id, 0)
				 , COALESCE(st.service_name, '')
				 , COALESCE(p.metod, 0) AS metod
				 , s.service_type
				 , COALESCE(cl.is_counter, 0)
				 , s.is_koef_up
				 , s.no_export_volume_gis
				 , o.total_sq
				 , st.blocked_kvit
				 , p.penalty_serv
			FROM dbo.Occupations AS o 
				JOIN dbo.Flats f ON o.flat_id = f.id
				JOIN dbo.Paym_list AS p ON o.occ = p.occ
				JOIN dbo.Services AS s ON p.service_id = s.id
				LEFT JOIN dbo.Consmodes_list AS cl ON p.occ = cl.occ
					AND p.service_id = cl.service_id
					AND p.sup_id = cl.sup_id
				LEFT JOIN dbo.Units AS u ON p.unit_id = u.id
				LEFT JOIN dbo.Services_types AS st ON st.service_id = s.id
					AND st.tip_id = o.tip_id
			WHERE (@Occ1 IS NULL OR o.occ = @Occ1)
				AND (@build_id IS NULL OR f.bldn_id = @build_id)
				AND (@Tip_Id IS NULL OR o.tip_id = @Tip_Id)
				--AND (p.subsid_only = 0)
		END
		ELSE
		BEGIN

			INSERT INTO @T
				(build_id
			   , occ
			   , short_name
			   , short_id
			   , service_id
			   , tarif
			   , kol
			   , koef
			   , saldo
			   , value
			   , added1
			   , paid
			   , debt
			   , sort_no
			   , mode_id
			   , unit_id
			   , service_id_from
			   , is_build
			   , sup_id
			   , account_one
			   , subsid_only
			   , tip_id
			   , VSODER
			   , VYDEL
			   , owner_id
			   , [service_name]
			   , metod
			   , service_type
			   , is_counter
			   , is_koef_up
			   , no_export_volume_gis
			   , total_sq
			   , blocked_kvit
			   , penalty_serv)
			SELECT f.bldn_id
				 , o.occ
				 , s.short_name
				 , CASE
                       WHEN LEN(st.short_id) > 0 THEN st.short_id
                       ELSE u.short_id
                END                                AS short_id
				 , s.id
				 , COALESCE(p.tarif, 0)            AS tarif
				 , COALESCE(ROUND(p.kol, CASE
                                             WHEN u.precision = 0 THEN 4
                                             ELSE u.precision
                END), 0)                           AS kol
				 , p.koef
				 , COALESCE(p.saldo, 0)
				 , COALESCE(p.value, 0)
				 , COALESCE(p.added, 0)
				 , COALESCE(p.paid, 0)
				 , COALESCE(p.debt, 0)
				 , COALESCE(st.sort_no, s.sort_no) AS sort_no
				 , p.mode_id
				 , p.unit_id
				 , CASE
					   WHEN s.serv_from IS NULL THEN NULL
					   ELSE SUBSTRING(s.serv_from, 1, 4)
				   END
				 , is_build
				 , COALESCE(p.sup_id, 0)
				 , COALESCE(p.account_one, 0)
				 , COALESCE(p.subsid_only, 0)
				 , o.tip_id
				 , COALESCE(st.VSODER, 0)
				 , COALESCE(st.VYDEL, 0)
				 , COALESCE(st.owner_id, 0)
				 , COALESCE(st.service_name, '')
				 , p.metod
				 , s.service_type
				 , COALESCE(p.is_counter, 0) --COALESCE(cl.is_counter, 0)
				 , s.is_koef_up
				 , s.no_export_volume_gis
				 , o.total_sq
				 , st.blocked_kvit
				 , p.penalty_serv
			FROM dbo.Occ_history AS o 
				JOIN dbo.Flats f ON o.flat_id = f.id
				LEFT JOIN dbo.Paym_history AS p ON o.occ = p.occ
					AND o.fin_id = p.fin_id
				--AND s.id = p.service_id --AND (p.subsid_only = 0)
				JOIN dbo.Services AS s ON s.id = p.service_id --AND (p.subsid_only = 0)
				LEFT JOIN dbo.Service_units AS su ON s.id = su.service_id
					AND o.roomtype_id = su.roomtype_id
					AND (o.fin_id = su.fin_id)
					AND (o.tip_id = su.tip_id)
				LEFT JOIN dbo.Units AS u ON su.unit_id = u.id
				LEFT JOIN dbo.Services_types AS st ON st.service_id = s.id
					AND st.tip_id = o.tip_id
			WHERE (o.fin_id = @Fin_Id1)
				AND (@Occ1 IS NULL OR o.occ = @Occ1)
				AND (@build_id IS NULL OR f.bldn_id = @build_id)
				AND (@Tip_Id IS NULL OR o.tip_id = @Tip_Id)

			-- Обновляем ед.измерения если у режима другой
			UPDATE t
			SET short_id = u.short_id
			FROM @T AS t
				JOIN dbo.Cons_modes_history AS cm ON t.mode_id = cm.mode_id
				JOIN dbo.Units AS u ON cm.unit_id = u.id
			WHERE cm.fin_id = @Fin_Id1
				AND t.short_id <> u.short_id

			-- если есть сохранённая ед.измерения
			UPDATE t
			SET short_id = u.short_id
			FROM @T AS t
				JOIN dbo.Units AS u ON t.unit_id = u.id
			WHERE u.short_id IS NOT NULL
		END

		SELECT TOP (1) @Tip_Id = tip_id
					 , @build_id = build_id
		FROM @T

		IF @Debug = 1
			SELECT '1'
				 , *
			FROM @T

		-- ставим группировочное название из типа фонда
		UPDATE t
		SET service_name = COALESCE(sb.service_name, '')
		FROM @T AS t
			JOIN dbo.Services_types AS sb ON t.owner_id = sb.id
		WHERE sb.tip_id = t.tip_id


		UPDATE t
		SET VSODER = COALESCE(sb.VSODER, 0)
		  , VYDEL = COALESCE(sb.VYDEL, 0)
		  , OWNER_ID_BUILD = COALESCE(sb.owner_id, 0)
		  , owner_id =
					  CASE
						  WHEN sb.owner_id > 0 THEN sb.owner_id  -- 21.03.2019
						  WHEN (COALESCE(sb.owner_id, 0) = 0) AND
							  (sb.VSODER = 0) AND
							  (sb.VYDEL = 1) THEN 0
						  ELSE t.owner_id
					  END
		  , blocked_kvit = sb.blocked_kvit
		FROM @T AS t
			JOIN dbo.Services_build AS sb ON t.service_id = sb.service_id
		WHERE sb.build_id = t.build_id

		-- ставим группировочное название из дома
		UPDATE t
		SET service_name = COALESCE(sb.service_name, '')
		FROM @T AS t
			JOIN dbo.Services_build AS sb ON t.OWNER_ID_BUILD = sb.id
		WHERE sb.build_id = t.build_id

		UPDATE @T
		SET sup_id = COALESCE(sup_id, 0)
		  , metod =
				   CASE metod
					   WHEN 4 THEN NULL
					   ELSE metod
				   END

		--UPDATE @T
		--SET	OWNER_ID=0
		--FROM @T AS t
		--WHERE (OWNER_ID<>0) AND VYDEL = 1

		IF @Debug = 1
			SELECT '2'
				 , *
			FROM @T

		-- Проставляяем ед.измерения, где нет
		UPDATE t
		SET unit_id = U.id
		  , short_id = U.short_id
		FROM @T AS t
			JOIN dbo.Service_units SU ON SU.service_id = t.service_id
			JOIN dbo.Units U ON U.id = SU.unit_id
		WHERE t.short_id IS NULL
			AND SU.roomtype_id = 'отдк'
			AND SU.fin_id = @Fin_Id1
			AND SU.tip_id = t.tip_id

		UPDATE @T
		SET value = 0
		  , kol = 0
		  , paid = 0
		  , tarif = 0
		WHERE subsid_only = 1

		-- устанавливаем нужные Перерасчеты ************************
		UPDATE t
		SET added12 = COALESCE(t2.value12, 0)
		  , added1 = COALESCE(t2.value, 0)
		FROM @T AS t
			OUTER APPLY (
				SELECT SUM(vp.value) AS value
					 , SUM(CASE
                               WHEN add_type = 15 THEN vp.value
                               ELSE 0
                    END) AS value12
				FROM dbo.View_added_lite_short AS vp
					JOIN dbo.Added_Types at ON vp.add_type = at.id
				WHERE vp.occ = t.occ
					AND vp.fin_id = @Fin_Id1
					AND vp.service_id = t.service_id
					AND vp.sup_id = t.sup_id
					AND at.visible_kvit = 1
				GROUP BY vp.occ
					   , vp.service_id
					   , vp.sup_id
			) AS t2
		--*******************************************************
		-- Заполняем причину перерасчёта по услугам
		UPDATE t
		SET reason_added = (
			SELECT [dbo].[Fun_GetAddStr](t.occ, @Fin_Id1, t.sup_id, t.service_id)
		)
		FROM @T AS t

		-- удалить из начислений скрытые разовые
		UPDATE t
		SET paid = t.paid - COALESCE(CAST(added_hide.add_value_hide AS DECIMAL(15, 4)), 0)
		FROM @T AS t
			CROSS APPLY (
				SELECT SUM(vp.value) AS add_value_hide
				FROM dbo.View_added_lite_short AS vp
					JOIN dbo.Added_Types at ON vp.add_type = at.id
				WHERE vp.occ = t.occ
					AND vp.fin_id = @Fin_Id1
					AND vp.service_id = t.service_id
					AND vp.sup_id = t.sup_id
					AND at.visible_kvit = 0
			) AS added_hide
		--***************************************************************

		IF @Debug = 1
			SELECT '3'
				 , *
			FROM @T

		--select * from @t order by sort_no

		--SELECT
		--	@NamesOdeRhoUsing = NameSoderHousing
		--FROM dbo.OCCUPATION_TYPES
		--WHERE id = @Tip_Id

		--IF @NamesOdeRhoUsing IS NULL
		--	OR @NamesOdeRhoUsing = ''
		--	SET @NamesOdeRhoUsing = 'С.жилья в т.ч:'

		--IF @Debug=1 print @NamesOdeRhoUsing
		--IF @Debug=1	SELECT * FROM @T AS t


		---- Удаляем тариф если нет начислений
		--UPDATE t
		--SET tarif = 0
		--FROM @T AS t
		--WHERE value = 0
		--	AND paid = 0
		--	AND kol_dom = 0

		-- бывает что электричества нет , а Эл.энергия на ОДН есть
		INSERT INTO @T
			(occ
		   , short_name
		   , short_id
		   , service_id)
		SELECT t.*
		FROM (
			SELECT DISTINCT occ
						  , 'Эл.энергия' AS short_name
						  , 'кВтч' AS short_id
						  , 'элек' AS service_id
			FROM @T
		) AS t
			LEFT JOIN @T AS t2 ON t.occ = t2.occ
				AND t.service_id = t2.service_id
		WHERE t2.service_id IS NULL

		IF @Debug = 1
			SELECT 4
				 , *
			FROM @T
		--IF @debug=1 SELECT * FROM @t_serv_from
		--RETURN
		-- Заполняем общедомовые колонки
		UPDATE t1
		SET tarif =
				   CASE
					   WHEN t1.tarif = 0 AND
						   t2.tarif > 0 THEN t2.tarif
					   ELSE t1.tarif
				   END
		  , kol_dom = COALESCE(t2.kol, 0)
		  , value_dom = t2.value
		  , paid_dom = t2.paid
		  , added1 = t1.added1 + t2.added
		  , added12 = t1.added12 + t2.added12
		  , sup_id =
					CASE
						WHEN t2.sup_id > 0 AND
							t1.sup_id = 0 AND
							t1.value = 0 THEN t2.sup_id
						ELSE t1.sup_id
					END
		  , debt = t1.debt + t2.debt
		FROM @T AS t1
			JOIN (
				SELECT g.sup_id
					 , g.occ
					 , g.service_id_from
					 , MAX(g.tarif) AS tarif
					 , kol = SUM(g.kol)
					 , value = SUM(g.value)
					 , paid = SUM(g.paid)
					 , added = SUM(g.added)
					 , added12 = SUM(g.added12)
					 , debt = SUM(g.debt)
				FROM @T AS g
				WHERE g.is_build = 1
				GROUP BY g.occ
					   , g.sup_id
					   , g.service_id_from
			--,g.tarif
			) AS t2 ON t1.occ = t2.occ
				AND t1.sup_id = t2.sup_id
				AND t1.service_id = t2.service_id_from
		WHERE (t2.value > 0)
			OR (t2.tarif > 0)
			OR (t2.kol > 0)
			OR (t2.added <> 0)

		DELETE FROM @T
		WHERE (paid_dom = 0
			AND value = 0
			AND added = 0
			AND paid = 0
			AND NOT (COALESCE(metod, 0) = 3
			AND tarif > 0
			AND mode_id % 1000 <> 0
			AND @Db_Name LIKE '%KR1%'
			)
			AND VYDEL = 0)

		IF @Debug = 1
			SELECT '5'
				 , *
			FROM @T

		INSERT INTO @T
			(build_id
		   , occ
		   , tip_id
		   , sup_id
		   , short_name
		   , short_id
		   , service_id
		   , tarif
		   , kol
		   , koef
		   , saldo
		   , value
		   , added1
		   , added12
		   , paid
		   , debt
		   , sort_no
		   , kol_dom
		   , value_dom
		   , paid_dom
		   , metod
		   , service_type
		   , is_counter
		   , reason_added
		   , total_sq)
		SELECT t.build_id
			 , t.occ
			 , MAX(t.tip_id)
			 , t.sup_id
			 , service_name
			 , t.short_id
			 , 'итог'
			 , tarif =
					  CASE
						  WHEN t.short_id = 'м2' THEN SUM(tarif)
						  ELSE MAX(tarif)
					  END
			 , kol =
					CASE
						WHEN t.short_id = 'м2' THEN MAX(total_sq)
						ELSE SUM(kol)
					END
			 , 1
			 , SUM(saldo)
			 , SUM(value)
			 , SUM(added1)
			 , SUM(added12)
			 , SUM(paid)
			 , SUM(debt)
			 , sort_no =
						CASE
							WHEN short_id = 'м2' THEN 1
							ELSE 2
						END
			 , SUM(kol_dom)
			 , SUM(value_dom)
			 , SUM(paid_dom)
			 , MIN(COALESCE(t.metod, 0))
			 , MAX(service_type)
			 , MAX(is_counter)
			 , MAX(COALESCE(reason_added, ''))
			 , MAX(t.total_sq)
		FROM @T AS t
		WHERE COALESCE(sup_id, 0) = @Sup_Id
			AND t.owner_id <> 0
		GROUP BY t.build_id
			   , t.occ
			   , t.sup_id
			   , service_name
			   , t.short_id
			   , t.owner_id
			   , t.short_id

		--IF @Debug=1 SELECT '6', * FROM @T
	
		-- Изменяем метод расчёта для вывода в квитанции
		-- метод в базе (0-не начислять,1-по норме,2-по среднему,3-по счетчику, 4-по общедомовому счётчику, 5 - на основании другой услуги)
		-- в рекомендованной квитанции надо (1)-норматив, (2)-показаний ИПУ; (3)-среднемесячного потребления; (4)-исходя из показаний ОПУ;
		--UPDATE t
		--SET metod=CASE 
		--                	WHEN metod=2 THEN 3
		--                	WHEN metod=3 THEN 2
		--                	ELSE 0
		--                END
		--FROM @T AS t
		--WHERE t.metod IS NOT NULL

		DELETE t
		FROM @T AS t
		WHERE VSODER = 1
			AND VYDEL = 0

		DELETE t
		FROM @T AS t
		WHERE t.owner_id <> 0
			AND VYDEL = 0

		UPDATE @T
		SET paid = 0
		  , is_sum = 0
		FROM @T AS t
		WHERE VSODER = 1
			AND VYDEL = 1

		-- Изменяем если есть названия услуг по разным типам фонда
		UPDATE t
		SET short_name = st.service_name
		FROM @T AS t
			JOIN dbo.Services_types AS st ON t.service_id = st.service_id
		WHERE st.tip_id = t.tip_id

		-- Изменяем если есть названия услуг по разным домам
		UPDATE t
		SET short_name = sb.service_name
		FROM @T AS t
			JOIN dbo.Services_build AS sb ON t.service_id = sb.service_id
		WHERE sb.build_id = t.build_id

		--**********************************************************
		UPDATE t
		SET service_name_gis = LTRIM(RTRIM(st.service_name_gis))
		FROM @T AS t
			JOIN dbo.Services_types AS st ON t.service_id = st.service_id   -- сначала по коду услуги
		WHERE st.tip_id = t.tip_id

		UPDATE t
		SET service_name_gis = LTRIM(RTRIM(st.service_name_gis))
		FROM @T AS t
			JOIN dbo.Services_types AS st ON t.short_name = st.service_name  -- потом по наименованию (допустим где кода услуги нет(группа))
		WHERE st.tip_id = t.tip_id

		UPDATE t
		SET service_name_gis = LTRIM(RTRIM(sb.service_name_gis))
		FROM @T AS t
			JOIN dbo.Services_build AS sb ON t.service_id = sb.service_id
		WHERE sb.build_id = t.build_id
			AND COALESCE(sb.service_name_gis, '') <> ''
		--**********************************************************

		--IF @Debug = 1 PRINT 'Код дома: '+STR(@build_id)
		--IF @Debug = 1 SELECT * FROM @T

		-- Услугу Эл.энергия МОП выводим в Общедомовых нуждах
		--IF dbo.strpos('KR1', @DB_NAME) > 0
		--	UPDATE t1
		--	SET kol		  = 0
		--	   ,value	  = 0
		--	   ,paid	  = 0
		--	   ,kol_dom	  = COALESCE(t2.kol, 0)
		--	   ,value_dom = t2.value
		--	   ,paid_dom  = t2.paid
		--	FROM @T AS t1
		--	JOIN @T AS t2
		--		ON t1.occ = t2.occ
		--		AND t1.service_id = t2.service_id
		--	WHERE t1.service_id IN ('элмп', 'элм2')

		--IF @debug=1 SELECT * FROM @t

		DELETE FROM @T
		WHERE is_build = 1
			OR blocked_kvit = 1

		UPDATE t
		SET sort_no = (t.sort_no * 100) -- дорабатываем сортировку в группированых полях
			, short_id = CASE
                             WHEN t.service_id = 'отоп' AND t.short_id = 'ед' THEN 'ГКал'
                             ELSE t.short_id
            END                         -- а то у отоп бывает - ед
		FROM @T AS t

		UPDATE t
		SET sort_no = t2.sort_no + 1
		FROM @T AS t
			JOIN @T AS t2 ON t.occ = t2.occ
				AND t.service_name = t2.short_name
		--************************************************

		-- устанавливаем группировку услуг в квитанции
		--if EXISTS(SELECT 1 FROM dbo.Group_kvit as g WHERE g.tip_id=@Tip_Id)

		UPDATE t
		SET group_name_kvit = g.name
		  , group_sort_id = g.sort_id
		FROM @T AS t
			JOIN dbo.Services_types AS st ON t.owner_id = st.id
				AND st.tip_id = t.tip_id
			JOIN dbo.Group_kvit AS g ON st.group_kvit_id = g.id

		UPDATE t
		SET group_name_kvit = g.name
		  , group_sort_id = g.sort_id
		FROM @T AS t
			JOIN dbo.Services_types AS st ON st.service_id = t.service_id
				AND st.tip_id = t.tip_id
			JOIN dbo.Group_kvit AS g ON st.group_kvit_id = g.id

		UPDATE t
		SET group_name_kvit = t2.group_name_kvit
		  , group_sort_id = t2.group_sort_id
		FROM @T AS t
			JOIN @T AS t2 ON t.short_name = t2.service_name
		WHERE t.group_name_kvit = ''

		
		IF dbo.strpos('KR1', @DB_NAME) > 0
		BEGIN -- Добавляем строки по много-тарифным расчетам
			--IF @Debug=1
			;WITH cte AS
			(SELECT cp2.occ AS occ
				  ,MAX(t2.build_id) AS build_id
				  ,MAX(t2.short_name) AS short_name
				  ,MAX(t2.service_name) AS service_name
				  ,MAX(t2.short_id) AS short_id
				  ,cp2.service_id
				  ,cp2.tarif
				  ,SUM(cp2.kol) AS kol
				  ,SUM(cp2.[value]) AS val
				  ,CAST(1 AS BIT) AS is_sum
				  ,MAX(t2.sort_no)+1 AS sort_no
				  ,MAX(t2.group_name_kvit) AS group_name_kvit
				  ,MAX(t2.group_sort_id) AS group_sort_id
				  ,COUNT(*) OVER(PARTITION BY cp2.occ) AS cnt
			FROM dbo.Counter_paym2 AS cp2 
				JOIN @T AS t2 ON t2.occ = cp2.occ
					AND t2.service_id = cp2.service_id
			  WHERE cp2.fin_id= @fin_id1
			  --and cp2.metod_rasch=3
			  and cp2.kol<>0
			  AND t2.service_id='элек'		  
			GROUP BY cp2.occ, cp2.service_id, cp2.tarif)
			INSERT INTO @T
				(occ, build_id, short_name, service_name, short_id, service_id, tarif, kol, value, is_sum, sort_no, group_name_kvit, group_sort_id
			   )
			SELECT occ, build_id, ' -'+short_name, service_name, short_id, service_id, tarif, kol, val, is_sum, sort_no, group_name_kvit, group_sort_id FROM cte WHERE cnt>1
		
			UPDATE t SET tarif=0, value=0 
			FROM @t as t		
			where t.service_id='элек' and t.unit_id is not NULL
			AND EXISTS (SELECT 1 FROM @t as t2 WHERE t2.occ=t.occ AND t2.service_id=t.service_id AND t2.unit_id is NULL)
		END
		--************************************************

		--DECLARE @num_pd VARCHAR(20)
		--SELECT
		--	@num_pd = dbo.Fun_GetNumPdSup(@Occ1, @Fin_Id1, @Sup_Id)
		--	@num_pd = dbo.Fun_GetNumUV(@Occ1, @Fin_Id1, @Sup_Id)

		SELECT num_pd = dbo.Fun_GetNumUV(occ, @Fin_Id1, @Sup_Id)
			 , *
		FROM @T
		WHERE sup_id = @Sup_Id
		ORDER BY occ
			   , group_sort_id
			   , sort_no

	END TRY

	BEGIN CATCH
		SET @strerror = @strerror + ' Лицевой: ' + LTRIM(STR(@Occ1))

		EXECUTE k_GetErrorInfo @visible = @Debug
							 , @strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1)
	END CATCH
go


go

