CREATE   PROCEDURE [dbo].[k_intPrint_occ_sup]
(
	  @fin_id1 SMALLINT
	, @occ1 INT = NULL
	, @build INT = NULL -- Код дома
	, @ops INT = 0 -- ОПС
	, @sort_tip SMALLINT = 0
	, @sup_id INT = NULL
	, @tip_id SMALLINT = NULL
	, @sum_dolg DECIMAL(9, 2) = 0 -- если не равно 0 вывод только с долгом более этой суммы 
	, @town_id INT = NULL
	, @current_dolg BIT = 0 -- использовать текущий долг для выборки
	, @debug BIT = 0
	, @SetLastDayMonthPrint BIT = NULL -- устанавливать последний день месяца печати
	, @is_out_gis BIT = NULL
	, @paidAll0_block BIT = 0 -- блокировать печать где нет начислений
	, @is_print_dolg BIT = 0 -- печатать если есть сумма к оплате (не смотря на @people0_block и @paidAll0_block)
	, @fin_id2 SMALLINT = NULL
)
AS
	/*
exec [k_intPrint_occ_sup] @fin_id1=232,@tip_id=1,@occ1=null, @sup_id=345
exec [k_intPrint_occ_sup] @fin_id1=232,@occ1=31001, @build=6785, @sup_id=345, @fin_id2=233
exec [k_intPrint_occ_sup] @fin_id1=232,@occ1=null, @build=6785, @sup_id=345
*/
	SET NOCOUNT ON;

	IF @sort_tip IS NULL
		SET @sort_tip = 0;

	IF @occ1 = 0
		SET @occ1 = NULL
	SET @paidAll0_block = coalesce(@paidAll0_block, 0)
	SET @is_print_dolg = coalesce(@is_print_dolg, 0)

	IF COALESCE(@fin_id2, 0) = 0
		OR @fin_id2 < @fin_id1
		SET @fin_id2 = @fin_id1

	DECLARE @sal INT
		  , @db_name VARCHAR(20)
		  , @dog_int INT
		  , @fin_current SMALLINT
		  , @SumPaymUks DECIMAL(9, 2) = 0
		  , @StrSub3 VARCHAR(100) = ''
		  , @KapRemont BIT
		  , @strerror VARCHAR(300)
		  , @rowcount_tmp INT
	;

	--****************************************************************        

	BEGIN TRY

		SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip_id, @build, NULL, @occ1);

		IF @sum_dolg = 0
			OR @sum_dolg IS NULL
			SET @sal = -999999999;
		ELSE
			SET @sal = @sum_dolg;

		IF @current_dolg IS NULL
			SET @current_dolg = 0;

		SELECT @occ1 = dbo.Fun_GetFalseOccIn(@occ1);

		DECLARE @t myTypeTableOcc;

		DECLARE @t_schet TABLE (
			  occ INT PRIMARY KEY
			, NameFirma VARCHAR(100) COLLATE Cyrillic_General_CI_AS DEFAULT NULL
			, BANK VARCHAR(100) COLLATE Cyrillic_General_CI_AS DEFAULT NULL
			, rasscht VARCHAR(30) DEFAULT NULL
			, korscht VARCHAR(30) DEFAULT NULL
			, bik VARCHAR(20) DEFAULT NULL
			, inn VARCHAR(20) DEFAULT NULL
			, kpp VARCHAR(9) DEFAULT NULL
			, tip_id SMALLINT DEFAULT 1
			, id_barcode VARCHAR(50) DEFAULT ''
			, licbank BIGINT DEFAULT 0
			, adres VARCHAR(60) COLLATE Cyrillic_General_CI_AS DEFAULT ''
			, adres_build VARCHAR(60) COLLATE Cyrillic_General_CI_AS DEFAULT ''
			, total_people SMALLINT DEFAULT 0
			, PersonStatus VARCHAR(80) DEFAULT ''
			, NameFirma_str2 VARCHAR(100) COLLATE Cyrillic_General_CI_AS DEFAULT NULL
			, LastDayPaym SMALLDATETIME DEFAULT NULL
			, LastDayPaym2 SMALLDATETIME DEFAULT NULL
			, tip_account_org SMALLINT		-- признак откуда взяли банковский счет
			, proptype_id VARCHAR(10) NULL
			, build_id INT DEFAULT NULL
			, cbc VARCHAR(20) DEFAULT NULL
			, oktmo VARCHAR(11) DEFAULT NULL
			, comments_print VARCHAR(50) DEFAULT NULL
			, kol_people_reg SMALLINT DEFAULT 0
			, id_els_gis VARCHAR(10) DEFAULT NULL
			, roomtype_id VARCHAR(10) DEFAULT NULL
		);

		--WHEN tip_account_org=1 THEN 'Тип фонда'
		--WHEN tip_account_org=2 THEN 'Участок'
		--WHEN tip_account_org=3 THEN 'Поставщик'
		--WHEN tip_account_org=4 THEN 'Район'
		--WHEN tip_account_org=5 THEN 'Дом'
		--WHEN tip_account_org=6 THEN 'Договор'

		IF @debug = 1
			SELECT @fin_id1 AS fin_id1
					, @fin_id2 AS fin_id2
					, @build AS build
					, @occ1 AS occ1
					, @sup_id AS sup_id
					, @tip_id AS tip_id
					, @town_id AS town_id
					, @current_dolg AS current_dolg
					, @paidAll0_block AS paidAll0_block
					, @is_print_dolg AS is_print_dolg

		IF @occ1 IS NULL AND (@build > 0 OR @tip_id>0)
		BEGIN
			INSERT INTO @t (occ
						  , proptype_id
						  , fin_id
						  , tip_id
						  , flat_id
						  , build_id
						  , total_sq
						  , sup_id
						  , occ_sup
						  , roomtype_id
						  , kol_people_reg
						  , summa1
						  , summa2)
			SELECT DISTINCT o.occ
						  , o.proptype_id
						  , o.fin_id
						  , o.tip_id
						  , o.flat_id
						  , o.bldn_id
						  , o.total_sq
						  , os.sup_id
						  , os.occ_sup
						  , o.roomtype_id
						  , o.kol_people_reg
						  , os.Whole_payment
						  , os.paid
			FROM dbo.View_occ_all_lite AS o 
				JOIN dbo.VOcc_Suppliers AS os ON o.occ = os.occ
					AND o.fin_id = os.fin_id
			WHERE (o.bldn_id = @build OR @build IS NULL)
				AND (o.occ = @occ1 OR @occ1 IS NULL)
				AND o.fin_id = @fin_id1
				AND o.status_id <> 'закр'
				AND os.sup_id = @sup_id
				AND (@tip_id IS NULL OR o.tip_id = @tip_id)
				AND NOT EXISTS (
					SELECT 1
					FROM dbo.Occ_not_print AS onp
					WHERE o.occ = onp.occ
						AND onp.flag = 1
				);
			GOTO LABEL1;
		END;

		IF @occ1 > 0
		BEGIN
			INSERT INTO @t (occ
						  , proptype_id
						  , fin_id
						  , tip_id
						  , flat_id
						  , build_id
						  , total_sq
						  , sup_id
						  , occ_sup
						  , roomtype_id
						  , kol_people_reg)
			SELECT DISTINCT o.occ
						  , o.proptype_id
						  , o.fin_id
						  , o.tip_id
						  , o.flat_id
						  , o.bldn_id
						  , o.total_sq
						  , bs.sup_id
						  , bs.occ_sup
						  , o.roomtype_id
						  , o.kol_people_reg						  
			FROM dbo.View_occ_all_lite AS o 
				JOIN dbo.Occ_Suppliers AS bs ON o.occ = bs.occ
					AND o.fin_id = bs.fin_id
			WHERE o.occ = @occ1
				AND o.fin_id = @fin_id1
				AND o.status_id <> 'закр'
				AND bs.sup_id = @sup_id
				AND bs.fin_id = @fin_id1;
		END;

		IF @town_id IS NOT NULL
		BEGIN
			INSERT INTO @t (occ
						  , proptype_id
						  , fin_id
						  , tip_id
						  , flat_id
						  , build_id
						  , total_sq
						  , sup_id
						  , occ_sup
						  , roomtype_id
						  , kol_people_reg
						  , summa1
						  , summa2)
			SELECT DISTINCT o.occ
						  , o.proptype_id
						  , o.fin_id
						  , o.tip_id
						  , o.flat_id
						  , o.bldn_id
						  , o.total_sq
						  , os.sup_id
						  , os.occ_sup
						  , o.roomtype_id
						  , o.kol_people_reg
						  , os.Whole_payment
						  , os.paid
			FROM dbo.View_occ_all_lite AS o 
				JOIN dbo.Buildings AS b ON o.bldn_id = b.id
				JOIN dbo.VOcc_Suppliers AS os ON o.occ = os.occ
					AND o.fin_id = os.fin_id
			WHERE b.town_id = @town_id
				AND o.fin_id = @fin_id1
				AND (o.status_id <> 'закр' OR o.proptype_id = 'арен')
				AND os.sup_id = @sup_id
				AND os.fin_id = @fin_id1
				AND (@tip_id IS NULL OR o.tip_id = @tip_id);
		END;

	LABEL1:;
		IF @debug = 1
			SELECT '@t 1' AS tbl, *	FROM @t;

		-- убираем лицевые которые не должны печатать
		IF COALESCE(@occ1, 0) = 0
		BEGIN
			DELETE t
			FROM @t AS t
				JOIN dbo.Occ_not_print AS onp ON t.occ = onp.occ
					AND onp.flag = 1;

			DELETE t
			FROM @t AS t
			WHERE t.total_sq = 0
				AND COALESCE(t.summa2, 0) = 0
			SET @rowcount_tmp = @@rowcount
			IF @rowcount_tmp > 0
				AND @debug = 1
				PRINT 'Удаляем лицевые TOTAL_SQ = 0 AND COALESCE(t.summa2, 0) = 0 ' + STR(@rowcount_tmp)
		END

		IF COALESCE(@occ1, 0) = 0
			AND @paidAll0_block = 1
		BEGIN 
			--if @debug=1 print 'Убираем печать где нет начислений'
			DELETE t
			--OUTPUT DELETED.occ,'Убираем печать где нет начислений'
			FROM @t AS t
			WHERE t.summa2 = 0
				AND EXISTS (
					SELECT *
					FROM @t
					WHERE t.summa1 <=
									 CASE
										 WHEN @is_print_dolg = 1 THEN 0 -- удаляем у кого нет долга
										 ELSE 9999999
									 END
				)
			SET @rowcount_tmp = @@rowcount
			IF @rowcount_tmp > 0
				AND @debug = 1
				RAISERROR (N'Убираем печать где нет начислений, удалили = %i', 10, 1, @rowcount_tmp) WITH NOWAIT;
		END

		IF COALESCE(@occ1, 0) = 0
			AND @is_print_dolg = 1
		BEGIN 
			--if @debug=1 print 'Убираем печать где нет долга'
			DELETE t
			--OUTPUT DELETED.occ,'Убираем печать где нет долга'
			FROM @t AS t
			WHERE t.summa1 = 0
			SET @rowcount_tmp = @@rowcount
			IF @rowcount_tmp > 0
				AND @debug = 1
				RAISERROR (N'Убираем печать где нет долга, удалили = %i', 10, 1, @rowcount_tmp) WITH NOWAIT;
		END

		IF @ops > 0
		BEGIN
			-- ограничиваем по ОПС
			DELETE t
			FROM @t AS t
				JOIN dbo.Occupations AS o ON t.occ = o.occ
				JOIN dbo.Flats AS f ON o.flat_id = f.id
				JOIN dbo.Buildings AS b ON f.bldn_id = b.id
			WHERE b.index_id <> @ops;

		END;

		---- список услуг по поставщику
		--DECLARE @_serv_sup TABLE
		--	(
		--		service_id VARCHAR(10)
		--	)
		--INSERT
		--INTO @_serv_sup
		--(service_id)
		--	SELECT
		--		s.service_id
		--	FROM dbo.SUPPLIERS AS s
		--	WHERE s.sup_id = @sup_id
		IF EXISTS (
				SELECT 1
				FROM dbo.Suppliers AS s
				WHERE s.sup_id = @sup_id
					AND s.service_id = 'капр'
			)
			SET
			@KapRemont = 1;
		ELSE
			SET @KapRemont = 0;


		DROP TABLE IF EXISTS #t_sort;
		CREATE TABLE #t_sort (
			  occ INT
			, index_id INT
			, index_postal INT
			, tip_id SMALLINT
			, sort_id INT
			, sort_no INT
			, nom_kvr VARCHAR(20) COLLATE database_default DEFAULT ''
		);

		INSERT INTO #t_sort (occ
						   , tip_id
						   , index_id
						   , index_postal
						   , sort_id
						   , nom_kvr)
		SELECT t.occ
			 , o.tip_id
			 , b.index_id
			 , b.index_postal
			 , ROW_NUMBER() OVER (ORDER BY b.sector_id, s.name, b.nom_dom_sort, f.nom_kvr_sort)
			 , f.nom_kvr
		FROM @t AS t
			JOIN dbo.Occupations AS o ON t.occ = o.occ
			JOIN dbo.Flats AS f ON o.flat_id = f.id
			JOIN dbo.Buildings AS b ON f.bldn_id = b.id
			JOIN dbo.VStreets AS s ON b.street_id = s.id;
		--WHERE b.blocked_house = 0

		UPDATE #t_sort
		SET sort_no = sort_id;

		CREATE INDEX occ ON #t_sort (occ);
		CREATE INDEX sort_no ON #t_sort (sort_no);

		IF @sort_tip = 0
			UPDATE #t_sort
			SET sort_no = sort_id;
		ELSE
		BEGIN
			DECLARE @kol INT = 0
				  , @kol2 INT = 0;
			SELECT @kol = COUNT(occ)
			FROM #t_sort;
			SELECT @kol2 = (@kol / 2) + @kol % 2;

			--SELECT @kol,@kol2

			UPDATE #t_sort
			SET sort_no = sort_id + (sort_id - 1)
			WHERE sort_id <= @kol2;

			-- N=N+N
			UPDATE #t_sort
			SET sort_no = sort_no - @kol2
			WHERE sort_id > @kol2;

			UPDATE #t_sort
			SET sort_no = sort_no + sort_no
			WHERE sort_id > @kol2;
		END;

		--IF @debug=1 select t.*,o.address from #t_sort as t join dbo.OCCUPATIONS as o ON t.occ=o.occ
		IF @debug = 1
			SELECT '@t' as tbl, * FROM @t;
		--IF @debug=1 select * FROM #t_sort

		SELECT TOP (1) @dog_int = db.dog_int
		FROM @t AS O
			JOIN Dog_build AS db ON O.fin_id = db.fin_id
				AND O.build_id = db.build_id
			JOIN dbo.Dog_sup AS ds ON db.dog_int = ds.id
		WHERE O.fin_id = @fin_id1
			AND ds.sup_id = @sup_id;

		IF @debug = 1
			SELECT @fin_id1 AS fin_id
				 , @sup_id AS sup_id
				 , @dog_int AS dog_int;
		IF @debug = 1
			PRINT 'Числовой код договора: ' + STR(@dog_int);

		IF @debug = 1
			SELECT '@t' as tbl, * FROM @t

		-- Записываем банковские реквизиты у поставщика
		INSERT INTO @t_schet (occ
							, NameFirma
							, BANK
							, rasscht
							, korscht
							, bik
							, inn
							, kpp
							, tip_id
							, id_barcode
							, licbank
							, adres
							, adres_build
							, NameFirma_str2
							, tip_account_org
							, LastDayPaym2
							, proptype_id
							, build_id
							, cbc
							, oktmo
							, comments_print
							, kol_people_reg
							, id_els_gis
							, roomtype_id)
		SELECT t.occ
			   --,t.sup_id
			 , ao.name_str1 COLLATE Cyrillic_General_CI_AS
			 , ao.BANK COLLATE Cyrillic_General_CI_AS
			 , ao.rasschet
			 , ao.korschet
			 , ao.bik
			 , ao.inn
			 , ao.kpp
			 , o.tip_id
			 , ao.id_barcode
			 , ao.licbank
			 , o.address COLLATE Cyrillic_General_CI_AS
			 , b.adres AS adres_build
			 , ao.name_str2
			 , ao.tip
			 , vst.LastPaymDay AS LastDayPaym2
			 , t.proptype_id
			 , t.build_id
			 , ao.cbc
			 , ao.oktmo
			 , o.comments_print
			 , t.kol_people_reg
			 , COALESCE(o.id_els_gis, '') AS id_els_gis
			 , o.roomtype_id
		FROM @t AS t
			JOIN dbo.Occupations AS o  ON t.occ = o.occ
			JOIN dbo.Flats f ON o.flat_id = f.id
			JOIN dbo.View_buildings_lite b ON f.bldn_id = b.id
			JOIN dbo.Dog_build AS db ON t.fin_id = db.fin_id
				AND t.build_id = db.build_id
			JOIN dbo.Dog_sup AS ds ON db.dog_int = ds.id
				AND t.sup_id = ds.sup_id
			JOIN dbo.Account_org AS ao ON ds.bank_account = ao.id
			LEFT JOIN [dbo].[View_suppliers_types] AS vst ON t.fin_id = vst.fin_id
				AND o.tip_id = vst.tip_id
				AND t.sup_id = vst.sup_id
				AND vst.service_id = ''

		IF EXISTS (
				SELECT 1
				FROM @t_schet AS t
				WHERE rasscht IS NULL
					OR rasscht = ''
			)
		BEGIN
			RAISERROR ('Нет банковских реквизитов!', 16, 1);
			RETURN;
		END;

		IF EXISTS (
				SELECT 1
				FROM dbo.Global_values
				WHERE fin_id = @fin_id1
					AND BlokedPrintAccount = 1
			)
		BEGIN -- Блокируем печать квитанций
			DELETE FROM @t_schet;
		END;

		IF @debug = 1
			SELECT '@t_schet'
				 , *
			FROM @t_schet
			ORDER BY occ;

		IF @db_name IN ('KR1', 'ARX_KR1')
		BEGIN
			SELECT @SumPaymUks = SUM(value)
			FROM dbo.View_payings 
			WHERE fin_id = @fin_id1
				AND occ = @occ1
				AND sup_id IS NOT NULL
				AND (
				tip_paym_id IN ('1013') --'Уступка долга'				
				)
			GROUP BY occ;

			EXEC dbo.k_StrsumPaymUks @occ1
								   , @fin_id1
								   , '1013'
								   , 'переданного в'
								   , @StrSub3 OUT
								   , @SumPaymUks OUT;

		END;

		DECLARE @DatePrint SMALLDATETIME;
		SELECT @DatePrint = dbo.Fun_GetOnlyDate(
			CASE
				WHEN @SetLastDayMonthPrint = 1 THEN (
						SELECT end_date
						FROM dbo.Global_values AS gb 
						WHERE fin_id = @fin_id1
					)
				ELSE current_timestamp
			END);


		--UPDATE ts SET Visible = 0
		DELETE ts
		--SELECT '1',*
		FROM @t_schet ts
			JOIN @t t ON ts.occ = t.occ --AND ts.sup_id=t.sup_id
		WHERE EXISTS (
				SELECT 1
				FROM dbo.Suppliers_build sb 
				WHERE sb.build_id = t.build_id
					AND sb.sup_id = t.sup_id
					AND sb.print_blocked = 1
			)
			OR EXISTS (
				SELECT 1
				FROM dbo.Suppliers_types sb 
				WHERE sb.tip_id = t.tip_id
					AND sb.sup_id = t.sup_id
					AND sb.print_blocked = 1
			);
		--DELETE FROM @t_schet WHERE Visible=0;

		IF @is_out_gis = 1
		BEGIN
			DELETE t
			FROM @t_schet t
				JOIN dbo.View_build_all_lite vbal ON t.build_id = vbal.build_id
					AND vbal.fin_id = @fin_id1
			WHERE vbal.is_paym_build = 0

			DELETE ts
			FROM @t_schet ts
				JOIN @t t ON ts.occ = t.occ
				JOIN dbo.View_suppliers_build sb ON t.build_id = sb.build_id
					AND t.sup_id = sb.sup_id
					AND t.fin_id = sb.fin_id
			WHERE sb.gis_blocked = 1
				AND sb.fin_id = @fin_id1

		--DELETE #t_sort
		--WHERE id_jku_gis = ''
		END

		IF @debug = 1
			SELECT '@t_schet'
				 , *
			FROM @t_schet
			ORDER BY occ;

		SELECT ts.sort_no                                                                                       -- INT
			 , os.fin_id                                                                                        -- SMALLINT
			 , os.occ                                                                                           -- INT
			 , os.sup_id                                                                                        -- INT
			 , os.occ_sup                                                                                       -- INT
			 , os.occ_sup AS occ_pd                                                                             -- INT
			   --,dbo.Fun_GetNumPd(i.occ_sup, i.fin_id) AS num_pd
			 , dbo.Fun_GetNumUV(os.occ_sup, os.fin_id, os.sup_id) AS num_pd                                     -- VARCHAR(20)
			 , t.id_els_gis                                                                                     -- VARCHAR(20)
			 , os.id_jku_gis AS id_jku_gis                                                                      -- VARCHAR(20)
			 , dbo.Fun_GetNumPdGis2(os.id_jku_gis, os.fin_id) AS id_jku_pd_gis                                  -- VARCHAR(20)
			 , os.saldo                                                                                         -- DECIMAL(9,2)
			 , os.value                                                                                         -- DECIMAL(9,2)
			 , os.added                                                                                         -- DECIMAL(9,2)
			 , os.paid                                                                                          -- DECIMAL(9,2)
			 , os.PaymAccount - @SumPaymUks AS PaymAccount                                                      -- DECIMAL(9,2)
			 , os.PaymAccount_peny                                                                              -- DECIMAL(9,2)
			 , os.debt                                                                                          -- DECIMAL(9,2)
			 , os.PaymAccount_storno                                                                            -- DECIMAL(9,2)
			 , os.Penalty_value                                                                                 -- DECIMAL(9,2)
			 , os.Penalty_added                                                                                 -- DECIMAL(9,2)
			 , os.Penalty_old_new                                                                               -- DECIMAL(9,2)
			 , os.Penalty_old                                                                                   -- DECIMAL(9,2)
			 , (os.Penalty_value + os.Penalty_added + os.Penalty_old_new) AS Penalty_itog                       -- DECIMAL(9,2)
			 , os.Whole_payment                                                                                 -- DECIMAL(9,2)
			 , os.Whole_payment AS SumPaym                                                                      -- DECIMAL(9,2)
			 , os.Whole_payment - (os.Penalty_value + os.Penalty_added + os.Penalty_old_new) AS SumPaymNoPeny   -- DECIMAL(9,2)
			 , COALESCE(os.debt, 0) + (os.Penalty_value + os.Penalty_added + os.Penalty_old_new) AS SumPaymDebt -- может быть отрицательным -- DECIMAL(9,2)
			 , os.KolMesDolg                                                                                    -- DECIMAL(5,1)
			 , os.Penalty_old_edit                                                                              -- SMALLINT
			 , os.Paid_old                                                                                      -- DECIMAL(9,2)
			 , os.dog_int                                                                                       -- INT
			 , os.cessia_dolg_mes_old                                                                           -- SMALLINT
			 , os.cessia_dolg_mes_new                                                                           -- SMALLINT
			 , t.NameFirma                                                                                      -- VARCHAR(100)
			 , t.NameFirma_str2                                                                                 -- VARCHAR(100)
			 , dbo.Fun_GetScaner_Kod_SUP_EAN(t.occ, @sup_id, @fin_id1, os.Whole_payment, t.id_barcode) AS [EAN] -- VARCHAR(25)
			 , CASE
				   --WHEN ot.is_2D_Code = 1 THEN [dbo].[Fun_GetScaner_PDF417](t.occ, @fin_id1, @sup_id, i.Whole_payment, t.adres, t.Initials, t.BANK, t.bik, t.korscht, t.NameFirma, t.rasscht, t.inn, t.kpp, t.licbank)
				   WHEN ot.is_2D_Code = 1 THEN [dbo].[Fun_GetScaner_2D_SBER](t.occ, @fin_id1, @sup_id, os.Whole_payment, t.adres, i.Initials, t.BANK, t.bik, t.korscht, t.NameFirma, t.rasscht, t.inn, t.kpp, t.licbank, p.Last_name, p.First_name, p.Second_name, t.cbc, t.oktmo, dbo.Fun_GetNumPdGis2(os.id_jku_gis, os.fin_id), '')
				   ELSE dbo.Fun_GetScaner_Kod_SUP_EAN(t.occ, @sup_id, @fin_id1, os.Whole_payment, t.id_barcode)
			   END AS [EAN_2D]                                                                   -- NVARCHAR(2000)
			 , t.BANK                                                                                           -- VARCHAR(100)
			 , t.rasscht                                                                                        -- VARCHAR(30)
			 , t.korscht                                                                                        -- VARCHAR(30)
			 , t.bik                                                                                            -- VARCHAR(20)
			 , t.inn                                                                                            -- VARCHAR(20)
			 , t.kpp                                                                                            -- VARCHAR(20)
			 , t.cbc                                                                                            -- VARCHAR(20)
			 , t.oktmo                                                                                          -- VARCHAR(20)
			 , ts.index_id AS [index]                                                                           -- INT
			 , ts.index_postal AS index_postal                                                                  -- INT
			 , t.tip_id                                                                                         -- SMALLINT
			 , CASE
				   WHEN DS.tip_name_dog IS NOT NULL AND
					   DS.tip_name_dog <> '' THEN DS.tip_name_dog
				   WHEN ot.synonym_name IS NULL OR
					   ot.synonym_name = '' THEN ot.name
				   ELSE ot.synonym_name
			   END AS [tip_name]                                                                 -- VARCHAR(150)
			 , [dbo].[Fun_GetAddStr](t.occ, @fin_id1, @sup_id, NULL) AS StrAdd                                  -- VARCHAR(800)
			 , CASE
				   WHEN ts.index_postal > 1 THEN LTRIM(STR(ts.index_postal, 6)) + ','
				   ELSE ''
			   END + t.adres AS adres                                                            -- VARCHAR(100)
			 , t.adres_build AS adres_build-- VARCHAR(100)
			 , ts.nom_kvr                                                                                       -- VARCHAR(20)
			 , i.Initials                                                                                       -- VARCHAR(120)
			 , i.FinPeriod                                                                                      -- SMALLDATETIME
			 , dbo.Fun_NameFinPeriodDate(i.FinPeriod) AS StrFinPeriod                                           -- VARCHAR(15)
			 , i.total_sq                                                                                       -- DECIMAL(10, 4)
			 , i.living_sq                                                                                      -- DECIMAL(10, 4)
			   --, total_people
			   --,[dbo].[Fun_GetKolPeopleOccReg](@fin_id1, t.occ) AS total_people
			 , t.kol_people_reg AS total_people                                                                 -- SMALLINT
			 , i.PersonStatus                                                                                     -- VARCHAR(80)
			 , COALESCE(sup.synonym_name, sup.name) AS sup_name                                                 -- VARCHAR(50)
			 , ot.adres AS adres_tip                                                                            -- VARCHAR(100)
			 , ot.telefon AS telefon_tip                                                                        -- VARCHAR(70)
			 , ot.inn AS inn_tip                                                                                -- VARCHAR(15)
			 , ot.kpp AS kpp_tip                                                                                -- VARCHAR(15)
			 , ot.ogrn AS ogrn_tip                                                                              -- VARCHAR(15)
			 , ot.email AS email_tip                                                                            -- VARCHAR(50)
			 , ot.laststr1 AS laststr1                                                                          -- VARCHAR(70)
			 , ot.laststr2 AS laststr2                                                                          -- VARCHAR(1000)
			 , ot.logo                                                                                          -- VARBINARY(MAX)
			 , CASE
				   WHEN (@sup_id > 0) AND
					   (COALESCE(sup.tip_org_for_account, '') <> '') THEN sup.tip_org_for_account
				   WHEN ot.tip_org_for_account IS NULL OR
					   LTRIM(ot.tip_org_for_account) = '' THEN 'Управляющая организация'
				   ELSE ot.tip_org_for_account
			   END AS tip_org_for_account                                                        -- VARCHAR(50)
			 , [dbo].[Fun_GetPrintStrPaymDiscount](t.occ, os.fin_id, os.sup_id) AS strPaymDiscount              -- VARCHAR(100)
			 , i.LastDayPaym                                                                                    -- SMALLDATETIME
			 , CASE
				   WHEN t.LastDayPaym2 IS NULL THEN I.LastDayPaym2
				   ELSE t.LastDayPaym2
			   END AS LastDayPaym2																-- SMALLDATETIME
			 , CASE
				   WHEN os.PaymAccount = 0 THEN ''
				   ELSE (
						   SELECT TOP 1 CONVERT(VARCHAR(10), p2.day, 104) -- дата последней оплаты
						   FROM dbo.Payings AS p1 
							   JOIN dbo.Paydoc_packs AS p2 
								ON p1.pack_id = p2.id
						   WHERE p1.occ = t.occ
							   AND p2.fin_id = @fin_id1
							   AND p1.sup_id = os.sup_id
						   ORDER BY p2.day DESC
					   )
			   END AS LastDayPaymAccount                                                         -- VARCHAR(10)
			 , @StrSub3 AS StrSubsidia3                                                                         -- VARCHAR(100)
			 , CASE
				   WHEN @KapRemont = 1 AND
					   t.proptype_id = 'непр' THEN 0
				   ELSE 1
			   END AS visible                                                                    -- печатать или не квитанцию поставщика	 -- SMALLINT
			 , sup.str_account1                                                                                 -- VARCHAR(100)
			 , @DatePrint AS DatePrint                                                                          -- SMALLDATETIME
			 , '' AS LastStrAccountSup                                                                          -- VARCHAR(15)
			 , sup.adres AS sup_adres                                                                           -- VARCHAR(100)
			 , sup.inn AS sup_inn                                                                               -- VARCHAR(15)
			 , sup.kpp AS sup_kpp                                                                               -- VARCHAR(15)
			 , sup.ogrn AS sup_ogrn                                                                             -- VARCHAR(15)
			 , sup.telefon AS sup_telefon                                                                       -- VARCHAR(70)
			 , sup.email AS sup_email                                                                           -- VARCHAR(50)
			 , sup.web_site AS sup_web_site                                                                     -- VARCHAR(50)
			 , sup.rezhim_work AS sup_rezhim_work                                                               -- VARCHAR(50)
			 , i.FinPeriod AS [start_date]                                                                      -- SMALLDATETIME
			 , sup.tip_occ                                                                                      -- SMALLINT
			 , CASE
				   WHEN COALESCE(bc.comments, '') = '' THEN sup.account_rich
				   ELSE bc.comments
			   END                                   AS account_rich                                            -- VARCHAR(4000)
			 , (os.Penalty_value + os.Penalty_added) AS Penalty_period                                          -- DECIMAL(9,2)
			 , t.comments_print                                                                                 -- VARCHAR(50)
			 , CASE
                   WHEN @db_name = 'NAIM' THEN 'ЛС ОГВ/ОМС'
                   ELSE tog.name
            END                                      AS tip_occ_name                                            -- VARCHAR(20)
			 , t.roomtype_id                         AS roomtype_id                                             -- VARCHAR(10)
			 , t.build_id                                                                                       -- INT
			 , 'Текущий'                             AS tip_pd                                                  -- Тип платёжного документа: Текущий или Долговой
			 , '' as qrData																						-- NVARCHAR(2000)
		-- НЕ ДЕЛАТЬ ПЕРЕСТАНОВОК ПОЛЕЙ    или меняй rep_ivc_pd
		FROM @t_schet AS t
			LEFT JOIN #t_sort AS ts ON t.occ = ts.occ
			LEFT JOIN dbo.VOcc_Suppliers AS os ON t.occ = os.occ
			LEFT JOIN dbo.Intprint AS I ON t.occ = I.occ AND os.fin_id=i.fin_id
			LEFT JOIN dbo.People AS p ON i.Initials_owner_id = p.id
			LEFT JOIN dbo.Occupation_Types AS ot ON t.tip_id = ot.id
			JOIN dbo.Suppliers_all AS sup ON os.sup_id = sup.id
			LEFT JOIN dbo.Dog_sup DS ON os.sup_id = DS.sup_id
				AND os.dog_int = DS.id
			LEFT JOIN dbo.VOcc_Suppliers AS i2 ON t.occ = i2.occ
				AND i2.fin_id = @fin_current
				AND i2.sup_id = @sup_id
			LEFT JOIN dbo.Buildings_comments AS bc ON bc.build_id = t.build_id
				AND bc.fin_id = os.fin_id
				AND bc.sup_id = os.sup_id
			LEFT JOIN dbo.Type_occ_gis tog ON sup.tip_occ = tog.id
		WHERE os.sup_id = @sup_id
			AND @sal <=
					   CASE
						   WHEN @current_dolg = 1 THEN i2.Whole_payment
						   ELSE os.Whole_payment
					   END
			AND os.fin_id BETWEEN @fin_id1 AND @fin_id2
		ORDER BY ts.sort_no;


	END TRY

	BEGIN CATCH

		SET @strerror = @strerror + 'Лицевой: ' + LTRIM(STR(@occ1));

		EXECUTE k_GetErrorInfo @visible = @debug
							 , @strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1);
	END CATCH;


	RETURN;
go

