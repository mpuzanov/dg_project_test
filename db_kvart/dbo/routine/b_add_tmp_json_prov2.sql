CREATE   PROCEDURE [dbo].[b_add_tmp_json_prov2]
(
	  @FileJson NVARCHAR(MAX)
	, @FileJson_out NVARCHAR(MAX) = '' OUTPUT
	, @msg_out VARCHAR(200) = '' OUTPUT
	, @debug BIT = 0
)
AS
	/*

Проверяем платежи из файла json

-- Тест процедуры проверки файла с платежами в формате json
DECLARE @RC int
DECLARE @FileJsonIn nvarchar(max)
DECLARE @FileJson_out nvarchar(max)
DECLARE @msg_out varchar(200)
DECLARE @debug bit

SET @FileJsonIn =  
N'
{
    "filename": "654010919_test.xls",
    "datafile": "01.09.2019",
    "bank_id": "987",
    "rasschet_file": null,
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
EXECUTE @RC = [dbo].[b_add_tmp_json_prov] 
   @FileJson = @FileJsonIn
  ,@FileJson_out = @FileJson_out OUTPUT
  ,@msg_out = @msg_out OUTPUT
  ,@debug=1

SELECT @msg_out as msg_out, @FileJson_out as FileJson_out

*/
	SET NOCOUNT ON

	DECLARE @trancount INT;
	SET @trancount = @@trancount;

	DECLARE @DB_NAME VARCHAR(20) = UPPER(DB_NAME())
		  , @filename1 VARCHAR(100)
		  , @datafile1 DATETIME
		  , @bank_id1 VARCHAR(4)
		  , @rasschet_file VARCHAR(20) = NULL
	--, @FileJson_out NVARCHAR(MAX) = ''

	SELECT @datafile1 = dbo.Fun_GetOnlyDate(@datafile1)
		 , @msg_out = ''

	-- проверяем файл 
	IF @FileJson IS NULL
		OR ISJSON(@FileJson) = 0
	BEGIN
		SET @msg_out = 'Входной файл не в JSON формате'
		IF @debug = 1
			PRINT @msg_out
		RETURN 0
	END

	CREATE TABLE #File_TMP (
		  [id] INT IDENTITY (1, 1) NOT NULL
		, [pdate] DATETIME NULL
		, [occ] INT NULL
		, [sum_opl] DECIMAL(9, 2) NULL
		, [commission] DECIMAL(9, 2) NULL
		, [adres] VARCHAR(100) COLLATE database_default NULL
		, [fio] VARCHAR(50) COLLATE database_default NULL
		, [service_id] VARCHAR(10) COLLATE database_default NULL
		, [sch_lic] BIGINT NULL
		, [pack_id] INT NULL
		, [p_opl] SMALLINT NULL
		, [sup_id] INT NULL
		, [dog_int] INT NULL
		, [rasschet] VARCHAR(20) COLLATE database_default NULL
		, error VARCHAR(50) COLLATE database_default NULL
		, [data_edit] SMALLDATETIME DEFAULT current_timestamp
		, [sysuser] VARCHAR(30) COLLATE database_default DEFAULT SUSER_SNAME()
		, PRIMARY KEY (id)
	)
	--CREATE INDEX occ ON #File_TMP (occ)
	--CREATE INDEX sch_lic ON #File_TMP (sch_lic)

	-- переносим данные из JSON
	SELECT @filename1 = j1.filename
		 , @datafile1 = j1.datafile
		 , @bank_id1 = j1.bank_id
		 , @rasschet_file = j1.rasschet_file
	FROM OPENJSON(@FileJson)
	WITH (
	FILENAME NVARCHAR(100) '$."filename"',
	datafile DATETIME '$."datafile"',
	bank_id NVARCHAR(4) '$."bank_id"',
	RASSCHET_FILE VARCHAR(20) '$."rasschet_file"'
	) AS j1


	INSERT #File_TMP (occ
					, sch_lic
					, fio
					, adres
					, pdate
					, service_id
					, commission
					, sum_opl
					, rasschet)
	SELECT j2.occ
		 , j2.occ
		 , j2.fio
		 , j2.adres
		 , j2.dataplat
		 , CASE
               WHEN j2.service_id = '' THEN NULL
               ELSE j2.service_id
        END
		 , j2.commission
		 , COALESCE(j2.summa, 0)
		 , j2.rasschet
	FROM OPENJSON(@FileJson, '$.data')
	WITH (
	occ BIGINT '$.occ',
	fio NVARCHAR(50) '$."fio"',
	adres NVARCHAR(100) '$."adres"',
	dataplat DATETIME '$."dataplat"',
	commission DECIMAL(9, 2) '$."commission"',
	summa DECIMAL(9, 2) '$."summa"',
	rasschet VARCHAR(20) '$."rasschet"',
	service_id VARCHAR(10) '$."service_id"'
	) AS j2

	IF @debug = 1
		SELECT *
		FROM #File_TMP bdt

	--RETURN

	IF NOT EXISTS (
			SELECT 1
			FROM dbo.Paycoll_orgs AS p
			WHERE p.ext = @bank_id1
		)
	BEGIN
		SET @msg_out = 'Найден файл неизвестного банка: ' + @filename1
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
		SET @msg_out = 'Файл: ' + @filename1 + ' уже есть в базе данных'
		IF @debug = 1
			PRINT @msg_out
		RETURN 0;
	END

	BEGIN TRY

		DECLARE @Kol INT
			  , @Summa DECIMAL(15, 2)
			  , @sup_processing TINYINT -- обрабатываемые платежи; 0-все,1-только от поставщиков, 2 - без поставщиков

		SELECT TOP 1 @sup_processing = sup_processing
		FROM dbo.Paycoll_orgs AS PO
		WHERE ext = @bank_id1
		ORDER BY fin_id DESC
		--PRINT @sup_processing

		---- таблица со списком типов фонда по которым может импортировать платежи пользователь
		--DECLARE @t_tipe_user TABLE (
		--	  tip_id SMALLINT
		--)
		--INSERT INTO @t_tipe_user (tip_id)
		--SELECT ONLY_TIP_ID
		--FROM dbo.Users_occ_types
		--WHERE sysuser = system_user
		--IF NOT EXISTS (SELECT 1 FROM @t_tipe_user)
		--BEGIN -- если нет ограничения то добавляем все типы
		--	INSERT INTO @t_tipe_user (tip_id)
		--	SELECT id
		--	FROM dbo.Occupation_Types AS OT
		--END
		---- ***********************************************

		SELECT @Kol = COUNT(*)
			 , @Summa = SUM(sum_opl)
		FROM #File_TMP

		--print @Kol

		IF (@Kol = 0)
		BEGIN
			SET @msg_out = 'Файл: ' + @filename1 + ' не импортировали. (кол-во записей 0)'
			IF @debug = 1
				PRINT @msg_out
			RETURN 0;
		END

		-- Определяем код услуги если платеж за конкретную услугу
		-- (длинный лицевой)
		UPDATE b
		SET service_id = dbo.Fun_GetService_idFromSchet(sch_lic) -- из лицевого услуги берем код услуги
		  , occ = dbo.Fun_GetOccFromSchet(sch_lic) -- из лицевого услуги берем лицевой счет квартиросьемщика
		  , sup_id = dbo.Fun_GetSUPFromSchetl(sch_lic)
		  , dog_int = dbo.Fun_GetDOGFromSchetl(sch_lic)
		FROM #File_TMP AS b
		WHERE sch_lic > 1 -- BETWEEN 1 AND 999999999 -- до 9 знаков
			AND service_id IS NULL


		-- убираем ошибочные значения услуги
		UPDATE b
		SET error = 'ошибочные значения услуги'
		FROM #File_TMP AS b
			LEFT JOIN dbo.Services s ON s.id = b.service_id
		WHERE b.service_id IS NOT NULL
			AND s.id IS NULL

		-- проверяем начисляем ли по поставщику по этому лицевому
		UPDATE b
		SET error = 'поставщик лицевому не начисляет'
		FROM #File_TMP AS b
			LEFT JOIN dbo.Occ_Suppliers os ON os.occ = b.occ
		WHERE b.sup_id > 0
			AND os.occ IS NULL

		-- убираем конкретную услугу у внутренних счётчиков
		UPDATE b
		SET service_id = NULL
		FROM #File_TMP AS b
			JOIN dbo.Consmodes_list AS cl ON b.occ = cl.occ
				AND b.service_id = cl.service_id
		WHERE sch_lic > 1 -- BETWEEN 1 AND 999999999 -- до 9 знаков
			AND
			b.service_id IS NOT NULL
			AND cl.is_counter = 2

		-- проверяем разрешено ли обрабатывать платежи по поставщику
		UPDATE b
		SET error =
				   CASE
					   WHEN @sup_processing = 1 AND
						   b.sup_id = 0 THEN 'запрещено обрабатывать платежи по поставщику'
					   WHEN @sup_processing = 2 AND
						   b.sup_id > 0 THEN 'запрещено обрабатывать платежи по поставщику'
					   ELSE error
				   END
		FROM #File_TMP AS b
			JOIN dbo.Occupations AS o 
				ON b.occ = o.occ
		WHERE NOT (o.tip_id IN (38, 60, 57, 59, 60, 130) AND dbo.strpos('KOMP', @DB_NAME) > 0) -- в этих фондах ложные лицевые  -- 20.09.12


		UPDATE b
		SET error =
				   CASE
					   WHEN o.status_id = 'закр' THEN 'лицевой закрыт'
					   WHEN o.occ IS NULL THEN 'лицевой ' +LTRIM(STR(sch_lic)) + ' не найден'
					   WHEN b.sum_opl = 0 THEN 'сумма = 0'
					   WHEN b.pdate IS NULL THEN 'Дата платежа не заполнена'
					   WHEN OT.tip_paym_blocked = 1 THEN 'блокировка оплаты по типу фонда'
				   END
		FROM #File_TMP AS b
			LEFT JOIN dbo.Occupations AS o ON b.occ = o.occ
			LEFT JOIN dbo.Occupation_Types AS OT ON o.tip_id = OT.id

		IF EXISTS (
				SELECT 1
				FROM #File_TMP AS b
				WHERE b.sup_id = 0
					AND b.occ IS NOT NULL
					AND EXISTS (
						SELECT 1
						FROM dbo.Occ_Suppliers OS
							JOIN dbo.Occupations O ON OS.occ = O.occ
							JOIN dbo.Occupation_Types OT ON O.tip_id = OT.id
								AND OS.fin_id = OT.fin_id
						WHERE b.sch_lic = OS.occ_sup
					)
			)
		BEGIN
			SET @msg_out = 'Не получилось определить поставщика в файле: ' + @filename1
			IF @debug = 1
				PRINT @msg_out
			RETURN 0
		END

		-- пробуем взять расч.счёт из имени файла (ищем 20 цифр)
		IF COALESCE(@rasschet_file, '') = ''
			AND PATINDEX('%[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]%', @filename1) > 0
			SET @rasschet_file = SUBSTRING(@filename1, PATINDEX('%[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]%', @filename1), 20)


		-- Проверяем правильность расч/счёта	
		--UPDATE bd
		--SET error_num = 1
		--   ,OCC		  = NULL
		--FROM dbo.BANK_DBF bd
		--JOIN dbo.OCCUPATIONS o
		--	ON bd.OCC = o.OCC
		--JOIN dbo.OCCUPATION_TYPES ot
		--	ON o.tip_id = ot.ID
		--WHERE PACK_ID IS NULL
		--AND (bd.rasschet IS NOT NULL
		--AND bd.rasschet <> '')
		--AND ot.occ_prefix_tip IS NULL -- не ложные лицевые с префиксом
		--AND bd.filedbf_id = @filedbf_id   -- только нового файла
		--AND EXISTS (SELECT
		--		1
		--	FROM dbo.OCC_SUPPLIERS os1
		--	WHERE os1.occ_sup = bd.SCH_LIC)
		--AND NOT EXISTS (SELECT
		--		1
		--	FROM dbo.OCC_SUPPLIERS os2
		--	WHERE os2.occ_sup = bd.SCH_LIC
		--	AND os2.rasschet = bd.rasschet)

		SET @FileJson_out = (
			SELECT id
				 , pdate
				 , occ
				 , sum_opl
				 , commission
				 , adres
				 , fio
				 , service_id
				 , sch_lic
				 , pack_id
				 , p_opl
				 , sup_id
				 , dog_int
				 , rasschet
				 , error
				 , data_edit
				 , sysuser
			FROM #File_TMP
			FOR JSON PATH, ROOT ('bank_payments')
		)

	--SELECT
	--	@msg_out AS msg_out
	--   ,@FileJson_out AS FileJson_out

	END TRY
	BEGIN CATCH

		DECLARE @xstate INT;
		SELECT @xstate = XACT_STATE();
		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @trancount = 0
			ROLLBACK;

		EXEC dbo.k_err_messages

	END CATCH
go

