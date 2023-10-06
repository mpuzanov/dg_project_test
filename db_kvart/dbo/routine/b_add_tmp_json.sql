CREATE   PROCEDURE [dbo].[b_add_tmp_json]
(
	  @FileJson NVARCHAR(MAX)
	, @msg_out VARCHAR(200) = '' OUTPUT
	, @filedbf_id INT = 0 OUTPUT   -- код занесённого в базу файла
	, @debug BIT = 0
)
AS
	/*
	
	Добавляем платежи из файла json
	
	-- Тест процедуры импорта файла с платежами в формате json
	DECLARE @RC int
	DECLARE @FileJson nvarchar(max)
	DECLARE @msg_out varchar(200)
	DECLARE @filedbf_id int
	DECLARE @debug bit
	
	SET @FileJson =  
	N'
	{
	    "filename": "654010919.xls",
	    "datafile": "01.09.2019",
	    "bank_id": "987",
	    "rasschet_file": null,
		"format_name": "Формат файла",
	    "data": [
	        {
	            "number": 1,
	            "occ": 341537,
	            "dataplat": "2019-09-13T00:00:00.000Z",
	            "adres": "Машиностроитель пос. д.56 кв.1",
	            "summa": 958.45,
	            "commission": 0,
	            "rasschet": null,
	            "fio": "",
	            "service_id": ""
	        },
	        {
	            "number": 2,
	            "occ": 341538,
	            "dataplat": "2019-09-23T00:00:00.000Z",
	            "adres": "Машиностроитель пос. д.56 кв.2",
	            "summa": 2000,
	            "commission": 0,
	            "rasschet": null,
	            "fio": "",
	            "service_id": ""
	        }
	    ]
	}
	'
	EXECUTE @RC = [dbo].[b_add_tmp_json] 
	   @FileJson
	  ,@msg_out OUTPUT
	  ,@filedbf_id OUTPUT
	  ,@debug=1
	
	SELECT @filedbf_id, @msg_out
	
	
	DECLARE	@return_value int
	EXEC	@return_value = [dbo].[b_paymdel_dbf]
			@filedbf_id = @filedbf_id
	SELECT	'Return Value' = @return_value
	
	*/
	SET NOCOUNT ON

	DECLARE @tran_count INT
		  , @tran_name VARCHAR(50) = 'b_add_tmp_json'
	SET @tran_count = @@trancount;

	DECLARE @DB_NAME VARCHAR(20) = UPPER(DB_NAME())
		  , @filename1 VARCHAR(100)
		  , @datafile1 DATETIME
		  , @bank_id1 VARCHAR(10)
		  , @rasschet_file VARCHAR(20) = NULL
		  , @format_name VARCHAR(30) = NULL
		  , @CntUpdateRow INT

	SELECT @datafile1 = dbo.Fun_GetOnlyDate(@datafile1)
		 , @filedbf_id = 0

	-- проверяем файл 
	IF @FileJson IS NULL
		OR ISJSON(@FileJson) = 0
	BEGIN
		SET @msg_out = N'Входной файл не в JSON формате'
		IF @debug = 1
			PRINT @msg_out
		EXEC dbo.b_addbank_error @msg_out
		RETURN 0
	END

	CREATE TABLE #File_TMP (
		  [ID] INT IDENTITY (1, 1) NOT NULL
		, [PDATE] DATETIME NOT NULL
		, [OCC] INT NULL
		, [SUM_OPL] DECIMAL(9, 2) NOT NULL
		, [COMMISSION] DECIMAL(9, 2) NULL
		, [ADRES] VARCHAR(100) COLLATE database_default NULL
		, [FIO] VARCHAR(50) COLLATE database_default NULL
		, [SERVICE_ID] CHAR(4) COLLATE database_default NULL
		, [SCH_LIC] BIGINT NULL
		, [PACK_ID] INT NULL
		, [P_OPL] SMALLINT NULL
		, [SUP_ID] INT NULL
		, [DOG_INT] INT NULL
		, [rasschet] VARCHAR(20) COLLATE database_default NULL
		, [data_edit] SMALLDATETIME DEFAULT current_timestamp
		, [sysuser] VARCHAR(30) COLLATE database_default DEFAULT SUSER_SNAME()
		, PRIMARY KEY (ID)
	)
	CREATE INDEX SCH_LIC ON #File_TMP (SCH_LIC)

	-- переносим данные из JSON
	SELECT @filename1 = t1.filename
		 , @datafile1 = dbo.Fun_GetOnlyDate(t1.datafile)
		 , @bank_id1 = t1.bank_id
		 , @rasschet_file = t1.rasschet_file
		 , @format_name = t1.format_name
	FROM OPENJSON(@FileJson)
	WITH (
	FILENAME NVARCHAR(100) '$."filename"',
	datafile DATETIME '$."datafile"',
	bank_id NVARCHAR(10) '$."bank_id"',
	RASSCHET_FILE VARCHAR(20) '$."rasschet_file"',
	format_name VARCHAR(30) '$."format_name"'
	) AS t1;


	INSERT #File_TMP
		(OCC
	   , FIO
	   , ADRES
	   , PDATE
	   , SERVICE_ID
	   , COMMISSION
	   , SUM_OPL
	   , rasschet)
	SELECT j2.OCC
		 , j2.FIO
		 , j2.ADRES
		 , j2.dataplat
		 , j2.SERVICE_ID
		 , j2.COMMISSION
		 , j2.summa
		 , j2.rasschet
	FROM OPENJSON(@FileJson, '$.data')
	WITH (
	OCC BIGINT '$.occ',
	FIO NVARCHAR(50) '$."fio"',
	ADRES NVARCHAR(100) '$."adres"',
	DATAPLAT DATETIME '$."dataplat"',
	COMMISSION DECIMAL(9, 2) '$."commission"',
	summa DECIMAL(9, 2) '$."summa"',
	rasschet VARCHAR(20) '$."rasschet"',
	SERVICE_ID VARCHAR(10) '$."service_id"'
	) AS j2

	IF @debug = 1 
		SELECT 'На входе', * FROM #File_TMP bdt;

	--RETURN

	IF EXISTS (
			SELECT 1
			FROM #File_TMP AS b
				LEFT JOIN dbo.View_paycoll_orgs AS p 
					ON @bank_id1 = p.ext
			WHERE ext IS NULL
		)
	BEGIN
		SET @msg_out = CONCAT('Найден файл неизвестного банка: ' , @filename1)
		EXEC dbo.b_addbank_error @msg_out
		IF @debug = 1
			PRINT @msg_out
		RETURN 0
	END

	-- если такой файл уже вводили в базу
	IF EXISTS (
			SELECT 1
			FROM dbo.Bank_tbl_spisok
			WHERE datafile = @datafile1
				AND filenamedbf = @filename1
		)
	BEGIN
		SET @msg_out = CONCAT('Файл: ' , @filename1 , ' уже есть в базе данных')
		IF @debug = 1
			PRINT @msg_out
		RETURN 0;
	END

	BEGIN TRY

		DECLARE @Kol INT
			  , @Summa DECIMAL(15, 2)
			  , @sup_processing TINYINT -- обрабатываемые платежи; 0-все,1-только от поставщиков, 2 - без поставщиков

		SELECT TOP (1) @sup_processing = sup_processing
		FROM dbo.Paycoll_orgs AS PO
		WHERE ext = @bank_id1
		ORDER BY fin_id DESC;
		--PRINT @sup_processing

		-- таблица со списком типов фонда по которым может импортировать платежи пользователь
		DECLARE @t_tipe_user TABLE (
			  tip_id SMALLINT
		)
		INSERT INTO @t_tipe_user
			(tip_id)
		SELECT ONLY_TIP_ID
		FROM dbo.Users_occ_types
		WHERE sysuser = system_user
		IF NOT EXISTS (SELECT 1 FROM @t_tipe_user)
		BEGIN -- если нет ограничения то добавляем все типы
			INSERT INTO @t_tipe_user
				(tip_id)
			SELECT ID
			FROM dbo.Occupation_Types AS OT
		END
		-- ***********************************************

		SELECT @Kol = COUNT(*)
			 , @Summa = SUM(SUM_OPL)
		FROM #File_TMP

		--print @Kol

		IF (@Kol = 0)
		BEGIN
			SET @msg_out = N'Файл: ' + @filename1 + N' не импортировали. (кол-во записей 0)'
			IF @debug = 1
				PRINT @msg_out
			RETURN 0;
		END

		UPDATE #File_TMP
		SET SCH_LIC = OCC -- здесь будет храниться лицевой счет из файла(dbf) как есть
		WHERE OCC IS NOT NULL;

		UPDATE #File_TMP
		SET OCC = NULL -- очищаем основное поле
		WHERE 1=1

		UPDATE #File_TMP
		SET SERVICE_ID = NULL -- очищаем основное поле
		WHERE SERVICE_ID = ''

		-- убираем ошибочные значения услуги
		UPDATE b
		SET SERVICE_ID = NULL
		FROM #File_TMP AS b
		WHERE SERVICE_ID IS NOT NULL
			AND NOT EXISTS (
				SELECT 1
				FROM dbo.Services s
				WHERE s.ID = b.SERVICE_ID
			)

		-- если существуют такие лицевые заносим в поле
		UPDATE b
		SET OCC = o.OCC
		FROM #File_TMP AS b
			JOIN dbo.Occupations AS o ON b.SCH_LIC = o.OCC

		-- Определяем код услуги если платеж за конкретную услугу
		-- (длинный лицевой)
		UPDATE b
		SET SERVICE_ID = dbo.Fun_GetService_idFromSchet(SCH_LIC) -- из лицевого услуги берем код услуги
		  , OCC = dbo.Fun_GetOccFromSchet(SCH_LIC) -- из лицевого услуги берем лицевой счет квартиросьемщика
		  , SUP_ID = dbo.Fun_GetSUPFromSchetl(SCH_LIC)
		  , DOG_INT = dbo.Fun_GetDOGFromSchetl(SCH_LIC)
		FROM #File_TMP AS b
		WHERE 
			SCH_LIC BETWEEN 1 AND 999999999 -- до 9 знаков
			AND SERVICE_ID IS NULL

		-- проверяем начисляем ли по поставщику по этому лицевому
		UPDATE b
		SET OCC = NULL
		FROM #File_TMP AS b
		WHERE b.SUP_ID > 0
			AND NOT EXISTS (
				SELECT 1
				FROM dbo.Occ_Suppliers
				WHERE OCC = b.OCC
			)

		-- убираем конкретную услугу у внутренних счётчиков
		UPDATE b
		SET SERVICE_ID = NULL
		FROM #File_TMP AS b
			JOIN dbo.Consmodes_list AS cl ON b.OCC = cl.OCC
				AND b.SERVICE_ID = cl.SERVICE_ID
		WHERE 
			SCH_LIC BETWEEN 1 AND 999999999 -- до 9 знаков
			AND	b.SERVICE_ID IS NOT NULL
			AND cl.is_counter = 2

		-- определяем ложные лицевые
		UPDATE b
		SET OCC = dbo.Fun_GetFalseOccIn(SCH_LIC)
		FROM #File_TMP AS b
		WHERE 
			b.OCC IS NULL
			AND SCH_LIC BETWEEN 1 AND 999999999 -- до 9 знаков

		UPDATE b
		SET OCC = NULL
		FROM #File_TMP AS b
			JOIN dbo.Occupations AS o ON b.OCC = o.OCC
		WHERE
			NOT EXISTS (
				SELECT 1
				FROM @t_tipe_user t
				WHERE o.tip_id = t.tip_id
			) -- ограничиваем по типам фонда 12.10.12
			AND	b.SUP_ID = 0

		-- проверяем разрешено ли обрабатывать платежи по поставщику
		UPDATE b
		SET OCC =
				 CASE
					 WHEN @sup_processing = 1 AND
						 b.SUP_ID = 0 THEN NULL
					 WHEN @sup_processing = 2 AND
						 b.SUP_ID > 0 THEN NULL
					 ELSE b.OCC
				 END
		FROM #File_TMP AS b
			JOIN dbo.Occupations AS o ON b.OCC = o.OCC
		WHERE NOT (o.tip_id IN (38, 60, 57, 59, 60, 130) 
			AND dbo.strpos('KOMP', @DB_NAME) > 0) -- в этих фондах ложные лицевые  -- 20.09.12

		UPDATE b
		SET OCC = NULL
		FROM #File_TMP AS b
			JOIN dbo.Occupations AS o 
				ON b.OCC = o.OCC
		WHERE o.status_id = 'закр'

		-- очищаем лицевые, которых нет
		UPDATE b
		SET OCC = NULL
		FROM #File_TMP AS b
			LEFT JOIN dbo.Occupations AS o 
				ON b.OCC = o.OCC
		WHERE o.OCC IS NULL

		-- очищаем лицевые, по которым блокировка оплаты по типу фонда
		UPDATE b
		SET OCC = NULL
		FROM #File_TMP AS b
			JOIN dbo.Occupations AS o 
				ON b.OCC = o.OCC
			JOIN dbo.Occupation_Types AS OT 
				ON o.tip_id = OT.ID
		WHERE OT.tip_paym_blocked = CAST(1 AS BIT)

		DECLARE @Procent DECIMAL(6, 2) = 0
			  , @comision DECIMAL(9, 2) = 0
			  , @ostatok DECIMAL(9, 2)
			  , @koef DECIMAL(16, 8) -- коэф. для раскидки по услугам

		IF EXISTS (
				SELECT 1
				FROM #File_TMP
				HAVING SUM(COALESCE(COMMISSION, 0)) = 0
			)
		BEGIN -- Вычисляем коммиссию банка сами если она по файлу = 0
			SELECT TOP 1 @Procent = comision
			FROM dbo.Paycoll_orgs 
			WHERE ext = @bank_id1
			ORDER BY fin_id DESC

			IF @Procent <> 0
			BEGIN
				-- находим общую коммиссию по файлу
				SELECT @comision = @Summa * @Procent * 0.01
				SET @koef = @comision / @Summa

				UPDATE bd_tmp
				SET COMMISSION = SUM_OPL * @koef
				FROM #File_TMP AS bd_tmp

				SELECT @ostatok = SUM(COALESCE(COMMISSION, 0))
				FROM #File_TMP

				IF @ostatok <> @comision
				BEGIN
					SET @ostatok = @comision - @ostatok

					;with cte as (
					SELECT TOP (1) *
					FROM #File_TMP AS bd_tmp
					WHERE 	
						commission > @ostatok
					)
					UPDATE cte
					SET commission = commission + @ostatok;
				END

			END --@Procent <> 0
		END

		SELECT @comision = SUM(COALESCE(COMMISSION, 0))
		FROM #File_TMP AS bd_tmp

		IF EXISTS (
				SELECT 1
				FROM #File_TMP AS b
				WHERE b.SUP_ID = 0
					AND b.OCC IS NOT NULL
					AND EXISTS (
						SELECT 1
						FROM dbo.Occ_Suppliers OS 
							JOIN dbo.Occupations O ON OS.OCC = O.OCC
							JOIN dbo.Occupation_Types OT ON O.tip_id = OT.ID
								AND OS.fin_id = OT.fin_id
						WHERE b.SCH_LIC = OS.occ_sup
					)
			)
		BEGIN
			SET @msg_out = N'Не получилось определить поставщика в файле: ' + @filename1
			EXEC dbo.b_addbank_error @msg_out
			IF @debug = 1
				PRINT @msg_out
			RETURN 0
		END

		-- пробуем взять расч.счёт из имени файла (ищем 20 цифр)
		IF COALESCE(@rasschet_file, '') = ''
			AND PATINDEX('%[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]%', @filename1) > 0
			SET @rasschet_file = SUBSTRING(@filename1, PATINDEX('%[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]%', @filename1), 20)


		IF @debug = 1 SELECT 'Обработан', * FROM #File_TMP bdt

		IF @tran_count = 0
			BEGIN TRANSACTION
		ELSE
			SAVE TRANSACTION @tran_name;

		INSERT INTO dbo.Bank_tbl_spisok
			(filenamedbf
		   , datafile
		   , bank_id
		   , datavvoda
		   , forwarded
		   , kol
		   , summa
		   , COMMISSION
		   , rasschet
		   , format_name
		   , sysuser)
			VALUES (@filename1
				  , @datafile1
				  , @bank_id1
				  , dbo.Fun_GetOnlyDate(current_timestamp)
				  , 0
				  , @Kol
				  , COALESCE(@Summa, 0)
				  , COALESCE(@comision, 0)
				  , @rasschet_file
				  , @format_name
				  , (
						SELECT TOP (1) [login]
						FROM dbo.Users
						WHERE [login] = SUSER_SNAME()
					))

		SELECT @filedbf_id = SCOPE_IDENTITY();

		--*************************************
		--
		-- Добавляем платежи из временного файла в основной
		INSERT INTO dbo.Bank_Dbf
			(bank_id
		   , SUM_OPL
		   , PDATE
		   , OCC
		   , SERVICE_ID
		   , SCH_LIC
		   , PACK_ID
		   , ADRES
		   , P_OPL
		   , filedbf_id
		   , SUP_ID
		   , COMMISSION
		   , DOG_INT
		   , rasschet
		   , FIO)
		SELECT @bank_id1
			 , SUM_OPL
			 , PDATE
			 , OCC
			 , CASE
                   WHEN SERVICE_ID = '' THEN NULL
                   ELSE SERVICE_ID
            END AS SERVICE_ID
			 , SCH_LIC
			 , PACK_ID
			 , SUBSTRING(adres,1,90)
			 , P_OPL
			 , @filedbf_id
			 , COALESCE(SUP_ID, 0)
			 , COALESCE(COMMISSION, 0)
			 , DOG_INT
			 , CASE
                   WHEN COALESCE(rasschet, '') = '' THEN @rasschet_file
                   ELSE rasschet
            END -- если расч.счёт пустой - берём из файла
			 , FIO
		FROM #File_TMP;

		IF @tran_count = 0
			COMMIT TRANSACTION;

		---- Проверяем правильность расч/счёта	
		UPDATE bd
		SET error_num = 1
		  , OCC = NULL
		FROM dbo.Bank_Dbf bd
			JOIN dbo.Occupations o 
				ON bd.OCC = o.OCC
			JOIN dbo.Occupation_Types ot 
				ON o.tip_id = ot.ID
		WHERE 
			PACK_ID IS NULL
			AND COALESCE(bd.rasschet,'')<>''
			AND COALESCE(ot.occ_prefix_tip,'')='' -- не ложные лицевые с префиксом
			AND bd.filedbf_id = @filedbf_id   -- только нового файла
			AND (
			EXISTS (
				SELECT 1
				FROM dbo.Occ_Suppliers os2
				WHERE os2.occ_sup = bd.SCH_LIC
					AND os2.rasschet <> bd.rasschet
			) 
			OR EXISTS (
				SELECT 1
				FROM dbo.Intprint i 
				WHERE i.OCC = bd.SCH_LIC
					--AND i.fin_id=ot.fin_id
					AND i.rasschet <> bd.rasschet
			)
			)
		SET @CntUpdateRow = @@ROWCOUNT 
		IF @debug=1
			SELECT @CntUpdateRow AS 'Ошибок правильности расч/счёта'

		--UPDATE bd SET error_num = 1,occ=NULL
		--FROM dbo.BANK_DBF bd
		--JOIN dbo.OCC_SUPPLIERS os1 
		-- ON os1.occ=bd.occ 
		--	AND os1.occ_sup=bd.SCH_LIC
		--WHERE (COALESCE(bd.rasschet,'')<>'')
		--AND os1.rasschet<>bd.rasschet

		--UPDATE bd SET error_num = 2
		--FROM dbo.BANK_DBF bd
		--WHERE OCC IS NULL

		IF @debug = 1
			SELECT 'Bank_tbl_spisok', *	FROM dbo.Bank_tbl_spisok WHERE filedbf_id = @filedbf_id;
		IF @debug = 1 
			SELECT 'Bank_Dbf', * FROM dbo.Bank_Dbf bd WHERE filedbf_id = @filedbf_id;

		IF NOT EXISTS (
				SELECT 1
				FROM dbo.Bank_tbl_spisok AS BTS
				WHERE filenamedbf = @filename1
			)
		BEGIN
			SET @msg_out = N'Файл не ' + @filename1 + N' импортировали!!!'
			IF @debug = 1
				PRINT @msg_out
			RETURN 0
		END
		ELSE
		BEGIN
			SET @msg_out = N'Файл ' + @filename1 + N' импортировали!'
			IF @debug = 1
				PRINT @msg_out
			RETURN 0
		END

		DROP TABLE IF EXISTS #File_TMP;
	END TRY
	BEGIN CATCH

		DECLARE @xstate INT;
		SELECT @xstate = XACT_STATE();
		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @tran_count = 0
			ROLLBACK;
		IF @xstate = 1
			AND @tran_count > 0
			ROLLBACK TRANSACTION @tran_name;

		EXEC dbo.k_err_messages

	END CATCH
go

