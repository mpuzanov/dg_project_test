-- =============================================
/*
Author:		Пузанов
Create date: 2.06.2011
Description:	Перенос данных из одной базы текущего месяца в историю другой базы по заданному дому(лицевому)

dbo.adm_transfer_basa_arxiv @build_id = 1224, @strArx = N'arx_komp',@strKomp = N'komp',@fin_id1 = 112,@occ=NULL

Запускать из текущей базы 

adm_transfer_basa_arxiv 1031,'arx_kr1','kr1',175,NULL,1

adm_transfer_basa_arxiv 8051,'arx_komp_04','arx_komp',207,370696,1

*/
-- =============================================
CREATE           PROCEDURE [dbo].[adm_transfer_basa_arxiv]
    (
    @build_id INT, -- код дома
    @strArx VARCHAR(30), -- Наименование архивной базы
    @strKomp VARCHAR(30), -- наименование текущей базы	
    @fin_id1 SMALLINT, -- код фин. периода из архивной базы (должен быть предыдущий от текущего)
    @occ INT = NULL, -- лицевой счет если нужен только он
    @debug BIT = 0,
    @is_counter BIT = 1,  -- перенос по счётчикам
    @is_peny BIT = 1,  -- перенос пени
    @is_paying BIT = 1,  -- перенос платежей
    @is_added BIT = 1,  -- перенос разовых
    @is_people BIT = 1,  -- перенос по людям
    @is_subs BIT = 1 -- перенос по субсидиям
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON

    DECLARE @SQL NVARCHAR(4000)
		  , @fin_current SMALLINT
		  , @err INT
		  , @strerror VARCHAR(4000)

    SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, @build_id, NULL, NULL)


    --IF (@fin_current - @fin_id1 <> 1)
    --	BEGIN
    --		RAISERROR ('Фин.периоды не соседние', 16, 1)
    --		RETURN
    --	END

    IF @occ = 0
		SET @occ = NULL

    IF @is_counter IS NULL
		SET @is_counter = 1
    IF @is_peny IS NULL
		SET @is_peny = 1
    IF @is_paying IS NULL
		SET @is_paying = 1
    IF @is_added IS NULL
		SET @is_added = 1
    IF @is_people IS NULL
		SET @is_people = 1
    IF @is_subs IS NULL
		SET @is_subs = 1

