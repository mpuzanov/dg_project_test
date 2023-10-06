-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE               PROCEDURE [dbo].[rep_gis_pd_serv]
(
	  @fin_id SMALLINT
	, @tip_id SMALLINT
	, @build_id INT = NULL
	, @sup_id INT = NULL
	, @occ1 INT = NULL
	, @debug BIT = NULL
	, @count_pd INT = 0 OUTPUT
)
AS
/*
rep_gis_pd_serv @fin_id=222, @tip_id=218,@build_id=8000, @sup_id=null, @occ1=369330, @debug=1

rep_gis_pd_serv @fin_id=175, @tip_id=28,@build_id=1037, @sup_id=323, @occ1=680000087
rep_gis_pd_serv @fin_id=178, @tip_id=28,@build_id=1064, @sup_id=347, @debug=1
rep_gis_pd_serv @fin_id=234, @tip_id=1,@sup_id=0, @occ1=480001, @debug=1

*/
BEGIN
	SET NOCOUNT ON;

	IF @build_id IS NULL
		AND @sup_id IS NULL
		AND @occ1 IS NULL
		SELECT @build_id = 0
			 , @sup_id = 0
			 , @fin_id = 0
			 , @tip_id = 0

	DECLARE @MAIN_USLUGA VARCHAR(100) = 'Содержание помещения'
	DECLARE @MAIN_USLUGA_BAK VARCHAR(100) = 'Плата за содержание жилого помещения'

	DECLARE @strerror VARCHAR(2000) = ''

	--****************************************************************        
	BEGIN TRY

		SELECT @occ1 = dbo.Fun_GetFalseOccIn(@occ1)

		CREATE TABLE #pdserv (
			  num_pd VARCHAR(20) COLLATE database_default
			, build_id INT
			, occ INT
			, short_name VARCHAR(50) COLLATE database_default
			, short_id VARCHAR(6) COLLATE database_default
			, service_id VARCHAR(10) COLLATE database_default
			, tarif DECIMAL(10, 4) DEFAULT 0
			, kol DECIMAL(12, 6) DEFAULT 0
			, kol_dom DECIMAL(12, 6) DEFAULT 0
			, koef DECIMAL(10, 4) DEFAULT NULL
			, saldo DECIMAL(9, 2) DEFAULT 0 NOT NULL
			, value DECIMAL(9, 2) DEFAULT 0 NOT NULL
			, value_dom DECIMAL(9, 2) DEFAULT 0 NOT NULL
			, value_itog DECIMAL(9, 2) DEFAULT 0 NOT NULL
			, added1 DECIMAL(9, 2) DEFAULT 0 NOT NULL
			, added12 DECIMAL(9, 2) DEFAULT 0 NOT NULL
			, added DECIMAL(9, 2) DEFAULT 0 NOT NULL
			, paid DECIMAL(9, 2) DEFAULT 0 NOT NULL
			, paid_dom DECIMAL(9, 2) DEFAULT 0 NOT NULL
			, paid_koef_up DECIMAL(9, 2) DEFAULT 0 NOT NULL
			, paid_itog DECIMAL(9, 2) DEFAULT 0 NOT NULL
			, debt DECIMAL(9, 2) DEFAULT 0 NOT NULL
			, sort_no INT DEFAULT 0
			, mode_id INT DEFAULT NULL
			, unit_id VARCHAR(10) COLLATE database_default DEFAULT NULL
			, is_build BIT DEFAULT 0
			, service_id_from VARCHAR(10) COLLATE database_default DEFAULT NULL
			, sup_id INT DEFAULT 0
			, account_one BIT DEFAULT 0
			, is_sum BIT DEFAULT 1
			, subsid_only BIT DEFAULT 0
			, tip_id SMALLINT DEFAULT 0
			, VSODER BIT DEFAULT 0
			, VYDEL BIT DEFAULT 0
			, OWNER_ID INT DEFAULT 0
			, [service_name] VARCHAR(50) COLLATE database_default DEFAULT ''
			, OWNER_ID_BUILD INT DEFAULT 0
			, metod SMALLINT DEFAULT 0
			, service_name_gis NVARCHAR(100) COLLATE database_default DEFAULT NULL
			, service_type SMALLINT DEFAULT 1
			, is_counter SMALLINT DEFAULT 0
			, reason_added VARCHAR(800) COLLATE database_default DEFAULT NULL
			, is_koef_up BIT DEFAULT 0
			, no_export_volume_gis BIT DEFAULT 0
			, koef_up DECIMAL(9, 4) DEFAULT NULL
			, total_sq DECIMAL(9, 2) DEFAULT 0
			, kol_norma_single DECIMAL(12, 6) DEFAULT 0
			, blocked_kvit BIT DEFAULT 0
			, source_id INT DEFAULT NULL
			, group_name_kvit VARCHAR(100) COLLATE database_default DEFAULT ''
			, group_sort_id SMALLINT DEFAULT 0
			, penalty_serv DECIMAL(15, 4) DEFAULT 0
			, value_occ DECIMAL(15, 4) DEFAULT 0 -- общее начисление по лицевому
		)

		--**************************************************************************
		DECLARE @build_tmp INT
		DECLARE cur CURSOR LOCAL FOR
			SELECT
			DISTINCT v.build_id
			FROM dbo.VOcc v
			WHERE (v.occ = @occ1 OR @occ1 IS NULL)
				AND (v.build_id = @build_id OR @build_id IS NULL)
				AND v.tip_id = @tip_id
				AND @fin_id > 0

		OPEN cur

		FETCH NEXT FROM cur INTO @build_tmp

		WHILE @@fetch_status = 0
		BEGIN
			IF @debug = 1
				RAISERROR ('Дом: %d', 10, 1, @build_tmp) WITH NOWAIT;

			INSERT INTO #pdserv
			EXEC k_intPrintDetail_occ_build @Fin_Id1 = @fin_id -- Фин.период
										  , @build_id = @build_tmp-- дом
										  , @occ1 = @occ1 -- лицевой
										  , @tip_id = @tip_id --жилой фонд
										  , @sup_id = @sup_id
										  , @debug = 0
										  , @is_out_gis = 1 -- выгрузка в гис 

			FETCH NEXT FROM cur INTO @build_tmp

		END

		CLOSE cur
		DEALLOCATE cur
		--**************************************************************************
		--if @debug=1 select * From #pdserv

		-- убираем лицевые где нет ЕЛС
		DELETE pd
		FROM #pdserv AS pd
			JOIN dbo.Occupations AS o ON 
				pd.occ = o.occ
		WHERE o.id_els_gis IS NULL;

		UPDATE #pdserv
		SET kol = 0
		WHERE no_export_volume_gis = 1;

		-- добавить услуги по типу фонда, которых нет в таблице SERVICES_TYPES
		INSERT INTO [dbo].[Services_types] ([tip_id]
										  , [service_id]
										  , [service_name]
										  , [is_load_value]
										  , [VSODER]
										  , [VYDEL]
										  , [OWNER_ID]
										  , [paym_rasckidka_no]
										  , [paym_blocked]
										  , [overpayment_blocked]
										  , [short_id]
										  , [overpayment_only]
										  , [blocked_account_info]
										  , [sup_id]
										  , [service_name_gis])
		SELECT @tip_id AS tip_id
			 , p.service_id
			 , p.short_name
			 , 0 AS [is_load_value]
			 , 0 AS [VSODER]
			 , 0 AS [VYDEL]
			 , NULL AS [owner_id]
			 , 0 AS [paym_rasckidka_no]
			 , 0 AS [paym_blocked]
			 , 0 AS [overpayment_blocked]
			 , NULL AS [short_id]
			 , 0 AS [overpayment_only]
			 , 0 AS [blocked_account_info]
			 , p.[sup_id]
			 , NULL AS [service_name_gis]
		FROM #pdserv p
			JOIN dbo.Services s ON 
				p.service_id = s.id
			LEFT JOIN [dbo].[Services_types] AS st ON 
				st.tip_id = @tip_id
				AND (p.service_id = st.[service_id])
		WHERE st.[service_id] IS NULL
			AND s.id IS NOT NULL
		GROUP BY p.service_id
			   , p.short_name
			   , p.[sup_id]

		--*******************************************************
		UPDATE p
		SET service_name_gis = 'Плата за пользование жилым помещением (плата за наем)'
		FROM #pdserv p
		WHERE service_name_gis IS NULL
			AND p.service_id = 'наем'
		--*******************************************************
		-- Обрабатываем повышающий коэф.
		UPDATE p
		SET paid_koef_up = p2.paid
		  , saldo = p.saldo + p2.saldo
		FROM #pdserv p
			JOIN #pdserv p2 ON p.occ = p2.occ
				AND p.service_id = p2.service_id_from
				AND p2.is_koef_up = 1


		--*******************************************************
		-- Общедомовые услуги в ГИС ЖКХ надо прибавить к услуге @MAIN_USLUGA 
		ALTER TABLE #pdserv ADD num_ref VARCHAR(10) DEFAULT NULL

		-- Суммы в содержании жилья в том числе()
		ALTER TABLE #pdserv ADD sum_vsod DECIMAL(9, 2) NOT NULL DEFAULT 0

		UPDATE p
		SET num_ref = stg.num_ref
		FROM #pdserv p
			JOIN dbo.Services_type_gis stg ON 
				p.tip_id = stg.tip_id --14.02.2020
				AND p.service_name_gis = stg.service_name_gis

		--if @debug=1
		--	SELECT 'num_ref', * from #pdserv p
			--FROM #pdserv p
			--JOIN dbo.Services_type_gis stg ON 
			--	p.tip_id = stg.tip_id --14.02.2020
			--	AND p.service_name_gis = stg.service_name_gis
		--************************************************************************************************
		/*    05/08/2020
		INT008130 Если в платежном документе заполнены строки с начислениями по видам коммунальных ресурсов или главным коммунальным ресурсам, 
		то должна быть заполнена строка с начислениями по жилищной услуге «Содержание помещения»; 
		FMT001314 Строка не обработана, так как одна или несколько связанных строк на других листах содержат ошибки.
		*/

		SELECT p.*
		INTO #tmp1
		FROM #pdserv p
		WHERE num_ref = '2'
			AND NOT EXISTS (
				SELECT 1
				FROM #pdserv p2
				WHERE p2.occ = p.occ
					AND (
					p2.service_name_gis IN (@MAIN_USLUGA, @MAIN_USLUGA_BAK, 'Обслуживание домов') OR (p2.service_id = 'итог')
					)
			)
		IF EXISTS (SELECT 1 FROM #tmp1)
		BEGIN
			IF @debug = 1
				PRINT 'есть услуги СОИ, а главной услуги нет'

			INSERT INTO #pdserv (num_pd
							   , build_id
							   , occ
							   , short_name
							   , short_id
							   , service_id
							   , service_name_gis
							   , num_ref)
			SELECT num_pd
				 , build_id
				 , occ
				 , short_name = 'Обслуживание домов'
				 , short_id = 'м2'
				 , service_id = 'площ'
				 , @MAIN_USLUGA
				 , 50
			FROM #tmp1
			GROUP BY num_pd
				   , build_id
				   , occ

		END
		--************************************************************************************************

		-- num_ref=2 в ГИС это общедомовые услуги
		UPDATE p
		SET p.paid_dom = COALESCE(odn.paid, 0) --+ COALESCE(@sum_vsod,0)
		  , sum_vsod = COALESCE((
				SELECT SUM(p2.value_itog)
				FROM #pdserv p2
				WHERE p2.occ = p.occ
					AND p2.VSODER = 1
					AND p2.VYDEL = 1
					AND (p2.OWNER_ID <> 0 OR p2.OWNER_ID_BUILD <> 0)
			), 0)
		FROM #pdserv p
			CROSS APPLY (
				SELECT SUM(p1.value) AS value
					 , SUM(p1.paid) AS paid
				FROM #pdserv p1
				WHERE p1.num_pd = p.num_pd
					AND p1.num_ref = '2'
			) AS odn
		WHERE service_name_gis IN (@MAIN_USLUGA_BAK, @MAIN_USLUGA)


		--*******************************************************
		UPDATE p
		SET paid_itog = paid_itog + paid_koef_up + paid_dom + sum_vsod
		  , debt = debt + paid_koef_up + paid_dom + sum_vsod
		  , is_build = CASE
                           WHEN p.num_ref = 2 THEN 1
                           ELSE is_build
            END
		FROM #pdserv p

		DELETE p
		FROM #pdserv p
		WHERE is_koef_up = 1
		OR p.is_sum=0 -- 12.04.23  детальные записи по ипу
		--*******************************************************

		DELETE p
		FROM #pdserv p
		WHERE p.saldo=0 AND p.value=0 AND p.debt=0		

		SELECT @count_pd = COUNT(DISTINCT occ)
		FROM #pdserv p

		SELECT p.*
			 , debt_itog = COALESCE((
				   SELECT SUM(p1.debt) - SUM(COALESCE(sum_vsod, 0))
				   FROM #pdserv p1
				   WHERE p1.num_pd = p.num_pd
			   ), 0)
			   - COALESCE((
				   SELECT SUM(paid)
				   FROM #pdserv p1
				   WHERE p1.num_pd = p.num_pd
					   AND p1.is_build = 1
			   ), 0)
			   -- покажем двойные услуги по л/сч если есть
			 , count_serv = DENSE_RANK() OVER (PARTITION BY p.occ, p.short_name ORDER BY p.service_id)
		FROM #pdserv p
		WHERE p.VSODER = 0 --AND p.service_id		
		ORDER BY p.num_pd
			   , p.sort_no
			   , p.service_name_gis

	END TRY

	BEGIN CATCH
		IF @occ1 > 0
			SET @strerror = @strerror + ' Лицевой: ' + LTRIM(STR(@occ1))

		EXECUTE k_GetErrorInfo @visible = @debug
							 , @strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1)
	END CATCH

END
go

