CREATE   PROCEDURE [dbo].[b_platezh_redact_port]
(
	@file VARCHAR(30)
   ,@er	  INT OUTPUT
)
AS
	/*
		-- импорт платежей из организаций
		-- перенос из временной таблицы в основную
	*/

	SET NOCOUNT ON;

	SET @er = 1 -- по умолчанию ошибка

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
		RAISERROR ('Лицевого: %i  нет в базе!', 16, 1, @o1)
		RETURN 1
	END

	--проверяем зачения сумм платежа, они должны быть больше 0 и не равны Null
	IF EXISTS (SELECT
				1
			FROM dbo.BANK_DBF2_TMP
			WHERE sum_opl = 0
			OR sum_opl IS NULL)
	BEGIN
		RAISERROR ('не все суммы платежа внесены или одно из значений равно 0 !', 16, 1)
		RETURN 1
	END

	--проверяем не был ли этот файл уже занесен в базу
	IF EXISTS (SELECT
				1
			FROM dbo.BANK_TBL_SPISOK
			WHERE FILENAMEDBF = @file)
	BEGIN
		RAISERROR ('Файл %s уже был загружен ранее!', 16, 1, @file)
		RETURN 1
	END

	BEGIN TRY

		DECLARE @Kol		INT
			   ,@Summa		DECIMAL(15, 2)
			   ,@data_paym  SMALLDATETIME
			   ,@bank		VARCHAR(10)
			   ,@filedbf_id INT

		SELECT
			@Kol = COUNT(*)
		   ,@Summa = SUM(sum_opl)
		   ,@data_paym = DATA_PAYM
		   ,@bank = bank_id
		FROM dbo.BANK_DBF2_TMP
		WHERE FILENAMEDBF = @file
		GROUP BY DATA_PAYM
				,bank_id

		BEGIN TRAN

		--данные о файле заносятся в таблицу, для последующей проверки не был ли этот файл уже занесен в базу
		INSERT INTO dbo.BANK_TBL_SPISOK
		(FILENAMEDBF
		,datafile
		,bank_id
		,kol
		,forwarded
		,summa
		,datavvoda
		,dbf_tip)
		VALUES (@file
			   ,@data_paym
			   ,@bank
			   ,@Kol
			   ,0
			   ,@Summa
			   ,current_timestamp
			   ,2)

		SELECT
			@filedbf_id = SCOPE_IDENTITY()

		-------------------------------------------------------
		--если все нормально, данные из временной таблицы заносятся в рабочую таблицу

		INSERT INTO dbo.BANK_DBF
		(filedbf_id
		,bank_id
		,grp
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
		,dbf_tip)
			SELECT
				@filedbf_id
			   ,bank_id
			   ,grp
			   ,sch_lic
			   ,sum_opl
			   ,pdate
			   ,p_opl
			   ,occ
			   ,service_id
			   ,adres
			   ,pack_id
			   ,date_edit
			   ,COALESCE(sup_id, 0)
			   ,DBF_TIP = 2
			FROM BANK_DBF2_TMP AS bt
			WHERE FILENAMEDBF = @file

		DELETE FROM dbo.BANK_DBF2_TMP

		SET @er = 0

		COMMIT TRAN
	--------------------------------------------------------
	END TRY
	BEGIN CATCH

		EXEC dbo.k_err_messages

	END CATCH
go