BEGIN TRY

    DROP TABLE IF EXISTS #t_occ;
    CREATE TABLE #t_occ
    (
        occ INT PRIMARY KEY,
        fin_id SMALLINT
    )

    INSERT INTO #t_occ
        (occ
        , fin_id)
    SELECT occ
		 , @fin_id1
    FROM dbo.Occupations AS o 
        JOIN dbo.Flats AS f 
			ON o.flat_id = f.id
        JOIN dbo.Buildings AS b 
			ON f.bldn_id = b.id
    WHERE b.id = @build_id
        AND (o.occ = @occ OR @occ IS NULL)
        AND o.status_id <> 'закр'

    IF NOT EXISTS (SELECT 1 FROM #t_occ)
	BEGIN
        RAISERROR ('Лицевых для переноса нет!', 16, 1);
        RETURN;
    END

    DROP TABLE IF EXISTS #t_counter;
    CREATE TABLE #t_counter
    (
        counter_id INT,
        occ INT
    )

    INSERT INTO #t_counter
        (counter_id
        , occ)
    SELECT cl.counter_id
		 , cl.occ
    FROM dbo.Counter_list_all AS cl 
        JOIN #t_occ AS o 
			ON cl.occ = o.occ
            AND cl.fin_id = @fin_id1

    DROP TABLE IF EXISTS #t_occ_sup;
    CREATE TABLE #t_occ_sup
    (
        occ INT PRIMARY KEY
		,
        fin_id SMALLINT
    )
    INSERT INTO #t_occ_sup
    SELECT os.occ_sup
		 , os.fin_id
    FROM dbo.Occ_Suppliers os 
        JOIN #t_occ AS o 
			ON os.occ = o.occ
            AND os.fin_id = @fin_id1

    DROP TABLE IF EXISTS #t_occ_peny;
    CREATE TABLE #t_occ_peny
    (
        occ INT PRIMARY KEY
		,
        fin_id SMALLINT
    )
    INSERT INTO #t_occ_peny
            SELECT *
        FROM #t_occ [to]
    UNION ALL
        SELECT *
        FROM #t_occ_sup [tos]


    IF @debug = 1
	BEGIN
        SELECT *
        FROM #t_occ
        SELECT *
        FROM #t_counter
        SELECT *
        FROM #t_occ_sup
        SELECT *
        FROM #t_occ_peny
    END

    --BEGIN TRAN

    --BEGIN TRY

    IF @is_added = 1
	BEGIN
        -- *************************************************************
        -- Сохраняем разовые 
        --
        RAISERROR ('Сохраняем разовые', 10, 1) WITH NOWAIT;
        SET @SQL =
		'DELETE aph FROM ' + @strKomp + '.dbo.added_payments_history as aph JOIN #t_occ as t ON aph.occ=t.occ WHERE aph.fin_id=t.fin_id'
        --EXECUTE sp_executesql	@SQL
        --,N'@fin_id1 smallint'
        --,@fin_id1 = @fin_id1

        SET @SQL = @SQL +
		'
		INSERT INTO ' + @strKomp + '.dbo.added_payments_history
		(occ,fin_id,service_id,sup_id,add_type,VALUE,doc,data1,data2,Hours,add_type2,manual_bit,
		 Vin1,Vin2,doc_no,doc_date,user_edit,dsc_owner_id,fin_id_paym,comments,tnorm2,kol,repeat_for_fin,date_edit)
		SELECT ap.occ,
			@fin_id1 as fin_id,
			service_id,
			sup_id,
			add_type,
			VALUE,
			doc,
			data1,
			data2,
			Hours,
			add_type2,
			manual_bit,
			Vin1,
			Vin2,
			doc_no,
			doc_date,
			user_edit,
			dsc_owner_id,
			fin_id_paym,
			comments,
			tnorm2,
			kol,
			repeat_for_fin,
			date_edit
		FROM ' + @strArx + '.dbo.View_ADDED as ap
		JOIN #t_occ as t ON ap.occ=t.occ AND ap.fin_id=@fin_id1'
        EXECUTE sp_executesql @SQL
							, N'@fin_id1 smallint'
							, @fin_id1 = @fin_id1

        --set @SQL=
        --'select * FROM '+@strKomp+'.dbo.added_payments_history as aph JOIN #t_occ as t ON aph.occ=t.occ WHERE aph.fin_id=@fin_id1'
        --EXECUTE sp_executesql @SQL, N'@fin_id1 smallint',@fin_id1 = @fin_id1

        -- *************************************************************
        -- Сохраняем разовые по счетчикам
        --
        RAISERROR ('Сохраняем разовые по счетчикам', 10, 1) WITH NOWAIT;
        SET @SQL =
		'DELETE aph FROM ' + @strKomp + '.dbo.ADDED_COUNTERS_ALL as aph JOIN #t_occ as t ON aph.occ=t.occ WHERE aph.fin_id=t.fin_id'
        --EXECUTE sp_executesql	@SQL
        --,N'@fin_id1 smallint'
        --,@fin_id1 = @fin_id1


        SET @SQL = @SQL +
		'
		INSERT INTO ' + @strKomp + '.dbo.ADDED_COUNTERS_ALL
		(fin_id, occ,service_id ,add_type,VALUE,doc,data1,data2,Vin1,Vin2,doc_no,doc_date,user_edit,dsc_owner_id)
		SELECT 
			@fin_id1 as fin_id,
			ap.occ,
			service_id ,
			add_type,
			VALUE,
			doc,
			data1,
			data2,
			Vin1,
			Vin2,
			doc_no,
			doc_date,
			user_edit,
			dsc_owner_id
		FROM ' + @strArx + '.dbo.added_COUNTERS_all as ap
			JOIN #t_occ as t ON ap.occ=t.occ
		WHERE VALUE<>0 AND ap.fin_id=@fin_id1'
        EXECUTE sp_executesql @SQL
							, N'@fin_id1 smallint'
							, @fin_id1 = @fin_id1

    END


    --********************************************************* 
    -- 3. Сохраняем историю начислений
    --
    RAISERROR ('Сохраняем историю начислений по норме', 10, 1) WITH NOWAIT;
    SET @SQL =
	'DELETE ph FROM ' + @strKomp + '.dbo.Paym_history as ph JOIN #t_occ as t ON ph.occ=t.occ WHERE ph.fin_id=t.fin_id'
    --EXECUTE sp_executesql	@SQL
    --,N'@fin_id1 smallint'
    --,@fin_id1 = @fin_id1

    SET @SQL = @SQL +
	'
	INSERT INTO ' + @strKomp + '.dbo.Paym_history
	(fin_id, occ, service_id, sup_id, subsid_only, tarif ,saldo , VALUE ,
	discount ,added ,compens ,paid,paymaccount, paymaccount_peny,account_one, kol, unit_id, metod, is_counter,kol_norma,
	metod_old,build_id,penalty_serv,penalty_old,kol_norma_single,source_id,mode_id,occ_sup_paym,date_start,date_end,kol_added,koef_day,penalty_prev)
	SELECT 
		@fin_id1 as fin_id,
		p.occ,
		service_id,
		coalesce(sup_id,0),
		subsid_only,
		tarif ,
		p.saldo ,
		p.value ,
		0, -- discount
		p.added ,
		0, -- compens
		p.paid,
		p.paymaccount,
		p.paymaccount_peny,
		account_one,
		kol,
		unit_id,
		metod,
		is_counter,
		kol_norma,
		metod_old,
		build_id,
		penalty_serv,
		penalty_old,
		kol_norma_single,
		source_id,
		mode_id,
		occ_sup_paym,
		date_start,
		date_end,
		kol_added,
		koef_day,
		penalty_prev
	FROM ' + @strArx + '.dbo.View_PAYM AS p
	JOIN #t_occ AS t ON p.occ=t.occ and p.fin_id=t.fin_id
	WHERE (p.value<>0 OR p.added<>0 OR p.paid<>0 OR p.paymaccount<>0 OR p.saldo<>0 OR p.tarif<>0 OR penalty_old<>0 OR penalty_serv<>0 OR p.kol <> 0
	OR ((source_id % 1000 <> 0) and (mode_id % 1000 <> 0)) )'
    EXECUTE sp_executesql @SQL
						, N'@fin_id1 smallint'
						, @fin_id1 = @fin_id1
    IF @debug = 1 PRINT @SQL
    --*********************************************************
    --
    RAISERROR ('Сохраняем историю начислений по счетчикам', 10, 1) WITH NOWAIT;
    SET @SQL =
	'DELETE ph FROM ' + @strKomp + '.dbo.PAYM_COUNTER_ALL as ph JOIN #t_occ as t ON ph.occ=t.occ WHERE ph.fin_id=t.fin_id'
    --EXECUTE sp_executesql	@SQL

    SET @SQL = @SQL +
	'
	INSERT INTO ' + @strKomp + '.dbo.PAYM_COUNTER_ALL
	(occ,fin_id,service_id ,subsid_only,tarif ,saldo ,VALUE ,
	discount ,added ,compens ,paid,paymaccount,paymaccount_peny,kol,avg_vday)
	SELECT 
		p.occ,
		@fin_id1 as fin_id,
		service_id ,
		subsid_only,
		tarif ,
		saldo ,
		VALUE ,
		discount ,
		added ,
		compens ,
		paid,
		paymaccount,
		paymaccount_peny,
		kol,
		avg_vday
	FROM ' + @strArx + '.dbo.PAYM_COUNTER_ALL AS p
	JOIN #t_occ AS t ON p.occ=t.occ
	WHERE p.fin_id=@fin_id1 and (VALUE<>0 OR discount<>0 OR added<>0
		  OR compens<>0 OR paid<>0 OR paymaccount<>0 OR saldo<>0)'
    EXECUTE sp_executesql @SQL
						, N'@fin_id1 smallint'
						, @fin_id1 = @fin_id1

	IF @debug = 1 PRINT @SQL
    --********************************************************
    -- 4. Сохраняем историю лиц.счета по единой квитанции
    --
    RAISERROR ('Сохраняем историю лиц.счета по единой квитанции', 10, 1) WITH NOWAIT;
    SET @SQL =
	'DELETE oh FROM ' + @strKomp + '.dbo.occ_history as oh JOIN #t_occ as t ON oh.occ=t.occ WHERE oh.fin_id=t.fin_id'
    --EXECUTE sp_executesql	@SQL
    --,N'@fin_id1 smallint'
    --,@fin_id1 = @fin_id1

    SET @SQL = @SQL +
	'
	INSERT INTO ' + @strKomp + '.dbo.occ_history
	(fin_id,occ,JEU,TIP_ID,FLAT_ID,ROOMTYPE_ID,PROPTYPE_ID,STATUS_ID,LIVING_SQ ,TOTAL_SQ ,TEPLO_SQ ,NORMA_SQ ,
	SOCNAIM ,SALDO  ,SALDO_SERV,saldo_edit, VALUE,Discount,Compens, Added,PaymAccount,
	PaymAccount_peny,Paid,Paid_minus,Paid_old,Penalty_Calc,Penalty_added, Penalty_value,Penalty_Old_new,Penalty_Old,Penalty_old_edit,
	COMMENTS,COMMENTS2,kol_people,SaldoAll,Paymaccount_ServAll,PaidAll,AddedAll,id_jku_gis,KolMesDolg,comments_print,
	kol_people_reg,kol_people_all,id_els_gis,kol_people_owner,Data_rascheta,date_start,date_end)
	SELECT 
		@fin_id1 as fin_id,
		o.occ,
		JEU,
		TIP_ID,
		FLAT_ID,
		ROOMTYPE_ID,
		PROPTYPE_ID,
		STATUS_ID,
		LIVING_SQ ,
		TOTAL_SQ ,
		TEPLO_SQ ,
		NORMA_SQ ,
		SOCNAIM ,
		SALDO  ,
		SALDO_SERV,
		saldo_edit,
		VALUE,
		Discount,
		Compens,
		Added,
		PaymAccount,
		PaymAccount_peny,
		Paid,
		Paid_minus,
		Paid_old,
		Penalty_Calc,
		Penalty_added,
		Penalty_value,
		Penalty_Old_new,
		Penalty_Old,
		Penalty_Old_edit,
		COMMENTS,
		COMMENTS2,
		kol_people,
		SaldoAll,
		Paymaccount_ServAll,
		PaidAll,
		AddedAll,
		id_jku_gis,
		KolMesDolg,
		comments_print,
		kol_people_reg,
		kol_people_all,
		id_els_gis,
		kol_people_owner,
		Data_rascheta, 
		date_start, 
		date_end
	FROM ' + @strArx + '.dbo.View_OCC_ALL AS o
	JOIN #t_occ AS t ON o.occ=t.occ and o.fin_id=t.fin_id'
    EXECUTE sp_executesql @SQL
						, N'@fin_id1 smallint'
						, @fin_id1 = @fin_id1
	IF @debug = 1 PRINT @SQL
    --**************************************************************************
    --
    RAISERROR ('Сохраняем режимы потребления', 10, 1) WITH NOWAIT;
    SET @SQL =
	'DELETE ch FROM ' + @strKomp + '.dbo.consmodes_history as ch JOIN #t_occ as t ON ch.occ=t.occ WHERE ch.fin_id=t.fin_id'
    --EXECUTE sp_executesql	@SQL
    --,N'@fin_id1 smallint'
    --,@fin_id1 = @fin_id1

    SET @SQL = @SQL +
	'
	INSERT INTO ' + @strKomp + '.dbo.consmodes_history
	(fin_id,occ,service_id,source_id,mode_id,koef,subsid_only,is_counter, account_one,sup_id,occ_serv_kol,date_end, date_start)
	SELECT 
		@fin_id1 as fin_id,
		cl.occ,
		cl.service_id ,
		cl.source_id,
		cl.mode_id,
		coalesce(cl.koef,1) AS koef,
		coalesce(cl.subsid_only,0) AS subsid_only,
		cl.is_counter,
		cl.account_one,
		coalesce(cl.sup_id,0),
		cl.occ_serv_kol,
		cl.date_end,
		cl.date_start
	FROM ' + @strArx + '.dbo.consmodes_list AS cl
		 JOIN ' + @strArx + '.dbo.paym_list AS pl ON cl.occ=pl.occ AND cl.service_id=pl.service_id
		 AND cl.sup_id=pl.sup_id
		 JOIN #t_occ AS t ON cl.occ=t.occ
	WHERE 
	(VALUE<>0 OR added<>0
	 OR paid<>0 OR paymaccount<>0 OR saldo<>0 
	 OR cl.is_counter>0 OR pl.kol <> 0)'
    EXECUTE sp_executesql @SQL
						, N'@fin_id1 smallint'
						, @fin_id1 = @fin_id1
	IF @debug = 1 PRINT @SQL

    IF @is_peny = 1
	BEGIN
        --*********************************************************  
        --
        RAISERROR ('Сохраняем историю пени PENY_DETAIL', 10, 1) WITH NOWAIT;
        SET @SQL =
		'DELETE ph FROM ' + @strKomp + '.dbo.PENY_DETAIL as ph JOIN #t_occ_peny as t ON ph.occ=t.occ WHERE ph.fin_id=t.fin_id'
        --EXECUTE sp_executesql	@SQL
        --,N'@fin_id1 smallint'
        --,@fin_id1 = @fin_id1


        SET @SQL = @SQL +
		'
		INSERT INTO ' + @strKomp + '.dbo.PENY_DETAIL
		(fin_id, occ, paying_id, dat1, data1, kol_day_dolg, kol_day, paying_id2, dolg_peny, paid_pred, 
		paymaccount_serv, paymaccount_peny, Peny_old, Peny_old_new, Peny,  dolg, proc_peny_day, fin_dolg, StavkaCB)
		SELECT 	
			@fin_id1 as fin_id,
			ps.occ, paying_id, dat1, data1, kol_day_dolg, kol_day, paying_id2, dolg_peny, paid_pred, 
			paymaccount_serv, paymaccount_peny, Peny_old, Peny_old_new, Peny,  dolg, proc_peny_day, fin_dolg, StavkaCB 
		FROM ' + @strArx + '.dbo.PENY_DETAIL as ps
			JOIN #t_occ_peny AS t ON ps.occ=t.occ
		WHERE ps.fin_id=@fin_id1 and (dolg_peny<>0 OR peny_old<>0 OR paymaccount_peny<>0 or Peny<>0)'
        EXECUTE sp_executesql @SQL
							, N'@fin_id1 smallint'
							, @fin_id1 = @fin_id1
		IF @debug = 1 PRINT @SQL

        --*********************************************************  
        --
        RAISERROR ('Сохраняем историю пени', 10, 1) WITH NOWAIT;
        SET @SQL =
		'DELETE ph FROM ' + @strKomp + '.dbo.PENY_ALL as ph JOIN #t_occ_peny as t ON ph.occ=t.occ AND ph.fin_id=t.fin_id'
        --EXECUTE sp_executesql	@SQL
        --,N'@fin_id1 smallint'
        --,@fin_id1 = @fin_id1

        SET @SQL = @SQL +
		'
		INSERT INTO ' + @strKomp + '.dbo.PENY_ALL
		(fin_id, occ, dolg, dolg_peny, paid_pred, peny_old, 
		paymaccount, paymaccount_peny, peny_old_new, penalty_added, kolday, penalty_value, metod, data_rascheta, occ1, sup_id,penalty_calc)
		SELECT 
			@fin_id1 as fin_id,
			ps.occ, dolg, dolg_peny, paid_pred, peny_old, 
			paymaccount, paymaccount_peny, peny_old_new, penalty_added, kolday, penalty_value, metod, data_rascheta, occ1, sup_id, penalty_calc
		FROM ' + @strArx + '.dbo.PENY_ALL as ps
			JOIN #t_occ_peny AS t ON ps.occ=t.occ AND ps.fin_id=t.fin_id '
        EXECUTE sp_executesql @SQL
							, N'@fin_id1 smallint'
							, @fin_id1 = @fin_id1
		IF @debug = 1 PRINT @SQL
    END

    --********************************************************
    -- Переносим информацию по квитанции
    --
    RAISERROR ('Переносим информацию по квитанции', 10, 1) WITH NOWAIT;
    --DELETE i FROM dbo.INTPRINT as i JOIN #t_occ as t ON i.occ=t.occ WHERE i.fin_id=@fin_id1
    SET @SQL =
	'DELETE i FROM ' + @strKomp + '.dbo.INTPRINT as i JOIN #t_occ as t ON i.occ=t.occ WHERE i.fin_id=t.fin_id'
    --EXECUTE sp_executesql	@SQL
    --,N'@fin_id1 smallint'
    --,@fin_id1 = @fin_id1

    SET @SQL = @SQL +
	'
	INSERT INTO ' + @strKomp + '.[dbo].[INTPRINT]
	([fin_id],[occ],[SumPaym],[Initials],[Lgota],[total_people],[Total_sq],[Living_sq]
	,[FinPeriod],[saldo],[PaymAccount],[PaymAccount_peny],[Debt],[LastDayPaym],[LastDayPaym2],[PersonStatus]
	,[Penalty_value],[StrSubsidia1],[StrSubsidia2],[StrSubsidia3],[KolMesDolg],[DateCreate],KolMesDolgAll
	,Initials_owner_id,Penalty_period,Penalty_old,PaymAccount_storno,rasschet)
	SELECT @fin_id1 as fin_id
		  ,i.[occ]
		  ,[SumPaym]
		  ,[Initials]
		  ,[Lgota]
		  ,[total_people]
		  ,[Total_sq]
		  ,[Living_sq]
		  ,[FinPeriod]
		  ,[saldo]
		  ,[PaymAccount]
		  ,[PaymAccount_peny]
		  ,[Debt]
		  ,[LastDayPaym]
		  ,[LastDayPaym2]
		  ,[PersonStatus]
		  ,[Penalty_value]
		  ,[StrSubsidia1]
		  ,[StrSubsidia2]
		  ,[StrSubsidia3]
		  ,[KolMesDolg]
		  ,[DateCreate]
		  ,i.KolMesDolgAll
		  ,i.Initials_owner_id
		  ,i.Penalty_period
		  ,i.Penalty_old
		  ,i.PaymAccount_storno
		  ,i.rasschet
	  FROM ' + @strArx + '.[dbo].[INTPRINT] as i 
		JOIN #t_occ as t ON i.occ=t.occ
	  where i.fin_id=@fin_id1'
    EXECUTE sp_executesql @SQL
						, N'@fin_id1 smallint'
						, @fin_id1 = @fin_id1
	IF @debug = 1 PRINT @SQL

    IF @is_subs = 1
	BEGIN
        --**************************************************************************
        --
        RAISERROR ('Сохраняем SUBSIDIA12', 10, 1) WITH NOWAIT;
        SET @SQL =
		'DELETE ch FROM ' + @strKomp + '.dbo.SUBSIDIA12 as ch JOIN #t_occ as t ON ch.occ=t.occ WHERE ch.fin_id=t.fin_id'
        --EXECUTE sp_executesql	@SQL
        --,N'@fin_id1 smallint'
        --,@fin_id1 = @fin_id1

        SET @SQL = @SQL +
		'
		INSERT INTO ' + @strKomp + '.dbo.SUBSIDIA12
		(fin_id, occ, service_id, value_max, value, paid, sub12, kol_people, tarif12, tarif, norma12, norma, value12, procent, fin_12, kol, kol_odn)
		SELECT 
			@fin_id1 as fin_id,
			cl.occ, service_id, value_max, value, paid, sub12, kol_people, tarif12, tarif, norma12, norma, value12, procent, fin_12, kol, kol_odn
		FROM ' + @strArx + '.dbo.SUBSIDIA12 AS cl
			 JOIN #t_occ AS t ON cl.occ=t.occ
		WHERE 
			cl.fin_id=@fin_id1'
        EXECUTE sp_executesql @SQL
							, N'@fin_id1 smallint'
							, @fin_id1 = @fin_id1
		IF @debug = 1 PRINT @SQL
    END

    IF @is_people = 1
	BEGIN
        --*********************************************************
        --
        RAISERROR ('Сохраняем историю по людям', 10, 1) WITH NOWAIT;
        DECLARE @occ1 INT

        DROP TABLE IF EXISTS #p1;

		create table #p1(fin_id smallint
			, occ int
			, owner_id  int
			, people_uid  UNIQUEIDENTIFIER
			, lgota_id smallint
			, status_id tinyint
			, status2_id VARCHAR(10) COLLATE database_default
			, birthdate  smalldatetime
			, doxod decimal(9,2)
			, KolDayLgota  tinyint
			, data1 smalldatetime
			, data2 smalldatetime
			, kolday tinyint
			, DateEnd SMALLDATETIME
		)

        SET @SQL = 'INSERT INTO #p1 EXEC ' + @strArx + '.dbo.k_PeopleFin @occ1,@fin_id1'
        DECLARE curs CURSOR LOCAL FOR
			SELECT occ
        FROM #t_occ
        ORDER BY occ
        OPEN curs
        FETCH NEXT FROM curs INTO @occ1

        WHILE (@@fetch_status = 0)
		BEGIN
            --INSERT INTO #p1 EXEC arx_komp.k_PeopleFin @occ1,@fin_id1
            EXECUTE sp_executesql @SQL
								, N'@occ1 int, @fin_id1 smallint'
								, @occ1 = @occ1
								, @fin_id1 = @fin_id1
            FETCH NEXT FROM curs INTO @occ1
        END

        CLOSE curs
        DEALLOCATE curs

        --********************************************************* 
        RAISERROR ('Соединяем таблицы people', 10, 1) WITH NOWAIT;
        SET @SQL =
		'DELETE i FROM ' + @strKomp + '.dbo.people_history as i JOIN #t_occ as t ON i.occ=t.occ WHERE i.fin_id=@fin_id1'
        EXECUTE sp_executesql @SQL
							, N'@fin_id1 smallint'
							, @fin_id1 = @fin_id1

        SET @SQL =
		'INSERT INTO ' + @strKomp + '.dbo.people_history
		(occ,fin_id,owner_id, lgota_id, status_id, status2_id, kol_day, KolDayLgota,data1,data2,lgota_kod,DateEnd)
		SELECT 
			 p.occ,
			 p.fin_id,
			 p.owner_id, 
			 p.lgota_id, 
			 p.status_id, 
			 p.status2_id, 
			 p.kolday as kol_day,
			 p.KolDayLgota, 
			 p.data1,
			 p.data2,
			 p1.lgota_kod,
			 p.DateEnd
		FROM #p1 AS p
			JOIN ' + @strArx + '.dbo.people AS p1 ON p.owner_id=p1.id'
        EXECUTE sp_executesql @SQL
							, N'@fin_id1 smallint'
							, @fin_id1 = @fin_id1
    END

    IF @is_paying = 1
	BEGIN
        --********************************************************
        -- Обновление по платежам
        -- dbo.PAYINGS
        RAISERROR ('Обновление по платежам PAYINGS', 10, 1) WITH NOWAIT;
        SET @SQL =
		'UPDATE p
		set
			value=arx_p.value
			,paymaccount_peny=arx_p.paymaccount_peny
			,commission=arx_p.commission
			,paying_vozvrat=arx_p.paying_vozvrat
			,peny_save=arx_p.peny_save
			,paying_manual=arx_p.paying_manual
			,comment=arx_p.comment
		from ' + @strKomp + '.dbo.PAYINGS as p
		  JOIN #t_occ as t ON p.occ=t.occ
		  JOIN ' + @strKomp + '.dbo.PAYDOC_PACKS as pd ON p.pack_id=pd.id
		  JOIN ' + @strArx + '.dbo.PAYINGS as arx_p ON p.id=arx_p.id 
		where pd.fin_id=@fin_id1
		and (p.paymaccount_peny<>arx_p.paymaccount_peny OR p.value<>arx_p.value OR p.commission<>arx_p.commission)'
        EXECUTE sp_executesql @SQL
							, N'@fin_id1 smallint'
							, @fin_id1 = @fin_id1
		IF @debug = 1 PRINT @SQL
        --********************************************************
        -- Обновление по платежам по услугам
        -- dbo.PAYING_SERV
        RAISERROR ('Обновление по платежам PAYING_SERV', 10, 1) WITH NOWAIT;
        SET @SQL =
		--'UPDATE ps
		--set
		--	value=arx_ps.value
		--	,paymaccount_peny=arx_ps.paymaccount_peny
		--	,commission=arx_ps.commission
		--from ' + @strKomp + '.dbo.PAYING_SERV as ps
		--  JOIN ' + @strKomp + '.dbo.PAYINGS as p ON ps.paying_id=p.id
		--  JOIN #t_occ as t ON p.occ=t.occ
		--  JOIN ' + @strKomp + '.dbo.PAYDOC_PACKS as pd ON p.pack_id=pd.id
		--  JOIN ' + @strArx + '.dbo.PAYING_SERV as arx_ps ON ps.occ=arx_ps.occ
		--  AND ps.service_id=arx_ps.service_id AND ps.paying_id=arx_ps.paying_id AND ps.sup_id=arx_ps.sup_id  
		--where pd.fin_id=@fin_id1
		--and (ps.paymaccount_peny<>arx_ps.paymaccount_peny OR ps.value<>arx_ps.value OR ps.commission<>arx_ps.commission)'

		';WITH T AS
		(SELECT ps.* FROM ' + @strKomp + '.dbo.PAYING_SERV as ps
			JOIN ' + @strKomp + '.dbo.PAYINGS as p ON ps.paying_id=p.id
			JOIN ' + @strKomp + '.dbo.PAYDOC_PACKS as pd ON p.pack_id=pd.id
			JOIN #t_occ as t ON p.occ=t.occ
			WHERE pd.fin_id=@fin_id1)
		MERGE T AS tgt
		USING (SELECT ps.* FROM ' + @strArx + '.dbo.PAYING_SERV as ps
			JOIN ' + @strArx + '.dbo.PAYINGS as p ON ps.paying_id=p.id
			JOIN ' + @strArx + '.dbo.PAYDOC_PACKS as pd ON p.pack_id=pd.id
			JOIN #t_occ as t ON p.occ=t.occ
			WHERE pd.fin_id=@fin_id1
		) AS src
		ON (tgt.paying_id=src.paying_id AND tgt.service_id=src.service_id AND tgt.sup_id=src.sup_id)
		WHEN NOT MATCHED BY SOURCE 
			THEN DELETE
		WHEN MATCHED and (tgt.paymaccount_peny<>src.paymaccount_peny OR tgt.value<>src.value OR tgt.commission<>src.commission)
		THEN UPDATE SET value=src.value
			,paymaccount_peny=src.paymaccount_peny
			,commission=src.commission
		WHEN NOT MATCHED 
			THEN INSERT (occ,service_id,paying_id,sup_id,value,paymaccount_peny,commission) 
			VALUES (src.occ,src.service_id,src.paying_id,src.sup_id,src.value,src.paymaccount_peny,src.commission)
		OUTPUT deleted.*, $action, inserted.*
		;'

        EXECUTE sp_executesql @SQL
							, N'@fin_id1 smallint'
							, @fin_id1 = @fin_id1
		IF @debug = 1 PRINT @SQL
    END

    IF @is_counter = 1
	BEGIN
        --********************************************************
        -- Обновление по счетчикам
        -- dbo.COUNTER_INSPECTOR
        RAISERROR ('Удаление показаний в COUNTER_INSPECTOR которых уже нет в архиве', 10, 1) WITH NOWAIT;
        SET @SQL =
		'DELETE ci
		from ' + @strKomp + '.dbo.COUNTER_INSPECTOR as ci
		  JOIN ' + @strKomp + '.dbo.COUNTER_LIST_ALL as cl ON ci.counter_id=cl.counter_id and ci.fin_id=cl.fin_id
		  JOIN #t_counter as tc ON ci.counter_id=tc.counter_id and tc.occ=cl.occ
		  LEFT JOIN ' + @strArx + '.dbo.COUNTER_INSPECTOR as arx_ci ON arx_ci.counter_id=ci.counter_id 
		  and arx_ci.inspector_date=ci.inspector_date and arx_ci.fin_id=ci.fin_id
		where arx_ci.counter_id IS NULL and ci.fin_id<=@fin_id1'
        EXECUTE sp_executesql @SQL
							, N'@fin_id1 smallint'
							, @fin_id1 = @fin_id1
		IF @debug = 1 PRINT @SQL
        --********************************************************
        -- Обновление по счетчикам
        -- dbo.COUNTER_INSPECTOR
        RAISERROR ('Обновление по счетчикам COUNTER_INSPECTOR', 10, 1) WITH NOWAIT;
        SET @SQL =
		'UPDATE ci
		set
		inspector_value=arx_ci.inspector_value,
		inspector_date=arx_ci.inspector_date, 
		blocked=arx_ci.blocked,
		user_edit=arx_ci.user_edit,
		date_edit=arx_ci.date_edit,
		kol_day=arx_ci.kol_day,
		actual_value=arx_ci.actual_value,
		value_vday=arx_ci.value_vday,
		comments=arx_ci.comments,
		fin_id=arx_ci.fin_id,
		mode_id=coalesce(arx_ci.mode_id,0),
		tarif=arx_ci.tarif,
		value_paym=arx_ci.value_paym,
		metod_rasch=arx_ci.metod_rasch,
		blocked_value_negativ=arx_ci.blocked_value_negativ,
		volume_odn=arx_ci.volume_odn,
		norma_odn=arx_ci.norma_odn,
		volume_direct_contract=arx_ci.volume_direct_contract
		from ' + @strKomp + '.dbo.COUNTER_INSPECTOR as ci
		  JOIN ' + @strKomp + '.dbo.COUNTER_LIST_ALL as cl ON ci.counter_id=cl.counter_id and ci.fin_id=cl.fin_id
		  JOIN #t_counter as tc ON ci.counter_id=tc.counter_id and tc.occ=cl.occ
		  JOIN ' + @strArx + '.dbo.COUNTER_INSPECTOR as arx_ci ON ci.counter_id=arx_ci.counter_id 
		  and ci.inspector_date=arx_ci.inspector_date and ci.fin_id=arx_ci.fin_id
		where ci.inspector_value<>arx_ci.inspector_value'
        EXECUTE sp_executesql @SQL
        --,N'@fin_id1 smallint'
        --,@fin_id1 = @fin_id1
		IF @debug = 1 PRINT @SQL

        --********************************************************
        -- загрузка новых показаний по счетчикам
        -- dbo.COUNTER_INSPECTOR
        RAISERROR ('загрузка новых показаний по счетчикам COUNTER_INSPECTOR', 10, 1) WITH NOWAIT;
        SET @SQL =
		'
		INSERT INTO ' + @strKomp + '.[dbo].[COUNTER_INSPECTOR]
		([counter_id],[tip_value],[inspector_value],[inspector_date],[blocked],[user_edit]
		,[date_edit],[kol_day],[actual_value],[value_vday],[comments],[fin_id],[mode_id],[tarif]
		,[value_paym],[volume_arenda],[is_info],[metod_input],[metod_rasch]
		,blocked_value_negativ,volume_odn,norma_odn,volume_direct_contract)
		SELECT 
		ARX_CI.[counter_id],ARX_CI.[tip_value],ARX_CI.[inspector_value],ARX_CI.[inspector_date],ARX_CI.[blocked],ARX_CI.[user_edit]
		,ARX_CI.[date_edit],ARX_CI.[kol_day],ARX_CI.[actual_value],ARX_CI.[value_vday],ARX_CI.[comments],ARX_CI.[fin_id],
		ARX_CI.[mode_id],ARX_CI.[tarif],ARX_CI.[value_paym],ARX_CI.[volume_arenda],ARX_CI.[is_info],ARX_CI.[metod_input],ARX_CI.[metod_rasch],
		ARX_CI.blocked_value_negativ, ARX_CI.volume_odn, ARX_CI.norma_odn, ARX_CI.volume_direct_contract
		FROM ' + @strArx + '.dbo.[COUNTER_INSPECTOR] ARX_CI
		  JOIN ' + @strArx + '.dbo.COUNTER_LIST_ALL as cl ON ARX_CI.counter_id=cl.counter_id and ARX_CI.fin_id=cl.fin_id
		  JOIN #t_counter tc ON ARX_CI.counter_id=tc.counter_id and tc.occ=cl.occ
		  LEFT JOIN ' + @strKomp + '.[dbo].[COUNTER_INSPECTOR] CI ON ARX_CI.counter_id=CI.counter_id 
		  and ARX_CI.inspector_date=CI.inspector_date and ci.fin_id=arx_ci.fin_id
		WHERE CI.inspector_date IS NULL'
        EXECUTE sp_executesql @SQL
		IF @debug = 1 PRINT @SQL

        --********************************************************
        -- dbo.COUNTER_PAYM2
        RAISERROR ('Обновление по счетчикам COUNTER_PAYM2', 10, 1) WITH NOWAIT;
        SET @SQL =
		'DELETE cp2 FROM ' + @strKomp + '.dbo.COUNTER_PAYM2 as cp2 JOIN #t_occ as t ON cp2.occ=t.occ WHERE cp2.fin_id=@fin_id1'
        EXECUTE sp_executesql @SQL
							, N'@fin_id1 smallint'
							, @fin_id1 = @fin_id1

        SET @SQL =
		'insert into ' + @strKomp + '.dbo.COUNTER_PAYM2
		(occ, fin_id, service_id, tip_value, tarif, saldo, value, discount, added, paymaccount, paid, kol, fin_paym, metod_rasch)
		select 
		cp2.occ, cp2.fin_id, service_id, tip_value, tarif, saldo, value, discount, added, paymaccount, paid, kol, fin_paym, metod_rasch
		FROM ' + @strArx + '.dbo.COUNTER_PAYM2 as cp2
			JOIN #t_occ as t ON cp2.occ=t.occ
		where cp2.fin_id=@fin_id1'
        EXECUTE sp_executesql @SQL
							, N'@fin_id1 smallint'
							, @fin_id1 = @fin_id1
		IF @debug = 1 PRINT @SQL
    END

    --********************************************************
    -- Определяем новое начальное сальдо на следующий месяц
    --		
    RAISERROR ('Определяем новое начальное сальдо на следующий месяц', 10, 1) WITH NOWAIT;
    SET @SQL =
	'UPDATE ' + @strKomp + '.dbo.occupations
	SET saldo=oh.Debt,
		Penalty_old=((oh.penalty_old_new+oh.penalty_added)+oh.penalty_value),
		Paid_old=oh.paid
	FROM dbo.occupations AS o
		JOIN dbo.occ_history as oh ON o.Occ=oh.occ and oh.fin_id=@fin_id1
		JOIN #t_occ AS t ON o.occ=t.occ
	WHERE o.status_id<>''закр'' '
    EXECUTE sp_executesql @SQL
						, N'@fin_id1 smallint'
						, @fin_id1 = @fin_id1

	IF @debug = 1 PRINT @SQL

    --********************************************************
    -- 4. Сохраняем историю лиц.счета по поставщикам
    --
    RAISERROR ('Сохраняем историю лиц.счета по поставщикам', 10, 1) WITH NOWAIT;
    SET @SQL =
	'DELETE oh FROM ' + @strKomp + '.dbo.OCC_SUPPLIERS as oh JOIN #t_occ as t ON oh.occ=t.occ WHERE oh.fin_id=t.fin_id'
    --EXECUTE sp_executesql	@SQL
    --,N'@fin_id1 smallint'
    --,@fin_id1 = @fin_id1

    SET @SQL = @SQL +
	'
	INSERT INTO ' + @strKomp + '.dbo.OCC_SUPPLIERS
	(fin_id, occ, sup_id, saldo, value, added, paid, paymaccount, PaymAccount_peny, Penalty_added, Penalty_value, 
	Penalty_old_new, Penalty_old, occ_sup, KolMesDolg, Penalty_old_edit, Paid_old, dog_int, id_jku_gis, rasschet, occ_sup_uid,schtl_old,PaymAccount_storno)
	SELECT 
		t.fin_id,
		o.occ, sup_id, saldo, value, added, paid, paymaccount, PaymAccount_peny, Penalty_added, Penalty_value, 
		Penalty_old_new, Penalty_old, occ_sup, KolMesDolg, Penalty_old_edit, Paid_old, dog_int, id_jku_gis, rasschet, occ_sup_uid, schtl_old,PaymAccount_storno
	FROM ' + @strArx + '.dbo.OCC_SUPPLIERS AS o
	JOIN #t_occ AS t ON o.occ=t.occ and o.fin_id=t.fin_id'
    EXECUTE sp_executesql @SQL
    --,N'@fin_id1 smallint'
    --,@fin_id1 = @fin_id1
	IF @debug = 1 PRINT @SQL

    --********************************************************
    -- 5. Сохраняем историю общедомовым услугам
    --
    RAISERROR ('Сохраняем историю общедомовх услуг по лицевым', 10, 1) WITH NOWAIT;
    SET @SQL =
	'DELETE oh FROM ' + @strKomp + '.dbo.PAYM_OCC_BUILD as oh JOIN #t_occ as t ON oh.occ=t.occ WHERE oh.fin_id=t.fin_id'
    --EXECUTE sp_executesql	@SQL
    --,N'@fin_id1 smallint'
    --,@fin_id1 = @fin_id1

    SET @SQL = @SQL +
	'
	INSERT INTO ' + @strKomp + '.dbo.PAYM_OCC_BUILD
	(fin_id, occ, service_id, kol, tarif, value, comments, unit_id, procedura, data, user_login, kol_add, metod_old, service_in, kol_excess, sup_id)
	SELECT 
		@fin_id1 as fin_id,
		o.occ, service_id, kol, tarif, value, comments, unit_id, procedura, data, user_login, kol_add, metod_old, service_in, kol_excess, sup_id
	FROM ' + @strArx + '.dbo.PAYM_OCC_BUILD AS o
	JOIN #t_occ AS t ON o.occ=t.occ and o.fin_id=@fin_id1'
    EXECUTE sp_executesql @SQL
						, N'@fin_id1 smallint'
						, @fin_id1 = @fin_id1
	IF @debug = 1 PRINT @SQL

    --********************************************************
    RAISERROR ('Сохраняем итоги по общедомовым услугам', 10, 1) WITH NOWAIT;
    SET @SQL =
	'DELETE oh FROM ' + @strKomp + '.dbo.BUILD_SOURCE_VALUE as oh WHERE oh.fin_id=@fin_id1 and build_id=@build_id'
    EXECUTE sp_executesql @SQL
						, N'@fin_id1 smallint, @build_id INT'
						, @fin_id1 = @fin_id1
						, @build_id = @build_id

    SET @SQL =
	'INSERT INTO ' + @strKomp + '.dbo.BUILD_SOURCE_VALUE
	(fin_id, build_id, service_id, value_source, value_arenda, value_norma, value_add, value_ipu, v_itog, S_arenda, kol_people_serv, unit_id
	,total_sq,use_add,flag_raskidka,value_raspred)
	SELECT 
		@fin_id1 as fin_id,
		build_id, service_id, value_source, value_arenda, value_norma, value_add, value_ipu, v_itog, S_arenda, kol_people_serv, unit_id
		,total_sq,use_add,flag_raskidka,value_raspred
	FROM ' + @strArx + '.dbo.BUILD_SOURCE_VALUE AS o
	WHERE fin_id = @fin_id1 and build_id=@build_id'
    EXECUTE sp_executesql @SQL
						, N'@fin_id1 smallint, @build_id INT'
						, @fin_id1 = @fin_id1
						, @build_id = @build_id
	IF @debug = 1 PRINT @SQL


    --********************************************************
    RAISERROR ('Сохраняем справочную информацию по дому', 10, 1) WITH NOWAIT;
    SET @SQL =
	'DELETE oh FROM ' + @strKomp + '.dbo.CounterHouse as oh WHERE oh.fin_id=@fin_id1 and build_id=@build_id'
    EXECUTE sp_executesql @SQL
						, N'@fin_id1 smallint, @build_id INT'
						, @fin_id1 = @fin_id1
						, @build_id = @build_id

    SET @SQL =
	'INSERT INTO ' + @strKomp + '.dbo.CounterHouse
	(fin_id, [tip_id],[build_id],[service_id],[short_name],[unit_id]
      ,[is_boiler],V_start,[V1],[V_arenda],[V_norma],[V_add],V_load_odn,[V2],[V3],V_economy,[block_paym_V],DateCreate,manual_edit)
	SELECT 
		@fin_id1 as fin_id,[tip_id],[build_id],[service_id],[short_name],[unit_id]
      ,[is_boiler],V_start, [V1],[V_arenda],[V_norma],[V_add],V_load_odn,[V2],[V3],V_economy,[block_paym_V],DateCreate,manual_edit	
	FROM ' + @strArx + '.dbo.CounterHouse AS o
	WHERE fin_id = @fin_id1 and build_id=@build_id'
    EXECUTE sp_executesql @SQL
						, N'@fin_id1 smallint, @build_id INT'
						, @fin_id1 = @fin_id1
						, @build_id = @build_id
	IF @debug = 1 PRINT @SQL
	

    --********************************************************
    RAISERROR ('Сохраняем историю по дому', 10, 1) WITH NOWAIT;
    SET @SQL =
	'DELETE oh FROM ' + @strKomp + '.dbo.BUILDINGS_HISTORY as oh WHERE oh.fin_id=@fin_id1 and bldn_id=@build_id'
    EXECUTE sp_executesql @SQL
						, N'@fin_id1 smallint, @build_id INT'
						, @fin_id1 = @fin_id1
						, @build_id = @build_id

    SET @SQL =
	'INSERT INTO ' + @strKomp + '.dbo.BUILDINGS_HISTORY
	(fin_id
	,bldn_id,street_id,sector_id,div_id,tip_id,nom_dom,old,standart_id,dog_bit,penalty_calc_build,arenda_sq
	,dog_num,dog_date,is_paym_build,dog_date_sobr,dog_date_protocol,dog_num_protocol,opu_sq,opu_sq_elek,build_total_sq
	,norma_gkal,build_type,norma_gkal_gvs,norma_gaz_gvs,norma_gaz_otop,opu_sq_otop,build_total_area,account_rich)
	SELECT 
		@fin_id1 as fin_id
		,id,street_id,sector_id,div_id,tip_id,nom_dom,old,standart_id,dog_bit,penalty_calc_build,arenda_sq
		,dog_num,dog_date,is_paym_build,dog_date_sobr,dog_date_protocol,dog_num_protocol,opu_sq,opu_sq_elek,build_total_sq
		,norma_gkal,build_type,norma_gkal_gvs,norma_gaz_gvs,norma_gaz_otop,opu_sq_otop,build_total_area,account_rich
	FROM ' + @strArx + '.dbo.BUILDINGS AS o
	WHERE id=@build_id'
    EXECUTE sp_executesql @SQL
						, N'@fin_id1 smallint, @build_id INT'
						, @fin_id1 = @fin_id1
						, @build_id = @build_id
	IF @debug = 1 PRINT @SQL

--	ROLLBACK

END TRY
BEGIN CATCH
	EXEC dbo.k_err_messages
END CATCH

END
go

