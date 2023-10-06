-- =============================================
-- Author:		Пузанов
-- Create date: 22.09.2011
-- Description:	Загрузка данных
-- =============================================
CREATE             PROCEDURE [dbo].[adm_load_people]
	  @OCC INT
	, @LAST_NAME VARCHAR(50)
	, @FIRST_NAME VARCHAR(30)
	, @SEC_NAME VARCHAR(30)
	, @STATUS2_ID VARCHAR(10)
	, @FAM_ID VARCHAR(10)
	, @BIRTHDATE DATETIME
	, @DATEREG DATETIME
	, @DateEnd DATETIME = NULL
	, @DOLA_PRIV1 SMALLINT
	, @DOLA_PRIV2 SMALLINT
	, @SEX SMALLINT = NULL  -- 0-жен, 1-муж, 2-организация
	, @DOCTYPE_ID VARCHAR(10)
	, @DOC_NO VARCHAR(12)
	, @PASSSER_NO VARCHAR(12)
	, @ISSUED DATETIME
	, @DOCORG VARCHAR(100)
	, @KOD_PVS VARCHAR(7)
	, @DateDel DATETIME = NULL
	, @owner_id INT = NULL OUTPUT
	, @people_uid UNIQUEIDENTIFIER = NULL OUTPUT
	, @doc_privat VARCHAR(50) = NULL
	, @only_fio_join BIT = 0  -- соединяем только по ФИО (без даты рождения, по умолчанию)
	, @comment VARCHAR(50) = NULL
	, @debug BIT = 0
	, @strerror VARCHAR(4000) = '' OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON

	SELECT @LAST_NAME = LTRIM(@LAST_NAME)
		 , @FIRST_NAME = LTRIM(COALESCE(@FIRST_NAME, ''))
		 , @SEC_NAME = LTRIM(COALESCE(@SEC_NAME, ''))
		 , @only_fio_join = COALESCE(@only_fio_join, 0)

	--IF UPPER(db_name()) in ('KOMP','KVART','NAIM') AND @OCC<99999999 RETURN

	DECLARE @doc_id INT
		  , @new_occ INT = NULL
		  , @fio VARCHAR(50)
		  , @status_id VARCHAR(10)

	IF @LAST_NAME IS NULL
		RETURN
	SET @fio = @LAST_NAME + ' ' + SUBSTRING(@FIRST_NAME, 1, 1) + '.' + SUBSTRING(@SEC_NAME, 1, 1) + '.'

	IF OBJECT_ID(N'dbo.ERROR_LOAD') IS NULL
		CREATE TABLE dbo.ERROR_LOAD (
			  date_load DATETIME DEFAULT current_timestamp PRIMARY KEY
			, occ INT
			, FIO VARCHAR(35) COLLATE database_default
			, [name] VARCHAR(80) COLLATE database_default
		)

	SELECT @new_occ = occ
		 , @status_id = Status_id
	FROM dbo.Occupations
	WHERE occ = @OCC
	-- если такого лицевого нет в базе то пропускаем 
	IF @new_occ IS NULL
		RETURN

	IF @status_id = 'закр'
		RETURN

	IF @SEX IS NULL
	BEGIN -- попробуем определить пол
		SELECT @SEX=(SELECT TOP(1) sex
					FROM dbo.people 
					WHERE First_name=@FIRST_NAME
					AND sex IS NOT NULL
					GROUP BY sex HAVING COUNT(id)>3)
	END

	BEGIN TRY
		IF YEAR(@BIRTHDATE) > 2050
			OR YEAR(@BIRTHDATE) < 1900
		BEGIN
			WAITFOR DELAY '00:00:00.050'
			INSERT INTO dbo.ERROR_LOAD (occ
									  , FIO
									  , name)
			VALUES(@new_occ
				 , @fio
				 , 'Дата рождения ')
			SET @BIRTHDATE = NULL
		END
		IF YEAR(@DATEREG) > 2050
			OR YEAR(@DATEREG) < 1900
		BEGIN
			WAITFOR DELAY '00:00:00.050'
			INSERT INTO dbo.ERROR_LOAD (occ
									  , FIO
									  , name)
			VALUES(@new_occ
				 , @fio
				 , 'Дата регистрации')
			SET @DATEREG = NULL
		END
		IF @BIRTHDATE > @DATEREG
		BEGIN
			WAITFOR DELAY '00:00:00.050'
			INSERT INTO dbo.ERROR_LOAD (occ
									  , FIO
									  , name)
			VALUES(@new_occ
				 , @fio
				 , 'Дата регистрации < Даты рождения')
			SET @DATEREG = NULL
		END

		IF @only_fio_join = 1
			AND @owner_id IS NULL
			SELECT @owner_id = id
			FROM dbo.People
			WHERE Last_name = @LAST_NAME
				AND First_name = @FIRST_NAME
				AND Second_name = @SEC_NAME
				AND @only_fio_join = 1
				AND occ = @OCC
				AND COALESCE(DateDel, '19000101') = COALESCE(@DateDel, '19000101')
		
		-- проверяем гражданина
		IF @owner_id IS NULL
			AND NOT EXISTS (
				SELECT 1
				FROM dbo.People
				WHERE (Last_name = @LAST_NAME AND First_name = @FIRST_NAME AND Second_name = @SEC_NAME 
				AND occ = @OCC AND @only_fio_join = 0 
				AND COALESCE(Birthdate, '19000101') = COALESCE(@BIRTHDATE, '19000101')
				AND COALESCE(DateDel, '19000101') = COALESCE(@DateDel, '19000101')
					)
			)
		BEGIN
			IF @debug = 1 PRINT 'добавляем'
			IF NOT EXISTS (
					SELECT 1
					FROM dbo.Fam_relations AS fr 
					WHERE fr.id = @FAM_ID
				)
				SET @FAM_ID = '????'

			--SELECT @owner_id = COALESCE(MAX(id), 0) + 1 FROM dbo.PEOPLE

			SELECT @owner_id = NEXT VALUE FOR dbo.GeneratePeolpleSequence

			INSERT INTO dbo.People (id
								  , occ
								  , Last_name
								  , First_name
								  , Second_name
								  , Status2_id
								  , Fam_id
								  , Birthdate
								  , DateReg
								  , DateEnd
								  , sex
								  , Dola_priv1
								  , Dola_priv2
								  , doc_privat
								  , Comments)
			VALUES(@owner_id
				 , @new_occ
				 , @LAST_NAME
				 , @FIRST_NAME
				 , @SEC_NAME
				 , @STATUS2_ID
				 , @FAM_ID
				 , CAST(@BIRTHDATE AS SMALLDATETIME)
				 , CAST(@DATEREG AS SMALLDATETIME)
				 , CASE
					   WHEN (@STATUS2_ID <> N'пост') THEN CAST(@DateEnd AS SMALLDATETIME)
					   ELSE NULL
				   END
				 , @SEX
				 , @DOLA_PRIV1
				 , @DOLA_PRIV2
				 , @doc_privat
				 , COALESCE(@comment,'загрузка из файла')
				 )

		--UPDATE dbo.KEY_ID
		--SET key_max = (SELECT
		--		COALESCE(MAX(id), 0)
		--	FROM dbo.PEOPLE)
		--WHERE id = 2

		END
		ELSE
		BEGIN
			IF @owner_id IS NULL
				SELECT @owner_id=id
				FROM dbo.People
				WHERE Last_name = @LAST_NAME 
					AND First_name = @FIRST_NAME 
					AND Second_name = @SEC_NAME 
					AND occ = @OCC AND @only_fio_join = 0 
					AND COALESCE(Birthdate, '19000101') = COALESCE(@BIRTHDATE, '19000101')
					AND COALESCE(DateDel, '19000101') = COALESCE(@DateDel, '19000101')
			
			IF @debug=1 PRINT 'нашли в бд'	+ str(@owner_id)
		END

		SELECT @people_uid = people_uid
		FROM dbo.People
		WHERE id = @owner_id
		
		IF @debug=1 PRINT CONCAT('owner_id=',@owner_id, ', people_uid=', CAST(@people_uid AS VARCHAR(40)) ) 

		UPDATE dbo.People 
		SET Status2_id = @STATUS2_ID
		  , Dola_priv1 = @DOLA_PRIV1
		  , Dola_priv2 = @DOLA_PRIV2
		  , Birthdate = CAST(@BIRTHDATE AS SMALLDATETIME)
		  , DateReg = CAST(@DATEREG AS SMALLDATETIME)
		  , DateEnd =
					 CASE
						 WHEN (@STATUS2_ID <> N'пост') THEN CAST(@DateEnd AS SMALLDATETIME)
						 ELSE DateEnd
					 END
		  , DateDel = @DateDel
		  , Del = CASE
                      WHEN @DateDel IS NOT NULL THEN 1
                      ELSE 0
            END
		  , sex = CASE
                      WHEN sex is NULL THEN @SEX
                      ELSE sex
            END
		WHERE id = @owner_id

		---- проверяем документ
		IF COALESCE(@DOCTYPE_ID, '') <> ''
			SELECT @DOCTYPE_ID = LOWER(@DOCTYPE_ID)
		IF @DOCTYPE_ID IN (N'свид')
			SELECT @DOCTYPE_ID = N'свдр'

		IF NOT EXISTS (
				SELECT 1
				FROM dbo.Iddoc
				WHERE owner_id = @owner_id
					AND doc_no = @DOC_NO
					AND PASSSER_NO = @PASSSER_NO
			)
			AND COALESCE(@DOC_NO, '') <> ''
			AND COALESCE(@DOCTYPE_ID, '') <> ''
		BEGIN --добавляем документ

			IF YEAR(@ISSUED) > 2074
				OR YEAR(@ISSUED) < 1900
			BEGIN
				INSERT INTO dbo.ERROR_LOAD (occ
										  , FIO
										  , name)
				VALUES(@new_occ
					 , @fio
					 , N'Дата выдачи документа')
				SET @ISSUED = NULL
			END

			IF NOT EXISTS (
					SELECT 1
					FROM dbo.Iddoc_types
					WHERE id = @DOCTYPE_ID
				)
			BEGIN
				RAISERROR (N'Тип документа <%s> не найден!', 16, 1, @DOCTYPE_ID)				
			END

			INSERT INTO dbo.Iddoc (owner_id
								 , active
								 , DOCTYPE_ID
								 , doc_no
								 , PASSSER_NO
								 , ISSUED
								 , DOCORG
								 , user_edit
								 , date_edit
								 , kod_pvs)
			VALUES(@owner_id
				 , 1
				 , @DOCTYPE_ID
				 , COALESCE(@DOC_NO, '')
				 , COALESCE(@PASSSER_NO, '')
				 , COALESCE(CAST(@ISSUED AS SMALLDATETIME), '19000101')
				 , COALESCE(@DOCORG, '')
				 , NULL
				 , current_timestamp
				 , @KOD_PVS)

			SELECT @doc_id = SCOPE_IDENTITY()
		END

		UPDATE dbo.Occupations 
		SET kol_people = dbo.Fun_GetKolPeopleOccStatus(@OCC)
		WHERE occ = @OCC

	END TRY

	BEGIN CATCH

		EXECUTE k_GetErrorInfo @visible = 0 --@debug
							 , @strerror = @strerror OUT
		SET @strerror = @strerror + N'Лицевой: ' + LTRIM(STR(@OCC))

		RAISERROR (@strerror, 16, 1)

	END CATCH

END
go

