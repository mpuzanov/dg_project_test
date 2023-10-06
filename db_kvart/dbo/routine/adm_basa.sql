CREATE   PROCEDURE [dbo].[adm_basa]
(
	  @Job BIT = 0
)
AS
	/*
	Обслуживание базы.
	Различные проверки таблиц.
	*/

	SET NOCOUNT ON
	SET LOCK_TIMEOUT 10000

	IF @@trancount > 0
		ROLLBACK TRAN

	IF @Job IS NULL
		SET @Job = 0

	-- Если запуск по расписанию - то днём (в рабочее время) не делать
	IF @Job = 1
		AND DATEPART(HOUR, current_timestamp) BETWEEN 8 AND 20
		RETURN;

	DECLARE @start_time DATETIME = current_timestamp, @msg VARCHAR(100)

	DECLARE @fin_current SMALLINT
	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL);

	BEGIN TRAN

		RAISERROR (N'Обновляем максимальные значения ключевых полей', 10, 1) WITH NOWAIT;

		MERGE dbo.Key_id AS target USING (
			SELECT 1
				 , COALESCE(MAX(occ), 0)
				 , N'Max значение лицевого счета в таблице OCCUPATIONS'
			FROM dbo.Occupations
			UNION
			SELECT 2
				 , COALESCE(MAX(id), 0)
				 , N'Max значение ключа  в таблице PEOPLE'
			FROM dbo.People
			UNION
			SELECT 3
				 , COALESCE(MAX(id), 0)
				 , N'Max значение ключа в таблице DSC_OWNERS'
			FROM dbo.Dsc_owners
			UNION
			SELECT 5
				 , COALESCE(MAX(id), 0)
				 , N'Max значение ключа в таблице PAYDOC_PACKS'
			FROM dbo.Paydoc_packs
			UNION
			SELECT 6
				 , COALESCE(MAX(id), 0)
				 , N'Max значение ключа в таблице PAYINGS'
			FROM dbo.Payings
		) AS source (id, key_max, Name)
		ON (target.id = source.id)
		WHEN MATCHED
			THEN UPDATE
				SET key_max = source.key_max
		WHEN NOT MATCHED
			THEN INSERT
					(id
				   , key_max
				   , decriptions)
					VALUES (source.id
						  , source.key_max
						  , source.Name);

		COMMIT TRAN

		RAISERROR (N'удаляем пени по услугам у закрытых лицевых', 10, 1) WITH NOWAIT;
		DELETE FROM p
		FROM dbo.Occupations AS o 
			JOIN dbo.Peny_all AS p 
				ON o.occ = p.occ
				AND o.fin_id = p.fin_id
		WHERE o.status_id = 'закр';

		RAISERROR (N'Удаляем квитанции по закрытым лицевыми', 10, 1) WITH NOWAIT;
		DELETE FROM i
		FROM dbo.Occupations AS o 
			JOIN dbo.Occupation_Types AS ot 
				ON o.tip_id = ot.id
			JOIN dbo.Intprint AS i ON o.occ = i.occ
				AND ot.fin_id = i.fin_id
		WHERE o.status_id = 'закр';

		RAISERROR (N'Удаляем начисления на закрытых лицевых', 10, 1) WITH NOWAIT;
		UPDATE p1
		SET p1.Value = 0
		  , p1.Paid = 0
		  , p1.Added = 0
		  , p1.SALDO = 0
		FROM [dbo].Paym_list AS p1
			JOIN dbo.Occupations AS O 
				ON O.occ = p1.occ
		WHERE O.status_id = 'закр'

		DELETE p1
		FROM [dbo].Paym_list AS p1
		WHERE (p1.[Value] = 0
			AND p1.Paid = 0
			AND p1.Added = 0
			AND p1.SALDO = 0
			AND p1.kol = 0
			AND p1.tarif = 0
			AND p1.PaymAccount = 0
			AND p1.PaymAccount_peny = 0
			AND p1.penalty_serv = 0
			AND p1.Penalty_old = 0
			AND p1.penalty_prev = 0
			AND ((source_id % 1000 = 0)	AND (mode_id % 1000 = 0))
			);

		--*****************************************************************
		RAISERROR (N'Отключаем тригеры на OCCUPATIONS', 10, 1) WITH NOWAIT;

		ALTER TABLE dbo.Occupations DISABLE TRIGGER ALL

		RAISERROR (N'Обновляем адреса на лицевых', 10, 1) WITH NOWAIT;
		UPDATE o
		SET address = [dbo].[Fun_GetAdres](f.bldn_id, o.flat_id, o.occ)
		FROM dbo.Occupations AS o
			JOIN dbo.Flats AS f 
				ON o.flat_id = f.id
		WHERE 1=1
		AND o.[address] IS NULL;

		RAISERROR (N'Проверяем фин.период на лицевых', 10, 1) WITH NOWAIT;
		UPDATE o
		SET o.fin_id = b.fin_current
		FROM dbo.Occupations AS o
			JOIN dbo.Flats AS f ON o.flat_id=f.id
			JOIN dbo.Buildings AS b ON f.bldn_id=b.id
		WHERE o.status_id <> 'закр'
			AND o.fin_id <> b.fin_current;

		RAISERROR (N'Проверка типа фонда на лицевых', 10, 1) WITH NOWAIT;
		UPDATE o
		SET tip_id = b.tip_id
		FROM dbo.Occupations AS o
			JOIN dbo.Flats AS f 
				ON o.flat_id = f.id
			JOIN dbo.Buildings AS b 
				ON f.bldn_id = b.id
		WHERE o.tip_id <> b.tip_id;
		--AND o.status_id <> 'закр'  29/04/13

		RAISERROR (N'надо сменить номер участка для всех лицевых где o.jeu<>b.sector_id or o.tip_id<>b.tip_id', 10, 1) WITH NOWAIT;
		UPDATE dbo.Occupations
		SET jeu = b.sector_id
		  , tip_id = b.tip_id
		FROM dbo.Occupations AS o
			JOIN dbo.Flats AS f 
				ON o.flat_id = f.id
			JOIN dbo.Buildings AS b 
				ON f.bldn_id = b.id
			JOIN dbo.Occupation_Types AS ot 
				ON b.tip_id = ot.id
		WHERE ot.state_id = 'норм'
			AND (o.jeu <> b.sector_id OR o.tip_id <> b.tip_id);
		-- AND o.status_id <> 'закр'  29/04/13

		RAISERROR (N'Удаляем начисления на закрытых лицевых по лицевому', 10, 1) WITH NOWAIT;
		UPDATE O
		SET O.Value = 0
		  , O.Paid = 0
		  , O.Added = 0
		  , O.SALDO = 0
		  , O.Penalty_value = 0
		  , O.Penalty_old_new = 0
		FROM dbo.Occupations AS O
		WHERE O.status_id = 'закр'
			AND (O.Value <> 0 OR O.Paid <> 0 OR O.Added <> 0 OR O.SALDO <> 0);

		ALTER TABLE dbo.Occupations ENABLE TRIGGER ALL;
				
		SET @msg = CONCAT('(прошло ', CONVERT(VARCHAR(10), current_timestamp - @start_time, 108), ')')
		RAISERROR (N'Проверка типа фонда на лицевых в истории %s', 10, 1, @msg) WITH NOWAIT;
		UPDATE o
		SET tip_id = b.tip_id
		FROM dbo.Occ_history AS o
			JOIN dbo.Flats AS f 
				ON o.flat_id = f.id
			JOIN dbo.Buildings_history AS b 
				ON f.bldn_id = b.bldn_id
				AND o.fin_id = b.fin_id
		WHERE o.tip_id <> b.tip_id
			AND o.status_id <> 'закр';

		/****************************************/
		RAISERROR (N'Очищаем таблицу %s', 10, 1, 'PEOPLE_LIST_RAS') WITH NOWAIT;
		DELETE FROM dbo.People_list_ras

		RAISERROR (N'Проверка целостности файла PEOPLE', 10, 1) WITH NOWAIT;
		--*************************************************************
		--ALTER TABLE dbo.People DISABLE TRIGGER ALL

		UPDATE p 
		SET lgota_id = 0
		FROM dbo.People AS p
		WHERE 1=1
			AND Del = CAST(0 AS BIT) -- у удаленных льгота должна остаться
			AND lgota_id <> 0
			AND
			NOT EXISTS (
				SELECT 1
				FROM dbo.Dsc_owners AS dsc
				WHERE dsc.owner_id = p.id
					AND dsc.active = CAST(1 AS BIT)
					AND dsc.owner_id = p.id
			)
		--ALTER TABLE dbo.People ENABLE TRIGGER ALL
		--*************************************************************


		-- ***********************************************************************************
		RAISERROR (N'Смена истёкшего статуса регистрации', 10, 1) WITH NOWAIT;
		IF dbo.Fun_GetRejim() <> N'чтен'
		BEGIN
			DECLARE @TablePeople TABLE (
				  id INT PRIMARY KEY
				, occ INT
				, comments VARCHAR(50)
			)

			INSERT INTO @TablePeople
				(id
			   , occ
			   , comments)
			SELECT p.id
				 , p.occ
				 , SUBSTRING(N'Стат.рег.' + dbo.Fun_InitialsPeople(p.id) + '(' + ps.short_name + N' до ' + CONVERT(VARCHAR(8), p.DateEnd, 3) + ')', 1, 50) as comments
			FROM [dbo].[People] AS p 
				JOIN dbo.Occupations AS o 
					ON p.occ = o.occ
				JOIN dbo.Flats AS f 
					ON o.flat_id = f.id
				JOIN dbo.Buildings AS b 
					ON f.bldn_id = b.id
				JOIN dbo.Occupation_Types AS ot 
					ON b.tip_id = ot.id
				JOIN dbo.Global_values AS gb 
					ON b.fin_current = gb.fin_id
				JOIN dbo.Person_statuses AS ps 
					ON p.Status2_id = ps.id
			WHERE DateEnd IS NOT NULL
				AND p.Del = CAST(0 AS BIT)
				AND DateEnd < gb.start_date
				AND p.Status2_id <> 'пост'
				AND ot.payms_value = CAST(1 AS BIT)
				AND ot.state_id = 'норм'
				AND o.status_id <> 'закр'
				AND p.AutoDelPeople = 2

			UPDATE p
			SET Status2_id = N'пост'
			  , DateEnd = NULL
			  , AutoDelPeople = NULL
			FROM dbo.People AS p
				JOIN @TablePeople AS p2 ON p.id = p2.id

			INSERT INTO dbo.Op_Log
				(user_id
			   , op_id
			   , occ
			   , done
			   , comments)
			SELECT NULL
				 , N'смчл'
				 , occ
				 , dbo.Fun_GetOnlyDate(current_timestamp)
				 , comments
			FROM @TablePeople

		END
		-- ***********************************************************************************

		RAISERROR (N'Проверка режимов потребления и поставщиков на лицевых', 10, 1) WITH NOWAIT;
		EXEC dbo.adm_proverka_modes;

		--*************************************************************
		SET @msg = CONCAT('(прошло ', CONVERT(VARCHAR(10), current_timestamp - @start_time, 108), ')')
		RAISERROR (N'Проверяем все ли есть услуги для начисления по статусам прописки %s', 10, 1, @msg) WITH NOWAIT;
		INSERT INTO dbo.Person_calc
			(status_id
		   , service_id
		   , have_paym
		   , is_rates)
		SELECT ps.id
			 , s.id
			 , 0
			 , 1
		FROM dbo.Services AS s
			CROSS JOIN dbo.Person_statuses AS ps
		WHERE NOT EXISTS (
				SELECT 1
				FROM dbo.Person_calc AS pc 
				WHERE s.id = pc.service_id
					AND ps.id = pc.status_id
			)

		--*************************************************************
		RAISERROR (N'Добавляем счётчики в историю на лицевые счета', 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Counter_list_all
			(fin_id
		   , counter_id
		   , occ
		   , service_id
		   , occ_counter
		   , internal
		   , no_vozvrat
		   , KolmesForPeriodCheck
		   , kol_occ)
		SELECT --top 100 ci.*
		DISTINCT ci.fin_id
			   , ci.counter_id
			   , ci.occ
			   , ci.service_id
			   , ch1.occ_serv
			   , CASE WHEN (ch.is_counter = 2) THEN 1 ELSE 0 END AS internal
			   , cl.no_vozvrat
			   , cl.KolmesForPeriodCheck
			   , cl.kol_occ
		FROM dbo.View_counter_inspector_lite AS ci 
			LEFT JOIN dbo.Counter_list_all AS cl ON ci.fin_id = cl.fin_id
				AND ci.counter_id = cl.counter_id
				AND ci.occ = cl.occ
			JOIN dbo.Paym_history AS ch ON ci.fin_id = ch.fin_id
				AND ci.occ = ch.occ
				AND ci.service_id = ch.service_id
			JOIN dbo.Consmodes_list AS ch1  ON ci.occ = ch1.occ
				AND ci.service_id = ch1.service_id
		WHERE cl.occ IS NULL
			AND ci.tip_value = 1

		-- Проверяем KolmesForPeriodCheck
		--SELECT occ,service_id,KolmesForPeriodCheck,KolmesForPeriodCheck2,fin_id
		UPDATE T
		SET KolmesForPeriodCheck = KolmesForPeriodCheck2
		FROM (
			SELECT cl.occ
				 , cl.service_id
				 , cl.KolmesForPeriodCheck
				 , KolmesForPeriodCheck2 = dbo.Fun_GetKolMonthPeriodCheck(cl.occ, cl.fin_id, cl.service_id)
				 , cl.fin_id
			FROM dbo.Occupations AS o 
				JOIN dbo.Occupation_Types ot 
					ON o.tip_id = ot.id
				JOIN dbo.Counter_list_all AS cl 
					ON o.occ = cl.occ
				JOIN dbo.Counters c  ON cl.counter_id = c.id
			WHERE cl.fin_id < ot.fin_id
				AND o.status_id <> 'закр'
				AND c.PeriodCheck IS NOT NULL
				AND c.date_del IS NULL
				AND cl.KolmesForPeriodCheck = 0
				AND cl.fin_id >= 180
				AND ot.payms_value = CAST(1 AS BIT)
		) AS T
		WHERE KolmesForPeriodCheck <> KolmesForPeriodCheck2;


		-- удаляем пользовательские сообщения 
		DELETE FROM [dbo].[Messages_users]
		WHERE [receive] < DATEADD(MONTH, -2, current_timestamp) -- когда получил старше 2 мес
			OR [date_msg] < DATEADD(YEAR, -2, current_timestamp); -- или дата отправки старше 2 лет

		-- удаляем логи выполнения отчётов старше 12 мес
		DELETE FROM [dbo].Reports_log
		WHERE [DATE] < DATEADD(MONTH, -12, current_timestamp);

		-- Чистим таблицу прогресса от старых записей
		DELETE FROM dbo.Progress_proces
		WHERE [DATETIME] < DATEADD(MONTH, -3, current_timestamp);


		RAISERROR (N'Смена квартиры по счётчикам', 10, 1) WITH NOWAIT;
		UPDATE c
		SET flat_id = (
			SELECT f1.id
			FROM Flats AS f1 
			WHERE f1.bldn_id = c.build_id
				AND EXISTS (
					SELECT 1
					FROM Flats AS f2
					WHERE f2.id = c.flat_id
						AND f2.nom_kvr = f1.nom_kvr
				)
		)
		FROM [dbo].[Counters] AS c
		WHERE is_build = 0
			AND date_del IS NULL
			AND NOT EXISTS (
				SELECT 1
				FROM dbo.Flats f 
				WHERE f.bldn_id = c.build_id
					AND f.id = c.flat_id
			);


		--	***************************************************************************
		RAISERROR (N'Устанавливаем ед. измерения по домовым услугам', 10, 1) WITH NOWAIT;

		DECLARE @serv_id_dom VARCHAR(10)
			  , @serv_from VARCHAR(10)
			  , @unit_id VARCHAR(10)
			  , @tip_id SMALLINT
			  , @fin_id SMALLINT = 130;

		DECLARE cursor_name CURSOR FOR
			SELECT S.id
				 , SUBSTRING(serv_from, 1, 4)
				 , OT.id
				 , SU.unit_id
			FROM dbo.Services AS S 
				CROSS JOIN dbo.Occupation_Types AS OT 
				JOIN dbo.Service_units AS SU 
					ON SUBSTRING(serv_from, 1, 4) = SU.service_id
					AND OT.id = SU.tip_id
			WHERE is_build = CAST(1 AS BIT)
				AND SU.fin_id = @fin_id

		OPEN cursor_name;

		FETCH NEXT FROM cursor_name INTO @serv_id_dom, @serv_from, @tip_id, @unit_id;

		WHILE @@fetch_status = 0
		BEGIN

			--PRINT @serv_id_dom+' '+@serv_from+' '+str(@tip_id)+' '+@unit_id

			INSERT INTO [dbo].[Service_units]
			SELECT [fin_id]
				 , @serv_id_dom
				 , [roomtype_id]
				 , [tip_id]
				 , @unit_id
			FROM [dbo].[Service_units] AS t1
			WHERE fin_id = @fin_id
				AND service_id = @serv_from
				AND tip_id = @tip_id
				AND NOT EXISTS (
					SELECT 1
					FROM [dbo].[Service_units] AS t2
					WHERE t2.fin_id = t1.fin_id
						AND t2.service_id = @serv_id_dom
						AND t2.tip_id = t1.tip_id
				)
			FETCH NEXT FROM cursor_name INTO @serv_id_dom, @serv_from, @tip_id, @unit_id;

		END

		CLOSE cursor_name;
		DEALLOCATE cursor_name;
		--****************************************************************

		-- перенёс в job с переиндексацией
		--RAISERROR ('Обновление статистики базы', 10, 1) WITH NOWAIT;  
		--EXEC sp_updatestats
		--

		--exec adm_recompile_proc  -- работает с ошибками
		--
		RAISERROR (N'===== Обновление прав', 10, 1) WITH NOWAIT;
		EXEC adm_permission @del_permission = 0
						  , @debug = 0
		RAISERROR ('=====================', 10, 1) WITH NOWAIT;

		RAISERROR (N'устанавливаем тек.период в разовых где его нет', 10, 1) WITH NOWAIT;
		UPDATE ap
		SET fin_id = b.fin_current
		FROM dbo.Added_Payments AS ap
			JOIN dbo.Occupations AS o 
				ON ap.occ = o.occ
			JOIN dbo.Flats AS f 
				ON o.flat_id=f.id
			JOIN dbo.Buildings AS b 
				ON f.bldn_id=b.id
		WHERE ap.fin_id IS NULL;

		RAISERROR (N'устанавливаем тек.период в лицевых где его нет', 10, 1) WITH NOWAIT;
		UPDATE o
		SET fin_id = b.fin_current
		FROM dbo.Occupations AS o
			JOIN dbo.Flats AS f 
				ON o.flat_id=f.id
			JOIN dbo.Buildings AS b 
				ON f.bldn_id=b.id
		WHERE o.fin_id IS NULL;

		RAISERROR (N'устанавливаем тек.период в режимах по лицевым где его нет', 10, 1) WITH NOWAIT;
		UPDATE cl
		SET fin_id = b.fin_current
		FROM dbo.Consmodes_list AS cl
			JOIN dbo.Occupations AS o 
				ON cl.occ = o.occ
			JOIN dbo.Flats AS f 
				ON o.flat_id=f.id
			JOIN dbo.Buildings AS b 
				ON f.bldn_id=b.id
		WHERE o.status_id <> 'закр'
			AND (cl.fin_id IS NULL OR cl.fin_id < b.fin_current);

		--****************************************************************
		ALTER TABLE dbo.Occupations ENABLE TRIGGER ALL;
		ALTER TABLE dbo.Consmodes_list ENABLE TRIGGER ALL;
		ALTER TABLE dbo.Added_Payments ENABLE TRIGGER ALL;
		--****************************************************************

		RAISERROR (N'Очищаем таблицу %s', 10, 1, 'PAYM_ADD') WITH NOWAIT;
		--TRUNCATE TABLE dbo.PAYM_ADD
		DELETE FROM dbo.Paym_add;

		SET @msg = CONCAT('(прошло ', CONVERT(VARCHAR(10), current_timestamp - @start_time, 108), ')')
		RAISERROR (N'Удаляем из истории начисления которые есть в текущем периоде %s', 10, 1, @msg) WITH NOWAIT;
		DELETE PH
		FROM dbo.Paym_history PH
			JOIN dbo.Paym_list AS PL ON PL.fin_id = PH.fin_id
				AND PL.occ = PH.occ
				AND PL.service_id = PH.service_id
				AND PH.sup_id = PL.sup_id;

		RAISERROR (N'Обновляем occ_sup_paym (у кого пусто)', 10, 1) WITH NOWAIT;
		UPDATE ph
		SET ph.occ_sup_paym = CASE WHEN (ph.sup_id > 0) THEN os.occ_sup ELSE ph.occ END
		FROM dbo.Paym_history ph
			LEFT JOIN dbo.Occ_Suppliers os 
				ON ph.fin_id = os.fin_id
				AND ph.occ = os.occ
				AND ph.sup_id = os.sup_id
		WHERE ph.occ_sup_paym IS NULL;

		SET @msg = CONCAT('(прошло ', CONVERT(VARCHAR(10), current_timestamp - @start_time, 108), ')')
		RAISERROR (N'Устанавливаем последнюю дату поверки (у кого пусто) %s', 10, 1, @msg) WITH NOWAIT;
		UPDATE c
		SET PeriodLastCheck = DATEADD(YEAR, -1 * c.PeriodInterval, c.PeriodCheck)
		FROM dbo.Counters c
		WHERE c.date_del IS NULL
			AND c.PeriodCheck IS NOT NULL
			AND c.PeriodInterval > 0
			AND c.PeriodLastCheck IS NULL;

		RAISERROR (N'Удаляем платежи по услугам если нет самих платежей', 10, 1) WITH NOWAIT;
		DELETE ps
		FROM dbo.Paying_serv ps
		WHERE NOT EXISTS (
				SELECT 1
				FROM Payings p
				WHERE p.id = ps.paying_id
			);

		RAISERROR (N'Проверяем заполнение метода расчёта', 10, 1) WITH NOWAIT;
		UPDATE p1
		SET metod_old = metod
		FROM [dbo].[Paym_list] AS p1
		WHERE p1.metod_old IS NULL
			AND metod IS NOT NULL;

		UPDATE dbo.Global_values
		SET KolDayFinPeriod = DATEDIFF(DAY, start_date, DATEADD(MONTH, 1, start_date))
		WHERE KolDayFinPeriod IS NULL;

		--RAISERROR ('Проверка расчётов', 10, 1) WITH NOWAIT;
		--EXEC [dbo].[adm_proverka_paym] @in_table = 1
		
		RAISERROR (N'фин. период на доме должен совпадать с типом фонда где нет раздельного учета', 10, 1) WITH NOWAIT;
		UPDATE B
		SET fin_current = OT.fin_id
		FROM dbo.Buildings B
			JOIN dbo.Occupation_Types OT ON 
				B.tip_id = OT.id
		WHERE B.fin_current <> OT.fin_id
			AND b.is_finperiod_owner=0;

		DELETE BH
		FROM dbo.Buildings_history AS BH
			JOIN dbo.View_buildings AS vb ON 
				vb.id = BH.bldn_id
				AND vb.fin_current = BH.fin_id;

		RAISERROR (N'удаляем копии экранов у старых ошибок', 10, 1) WITH NOWAIT;
		UPDATE dbo.Errors_card
		SET file_error = NULL
		WHERE data < DATEADD(DAY, -14, current_timestamp)
		
		RAISERROR (N'удаляем старые ошибки', 10, 1) WITH NOWAIT;
		DELETE FROM dbo.Errors_card
		WHERE data < DATEADD(DAY, -90, current_timestamp)

		DELETE FROM dbo.Op_log_adm
		WHERE done < DATEADD(YEAR, -3, current_timestamp)

		DELETE FROM dbo.Paying_log
		WHERE done < DATEADD(MONTH, -3, current_timestamp)

		DELETE FROM dbo.Error_log
		WHERE ErrorDate < DATEADD(MONTH, -6, current_timestamp)

		--******************************************************************
		-- Обновляем BANK_TBL_SPISOK если не сходиться с реальными данными
		-- SELECT bs.filenamedbf, bs.kol, COALESCE(t.kol,0), bs.summa, COALESCE(t.sum_olp,0)
		UPDATE bs
		SET kol = COALESCE(t.kol, 0)
		  , bs.summa = COALESCE(t.sum_olp, 0)
		FROM dbo.Bank_tbl_spisok bs
			CROSS APPLY (
				SELECT COUNT(*) AS kol
					 , SUM(bd.sum_opl) AS sum_olp
				FROM dbo.Bank_Dbf bd
				WHERE bd.filedbf_id = bs.filedbf_id
			) AS t
		WHERE bs.kol <> t.kol
			OR bs.summa <> t.sum_olp

		UPDATE bs
		SET sysuser = COALESCE(t.sysuser, bs.sysuser)
		FROM dbo.Bank_tbl_spisok bs
			CROSS APPLY (
				SELECT MAX(bd.sysuser) AS sysuser
				FROM dbo.Bank_Dbf bd
				WHERE bd.filedbf_id = bs.filedbf_id
					AND bd.sysuser IS NOT NULL
			) AS t
			LEFT JOIN Users u ON bs.sysuser = u.login
		WHERE bs.sysuser IS NULL
			OR u.login IS NULL;

		--******************************************************************

		RAISERROR (N'Заносим ед.измерения по цессии где не установлено', 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Service_units
			(fin_id
		   , service_id
		   , roomtype_id
		   , tip_id
		   , unit_id)
		SELECT fin_id = OT.fin_id
			 , service_id = N'цеся'
			 , R.name
			 , OT.id
			 , unit_id = N'проц'
		FROM dbo.Dog_sup DS
				 JOIN dbo.Occupation_Types OT 
					ON DS.tip_id = OT.id
				 LEFT JOIN dbo.Service_units SU 
					ON SU.tip_id = OT.id
					 AND SU.fin_id = OT.fin_id
					 AND SU.service_id = N'цеся'
		   , (
				 SELECT name = N'комм'
				 UNION ALL
				 SELECT N'об06'
				 UNION ALL
				 SELECT N'об10'
				 UNION ALL
				 SELECT N'отдк'
			 ) AS R
		WHERE DS.is_cessia = 1
			AND SU.service_id IS NULL;
		--******************************************************************

		RAISERROR (N'Обновляем идентификатор гис ЖКХ там где его нет из истории', 10, 1) WITH NOWAIT;
		UPDATE os
		SET os.id_jku_gis = t.id_jku_gis
		FROM dbo.Occ_Suppliers os
			CROSS APPLY (
				SELECT TOP (1) os1.id_jku_gis
				FROM dbo.Occ_Suppliers os1
				WHERE os1.occ_sup = os.occ_sup
					AND (os1.fin_id < os.fin_id AND os1.fin_id>os.fin_id-3)
					AND (os1.id_jku_gis IS NOT NULL OR os1.id_jku_gis <> '')
				ORDER BY os1.fin_id DESC
			) AS t
		WHERE os.fin_id = @fin_current
			AND (os.id_jku_gis IS NULL OR os.id_jku_gis = '');
		--******************************************************************

		RAISERROR (N'Удаление старых шаблонов ПД ГИС (оставляем последние 3)', 10, 1) WITH NOWAIT;
		DELETE t1
		FROM [dbo].[Type_gis_file] AS t1
			JOIN (
				SELECT *
				FROM (
					SELECT [id]
						 , [tip_id]
						 , [FileName]
						 , [FileDateEdit]
						 , [Version]
						 , [VersionInt]
						 , [name]
						 , [UserEdit]
						 , DENSE_RANK() OVER (PARTITION BY tip_id ORDER BY FileDateEdit DESC) AS toprank
					FROM [dbo].[Type_gis_file]
				) AS tmp
				WHERE toprank > 3
			) AS t2 ON t1.id = t2.id;

		RAISERROR (N'Очищаем таблицу BANK_DBF_TMP', 10, 1) WITH NOWAIT;
		DELETE FROM dbo.Bank_dbf_tmp;

		RAISERROR (N'Удаляем тарифы если режим или поставщик = НЕТ', 10, 1) WITH NOWAIT;
		DELETE FROM dbo.Rates
		WHERE (mode_id % 1000 = 0)
			OR (source_id % 1000 = 0);

		--===================================================
		RAISERROR ('FileFTP', 10, 1) WITH NOWAIT;
		DELETE ftp
		FROM dbo.[FileFTP] AS ftp
		WHERE NOT EXISTS (
				SELECT *
				FROM dbo.Occupations AS o
				WHERE o.occ = ftp.occ
			);
		--===================================================
		-- Fio_history
		DELETE t1
		FROM dbo.Fio_history AS t1
		WHERE NOT EXISTS (
				SELECT *
				FROM dbo.People AS p
				WHERE p.id = t1.owner_id
			);

		-- Dsc_owners
		DELETE t1
		FROM dbo.Dsc_owners AS t1
		WHERE NOT EXISTS (
				SELECT *
				FROM dbo.People AS p
				WHERE p.id = t1.owner_id
			);

		-- Iddoc
		DELETE t1
		FROM dbo.Iddoc AS t1
		WHERE NOT EXISTS (
				SELECT *
				FROM dbo.People AS p
				WHERE p.id = t1.owner_id
			);

		-- People_2
		DELETE t1
		FROM dbo.People_2 AS t1
		WHERE NOT EXISTS (
				SELECT *
				FROM dbo.People AS p
				WHERE p.id = t1.owner_id
			);

		-- People_image
		DELETE t1
		FROM dbo.People_image AS t1
		WHERE NOT EXISTS (
				SELECT *
				FROM dbo.People AS p
				WHERE p.id = t1.owner_id
			)

		-- People_list_ras
		DELETE t1
		FROM dbo.People_list_ras AS t1
		WHERE NOT EXISTS (
				SELECT *
				FROM dbo.People AS p
				WHERE p.id = t1.owner_id
			);

		-- People_listok
		DELETE t1
		FROM dbo.People_listok AS t1
		WHERE NOT EXISTS (
				SELECT *
				FROM dbo.People AS p
				WHERE p.id = t1.owner_id
			);

		-- People_TmpOut
		DELETE t1
		FROM dbo.People_TmpOut AS t1
		WHERE NOT EXISTS (
				SELECT *
				FROM dbo.People AS p
				WHERE p.id = t1.owner_id
			);

		--===================================================
		SET @msg = CONCAT('(прошло ', CONVERT(VARCHAR(10), current_timestamp - @start_time, 108), ')')
		RAISERROR (N'Удаляем платежи по которым нет лицевых счетов %s', 10, 1, @msg) WITH NOWAIT;
		--SELECT p.occ, p.fin_id, p.value, p.pack_id, pd.tip_id
		DELETE p
		FROM dbo.Payings AS p
			JOIN dbo.Paydoc_packs AS pd 
				ON pd.id = p.pack_id
			LEFT JOIN Occupations AS o 
				ON p.occ = o.occ
		WHERE o.occ IS NULL;

		RAISERROR (N'Удаляем пачки в которых нет платежей', 10, 1) WITH NOWAIT;
		--SELECT pd.* 
		DELETE pd
		FROM dbo.Paydoc_packs AS pd
			JOIN dbo.Occupation_Types AS ot 
				ON pd.tip_id = ot.id
		WHERE pd.fin_id < ot.fin_id
			AND NOT EXISTS (
				SELECT *
				FROM Payings AS p
				WHERE p.pack_id = pd.id
			);

		--===================================================
		RAISERROR (N'Удаляем блокировку квитанций по которым нет лицевых счетов', 10, 1) WITH NOWAIT;
		--SELECT t.*
		DELETE t
		FROM dbo.Occ_not_print AS t
			LEFT JOIN Occupations AS o 
				ON t.occ = o.occ
		WHERE o.occ IS NULL;

		RAISERROR (N'Установка площади по паспорту (если не заполнена)', 10, 1) WITH NOWAIT;
		UPDATE dbo.Buildings
		SET build_total_area = build_total_sq + COALESCE(arenda_sq, 0)
		WHERE build_total_area = 0
			AND build_total_sq > 0;

		RAISERROR (N'Помечаем ALERT подозрительные показания ПУ', 10, 1) WITH NOWAIT;
		EXEC k_counter_inspector_alert;

		RAISERROR (N'изменяем период поверки (если его можно подсчитать)', 10, 1) WITH NOWAIT;
		UPDATE c
		SET PeriodCheck = DATEADD(YEAR, c.PeriodInterval, c.PeriodLastCheck)
		FROM [dbo].[Counters] AS c
		WHERE PeriodCheck IS NULL
			AND [PeriodLastCheck] IS NOT NULL
			AND [PeriodInterval] > 0
			AND c.date_del IS NULL;

		RAISERROR (N'устанавливаем признак закрытости периода кроме последних 2', 10, 1) WITH NOWAIT;
		UPDATE gv
		SET closed = 1
		FROM dbo.Global_values gv
		WHERE fin_id NOT IN (
				SELECT TOP (2) fin_id
				FROM Global_values gv
				ORDER BY fin_id DESC
			);

		--====================================================
		RAISERROR (N'добавление режимов на дома (есть на лицевых)', 10, 1) WITH NOWAIT;
		INSERT INTO dbo.Build_mode
			(build_id
		   , service_id
		   , mode_id)
		SELECT DISTINCT f.bldn_id
					  , cl.service_id
					  , cl.mode_id
		FROM dbo.Flats AS f
			JOIN dbo.Occupations AS o 
				ON f.id = o.flat_id
			JOIN dbo.Consmodes_list AS cl 
				ON o.occ = cl.occ
		WHERE o.tip_id = 1
			AND NOT EXISTS (
				SELECT *
				FROM dbo.Build_mode t
				WHERE t.build_id = f.bldn_id
					AND t.service_id = cl.service_id
					AND t.mode_id = cl.mode_id
			)
		INSERT INTO dbo.Build_source
			(build_id
		   , service_id
		   , source_id)
		SELECT DISTINCT f.bldn_id
					  , cl.service_id
					  , cl.source_id
		FROM dbo.Flats AS f
			JOIN dbo.Occupations AS o 
				ON f.id = o.flat_id
			JOIN dbo.Consmodes_list AS cl 
				ON o.occ = cl.occ
		WHERE o.tip_id = 1
			AND NOT EXISTS (
				SELECT *
				FROM dbo.Build_source t
				WHERE t.build_id = f.bldn_id
					AND t.service_id = cl.service_id
					AND t.source_id = cl.source_id
			);
		--====================================================
		RAISERROR (N'добавляем ед.измерения по умолчанию у кого нет', 10, 1) WITH NOWAIT;
		EXEC adm_add_servunits_default @tip_id1 = NULL;

		RAISERROR (N'заполним площади помещений если = 0', 10, 1) WITH NOWAIT;
		UPDATE f
		SET area = COALESCE((
			SELECT SUM(o.total_sq)
			FROM dbo.Occupations AS o
			WHERE o.flat_id = f.id
		), 0)
		FROM dbo.Flats AS f
		WHERE f.area = 0;

		RAISERROR (N'Добавление на дома режима и поставщика - Нет', 10, 1) WITH NOWAIT;
		--================================================================================
		INSERT INTO Build_mode
			(build_id
		   , service_id
		   , mode_id)
		SELECT DISTINCT t1.build_id
					  , t1.service_id
					  , t1.mode_id / 1000 * 1000
		FROM Build_mode t1
		WHERE NOT EXISTS (
				SELECT *
				FROM Build_mode t
				WHERE t.build_id = t1.build_id
					AND t.service_id = t1.service_id
					AND t.mode_id % 1000 = 0
			);

		INSERT INTO Build_source
			(build_id
		   , service_id
		   , source_id)
		SELECT DISTINCT t1.build_id
					  , t1.service_id
					  , t1.source_id / 1000 * 1000
		FROM Build_source AS t1
		WHERE NOT EXISTS (
				SELECT *
				FROM Build_source t
				WHERE t.build_id = t1.build_id
					AND t.service_id = t1.service_id
					AND t.source_id % 1000 = 0
			);

		RAISERROR (N'Подчищаем Counter_paym без показаний', 10, 1) WITH NOWAIT;
		DELETE cp
		FROM dbo.Counter_paym cp		
		LEFT JOIN Counter_inspector ci
			ON cp.counter_id=ci.counter_id 
			AND cp.kod_insp=ci.id 
			AND cp.tip_value = ci.tip_value
		WHERE ci.id IS NULL;
		
		--================================================================================
		RAISERROR (N'удаляем не существующие л.сч из групп печати', 10, 1) WITH NOWAIT;
		DELETE po
		FROM dbo.Print_occ po
		WHERE NOT EXISTS(SELECT * FROM dbo.Occupations as o WHERE o.occ=po.occ);

		--================================================================================
		RAISERROR (N'добавление, удаление пользователей в sysadmin', 10, 1) WITH NOWAIT;
		DECLARE	@oper INT, @login1	SYSNAME

		DECLARE curs CURSOR FOR
			SELECT
				u.[login]
				,CASE
					WHEN u.SuperAdmin=1 AND COALESCE(s.sysadmin,0)=0 THEN 1 
					WHEN u.SuperAdmin=0 AND COALESCE(s.sysadmin,0)=1 THEN 2
					ELSE 0
				END AS oper 
			FROM USERS AS u 
				JOIN sys.syslogins s 
					ON u.login=s.loginname
			WHERE u.[login] NOT IN ('sa', 'guest') 

		OPEN curs
		FETCH NEXT FROM curs INTO @login1, @oper
		WHILE (@@fetch_status = 0)
		BEGIN
			--PRINT @login1 + ' ' + STR(@oper)

			IF @oper=1
				EXEC sp_addsrvrolemember  @LogiName=@login1,  @RoleName='sysadmin'	
			IF @oper=2
				EXEC sp_dropsrvrolemember @loginame = @login1, @rolename = 'sysadmin'

			FETCH NEXT FROM curs INTO @login1, @oper
		END
		CLOSE curs
		DEALLOCATE curs;
		--=================================================================================
		RAISERROR (N'выписываем граждан кому положено', 10, 1) WITH NOWAIT;
		DECLARE @occ1 INT
		DECLARE curs1 CURSOR LOCAL FOR
			SELECT occ FROM dbo.Occupations	as o WHERE status_id<>'закр'	
					AND EXISTS(SELECT 1 From dbo.People p WHERE p.occ=o.occ and p.Status2_id<>'пост')
			ORDER BY occ
		OPEN curs1
		FETCH NEXT FROM curs1 INTO @occ1
		WHILE (@@fetch_status = 0)
		BEGIN
			--RAISERROR ('%d', 10, 1, @occ1) WITH NOWAIT;
			EXEC dbo.k_people_delete_status @occ = @occ1;
			FETCH NEXT FROM curs1 INTO @occ1		
		END
		CLOSE curs1
		DEALLOCATE curs1;
		--=================================================================================
		RAISERROR (N'удаляем логи по пени по лицевым которых нет пени', 10, 1) WITH NOWAIT;
		DELETE pl 
		FROM Penalty_log AS pl
		WHERE NOT EXISTS(SELECT * FROM dbo.Peny_all AS pa WHERE pa.occ=pl.occ);

		--=================================================================================

		RAISERROR (N'удаляем старые записи в Op_log_mode', 10, 1) WITH NOWAIT;
		DELETE FROM [dbo].[Op_log_mode]
		WHERE done<DATEADD(MONTH,-12,current_timestamp);
		--=================================================================================

		RAISERROR (N'устанавливаем occ_sup_uid там где пусто', 10, 1) WITH NOWAIT;
		UPDATE t1
		SET occ_sup_uid = COALESCE((
			SELECT TOP (1) occ_sup_uid
			FROM dbo.Occ_Suppliers AS t2 
			WHERE t2.occ = t1.occ
				AND t2.sup_id = t1.sup_id
				AND t2.occ_sup_uid IS NOT NULL
			ORDER BY t2.fin_id
		), dbo.fn_newid())
		FROM dbo.Occ_Suppliers AS t1
		WHERE t1.occ_sup_uid IS NULL

		--=================================================================================
		RAISERROR (N'удаляем строки Consmodes_list по Крем без поставщика если есть с поставщиком', 10, 1) WITH NOWAIT;
		--SELECT TOP (1000) cl.*
		DELETE cl
		FROM dbo.Consmodes_list cl
			JOIN dbo.VOcc as o 
			ON cl.occ=o.occ
		where 1=1
		--and o.build_id=6922
		and cl.service_id='Крем'
		and cl.sup_id=0
		and EXISTS(SELECT count(*)  FROM [Consmodes_list] cl2 WHERE cl2.occ=cl.occ AND cl2.service_id=cl.service_id HAVING count(*)>1)
		--ORDER BY cl.occ

		--=================================================================================
		RAISERROR (N'очищаем поле с доп информацией по дому в квитанции', 10, 1) WITH NOWAIT;
		--SELECT id, tip_id, b.account_rich
		UPDATE b set account_rich=null
		FROM Buildings as b 
		where DATALENGTH(account_rich)<250 -- там rtf коды в пустом значении
		--=================================================================================

		CHECKPOINT		

		SET @msg = CONCAT('(прошло ', CONVERT(VARCHAR(10), current_timestamp - @start_time, 108), ')')
		RAISERROR (N'ОК. %s', 10, 1, @msg) WITH NOWAIT;
go

