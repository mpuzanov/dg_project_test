CREATE   PROCEDURE [dbo].[k_people_add]
(
	@occ1	   INT
   ,@owner_new INT = 0 OUT
)
AS
	/*
	Добавление человека в базу
	создается код человека и
	заводятся обязательные поля
	*/
	SET NOCOUNT ON
	SET XACT_ABORT ON;

	DECLARE @trancount INT;
	SET @trancount = @@trancount;

	IF dbo.Fun_GetRejimOcc(@occ1) <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END
	
	IF NOT EXISTS(SELECT 1 FROM dbo.AccessAddPeople)
	BEGIN
		RAISERROR ('У вас нет прав прописки-выписки граждан', 16, 1)
		RETURN
	END

	DECLARE @id1	  INT
		   ,@DateReg  SMALLDATETIME
		   ,@People1  VARCHAR(10)
		   ,@err	  INT
		   ,@comments VARCHAR(30)

	IF EXISTS (SELECT
				1
			FROM dbo.OCCUPATIONS O 
			JOIN dbo.OCCUPATION_TYPES OT
				ON OT.id = O.tip_id
			WHERE O.Occ = @occ1
			AND OT.people_reg_blocked = CAST(1 AS BIT))
	BEGIN
		RAISERROR ('Тип фонда закрыт для регистрации граждан!', 16, 1)
		RETURN
	END

	IF EXISTS (SELECT
				1
			FROM dbo.OCCUPATIONS O 
			JOIN dbo.FLATS F
				ON O.flat_id = F.id
			JOIN dbo.BUILDINGS AS b 
				ON F.bldn_id = b.id
			WHERE O.Occ = @occ1
			AND b.people_reg_blocked = CAST(1 AS BIT))
	BEGIN
		RAISERROR ('В доме закрыта регистрация граждан!', 16, 1)
		RETURN
	END

	IF EXISTS (SELECT
				1
			FROM dbo.PEOPLE 
			WHERE Occ = @occ1
			AND DateDel IS NULL)
		-- Если уже существуют люди на этом лицевом счете
		SET @People1 = '????'
	ELSE
		-- то первый прописанный является ответств. квартиросъемщиком
		SET @People1 = 'отвл'

	SET @DateReg = DATEADD(dd, DATEDIFF(dd, '', current_timestamp), '')

	BEGIN TRY
		IF @trancount = 0
			BEGIN TRANSACTION
			ELSE
				SAVE TRANSACTION k_people_add;

			--EXEC @id1 = dbo.k_people_next -- новое значение ключа
			SET @id1 = NEXT VALUE FOR dbo.GeneratePeolpleSequence; -- новое значение ключа

			INSERT
			INTO dbo.PEOPLE
			(id
			,Occ
			,Last_name
			,First_name
			,Second_name
			,Fam_id
			,DateReg)
			VALUES (@id1
				   ,@occ1
				   ,''
				   ,''
				   ,''
				   ,@People1
				   ,@DateReg)

			--select @id1=SCOPE_IDENTITY()
			SELECT
				@owner_new = @id1

			IF @trancount = 0
			COMMIT TRANSACTION;

		EXEC dbo.k_occ_status @occ1

		SELECT
			@id1 AS id

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
			ROLLBACK TRANSACTION k_people_add;

		DECLARE @strerror VARCHAR(4000) = ''
		EXECUTE k_GetErrorInfo @visible = 0
							  ,@strerror = @strerror OUT
		RAISERROR (@strerror, 16, 1)

	END CATCH
go

