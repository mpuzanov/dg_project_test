CREATE   PROCEDURE [dbo].[b_add_tmp_org]
(
	@file		VARCHAR(100)  -- имя файла
   ,@er			INT OUTPUT   -- 0 - успешно, 1 - ошибка
   ,@filedbf_id INT = NULL OUTPUT   -- код занесённого в базу файла
)
AS
	/*
	 импорт платежей из организаций
	 перенос из временной таблицы в основную
	*/

	SET NOCOUNT ON;

	DECLARE @DB_NAME VARCHAR(20) = UPPER(DB_NAME())

	SET @er = 1 -- по умолчанию ошибка

	--проверяем не был ли этот файл уже занесен в базу
	IF EXISTS (SELECT
				1
			FROM dbo.BANK_TBL_SPISOK
			WHERE filenamedbf = @file)
	BEGIN
		RAISERROR ('Файл %s уже был загружен ранее!', 16, 10, @file)
		RETURN 1
	END

	-- проверяем все ли единые счета внесены в файл Excel
	IF EXISTS (SELECT
				1
			FROM dbo.BANK_DBF2_TMP
			WHERE occ IS NULL)
	BEGIN
		RAISERROR ('не все единые лицевые счета внесены!', 16, 10)
		RETURN 1
	END

	--проверяем все ли единые лицевые существуют
	DECLARE @t1 TABLE
		(
			occ INT
		)

	INSERT INTO @t1
		SELECT
			b.sch_lic
		FROM dbo.BANK_DBF2_TMP AS b
		LEFT JOIN dbo.OCCUPATIONS AS o
			ON b.occ = o.occ
		WHERE o.occ IS NULL

	IF EXISTS (SELECT
				1
			FROM @t1)
	BEGIN
		DECLARE @o1 INT
		SELECT TOP 1
			@o1 = occ
		FROM @t1
		RAISERROR ('Лицевого: %i  нет в базе!', 16, 10, @o1)
		RETURN 1
	END

	--проверяем зачения сумм платежа, они должны быть больше 0 и не равны Null
	IF EXISTS (SELECT
				1
			FROM dbo.BANK_DBF2_TMP
			WHERE sum_opl = 0
			OR sum_opl IS NULL)
	BEGIN
		RAISERROR ('не все суммы платежа внесены или одно из значений равно 0 !', 16, 10)
		RETURN 1
	END

	BEGIN TRY

		-- Определяем код услуги если платеж за конкретную услугу
		-- (длинный лицевой)
		UPDATE b
		SET service_id = dbo.Fun_GetService_idFromSchet(sch_lic) -- из лицевого услуги берем код услуги
		   ,occ		   = dbo.Fun_GetOccFromSchet(sch_lic) -- из лицевого услуги берем лицевой счет квартиросьемщика
		   ,sup_id	   = dbo.Fun_GetSUPFromSchetl(sch_lic)
		   ,dog_int	   = dbo.Fun_GetDOGFromSchetl(sch_lic)
		FROM dbo.BANK_DBF2_TMP AS b
		WHERE sch_lic BETWEEN 1 AND 999999999 -- до 9 знаков
		AND
		filenamedbf = @file
		AND service_id IS NULL

		-- определяем ложные лицевые
		UPDATE b
		SET occ = dbo.Fun_GetFalseOccIn(sch_lic)
		FROM dbo.BANK_DBF2_TMP AS b
		WHERE b.occ IS NULL

		UPDATE b
		SET occ = NULL
		FROM dbo.BANK_DBF2_TMP AS b
		JOIN dbo.OCCUPATIONS AS o
			ON b.occ = o.occ
		WHERE filenamedbf = @file
		AND o.status_id = 'закр'

		-- убираем ошибочные значения услуги
		UPDATE b
		SET service_id = NULL
		FROM dbo.BANK_DBF2_TMP AS b
		WHERE filenamedbf = @file
		AND service_id IS NOT NULL
		AND NOT EXISTS (SELECT
				1
			FROM dbo.SERVICES s
			WHERE s.Id = b.service_id)


		DECLARE @Kol	   INT
			   ,@Summa	   DECIMAL(15, 2)
			   ,@data_paym SMALLDATETIME
			   ,@bank	   VARCHAR(10)
			   ,@DBF_TIP   SMALLINT
			   ,@comision  DECIMAL(9, 2) = 0

		SELECT
			@Kol = COUNT(*)
		   ,@Summa = SUM(sum_opl)
		   ,@comision = SUM(COALESCE(commission, 0))
		   ,@data_paym = DATA_PAYM
		   ,@bank = bank_id
		FROM dbo.BANK_DBF2_TMP
		WHERE filenamedbf = @file
		GROUP BY DATA_PAYM
				,bank_id

		IF EXISTS (SELECT
					1
				FROM [dbo].[View_PAYCOLL_ORGS]
				WHERE ext = @bank
				AND is_bank = 1)
			SELECT
				@DBF_TIP = 1
		ELSE
			SELECT
				@DBF_TIP = 2


		IF EXISTS (SELECT
					1
				FROM dbo.BANK_DBF2_TMP AS b
				WHERE b.filenamedbf = @file
				AND b.sup_id = 0
				AND b.occ IS NOT NULL
				AND EXISTS (SELECT
						1
					FROM dbo.OCC_SUPPLIERS OS 
					JOIN dbo.OCCUPATIONS O
						ON OS.occ = O.occ
					JOIN dbo.OCCUPATION_TYPES OT 
						ON O.tip_id = OT.Id
						AND OS.fin_id = OT.fin_id
					WHERE OS.occ_sup = b.sch_lic))
		BEGIN
			RAISERROR ('Не получилось определить поставщика в файле: %s', 16, 10, @file)
			--EXEC dbo.b_addbank_error @msg_out
			RETURN 0
		END

		BEGIN TRAN

		--данные о файле заносятся в таблицу, для последующей проверки не был ли этот файл уже занесен в базу
		INSERT INTO dbo.BANK_TBL_SPISOK
		(filenamedbf
		,datafile
		,bank_id
		,kol
		,forwarded
		,summa
		,datavvoda
		,dbf_tip
		,commission)
		VALUES (@file
			   ,@data_paym
			   ,@bank
			   ,@Kol
			   ,0
			   ,@Summa
			   ,dbo.Fun_GetOnlyDate(current_timestamp)
			   ,@DBF_TIP
			   ,COALESCE(@comision, 0))
		SELECT
			@filedbf_id = SCOPE_IDENTITY()

		-------------------------------------------------------
		--если все нормально, данные из временной таблицы заносятся в рабочую таблицу

		INSERT INTO dbo.BANK_DBF
		(filedbf_id
		,bank_id
		,sch_lic
		,sum_opl
		,pdate
		,p_opl
		,occ
		,service_id
		,adres
		,pack_id
		,date_edit
		,sup_id
		,dog_int
		,dbf_tip
		,commission)
			SELECT
				@filedbf_id
			   ,bank_id
			   ,sch_lic
			   ,sum_opl
			   ,dbo.Fun_GetOnlyDate(pdate)
			   ,p_opl
			   ,occ
			   ,service_id =
					CASE
						WHEN service_id = '' THEN NULL
						ELSE service_id
					END
				--, service_id 
			   ,SUBSTRING(adres,1,90)
			   ,pack_id
			   ,date_edit
			   ,COALESCE(sup_id, 0)
			   ,dog_int
			   ,@DBF_TIP
			   ,COALESCE(commission, 0)
			FROM BANK_DBF2_TMP AS bt
			WHERE filenamedbf = @file

		DELETE FROM dbo.BANK_DBF2_TMP

		SET @er = 0

		COMMIT TRAN
	--------------------------------------------------------
	END TRY
	BEGIN CATCH

		EXEC dbo.k_err_messages

	END CATCH
go

