CREATE   PROCEDURE [dbo].[k_intPrint_occ]
(
	  @fin_id1 SMALLINT
	, @occ1 INT = 0
	, @build INT = 0 -- Код дома
	, @jeu SMALLINT = 0 -- Участок
	, @tip_id SMALLINT = NULL -- жилой фонд
	, @ops INT = 0 -- ОПС
	, @notocc SMALLINT = 0
	, @sum_dolg DECIMAL(9, 2) = 0 -- если не равно 0 вывод только с долгом более этой суммы
	, @group_id INT = 0
	, @sort_tip SMALLINT = 0
	, @town_id INT = NULL
	, @current_dolg BIT = 0 -- использовать текущий долг для выборки
	, @sup_id INT = NULL
	, @kol_mes1 SMALLINT = NULL -- кол.месяцев долга от
	, @kol_mes2 INT = 999999 -- кол.месяцев долга до
	, @fin_id2 SMALLINT = NULL
	, @people0_block BIT = 0 -- блокировать печать где нет людей
	, @debug BIT = 0
	, @SetLastDayMonthPrint BIT = NULL -- устанавливать последний день месяца печати
	, @is_out_gis BIT = NULL -- удаляем если id_jku_gis=''
	, @paidAll0_block BIT = 0 -- блокировать печать где нет начислений
	, @is_print_dolg BIT = 0 -- печатать если есть сумма к оплате (не смотря на @people0_block и @paidAll0_block)
	, @PROPTYPE_STR VARCHAR(10) = NULL -- строка с разрешёнными к печати типами собственности
	, @is_update_kvit BIT = 0 -- обновлять квитанции перед выборкой
	, @paid_block BIT = 0 -- блокировать печать где есть начисления	
)
AS
	/*
--
--  Показываем часть информации по счету-квитанции
--

дата изменения: 26.04.07
автор изменения: Пузанов 
добавил
 'EAN2'=dbo.Fun_GetScaner_Kod_EAN2(i.occ,@fin_id1,i.SumPaym),


дата изменения: 20.03.06
автор изменения: Пузанов 
банковские реквизиты по участкам


изменил
-- 'EAN'=dbo.Fun_GetScaner_Kod_EAN(i.occ,@fin_id1,null),
--добавил переменную почтампа

exec k_intPrint_occ @fin_id1=254,@tip_id=1,@sup_id=345,@town_id=1,@debug=1

exec k_intPrint_occ @fin_id1=234,@occ1=6133142,@tip_id=21,@debug=0,@PROPTYPE_STR='непр,прив'
exec k_intPrint_occ @fin_id1=255,@occ1=30062,@debug=0
exec k_intPrint_occ @fin_id1=190,@occ1=680001888,@build=1045,@debug=1
exec k_intPrint_occ @fin_id1=152,@occ1=700042209,@build=843,@debug=1
exec k_intPrint_occ @fin_id1=180,@occ1=680004137,@debug=0
*/
	SET NOCOUNT ON

	DECLARE @sal INT
		  , @DB_NAME VARCHAR(20) = UPPER(DB_NAME())
		  , @rowcount_tmp INT
		  , @start_date SMALLDATETIME
		  , @Program	VARCHAR(30) = dbo.fn_app_name()

	IF @sort_tip IS NULL
		SET @sort_tip = 0

	IF @group_id IS NULL
		SET @group_id = 0

	IF @notocc IS NULL
		SET @notocc = 0

	IF @sum_dolg = 0
		OR @sum_dolg IS NULL
		SET @sal = -999999999
	ELSE
		SET @sal = @sum_dolg

	IF @current_dolg IS NULL
		SET @current_dolg = 0

	IF @sup_id = 0
		SET @sup_id = NULL

	IF @kol_mes1 IS NULL
		SET @kol_mes1 = 0

	IF @kol_mes2 IS NULL
		SET @kol_mes2 = 999999

	IF COALESCE(@fin_id2, 0) = 0
		OR @fin_id2 < @fin_id1
		SET @fin_id2 = @fin_id1

	SET @paidAll0_block = coalesce(@paidAll0_block, 0)
	SET @paid_block = coalesce(@paid_block, 0)

	IF @is_out_gis IS NULL
		SET @is_out_gis = 0
	IF @is_print_dolg IS NULL
		SET @is_print_dolg = 0

	SELECT @start_date = start_date
	FROM dbo.Calendar_period
	WHERE fin_id = @fin_id1

	DECLARE @t dbo.myTypeTableOcc

	--DECLARE @t_schet TABLE
	CREATE TABLE #t_schet (
		  occ INT PRIMARY KEY
		, occ_false INT -- ложный лицевой для печати в квитанциях
		, NameFirma VARCHAR(100) COLLATE Cyrillic_General_CI_AS DEFAULT NULL
		, bank VARCHAR(100) COLLATE Cyrillic_General_CI_AS DEFAULT NULL
		, rasscht VARCHAR(30) COLLATE database_default DEFAULT NULL
		, korscht VARCHAR(30) COLLATE database_default DEFAULT NULL
		, bik VARCHAR(20) COLLATE database_default DEFAULT NULL
		, inn VARCHAR(20) COLLATE database_default DEFAULT NULL
		, kpp VARCHAR(20) COLLATE database_default DEFAULT NULL
		, tip_id SMALLINT DEFAULT 1
		, id_barcode VARCHAR(50) COLLATE database_default DEFAULT ''
		, licbank BIGINT DEFAULT 0
		, NameFirma_str2 VARCHAR(100) COLLATE Cyrillic_General_CI_AS DEFAULT NULL
		, tip_account_org SMALLINT
		, barcode_type SMALLINT
		, adres VARCHAR(60) COLLATE Cyrillic_General_CI_AS
		, build_id INT DEFAULT NULL
		, cbc VARCHAR(20) COLLATE database_default DEFAULT NULL
		, oktmo VARCHAR(11) COLLATE database_default DEFAULT NULL
		, id_els_gis VARCHAR(10) COLLATE database_default DEFAULT NULL
		, id_jku_gis VARCHAR(13) COLLATE database_default DEFAULT NULL
		, id_jku_pd_gis VARCHAR(20) COLLATE database_default DEFAULT NULL
		, comments_print VARCHAR(50) COLLATE database_default DEFAULT NULL
		, opu_tepl_kol SMALLINT DEFAULT 0
		, sector_id SMALLINT DEFAULT 0
	    , is_commission_uk BIT DEFAULT 0
	    , commission_bank_code varchar(10) COLLATE database_default DEFAULT ''
	    , dop_params NVARCHAR(100) COLLATE database_default DEFAULT ''
	)

	--WHEN tip_account_org=1 THEN 'Тип фонда'
	--WHEN tip_account_org=2 THEN 'Участок'
	--WHEN tip_account_org=3 THEN 'Поставщик'
	--WHEN tip_account_org=4 THEN 'Район'
	--WHEN tip_account_org=5 THEN 'Дом'
	--WHEN tip_account_org=6 THEN 'Договор'

	IF @build > 0
	BEGIN
		IF @debug = 1
			PRINT CONCAT('@build=', @build)
		INSERT INTO @t (occ
					  , fin_id
					  , flat_id
					  , build_id
					  , summa1
					  , tip_id
					  , total_sq
					  , summa3
					  , summa2  --PaidAll
					  , proptype_id
					  , roomtype_id
					  , kol_people_reg)
		SELECT o.occ
			 , o.fin_id
			 , o.flat_id
			 , o.bldn_id
			 , o.Whole_payment
			 , o.tip_id
			 , o.total_sq
			 , o.PaidItog
			 , o.PaidAll
			 , o.proptype_id
			 , o.roomtype_id
			 , o.kol_people_reg
		FROM dbo.View_occ_all_lite AS o 
		WHERE o.bldn_id = @build
			AND o.fin_id = @fin_id1
			AND o.Status_id <> 'закр'
			AND (@tip_id IS NULL OR o.tip_id = @tip_id)
			AND (@notocc=1 OR (@notocc=0 AND NOT EXISTS (
				SELECT 1
				FROM dbo.Occ_not_print AS onp 
				WHERE o.occ = onp.occ
					AND onp.flag = 1
			)))
		GOTO LABEL1
	END

	IF @jeu > 0
	BEGIN
		IF @debug = 1
			PRINT CONCAT('@jeu=', @jeu)
		INSERT INTO @t (occ
					  , fin_id
					  , flat_id
					  , build_id
					  , summa1
					  , tip_id
					  , total_sq
					  , summa3
					  , summa2
					  , proptype_id
					  , roomtype_id
					  , kol_people_reg)
		SELECT o.occ
			 , o.fin_id
			 , o.flat_id
			 , o.bldn_id
			 , o.Whole_payment
			 , o.tip_id
			 , o.total_sq
			 , o.PaidItog
			 , o.PaidAll
			 , o.proptype_id
			 , o.roomtype_id
			 , o.kol_people_reg
		FROM dbo.View_occ_all_lite AS o 
			JOIN dbo.Buildings AS b ON 
				o.bldn_id = b.id
		WHERE b.sector_id = @jeu
			AND o.fin_id = @fin_id1
			AND (o.Status_id <> 'закр' OR o.proptype_id = 'арен')
			AND (@tip_id IS NULL OR o.tip_id = @tip_id)
			AND (@notocc=1 OR (@notocc=0 AND NOT EXISTS (
				SELECT 1
				FROM dbo.Occ_not_print AS onp 
				WHERE o.occ = onp.occ
					AND onp.flag = 1
				)))
		GOTO LABEL1
	END

	--IF @notocc > 0
	--BEGIN
	--	IF @debug = 1
	--		PRINT '@notocc=' + LTRIM(STR(@notocc))
	--	INSERT INTO @t (occ
	--				  , fin_id
	--				  , flat_id
	--				  , build_id
	--				  , summa1
	--				  , tip_id
	--				  , total_sq
	--				  , summa3
	--				  , summa2
	--				  , proptype_id
	--				  , roomtype_id
	--				  , kol_people_reg)
	--	SELECT onp.occ
	--		 , o.fin_id
	--		 , o.flat_id
	--		 , o.bldn_id
	--		 , o.Whole_payment
	--		 , o.tip_id
	--		 , o.total_sq
	--		 , o.PaidItog
	--		 , o.PaidAll
	--		 , o.proptype_id
	--		 , o.roomtype_id
	--		 , o.kol_people_reg
	--	FROM dbo.Occ_not_print AS onp 
	--		JOIN dbo.View_occ_all_lite AS o ON o.occ = onp.occ
	--	WHERE onp.flag = 1
	--		AND o.fin_id = @fin_id1
	--		AND (o.tip_id = @tip_id OR @tip_id IS NULL)
	--		AND (o.build_id = @build OR @build IS NULL)
	--		AND (o.fin_id = @fin_id1)
	--	GOTO LABEL1
	--END

	IF @group_id > 0
	BEGIN
		IF @debug = 1
			PRINT CONCAT('@group_id=', @group_id)
		INSERT INTO @t (occ
					  , fin_id
					  , flat_id
					  , build_id
					  , summa1
					  , tip_id
					  , total_sq
					  , summa3
					  , summa2
					  , proptype_id
					  , roomtype_id
					  , kol_people_reg)
		SELECT DISTINCT o.occ
					  , o.fin_id
					  , o.flat_id
					  , o.bldn_id
					  , o.Whole_payment
					  , o.tip_id
					  , o.total_sq
					  , o.PaidItog
					  , o.PaidAll
					  , o.proptype_id
					  , o.roomtype_id
					  , o.kol_people_reg
		FROM dbo.Print_occ AS po 
			JOIN dbo.View_occ_all_lite AS o ON 
				o.occ = po.occ
		WHERE po.group_id = @group_id
			AND (@tip_id IS NULL OR o.tip_id = @tip_id)
			AND o.fin_id = @fin_id1
		GOTO LABEL1
	END

	IF @tip_id > 0
		AND COALESCE(@build, 0) = 0
		AND COALESCE(@occ1, 0) = 0
	BEGIN
		IF @debug = 1
			PRINT CONCAT('@tip_id=', @tip_id)
		INSERT INTO @t (occ
					  , fin_id
					  , flat_id
					  , build_id
					  , summa1
					  , tip_id
					  , total_sq
					  , summa3
					  , summa2  --PaidAll
					  , proptype_id
					  , roomtype_id
					  , kol_people_reg)
		SELECT o.occ
			 , o.fin_id
			 , o.flat_id
			 , o.bldn_id
			 , o.Whole_payment
			 , o.tip_id
			 , o.total_sq
			 , o.PaidItog
			 , o.PaidAll
			 , o.proptype_id
			 , o.roomtype_id
			 , o.kol_people_reg
		FROM dbo.View_occ_all_lite AS o 
		WHERE o.fin_id = @fin_id1
			AND o.Status_id <> 'закр'
			AND o.tip_id = @tip_id
			AND (@notocc=1 OR (@notocc=0 AND NOT EXISTS (
				SELECT 1
				FROM dbo.Occ_not_print AS onp 
				WHERE o.occ = onp.occ
					AND onp.flag = 1
			)))
		GOTO LABEL1
	END

	IF @occ1 > 0
	BEGIN
		IF @debug = 1
			PRINT CONCAT('@occ1=', @occ1)
		INSERT INTO @t (occ
					  , fin_id
					  , flat_id
					  , build_id
					  , summa1
					  , tip_id
					  , total_sq
					  , summa3
					  , summa2
					  , proptype_id
					  , roomtype_id
					  , kol_people_reg)
		SELECT o.occ
			 , o.fin_id
			 , o.flat_id
			 , o.bldn_id
			 , o.Whole_payment
			 , o.tip_id
			 , o.total_sq
			 , o.PaidItog
			 , o.PaidAll
			 , o.proptype_id
			 , o.roomtype_id
			 , o.kol_people_reg
		FROM dbo.View_occ_all_lite AS o 
		WHERE occ = @occ1
			AND o.Status_id <> 'закр'
			AND o.fin_id = @fin_id1
		GOTO LABEL1
	END

	IF @town_id IS NOT NULL
	BEGIN
		--IF @debug = 1 PRINT CONCAT('@town_id=', @town_id)
		INSERT INTO @t (occ
					  , fin_id
					  , flat_id
					  , build_id
					  , summa1
					  , tip_id
					  , total_sq
					  , summa3
					  , summa2
					  , proptype_id
					  , roomtype_id
					  , kol_people_reg)
		SELECT o.occ
			 , o.fin_id
			 , o.flat_id
			 , o.bldn_id
			 , o.Whole_payment
			 , o.tip_id
			 , o.total_sq
			 , o.PaidItog
			 , o.PaidAll
			 , o.proptype_id
			 , o.roomtype_id
			 , o.kol_people_reg
		FROM dbo.View_occ_all_lite AS o 
			JOIN dbo.Buildings AS b ON 
				o.bldn_id = b.id
		WHERE b.town_id = @town_id
			AND o.fin_id = @fin_id1
			AND (o.Status_id <> 'закр' OR o.proptype_id = 'арен')
			AND (@tip_id IS NULL OR o.tip_id = @tip_id)
	END

