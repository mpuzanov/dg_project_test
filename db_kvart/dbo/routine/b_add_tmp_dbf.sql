CREATE   PROCEDURE [dbo].[b_add_tmp_dbf]
(
	@filename1  VARCHAR(100)
   ,@datafile1  DATETIME
   ,@bank_id1   VARCHAR(10)
   ,@msg_out	VARCHAR(200) = '' OUTPUT
   ,@rasschet   VARCHAR(20)	 = NULL
   ,@filedbf_id INT			 = 0 OUTPUT   -- код занесённого в базу файла
)
AS
	/*

  Добавляем платежи из временного файла в основной

DECLARE	@return_value int,
		@msg_out varchar(200)

EXEC	@return_value = [dbo].[b_add_tmp_dbf]
		@filename1 = N'51014102016.csv',
		@datafile1 = N'20161014',
		@bank_id1 = N'S96',
		@msg_out = @msg_out OUTPUT

SELECT	@msg_out as N'@msg_out'

*/
	SET NOCOUNT ON


	DECLARE @trancount INT;
	SET @trancount = @@trancount;

	DECLARE @DB_NAME VARCHAR(20) = UPPER(DB_NAME())
		,@sysuser varchar(30)=system_user

	SELECT
		@datafile1 = dbo.Fun_GetOnlyDate(@datafile1)

	IF EXISTS (SELECT
				1
			FROM dbo.BANK_DBF_TMP AS b
			LEFT JOIN dbo.View_PAYCOLL_ORGS AS p
				ON b.bank_id = p.ext
			WHERE ext IS NULL
				AND FILENAMEDBF = @filename1
				AND sysuser = @sysuser)
	BEGIN
		SET @msg_out = 'Найден файл неизвестного банка: ' + @filename1
		EXEC dbo.b_addbank_error @msg_out
		RETURN 0
	END

	IF EXISTS (SELECT
				1
			FROM dbo.Bank_dbf_tmp
			WHERE 
				ABS(DATEDIFF(DAY, DATA_PAYM, pdate)) > 31
				AND FILENAMEDBF = @filename1
				AND sysuser = @sysuser)
	BEGIN
		SET @msg_out = 'Даты платежей не совпадают с датай файла ' + @filename1
		EXEC dbo.b_addbank_error @msg_out
		RETURN 0
	END

	--print @filename1 

	-- если такой файл уже вводили в базу
	IF EXISTS (SELECT
				1
			FROM dbo.Bank_tbl_spisok
			WHERE 
				datafile = @datafile1
				AND FILENAMEDBF = @filename1)
	BEGIN
		SET @msg_out = 'Файл: ' + @filename1 + ' уже есть в базе данных'
		RETURN 0;
	END

	BEGIN TRY

		DECLARE @Kol			INT
			   ,@Summa			DECIMAL(15, 2)
			   ,@sup_processing TINYINT -- обрабатываемые платежи; 0-все,1-только от поставщиков, 2 - без поставщиков

		SELECT TOP 1
			@sup_processing = sup_processing
		FROM dbo.Paycoll_orgs AS PO
		WHERE 
			ext = @bank_id1
		ORDER BY fin_id DESC;
		--PRINT @sup_processing

		-- таблица со списком типов фонда по которым может импортировать платежи пользователь
		DECLARE @t_tipe_user TABLE
			(
				tip_id SMALLINT
			)
		INSERT INTO @t_tipe_user
		(tip_id)
			SELECT
				ONLY_TIP_ID
			FROM dbo.Users_occ_types
			WHERE sysuser = system_user
		IF NOT EXISTS (SELECT
					1
				FROM @t_tipe_user)
		BEGIN -- если нет ограничения то добавляем все типы
			INSERT INTO @t_tipe_user
			(tip_id)
				SELECT
					id
				FROM dbo.Occupation_Types AS OT
		END
		-- ***********************************************

		SELECT
			@Kol = COUNT(*)
		   ,@Summa = SUM(sum_opl)
		FROM dbo.BANK_DBF_TMP
		WHERE FILENAMEDBF = @filename1
		and sysuser=@sysuser

		--print @Kol

		IF (@Summa = 0)
		BEGIN
			SET @msg_out = 'Файл: ' + @filename1 + ' сумма оплаты=0! Не импортировали.'
			RETURN 0;
		END

		UPDATE dbo.Bank_dbf_tmp
		SET sch_lic = Occ -- здесь будет храниться лицевой счет из файла(dbf) как есть
		WHERE 
			FILENAMEDBF = @filename1
			and sysuser=@sysuser
			AND Occ IS NOT NULL;

		UPDATE dbo.Bank_dbf_tmp
		SET Occ = NULL -- очищаем основное поле
		WHERE 
			FILENAMEDBF = @filename1
			and sysuser=@sysuser;

		UPDATE dbo.Bank_dbf_tmp
		SET service_id = NULL -- очищаем основное поле
		WHERE 
			FILENAMEDBF = @filename1
			and sysuser=@sysuser
			AND service_id = ''

		-- если существуют такие лицевые заносим в поле
		UPDATE b
		SET Occ = o.Occ
		FROM dbo.Bank_dbf_tmp AS b
		JOIN dbo.Occupations AS o
			ON b.sch_lic = o.Occ
		WHERE 
			FILENAMEDBF = @filename1
			and sysuser=@sysuser

		-- Определяем код услуги если платеж за конкретную услугу
		-- (длинный лицевой)
		UPDATE b
		SET service_id = dbo.Fun_GetService_idFromSchet(sch_lic) -- из лицевого услуги берем код услуги
		   ,Occ		   = dbo.Fun_GetOccFromSchet(sch_lic) -- из лицевого услуги берем лицевой счет квартиросьемщика
		   ,sup_id	   = dbo.Fun_GetSUPFromSchetl(sch_lic)
		   ,dog_int	   = dbo.Fun_GetDOGFromSchetl(sch_lic)
		FROM dbo.BANK_DBF_TMP AS b
		WHERE 
			sch_lic BETWEEN 1 AND 999999999 -- до 9 знаков
			AND FILENAMEDBF = @filename1
			and sysuser=@sysuser
			AND service_id IS NULL;

		-- проверяем начисляем ли по поставщику по этому лицевому
		UPDATE b
		SET Occ = NULL
		FROM dbo.Bank_dbf_tmp AS b
		WHERE 
			b.sup_id > 0
			AND FILENAMEDBF = @filename1
			and sysuser=@sysuser
			AND NOT EXISTS (SELECT
					1
				FROM dbo.Occ_Suppliers
				WHERE Occ = b.Occ)

		-- убираем ошибочные значения услуги
		UPDATE b
		SET service_id = NULL
		FROM dbo.Bank_dbf_tmp AS b
		WHERE 
			FILENAMEDBF = @filename1
			and sysuser=@sysuser
			AND service_id IS NOT NULL
			AND NOT EXISTS (SELECT
					1
				FROM dbo.SERVICES s
				WHERE s.id = b.service_id)

		-- убираем конкретную услугу у внутренних счётчиков
		UPDATE b
		SET service_id = NULL
		FROM dbo.Bank_dbf_tmp AS b
		JOIN dbo.Consmodes_list AS cl
			ON b.Occ = cl.Occ
			AND b.service_id = cl.service_id
		WHERE 
			sch_lic BETWEEN 1 AND 999999999 -- до 9 знаков
			AND	b.service_id IS NOT NULL
			AND cl.is_counter = 2;

		-- определяем ложные лицевые
		UPDATE b
		SET Occ = dbo.Fun_GetFalseOccIn(sch_lic)
		FROM dbo.Bank_dbf_tmp AS b
		WHERE 
			b.Occ IS NULL
			AND sch_lic BETWEEN 1 AND 999999999 -- до 9 знаков

		UPDATE b
		SET Occ = NULL
		FROM dbo.Bank_dbf_tmp AS b
		JOIN dbo.Occupations AS o
			ON b.Occ = o.Occ
		WHERE 
			FILENAMEDBF = @filename1
			and sysuser=@sysuser
			AND NOT EXISTS (SELECT
					1
				FROM @t_tipe_user t
				WHERE o.tip_id = t.tip_id) -- ограничиваем по типам фонда 12.10.12
		AND	b.sup_id = 0

		-- проверяем разрешено ли обрабатывать платежи по поставщику
		UPDATE b
		SET Occ =
			CASE
				WHEN @sup_processing = 1 AND
				b.sup_id = 0 THEN NULL
				WHEN @sup_processing = 2 AND
				b.sup_id > 0 THEN NULL
				ELSE b.Occ
			END
		FROM dbo.Bank_dbf_tmp AS b
		JOIN dbo.Occupations AS o
			ON b.Occ = o.Occ
		WHERE NOT (o.tip_id IN (38, 60, 57, 59, 60, 130)
			AND dbo.strpos('KOMP', UPPER(@DB_NAME)) > 0) -- в этих фондах ложные лицевые  -- 20.09.12
			AND b.FILENAMEDBF = @filename1
			and b.sysuser=@sysuser

		UPDATE b
		SET Occ = NULL
		FROM dbo.Bank_dbf_tmp AS b
		JOIN dbo.Occupations AS o
			ON b.Occ = o.Occ
		WHERE 
			FILENAMEDBF = @filename1
			and sysuser=@sysuser
			AND o.STATUS_ID = 'закр';

		-- очищаем лицевые, которых нет
		UPDATE b
		SET Occ = NULL
		FROM dbo.BANK_DBF_TMP AS b
		LEFT JOIN dbo.OCCUPATIONS AS o
			ON b.Occ = o.Occ
		WHERE FILENAMEDBF = @filename1
		and sysuser=@sysuser
		AND o.Occ IS NULL

		-- очищаем лицевые, по которым блокировка оплаты по типу фонда
		UPDATE b
		SET Occ = NULL
		FROM dbo.Bank_dbf_tmp AS b
		JOIN dbo.Occupations AS o
			ON b.Occ = o.Occ
		JOIN dbo.Occupation_Types AS OT
			ON o.tip_id = OT.id
		WHERE FILENAMEDBF = @filename1
		and sysuser=@sysuser
		AND OT.tip_paym_blocked = 1

		DECLARE @Procent  DECIMAL(6, 2) = 0
			   ,@comision DECIMAL(9, 2) = 0
			   ,@ostatok  DECIMAL(9, 2)
			   ,@koef	  DECIMAL(16, 8) -- коэф. для раскидки по услугам

		IF EXISTS (SELECT
					1
				FROM dbo.Bank_dbf_tmp
				WHERE 
					FILENAMEDBF = @filename1
					and sysuser=@sysuser
				HAVING SUM(COALESCE(commission, 0)) = 0)
		BEGIN -- Вычисляем коммиссию банка сами если она по файлу = 0
			SELECT TOP 1
				@Procent = comision
			FROM dbo.Paycoll_orgs 
			WHERE ext = @bank_id1
			ORDER BY fin_id DESC;

			IF @Procent <> 0
			BEGIN
				-- находим общую коммиссию по файлу
				SELECT
					@comision = @Summa * @Procent * 0.01
				SET @koef = @comision / @Summa

				UPDATE bd_tmp
				SET commission = sum_opl * @koef
				FROM dbo.Bank_dbf_tmp AS bd_tmp
				WHERE 
					FILENAMEDBF = @filename1
					and sysuser=@sysuser

				SELECT
					@ostatok = SUM(COALESCE(commission, 0))
				FROM dbo.Bank_dbf_tmp
				WHERE 
					FILENAMEDBF = @filename1
					and sysuser=@sysuser

				IF @ostatok <> @comision
				BEGIN
					SET @ostatok = @comision - @ostatok

					;with cte as (
					SELECT TOP (1) *
					FROM dbo.Bank_dbf_tmp AS bd_tmp
					WHERE 
						FILENAMEDBF = @filename1
						and sysuser=@sysuser
						AND commission > @ostatok
					)
					UPDATE cte
					SET commission = commission + @ostatok;
					
				END

			END --@Procent <> 0
		END

		SELECT
			@comision = SUM(COALESCE(commission, 0))
		FROM dbo.Bank_dbf_tmp AS bd_tmp
		WHERE 
			FILENAMEDBF = @filename1
			and sysuser=@sysuser;

		IF EXISTS (SELECT
					1
				FROM dbo.Bank_dbf_tmp AS b
				WHERE b.FILENAMEDBF = @filename1
				and sysuser=@sysuser
				AND b.sup_id = 0
				AND b.Occ IS NOT NULL
				AND EXISTS (SELECT
						1
					FROM dbo.Occ_Suppliers OS 
					JOIN dbo.Occupations O 
						ON OS.Occ = O.Occ
					JOIN dbo.Occupation_Types OT 
						ON O.tip_id = OT.id
						AND OS.fin_id = OT.fin_id
					WHERE b.sch_lic = OS.occ_sup))
		BEGIN
			SET @msg_out = 'Не получилось определить поставщика в файле: ' + @filename1
			EXEC dbo.b_addbank_error @msg_out
			RETURN 0
		END

		-- пробуем взять расч.счёт из имени файла (ищем 20 цифр)
		IF COALESCE(@rasschet, '') = ''
			AND PATINDEX('%[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]%', @filename1) > 0
			SET @rasschet = SUBSTRING(@filename1, PATINDEX('%[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]%', @filename1), 20)

		IF @trancount = 0
			BEGIN TRANSACTION
		ELSE
			SAVE TRANSACTION b_add_tmp_dbf;

		INSERT INTO dbo.BANK_TBL_SPISOK
		(FILENAMEDBF
		,datafile
		,bank_id
		,datavvoda
		,forwarded
		,kol
		,summa
		,commission
		,rasschet)
		VALUES (@filename1
			   ,@datafile1
			   ,@bank_id1
			   ,dbo.Fun_GetOnlyDate(current_timestamp)
			   ,0
			   ,@Kol
			   ,COALESCE(@Summa, 0)
			   ,COALESCE(@comision, 0)
			   ,@rasschet)

		SELECT
			@filedbf_id = SCOPE_IDENTITY()

		--*************************************
		--
		-- Добавляем платежи из временного файла в основной
		INSERT INTO dbo.BANK_DBF
		(bank_id
		,sum_opl
		,pdate
		,Occ
		,service_id
		,sch_lic
		,pack_id
		,adres
		,p_opl
		,filedbf_id
		,sup_id
		,commission
		,dog_int
		,rasschet)
			SELECT
				bank_id
			   ,sum_opl
			   ,pdate
			   ,Occ
			   ,CASE
					WHEN SERVICE_ID = '' THEN NULL
					ELSE SERVICE_ID
				END AS SERVICE_ID
			   ,sch_lic
			   ,pack_id
			   ,adres
			   ,p_opl
			   ,@filedbf_id
			   ,COALESCE(sup_id, 0)
			   ,COALESCE(commission, 0)
			   ,dog_int
			   , CASE
                     WHEN COALESCE(rasschet, '') = '' THEN @rasschet
                     ELSE rasschet
                END -- если расч.счёт пустой - берём из файла
			FROM dbo.Bank_dbf_tmp
			WHERE 
				FILENAMEDBF = @filename1
				and sysuser=@sysuser


		IF @trancount = 0
			COMMIT TRANSACTION;

		-- Проверяем правильность расч/счёта	
		UPDATE bd
		SET error_num = 1
		   ,Occ		  = NULL
		FROM dbo.Bank_Dbf bd
		JOIN dbo.Occupations o
			ON bd.Occ = o.Occ
		JOIN dbo.Occupation_Types ot
			ON o.tip_id = ot.id
		WHERE 
			pack_id IS NULL
			AND (bd.rasschet IS NOT NULL
			AND bd.rasschet <> '')
			AND ot.occ_prefix_tip IS NULL -- не ложные лицевые с префиксом
			AND bd.filedbf_id = @filedbf_id   -- только нового файла
			AND EXISTS (SELECT
					1
				FROM dbo.OCC_SUPPLIERS os1 
				WHERE os1.occ_sup = bd.sch_lic)
			AND NOT EXISTS (SELECT
					1
				FROM dbo.OCC_SUPPLIERS os2 
				WHERE os2.occ_sup = bd.sch_lic
				AND os2.rasschet = bd.rasschet)

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

		IF NOT EXISTS (SELECT
					1
				FROM dbo.Bank_tbl_spisok AS BTS
				WHERE FILENAMEDBF = @filename1)
		BEGIN
			SET @msg_out = 'Файл не ' + @filename1 + ' импортировали!!!'
			RETURN 0
		END
		ELSE
		BEGIN
			SET @msg_out = 'Файл ' + @filename1 + ' импортировали!'
			RETURN 0
		END

	END TRY
	BEGIN CATCH

		DECLARE @xstate INT;
		SELECT
			@xstate = XACT_STATE();
		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @trancount = 0
			ROLLBACK;
		IF @xstate = 1
			AND @trancount > 0
			ROLLBACK TRANSACTION b_add_tmp_dbf;

		EXEC dbo.k_err_messages

	END CATCH
go

