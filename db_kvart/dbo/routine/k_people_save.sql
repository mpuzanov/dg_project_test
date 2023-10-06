-- Проверяем введенные данные у человека
CREATE   PROCEDURE [dbo].[k_people_save]
(
	@id1			INT
	,@occ1			INT
	,@Fam_id1		VARCHAR(10)		= '????'
	,@peopleSave	BIT			OUTPUT
	,@Last_name		VARCHAR(50)	= NULL
	,@First_name	VARCHAR(30)	= NULL
	,@Second_name	VARCHAR(30)	= NULL
)
AS
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	
	DECLARE @trancount INT;
	SET @trancount = @@trancount;

	BEGIN TRY

	IF @Last_name IS NULL
		SET @Last_name = ''
	IF @First_name IS NULL
		SET @First_name = ''
	IF @Second_name IS NULL
		SET @Second_name = ''

	SELECT
		@peopleSave = 1
	-- На лицевом счете должен быть только один ответственный квартиросьемщик

	IF @Fam_id1 IS NULL
		OR @Fam_id1 = ''
	BEGIN
	    SELECT
			@peopleSave = 0
		RAISERROR (N'Укажите родственные отношения!', 16, 1)
	END

	DECLARE	@Fam_id2			VARCHAR(10) -- текущее значение 
			,@KolFam			SMALLINT
			,@id2				INT
			,@comments			VARCHAR(100)	= ''
			,@new				BIT -- признак что сохраняемый гражданин только что зарегистрирован
			,@Initials_people	VARCHAR(100)

	SELECT
		@Fam_id2 = Fam_id
		,@comments =
			CASE
				WHEN (p.Last_name = '') AND
				(@Last_name <> '') THEN 
				     CONCAT(p.Initials_people , '. (Код:' + LTRIM(STR(@id1)) , ')')
				ELSE CONCAT(p.Initials_people , '. (Код:' , LTRIM(STR(p.id)) , ')')
			END
		,@new = COALESCE(p.new, 0)
		,@Initials_people = p.Initials_people
	FROM dbo.VPeople AS p 
	WHERE id = @id1



	IF (@Fam_id1 = N'отвл')
		AND (@Fam_id1 <> @Fam_id2)
	BEGIN
		SELECT
			@id2 = id
		FROM dbo.People 
		WHERE occ = @occ1
			AND Fam_id = N'отвл'
			AND DateDel IS NULL

		IF @id1 IS NOT NULL
		BEGIN
			UPDATE dbo.People
			SET Fam_id = '????'
			WHERE id = @id2
		--       Raiserror ( 'У вас сменилось ответственное лицо! Необходимо указать статус прежнего владельца!!!',10,1) 
		END

	END
	--******На лицевом счете должен быть хотябы один ответственный квартиросьемщик
	IF (@Fam_id2 = 'отвл')
		AND (@Fam_id1 <> @Fam_id2)
	BEGIN
		SELECT
			@KolFam = COUNT(Fam_id)
		FROM dbo.People
		WHERE occ = @occ1
			AND Fam_id = 'отвл'
			AND DateDel IS NULL
		IF @KolFam = 1
		BEGIN
			SET	@peopleSave = 0
		    RAISERROR (N'Ответственное лицо убирать нельзя! Его можно сменить!!!', 16, 1)
		END
	END
	--***********************************
	-- сохраняем в историю изменений
	IF @new = 1
	BEGIN
		UPDATE dbo.PEOPLE
		SET new = 0
		WHERE id = @id1

		SET @comments = 'Регистрация гражданина: ' + @Initials_people + '(' + LTRIM(STR(@id1)) + ')'		
		EXEC dbo.k_write_log	@occ1=@occ1
								,@oper1=N'прчл'
								,@comments1=@comments
	END
	ELSE
		EXEC k_write_log	@occ1=@occ1
							,@oper1=N'рдчл'
							,@comments1=@comments

END TRY
	BEGIN CATCH
		DECLARE @xstate INT = XACT_STATE();
			
		IF @xstate = -1
			ROLLBACK;

		IF @xstate = 1
			AND @trancount = 0
			ROLLBACK;

		DECLARE @strerror VARCHAR(4000) = ''
		EXECUTE k_GetErrorInfo @visible = 0
							  ,@strerror = @strerror OUT
		RAISERROR (@strerror, 16, 1)

	END CATCH
go

