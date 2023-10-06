CREATE   PROCEDURE [dbo].[k_people_add_basa]
(
	  @occ1 INT -- код лицевого
	, @owner_id1 INT -- код человека для прописки по лицевому @occ1
	, @lgota_add1 BIT = 1 -- со льготой если есть

)
AS
/* 
 Добавление человека из базы
 (он был выписан из другой квартиры)
*/

	IF dbo.Fun_GetRejimOcc(@occ1) <> N'норм'
	BEGIN
		RAISERROR (N'База закрыта для редактирования!', 16, 1)
	END

	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE @tran_count INT
		  , @tran_name VARCHAR(50) = 'k_people_add_basa'
	SET @tran_count = @@trancount;

	DECLARE @id1 INT
		  , @DateReg SMALLDATETIME
		  , @Fam_id1 VARCHAR(10)

	BEGIN TRY

		IF EXISTS (
				SELECT 1
				FROM dbo.People 
				WHERE Occ = @occ1
					AND DateDel IS NULL
			)
			-- Если уже существуют люди на этом лицевом счете
			SET @Fam_id1 = '????'
		ELSE
			-- то первый прописанный является ответств. квартиросъемщиком
			SET @Fam_id1 = N'отвл'

		SET @DateReg = DATEADD(dd, DATEDIFF(dd, '', current_timestamp), '')

		--=============================================
		DECLARE @Last_name1 VARCHAR(50)
			  , @First_name1 VARCHAR(30)
			  , @Second_name1 VARCHAR(30)
			  , @Initials_people VARCHAR(60)
			  , @Status_id1 TINYINT
			  , @Status2_id1 VARCHAR(10)
			  , @Birthdate1 SMALLDATETIME
			  , @sex1 TINYINT
			  , @Military1 TINYINT
			  , @Criminal1 TINYINT
			  , @doxod1 DECIMAL(9, 2)
			  , @lgota_id1 SMALLINT
			  , @lgota_kod1 INT

		SELECT @Last_name1 = last_name
			 , @First_name1 = first_name
			 , @Second_name1 = second_name
			 , @Initials_people = p.Initials_people
			 , @Status_id1 = status_id
			 , @Status2_id1 = status2_id
			 , @Birthdate1 = Birthdate
			 , @sex1 = sex
			 , @Military1 = Military
			 , @Criminal1 = Criminal
			 , @doxod1 = Doxod
			 , @lgota_id1 = lgota_id
			 , @lgota_kod1 = lgota_kod
		FROM dbo.VPeople AS p 
		WHERE id = @owner_id1

		--=============================================
		DECLARE @DOCTYPE_ID1 VARCHAR(10)
			  , @PASSSER_NO1 VARCHAR(12)
			  , @DOC_NO1 VARCHAR(12)
			  , @ISSUED1 SMALLDATETIME
			  , @DOCORG1 VARCHAR(50)

		SELECT TOP (1) @DOCTYPE_ID1 = DOCTYPE_ID
					 , @PASSSER_NO1 = PASSSER_NO
					 , @DOC_NO1 = doc_no
					 , @ISSUED1 = issued
					 , @DOCORG1 = DOCORG
		FROM dbo.Iddoc AS t1 
		WHERE t1.owner_id = @owner_id1
			AND active = 1
		--=============================================
		DECLARE @KraiBirth1 VARCHAR(50)
			  , @RaionBirth1 VARCHAR(30)
			  , @TownBirth1 VARCHAR(30)
			  , @VillageBirth1 VARCHAR(30)
			  , @KraiOld1 VARCHAR(50)
			  , @TownOld1 VARCHAR(30)
			  , @StreetOld1 VARCHAR(30)
			  , @Nom_domOld1 VARCHAR(12)
			  , @Nom_kvrOld1 VARCHAR(20)

		SELECT @KraiBirth1 = KraiBirth
			 , @RaionBirth1 = RaionBirth
			 , @TownBirth1 = TownBirth
			 , @VillageBirth1 = VillageBirth
		FROM dbo.People_2 
		WHERE owner_id = @owner_id1

		SELECT TOP 1 @KraiOld1 = Region
				   , @TownOld1 = Town
		FROM dbo.Global_values
		ORDER BY fin_id DESC

		SELECT @StreetOld1 = s.name
			 , @Nom_domOld1 = b.nom_dom
			 , @Nom_kvrOld1 = f.nom_kvr
		FROM dbo.People AS p 
			JOIN dbo.Occupations AS o ON p.Occ = o.Occ
			JOIN dbo.Flats AS f ON o.flat_id = f.id
			JOIN dbo.Buildings AS b ON f.bldn_id = b.id
			JOIN dbo.VStreets AS s ON b.street_id = s.id
		WHERE p.id = @owner_id1


		--=============================================
		DECLARE @dscgroup_id1 SMALLINT
			  , @issued_lgota1 SMALLDATETIME
			  , @issued_lgota2 SMALLDATETIME
			  , @expire_date1 SMALLDATETIME
			  , @doc1 VARCHAR(50)

		IF @lgota_kod1 IS NOT NULL
		BEGIN
			SELECT @dscgroup_id1 = dscgroup_id
				 , @issued_lgota1 = issued
				 , @issued_lgota2 = issued2
				 , @expire_date1 = expire_date
				 , @doc1 = doc
			FROM dbo.Dsc_owners 
			WHERE id = @lgota_kod1
		END
		--=============================================

		IF @tran_count = 0
			BEGIN TRANSACTION
		ELSE
			SAVE TRANSACTION @tran_name;

		--EXEC @id1 = dbo.k_people_next -- новое значение ключа
		SET @id1 = NEXT VALUE FOR dbo.GeneratePeolpleSequence;

		INSERT INTO dbo.People (id
							  , Occ
							  , last_name
							  , first_name
							  , second_name
							  , Fam_id
							  , DateReg
							  , status_id
							  , status2_id
							  , Birthdate
							  , sex
							  , Military
							  , Criminal
							  , Doxod)
		VALUES(@id1
			 , @occ1
			 , @Last_name1
			 , @First_name1
			 , @Second_name1
			 , @Fam_id1
			 , @DateReg
			 , @Status_id1
			 , @Status2_id1
			 , @Birthdate1
			 , @sex1
			 , @Military1
			 , @Criminal1
			 , @doxod1)

		--select @id1=SCOPE_IDENTITY()
		IF @tran_count = 0
			COMMIT TRANSACTION;

		DECLARE @people_uid_new UNIQUEIDENTIFIER
		SELECT @people_uid_new = people_uid
		FROM People
		WHERE id = @id1;

		-- обновляем статус лицевого(открыт, свободен, закрыт)
		EXEC k_occ_status @occ1

		-- добавляем паспортные дынные
		IF @DOCTYPE_ID1 IS NOT NULL
			EXEC dbo.k_pasport_add @id1
								 , @DOCTYPE_ID1
								 , @DOC_NO1
								 , @PASSSER_NO1
								 , @ISSUED1
								 , @DOCORG1

		-- Добавляем историю проживания
		IF NOT EXISTS (
				SELECT *
				FROM People_2 p
				WHERE p.owner_id = @id1
			)
			INSERT INTO dbo.People_2 (owner_id
									, KraiBirth
									, RaionBirth
									, TownBirth
									, VillageBirth
									, KraiOld
									, TownOld
									, StreetOld
									, Nom_domOld
									, Nom_kvrOld)
			VALUES(@id1
				 , @KraiBirth1
				 , @RaionBirth1
				 , @TownBirth1
				 , @VillageBirth1
				 , @KraiOld1
				 , @TownOld1
				 , @StreetOld1
				 , @Nom_domOld1
				 , @Nom_kvrOld1)

		-- Добавляем льготы если есть
		IF (@lgota_kod1 IS NOT NULL)
			AND (@lgota_add1 = 1)
			AND @dscgroup_id1 IS NOT NULL
			EXEC dbo.k_dsc_add @id1
							 , @dscgroup_id1
							 , @doc1
							 , @issued_lgota1
							 , @issued_lgota2
							 , @expire_date1

		-- сохраняем в историю изменений
		DECLARE @comments VARCHAR(30) = N'из базы: ' + @Initials_people

		EXEC k_write_log @occ1
					   , N'прчл'
					   , @comments

		SELECT @id1 AS id
			 , @people_uid_new AS people_uid_new

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

		DECLARE @str_error VARCHAR(4000) = ''
		EXECUTE k_GetErrorInfo @visible = 0
							 , @strerror = @str_error OUT
		RAISERROR (@str_error, 16, 1)

	END CATCH
go