LABEL1:
	IF @tip_id IS NULL
		SELECT TOP (1) @tip_id = tip_id
		FROM @t

	IF @debug = 1
		SELECT N'Исх.выборка'
			 , *
		FROM @t

	IF @is_update_kvit = 1
	BEGIN
		-- попробуем определить: Печать за текущий период или из истории	
		IF NOT EXISTS (
				SELECT *
				FROM @t AS t
					JOIN dbo.Occupation_Types ot ON 
						t.tip_id = ot.id
						AND t.fin_id < ot.fin_id
			)
		BEGIN
			IF @debug = 1
				PRINT N'обновляем квитанции  k_intPrint_basa'
			EXEC k_intPrint_basa @tip_id1 = @tip_id
							   , @occ1 = @occ1
							   , @debug = 0
							   , @build_id = @build
		END
		ELSE
			IF @debug = 1
				PRINT N'печать из истории'
	END

	-- убираем лицевые которые не должны печатать
	IF @occ1 = 0
		AND @notocc = 0
	BEGIN
		DELETE t
		--OUTPUT DELETED.occ,'Убираем лицевые которые не должны печатать(OCC_NOT_print)'
		FROM @t AS t
			JOIN dbo.Occ_not_print AS onp ON 
				t.occ = onp.occ
				AND onp.flag = 1
		SET @rowcount_tmp = @@rowcount
		IF @rowcount_tmp > 0
			AND @debug = 1
			RAISERROR (N'Убираем лицевые которые не должны печатать(OCC_NOT_print), удалили = %i', 10, 1, @rowcount_tmp) WITH NOWAIT;
	END

	IF @occ1 = 0
		AND @is_out_gis = 0
		AND @paid_block = 0
	BEGIN
		DELETE t
		--OUTPUT DELETED.occ, 'Удаляем лицевые TOTAL_SQ=0 AND COALESCE(t.summa2,0)=0 (т.е. нет начислений)'
		FROM @t AS t
		WHERE t.total_sq = 0
			AND COALESCE(t.summa2, 0) = 0
		SET @rowcount_tmp = @@rowcount
		IF @rowcount_tmp > 0
			AND @debug = 1
			RAISERROR (N'Удаляем лицевые TOTAL_SQ=0 AND COALESCE(t.summa2,0)=0 (т.е. нет начислений), удалили = %i', 10, 1, @rowcount_tmp) WITH NOWAIT;
	END


	IF @occ1 = 0
		AND @is_out_gis = 0
		AND (@group_id IS NULL
		OR @group_id = 0)
	BEGIN
		DELETE t
		--OUTPUT DELETED.occ,'Удаляем лицевые которые можно печатать только из группы'
		FROM @t AS t
			JOIN dbo.Print_occ po ON 
				t.occ = po.occ
			JOIN dbo.Print_group pg ON 
				po.group_id = pg.id
		WHERE pg.print_only_group = 1
		SET @rowcount_tmp = @@rowcount
		IF @rowcount_tmp > 0
			AND @debug = 1
			RAISERROR (N'Удаляем лицевые которые можно печатать только из группы, удалили = %i', 10, 1, @rowcount_tmp) WITH NOWAIT;
	END

	IF @occ1 = 0
		AND @is_out_gis = 0
		AND (@group_id IS NOT NULL)
	BEGIN
		DELETE t
		--OUTPUT DELETED.occ,'Печатаем только группу'
		FROM @t AS t
			JOIN dbo.Print_occ po ON 
				t.occ = po.occ
			JOIN dbo.Print_group pg ON 
				po.group_id = pg.id
		WHERE po.group_id <> @group_id
			AND pg.print_only_group = 1
		SET @rowcount_tmp = @@rowcount
		IF @rowcount_tmp > 0
			AND @debug = 1
			RAISERROR (N'Печатаем только группу= %i, удалили = %i', 10, 1, @group_id, @rowcount_tmp) WITH NOWAIT;

	END

	IF @ops > 0
	BEGIN
		DELETE t
		--OUTPUT DELETED.occ,'Ограничиваем по ОПС'
		FROM @t AS t
			JOIN dbo.Occupations AS o ON 
				t.occ = o.occ
			JOIN dbo.Flats AS f ON 
				o.flat_id = f.id
			JOIN dbo.Buildings AS b ON 
				f.bldn_id = b.id
		WHERE b.index_id <> @ops
		SET @rowcount_tmp = @@rowcount
		IF @rowcount_tmp > 0
			AND @debug = 1
			RAISERROR (N'Ограничиваем по ОПС= %i, удалили = %i', 10, 1, @ops, @rowcount_tmp) WITH NOWAIT;
	END

	IF @occ1 = 0
		AND @group_id IS NULL
		AND @sup_id IS NOT NULL -- только в программе печать @occ1=0
	BEGIN
		DELETE t
		--OUTPUT DELETED.occ,'Отбираем только поставщика'
		FROM @t AS t
		WHERE @occ1 = 0
			AND NOT EXISTS (
				SELECT 1
				FROM dbo.Occ_Suppliers OS 
				WHERE OS.occ = t.occ
					AND fin_id = @fin_id1
					AND OS.sup_id = @sup_id
			)
		SET @rowcount_tmp = @@rowcount
		IF @rowcount_tmp > 0
			RAISERROR (N'Отбираем только поставщика= %i, удалили = %i', 10, 1, @sup_id, @rowcount_tmp) WITH NOWAIT;
	END

	IF @build = 0
		AND @occ1 = 0
	BEGIN	   -- удаляем дома, которым не начисляем
		DELETE t
		--OUTPUT DELETED.occ,'удаляем дома, которым не начисляем'
		FROM @t AS t
			JOIN dbo.Occupations AS o ON 
				t.occ = o.occ
			JOIN dbo.Flats AS f ON 
				o.flat_id = f.id
			JOIN dbo.View_build_all AS b ON 
				f.bldn_id = b.build_id
				AND b.fin_id = @fin_id1
		WHERE b.is_paym_build = 0
		SET @rowcount_tmp = @@rowcount
		IF @rowcount_tmp > 0
			AND @debug = 1
			RAISERROR (N'удаляем дома, которым не начисляем, удалили л/сч = %i', 10, 1, @rowcount_tmp) WITH NOWAIT;
	END

	-- *********************************************************
	IF @debug = 1
		SELECT *
		FROM @t

	IF @occ1 = 0
		AND @people0_block = 1
	BEGIN -- Убираем печать где нет людей
		DELETE t
		--OUTPUT DELETED.occ,'Убираем печать где нет людей'
		FROM @t AS t
			JOIN dbo.View_occ_all_lite voa ON t.occ = voa.occ
		WHERE voa.fin_id = @fin_id1
			AND voa.kol_people_all = 0
			AND EXISTS (
				SELECT *
				FROM @t
				WHERE t.summa1 <=
								 CASE
									 WHEN @is_print_dolg = 1 THEN 0  -- удаляем у кого нет долга
									 ELSE 9999999
								 END
			)
		SET @rowcount_tmp = @@rowcount
		IF @rowcount_tmp > 0
			AND @debug = 1
			RAISERROR (N'Убираем печать где нет людей, удалили = %i', 10, 1, @rowcount_tmp) WITH NOWAIT;
	END

	IF @occ1 = 0
		AND @paidAll0_block = 1
	BEGIN 
		if @debug=1 print 'Убираем печать где нет начислений'
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

	IF @occ1 = 0
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

	IF @occ1 = 0
		AND @paid_block = 1
	BEGIN 
		--if @debug=1 print 'Убираем печать где ЕСТЬ начисления'
		DELETE t
		--OUTPUT DELETED.occ,'Убираем печать где ЕСТЬ начисления'
		FROM @t AS t
		WHERE t.summa2 > 0
		SET @rowcount_tmp = @@rowcount
		IF @rowcount_tmp > 0
			AND @debug = 1
			RAISERROR (N'Убираем печать где ЕСТЬ начисления, удалили = %i', 10, 1, @rowcount_tmp) WITH NOWAIT;
	END

	IF @occ1 = 0
		AND COALESCE(@PROPTYPE_STR, '') <> ''
	BEGIN -- Убираем печать где тип собственности не тот
		DELETE t
		--OUTPUT DELETED.occ,'Убираем печать где тип собственности не тот'
		FROM @t AS t
		WHERE NOT EXISTS (
				SELECT 1
				FROM STRING_SPLIT(@PROPTYPE_STR, ',')
				WHERE RTRIM(value) <> ''
					AND value = t.proptype_id
			)
		SET @rowcount_tmp = @@rowcount
		IF @rowcount_tmp > 0
			AND @debug = 1
			RAISERROR (N'Убираем печать где тип собств.<> %s , удалили = %i', 10, 1, @PROPTYPE_STR, @rowcount_tmp) WITH NOWAIT;
	END

	DROP TABLE IF EXISTS #t_sort;
	CREATE TABLE #t_sort (
		  occ INT
		, index_id INT
		, index_postal INT
		, tip_id SMALLINT
		, sort_id INT
		, sort_no INT
		, KolMesDolg DECIMAL(5, 1) DEFAULT 0
		, nom_kvr VARCHAR(20) COLLATE database_default DEFAULT ''
	)
	CREATE INDEX occ ON #t_sort (occ)
	CREATE INDEX sort_no ON #t_sort (sort_no)

	INSERT INTO #t_sort (occ
					   , tip_id
					   , index_id
					   , index_postal
					   , sort_id
					   , KolMesDolg
					   , nom_kvr)
	SELECT t.occ
		 , o.tip_id
		 , b.index_id
		 , COALESCE(b.index_postal, 0)
		 , ROW_NUMBER() OVER (ORDER BY 
							CASE
								WHEN @ops > 0 THEN 0 ELSE b.sector_id
							END
							, s.name, b.nom_dom_sort, o.nom_kvr_sort
		) AS sort_id
		 , o.KolMesDolg
		 , o.nom_kvr
	FROM @t AS t
		JOIN dbo.View_occ_all_lite AS o ON 
			t.occ = o.occ
		JOIN dbo.Buildings AS b ON 
			o.bldn_id = b.id
		JOIN dbo.VStreets AS s ON b.
			street_id = s.id
	WHERE o.fin_id = @fin_id1
		AND @sal <= o.Whole_payment
		AND @kol_mes1 <= o.KolMesDolg
		AND o.KolMesDolg < @kol_mes2

	UPDATE #t_sort
	SET sort_no = sort_id

	IF @sort_tip = 0
		UPDATE #t_sort
		SET sort_no = sort_id
	ELSE
	BEGIN
		DECLARE @kol INT = 0
			  , @kol2 INT = 0
		SELECT @kol = COUNT(occ)
		FROM #t_sort
		SELECT @kol2 = (@kol / 2) + @kol % 2

		--SELECT @kol,@kol2

		UPDATE #t_sort
		SET sort_no = sort_id + (sort_id - 1)
		WHERE sort_id <= @kol2

		-- N=N+N
		UPDATE #t_sort
		SET sort_no = sort_no - @kol2
		WHERE sort_id > @kol2

		UPDATE #t_sort
		SET sort_no = sort_no + sort_no
		WHERE sort_id > @kol2
	END

	--IF @debug=1 select t.*,o.address from #t_sort as t join dbo.OCCUPATIONS as o ON t.occ=o.occ
	--IF @debug=1 select * from @t
	--IF @debug=1 select * FROM dbo.Fun_GetAccount_ORG_Table(@t)

	-- Записываем банковские реквизиты
	INSERT INTO #t_schet (occ
						, occ_false
						, NameFirma
						, bank
						, rasscht
						, korscht
						, bik
						, inn
						, kpp
						, tip_id
						, id_barcode
						, licbank
						, NameFirma_str2
						, tip_account_org
						, barcode_type
						, adres
						, build_id
						, cbc
						, oktmo
						, id_els_gis
						, id_jku_gis
						, id_jku_pd_gis
						, comments_print
						, opu_tepl_kol
						, sector_id
						, is_commission_uk
						, commission_bank_code)
	SELECT t.occ
		 , t.occ
		 , ban.name_str1
		 , ban.bank
		 , ban.rasschet
		 , ban.korschet
		 , ban.bik
		 , ban.inn
		 , ban.kpp
		 , o.tip_id
		 , ban.id_barcode
		 , ban.licbank
		 , ban.name_str2 -- адрес получателя
		 , ban.tip_account_org
		 , ban.barcode_type
		 , o.address
		 , t.build_id
		 , ban.cbc
		 , ban.oktmo
		 , COALESCE(o.id_els_gis, '')
		 , COALESCE(o.id_jku_gis, '')
		 , dbo.Fun_GetNumPdGis2(o.id_jku_gis, @fin_id1) AS id_jku_pd_gis
		 , o.comments_print
		 , b.opu_tepl_kol
		 , b.sector_id
	     , b.is_commission_uk
	     , ot.commission_bank_code
	FROM @t AS t
		JOIN dbo.View_occ_all_lite AS o 
			ON t.occ = o.occ
		JOIN dbo.Flats f 
			ON o.flat_id = f.id
		JOIN dbo.Buildings AS b 
			ON f.bldn_id = b.id
	    JOIN dbo.Occupation_Types ot 
			ON o.tip_id = ot.id
		LEFT JOIN dbo.Fun_GetAccount_ORG_Table(@t) AS ban 
			ON t.occ = ban.occ
    where o.fin_id = @fin_id1

	IF EXISTS (
			SELECT 1
			FROM #t_schet AS t
			WHERE rasscht IS NULL
				OR rasscht = ''
		)
	BEGIN
		RAISERROR (N'Нет банковских реквизитов!', 16, 1)
		--RETURN
	END

	IF EXISTS (
			SELECT 1
			FROM dbo.Global_values 
			WHERE fin_id = @fin_id1
				AND BlokedPrintAccount = 1
				AND @Program <> N'Картотека.exe'
		)
	BEGIN -- Блокируем печать квитанций
		DELETE FROM #t_schet
	END

	IF @is_out_gis = 1
	BEGIN
		DELETE t
		FROM @t t
			JOIN dbo.View_build_all_lite vbal ON 
				t.build_id = vbal.build_id
				AND vbal.fin_id = @fin_id1
		WHERE vbal.is_paym_build = CAST(0 AS BIT)

		DELETE #t_schet
		WHERE id_jku_gis = ''
	END


	IF @debug = 1
		SELECT '#t_schet'
			 , *
		FROM #t_schet
		ORDER BY occ

	UPDATE #t_schet
	SET occ_false = dbo.Fun_GetFalseOccOut(occ, tip_id)


	DECLARE @quarte_account BIT = 0
	SELECT TOP 1 @tip_id = tip_id
	FROM @t
	--IF @DB_NAME IN ('KOMP')
	--	AND @tip_id = 181 -- тихие зори печать раз в квартал
	--	SET @quarte_account = 1

	DECLARE @kol_jeu SMALLINT
	SELECT @kol_jeu = COUNT(DISTINCT sector_id)
	FROM #t_schet AS t
	IF @kol_jeu IS NULL
		SET @kol_jeu = 1

    Update t
    set  dop_params = 'serviceName='+dbo.Fun_GetPosStringSplit(t.commission_bank_code,',',
                                                               CASE
                                                                   WHEN t.is_commission_uk = 0 THEN 1
                                                                   ELSE 2
                                                                   END)
    From #t_schet as t
    where t.commission_bank_code<>''

	--print @tip_id
	--print @quarte_account
	--exec k_intPrint_occ 155,328085
	--exec k_intPrint_occ 152,680001666

	--select * from #t_schet order by occ
	--select * from #t_sort order by occ
	--IF @debug = 1
	--	select t.*,'Нет в INTPRINT' as Error from @t AS t
	--		LEFT JOIN INTPRINT AS i ON t.occ=i.occ
	--		AND i.fin_id=@fin_id1
	--		WHERE i.occ IS null
	--		order by t.occ

	DECLARE @DatePrint SMALLDATETIME
	SELECT @DatePrint = CAST(
		CASE
			WHEN @SetLastDayMonthPrint = 1 THEN (
					SELECT end_date
					FROM dbo.Global_values AS gb 
					WHERE fin_id = @fin_id1
				)
			ELSE current_timestamp
		END AS DATE)

	IF @debug = 1
		SELECT '#t_sort'
			 , *
		FROM #t_sort

	-- НЕ ДЕЛАТЬ ПЕРЕСТАНОВОК ПОЛЕЙ    или меняй rep_ivc_pd
	SELECT ts.sort_no                                                                                  -- INT
		 , i.fin_id                                                                                    -- SMALLINT
		 , CASE
			   WHEN @is_out_gis = 1 AND
				   ot.export_gis_occ_prefix = 0 THEN t.occ
			   ELSE t.occ_false
		   END AS occ                                                                       -- INT
		 , i.SumPaym AS SumPaym                                                                        --o.Summa1 --o.Whole_payment  DECIMAL(9,2)
		 , i.SumPaym - i.Penalty_value AS SumPaymNoPeny                                                -- DECIMAL(9,2)
		 , i.debt + i.Penalty_value AS SumPaymDebt                                                     -- может быть отрицательным -- DECIMAL(9,2)
		 , o.summa3 AS Paid                                                                            -- DECIMAL(9,2)
		 , i.occ AS occ_pd                                                                             -- INT
		   --,dbo.Fun_GetNumPd(i.occ, i.fin_id, @sup_id) AS num_pd
		 , dbo.Fun_GetNumUV(i.occ, i.fin_id, @sup_id) AS num_pd                                        -- VARCHAR(16)
		 , t.id_els_gis                                                                                -- VARCHAR(10)
		 , t.id_jku_gis AS id_jku_gis                                                                  -- VARCHAR(13)
		 , t.id_jku_pd_gis AS id_jku_pd_gis                                                            -- VARCHAR(20)
		 , i.Penalty_value AS Penalty_itog                                                             -- DECIMAL(9,2)
		 , vba.sector_id AS jeu                                                                        -- SMALLINT
		 , vba.sector_name AS jeu_name                                                                 -- VARCHAR(30)
		 , i.Initials                                                                                  -- VARCHAR(120)
		 , CASE
			   WHEN ts.index_postal > 1 THEN LTRIM(STR(ts.index_postal, 6)) + ','
			   ELSE ''
		   END + t.adres AS adres                                                           -- VARCHAR(100)
		 , i.Lgota                                                                                     -- VARCHAR(20)
		   --,[dbo].[Fun_GetKolPeopleOccReg](@fin_id1, t.occ) AS total_people
		 , o.kol_people_reg AS total_people                                                            -- SMALLINT
		 , i.total_sq                                                                                  -- DECIMAL(9,2)
		 , i.living_sq                                                                                 -- DECIMAL(9,2)
		 , i.FinPeriod                                                                                 -- SMALLDATETIME
		 , CASE
			   WHEN @quarte_account = 1 THEN CAST(DATENAME(QUARTER, i.FinPeriod) + N' квартал' AS VARCHAR(15))
			   ELSE dbo.Fun_NameFinPeriodDate(i.FinPeriod)  -- 'MMMM yyyy'
				--ELSE dbo.Fun_NameFinPeriod(i.fin_id)
		   END AS StrFinPeriod                                                              -- VARCHAR(30)
		 , i.saldo                                                                                     -- DECIMAL(9,2)
		 , i.saldo + COALESCE(i.Penalty_old, 0) AS DolgWithPeny                                        -- DECIMAL(9,2)  -- долг с учетом пени
		 , i.paymaccount                                                                               -- DECIMAL(9,2)
		 , i.paymaccount_peny                                                                          -- -- DECIMAL(9,2)
		 , i.debt                                                                                      -- DECIMAL(9,2)
		 , i.PaymAccount_storno                                                                        -- -- DECIMAL(9,2)
		 , i.LastDayPaym AS LastDayPaym                                                                -- SMALLDATETIME  -- Долг на
		 , i.LastDayPaym2                                                                              -- SMALLDATETIME  -- Оплата учтена по
		 , i.PersonStatus                                                                              -- VARCHAR(50)
		 , '' AS Month3                                                                                -- не нужно но осталось поле во многих квитанциях  -- VARCHAR(20)
		 , i.Penalty_value                                                                             -- DECIMAL(9,2)
		 , i.StrSubsidia1                                                                              -- VARCHAR(100)
		 , i.StrSubsidia2                                                                              -- VARCHAR(100)
		 , i.StrSubsidia3                                                                              -- VARCHAR(100)
		 , 0 AS Div_id                                                                                 -- SMALLINT
		 , i.KolMesDolg                                                                                -- DECIMAL(5,1)
		 , i.DateCreate                                                                                -- SMALLDATETIME
		 , t.NameFirma                                                                                 -- VARCHAR(100)
		 , t.NameFirma_str2                                                                            -- VARCHAR(100)
		 --, CASE
			--   WHEN @tip_id IN (60, 57, 59) THEN dbo.Fun_GetScaner_Kod_SUP_EAN(t.occ_false, 0, @fin_id1, o.summa1, t.id_barcode) --o.Whole_payment
			--   ELSE dbo.Fun_GetScaner_Kod_EAN(t.occ_false, NULL, @fin_id1, i.SumPaym, t.id_barcode, barcode_type, t.inn)
		 --  END 
		  ,'' AS [EAN]                                                                     -- VARCHAR(50)
		   --, [EAN] = dbo.Fun_GetScaner_Kod_EAN(t.occ_false, NULL, @fin_id1, i.SumPaym, t.id_barcode, barcode_type)
		   --, [EAN_2D] = dbo.Fun_GetScaner_Kod_PDF417(t.occ_false, NULL, @fin_id1, i.SumPaym, i.Adres, i.Initials, t.NameFirma, t.bik, t.rasscht, t.licbank)
		 --, CASE
			--   WHEN ot.is_2D_Code = 1
			--       THEN [dbo].[Fun_GetScaner_2D_SBER](t.occ_false, @fin_id1, NULL, i.SumPaym, t.adres COLLATE Cyrillic_General_CI_AS, i.Initials, t.bank, t.bik, t.korscht, t.NameFirma COLLATE Cyrillic_General_CI_AS, t.rasscht, t.inn, t.kpp, t.licbank, p.Last_name, p.First_name, p.Second_name, t.cbc, t.oktmo, t.id_jku_pd_gis, t.dop_params)
			--   --[dbo].[Fun_GetScaner_PDF417](t.occ_false, @fin_id1, NULL, i.SumPaym, t.adres, i.Initials, t.bank, t.bik, t.korscht, t.NameFirma, t.rasscht, t.inn, t.kpp, t.licbank)
			--   ELSE CASE
			--		   WHEN @tip_id IN (60, 57, 59) THEN dbo.Fun_GetScaner_Kod_SUP_EAN(t.occ_false, 0, @fin_id1, o.summa1, t.id_barcode) --o.Whole_payment
			--		   ELSE dbo.Fun_GetScaner_Kod_EAN(t.occ_false, NULL, @fin_id1, i.SumPaym, t.id_barcode, barcode_type, t.inn)
			--	   END
		 --  END 
		 , [dbo].[Fun_GetScaner_2D_SBER](t.occ_false, @fin_id1, NULL, i.SumPaym, t.adres COLLATE Cyrillic_General_CI_AS, i.Initials, t.bank, t.bik, t.korscht, t.NameFirma COLLATE Cyrillic_General_CI_AS, t.rasscht, t.inn, t.kpp, t.licbank, p.Last_name, p.First_name, p.Second_name, t.cbc, t.oktmo, t.id_jku_pd_gis, t.dop_params)
		   AS [EAN_2D]                                                                  -- NVARCHAR(2000)		   
		 , '' AS [EAN_2D_NoPeny]                                                                       -- VARCHAR(50)
		   --CASE
		   --	WHEN ot.is_2D_Code = 1 THEN [dbo].[Fun_GetScaner_2D_SBER](t.occ_false, @fin_id1, NULL, i.SumPaym-i.Penalty_value, t.adres COLLATE Cyrillic_General_CI_AS, i.Initials, t.bank, t.bik, t.korscht, t.NameFirma COLLATE Cyrillic_General_CI_AS, t.rasscht, t.inn, t.kpp, t.licbank)				
		   --	ELSE dbo.Fun_GetScaner_Kod_EAN(t.occ_false, NULL, @fin_id1, i.SumPaym-i.Penalty_value, t.id_barcode, barcode_type, t.inn)
		   --END
		 , '' AS [EAN_2D_Peny]                                                                         -- VARCHAR(50)
		   --CASE
		   --	WHEN ot.is_2D_Code = 1 THEN [dbo].[Fun_GetScaner_2D_SBER](t.occ_false, @fin_id1, NULL, i.Penalty_value, t.adres COLLATE Cyrillic_General_CI_AS, i.Initials, t.bank, t.bik, t.korscht, t.NameFirma COLLATE Cyrillic_General_CI_AS, t.rasscht, t.inn, t.kpp, t.licbank)				
		   --	ELSE dbo.Fun_GetScaner_Kod_EAN(t.occ_false, NULL, @fin_id1, i.Penalty_value, t.id_barcode, barcode_type, t.inn)
		   --END			
		 , '' AS [EAN_SBER]                                                                            --dbo.Fun_GetScaner_Kod_EAN_SBER(t.occ_false, @fin_id1, i.SumPaym, t.inn) -- VARCHAR(50)
		 , t.bank                                                                                      -- VARCHAR(100)
		 , t.rasscht                                                                                   -- VARCHAR(30)
		 , t.korscht                                                                                   -- VARCHAR(30)
		 , t.bik                                                                                       -- VARCHAR(20)
		 , t.inn                                                                                       -- VARCHAR(20)
		 , t.kpp                                                                                       -- VARCHAR(20)
		 , t.cbc                                                                                       -- VARCHAR(20)
		 , t.oktmo                                                                                     -- VARCHAR(20)
		 , ts.index_id AS [INDEX]                                                                      -- INT
		 , ts.index_postal AS index_postal                                                             -- INT
		 , t.tip_id                                                                                    -- SMALLINT
		 , CASE
			   WHEN (ot.payms_value = 0) THEN ''
			   WHEN (ot.synonym_name IS NULL OR ot.synonym_name = '') THEN ot.name
			   ELSE ot.synonym_name
		   END AS [tip_name]                                                                -- VARCHAR(150)
		 , ot.adres AS adres_tip                                                                       -- VARCHAR(100)
		 , ot.telefon AS telefon_tip                                                                   -- VARCHAR(100)
		 , ot.inn AS inn_tip                                                                           -- VARCHAR(20)
		 , ot.kpp AS kpp_tip                                                                           -- VARCHAR(20)
		 , ot.ogrn AS ogrn_tip                                                                         -- VARCHAR(20)
		 , ot.email AS email_tip                                                                       -- VARCHAR(50)
		 , ot.tip_details AS details_tip                                                               -- VARCHAR(500)
		 --, dbo.Fun_GetAddStr(t.occ, i.fin_id, NULL, NULL) AS StrAdd -- VARCHAR(800)
		 , dbo.Fun_GetAddStrSum(t.occ, i.fin_id, NULL, NULL) AS StrAdd                                 -- VARCHAR(800)
		 , ot.LastStr1 AS LastStr1                                                                     -- VARCHAR(100)
		 , ot.LastStr2 AS LastStr2                                                                     -- VARCHAR(1000)
		 , ot.logo                                                                                     -- VARBINARY(MAX)
		 , sec.adres_sec                                                                               -- VARCHAR(100)
		 , sec.fio_sec                                                                                 -- VARCHAR(50)
		 , sec.telefon_sec                                                                             -- VARCHAR(100)
		 , CASE
			   WHEN ot.tip_org_for_account IS NULL OR
				   LTRIM(ot.tip_org_for_account) = '' THEN 'Управляющая организация'
			   ELSE ot.tip_org_for_account
		   END AS tip_org_for_account                                                       -- VARCHAR(100)
		 , o.build_id AS bldn_id                                                                       --o.bldn_id  INT
		 , t_date_paym.date_paym_last_str AS LastDayPaymAccount                                        -- дата последней учтённой оплаты в квитанции -- VARCHAR(10)
		 , vba.norma_gkal AS build_norma_gkal                                                          -- DECIMAL(9,6)
		 , vba.opu_sq AS build_opu_sq                                                                  -- DECIMAL(9,2)
		 , vba.opu_sq_elek AS build_opu_sq_elek                                                        -- DECIMAL(9,2)
		 , vba.build_total_sq                                                                          -- DECIMAL(9,2)
		 , vba.arenda_sq AS build_arenda_sq                                                            -- DECIMAL(9,2)
		 , t_build_comments.comments AS build_comments                                                 -- VARCHAR(4000)
		 , vba.adres AS adres_build                                                                    -- VARCHAR(100)
		 , CASE
			   WHEN vba.account_rich IS NOT NULL THEN vba.account_rich
			   WHEN i.fin_id = o.fin_id AND
				   ot.account_rich IS NOT NULL THEN ot.account_rich
			   WHEN i.fin_id < o.fin_id AND
				   ot2.account_rich IS NOT NULL THEN ot2.account_rich
			   ELSE NULL
		   END AS account_rich                                                              -- VARCHAR(MAX)
		 , ts.nom_kvr                                                                                  -- VARCHAR(20)
		   --'Убедительная просьба, погасить имеющуюся задолженность, в случае отсутствия оплаты, задолженность будет взыскана через суд.'
		 , '' AS StrLast                                                                               -- VARCHAR(1000)
		 , @DatePrint AS DatePrint                                                                     -- SMALLDATETIME  -- дата печати
		 , @kol_jeu AS kol_jeu                                                                         -- SMALLINT
		 , ROW_NUMBER() OVER (PARTITION BY vba.sector_id ORDER BY i.fin_id, ts.sort_no) AS row_num_jeu -- SMALLINT
		 , COUNT(i.occ) OVER (PARTITION BY vba.sector_id) AS kol_occ_jeu                               -- SMALLINT
		 , COUNT(o.occ) OVER (PARTITION BY o.build_id) AS kol_occ_build                                -- INT
		 , i.FinPeriod AS [start_date]                                                                 -- SMALLDATETIME
		 , ot.tip_occ                                                                                  -- SMALLINT
		 , ot.soi_isTotalSq_Pasport                                                                    -- BIT
		   --, vba.build_total_area	  -- DECIMAL(9,2)
		 , CASE
			   WHEN ot.soi_isTotalSq_Pasport = 1 AND
				   vba.build_total_area > 0 THEN vba.build_total_area
			   WHEN vba.build_total_sq > 0 THEN vba.build_total_sq
			   ELSE 0
		   END AS build_total_area                                                          -- DECIMAL(9,2)
		 --, CASE
			--   WHEN (@DB_NAME = 'KOMP') AND
			--	   (t.tip_id IN (50, 57, 60, 188)) THEN 'Мобильное приложение: <b>Bill18_jkh</b> — Ввод показаний. Доступно в GooglePlay.'
			--   ELSE ''
		 --  END 
		 , '' AS marketing_str                                                                         -- VARCHAR(1000)
		 , CASE
			   WHEN ot.watermark_dolg_mes IS NULL THEN CAST(0 AS BIT)
			   WHEN --o.tip_id IN (15) AND
				   --i.KolMesDolgAll > COALESCE(ot.watermark_dolg_mes, 0) THEN CAST(1 AS BIT)
				   i.KolMesDolg > COALESCE(ot.watermark_dolg_mes, 0) THEN CAST(1 AS BIT)
			   ELSE CAST(0 AS BIT)
		   END AS watermark                                                                 -- BIT
		 , COALESCE(ot.watermark_text, '') AS watermark_text                                           -- VARCHAR(50)
		 , (CASE
			   WHEN ot.soi_isTotalSq_Pasport = 1 AND
				   vba.build_total_area > 0 THEN 'Площадь жилых и нежилых пом.,м2: ' + LTRIM(STR(vba.build_total_area, 9, 2))
			   WHEN vba.build_total_sq > 0 THEN 'Общ.площадь жилых пом.,м2: ' + LTRIM(STR(vba.build_total_sq, 9, 2))
			   ELSE ''
		   END
		   +
			CASE
				WHEN (vba.arenda_sq > 6) THEN ',Общ.площадь нежилых пом.,м2: ' + LTRIM(STR(vba.arenda_sq, 9, 2))
				ELSE ''
			END
		   +
			CASE
				--WHEN (vba.opu_sq > 0) AND @DB_NAME LIKE '%KR1%' THEN ',Площадь МОП,м2:' + LTRIM(STR(vba.opu_sq, 9, 2))
				WHEN (vba.opu_sq > 0) THEN ',Площадь МОП для ГВ и ХВ,м2: ' + LTRIM(STR(vba.opu_sq, 9, 2))
				ELSE ''
			END
		   +
			CASE
				WHEN (vba.opu_sq_elek > 0)
				--AND @DB_NAME NOT LIKE '%KR1%' --AND vba.opu_sq_elek <> vba.opu_sq) 
				THEN ',Площадь МОП по эл.эн.,м2: ' + LTRIM(STR(vba.opu_sq_elek, 9, 2))
				ELSE ''
			END
		   +
			CASE
				WHEN (t.opu_tepl_kol > 0) THEN ',Кол-во ОПУ тепловой энергии: ' + LTRIM(STR(t.opu_tepl_kol))
				ELSE ''
			END
		   ) AS Square_str                                                                  -- VARCHAR(200)
		 , o.proptype_id                                                                               -- VARCHAR(10)
		 , COALESCE(i.Penalty_old, 0) AS Penalty_old                                                   -- DECIMAL(9,2)
		 , COALESCE(i.Penalty_period, 0)                     AS Penalty_period                         -- DECIMAL(9,2)
		 , (i.Penalty_value - COALESCE(i.Penalty_period, 0)) AS Penalty_old_new                        -- DECIMAL(9,2)
		 , t.comments_print                                                                            -- VARCHAR(50)
		 , ot.web_site                                                                                 -- VARCHAR(50)
		 , ot.rezhim_work                                                                              -- VARCHAR(100)
		 , ot.comments                                       AS comments_tip                           -- VARCHAR(100)
		 , ot.telefon_pasp                                                                             -- VARCHAR(100)
		 , CASE
               WHEN @DB_NAME = 'NAIM' THEN 'ЛС ОГВ/ОМС'
               ELSE tog.name
        END                                                  AS tip_occ                                -- VARCHAR(20)
		 , o.roomtype_id                                     AS roomtype_id                            -- VARCHAR(10)
		 , i.epd_dolg                                                                                  -- DECIMAL(15,2)
		 , i.epd_overpayment                                                                           -- DECIMAL(15,2)
		 , COALESCE(i.epd_saldo_dolg, 0)                     AS epd_saldo_dolg-- DECIMAL(15,2)
		 , COALESCE(i.epd_saldo_overpayment, 0)              AS epd_saldo_overpayment-- DECIMAL(15,2)
		 , 'Текущий'                                         AS tip_pd                                 -- VARCHAR(10) Тип платёжного документа: Текущий или Долговой 
		 , coalesce(i.qrData,'') as qrData															   -- NVARCHAR(2000)
	-- НЕ ДЕЛАТЬ ПЕРЕСТАНОВОК ПОЛЕЙ    или меняй rep_ivc_pd
	FROM #t_schet AS t
		JOIN #t_sort AS ts ON t.occ = ts.occ
		JOIN dbo.Intprint AS i ON t.occ = i.occ
		JOIN @t AS o ON t.occ = o.occ --AND i.fin_id = o.fin_id
		JOIN dbo.Occupation_Types AS ot ON t.tip_id = ot.id
		LEFT JOIN dbo.Occupation_Types_History AS ot2 ON t.tip_id = ot2.id
			AND i.fin_id = ot2.fin_id
		LEFT JOIN dbo.People AS p ON i.Initials_owner_id = p.id
		LEFT JOIN dbo.View_build_all AS vba ON t.build_id = vba.bldn_id
			AND i.fin_id = vba.fin_id
		LEFT JOIN dbo.Type_occ_gis tog ON ot.tip_occ = tog.id
		LEFT JOIN dbo.Sector AS sec ON vba.sector_id = sec.id
		OUTER APPLY (
			SELECT TOP (1) bc.comments
			FROM dbo.Buildings_comments AS bc 
			WHERE bc.build_id = t.build_id
				AND bc.fin_id = i.fin_id
				AND bc.sup_id = 0
		) AS t_build_comments
		OUTER APPLY (
			SELECT TOP (1) CONVERT(VARCHAR(10), p2.day, 104) AS date_paym_last_str  -- дата последней оплаты
			FROM dbo.Payings AS p1 
				JOIN dbo.Paydoc_packs AS p2 ON p1.pack_id = p2.id
			WHERE p1.occ = t.occ
				AND p2.fin_id <= @fin_id1
				AND (p1.sup_id = 0)
			ORDER BY p2.day DESC
		) AS t_date_paym
	WHERE i.fin_id BETWEEN @fin_id1 AND @fin_id2
	--and i.SumPaym>@sal 
	ORDER BY i.fin_id
		   , ts.sort_no
	OPTION (RECOMPILE)
go

