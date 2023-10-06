CREATE   PROCEDURE [dbo].[adm_added_all_occ]
(
	  @occ1 INT
	, @fin_id1 SMALLINT = NULL -- код финансового периода
	, @serv_one1 VARCHAR(10) = NULL
	, @doc1 VARCHAR(100) = NULL
	, @no_is_counter BIT = 1
	, @add_type1 INT = 9
	, @kol_added INT = 0 OUTPUT
)
/*
 
Перерасчет лицевого по заданному финансовому периоду

exec [adm_added_all_occ] 291785,141,'вотв','тест',0,9

*/
AS
	SET NOCOUNT ON

	IF @no_is_counter IS NULL
		SET @no_is_counter = 0

	IF @add_type1 IS NULL
		SELECT @add_type1 = 9 --Перерасчет по всей базе

	SET @kol_added = 0

	DECLARE @fin_id_current SMALLINT
	SELECT @fin_id_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	IF (@fin_id1 IS NULL)
		OR (@fin_id1 = 0)
		SET @fin_id1 = @fin_id_current - 1

	IF @fin_id1 = @fin_id_current
	BEGIN
		RAISERROR ('Ошибка! Фин.перериод должен быть меньше текущего!', 16, 1)
		RETURN -1
	END

	IF @add_type1 = 9 -- Тип разового "Общий перерасчет"
		DELETE ap
		FROM dbo.Added_Payments AS ap
			JOIN dbo.View_services AS s ON ap.service_id = s.id -- для ограничения досупа к услугам
		WHERE occ = @occ1
			AND add_type = @add_type1
			AND (@serv_one1 IS NULL OR service_id = @serv_one1)
			AND (ap.doc = @doc1 OR @doc1 IS NULL);

	UPDATE dbo.People 
	SET kol_day_add = NULL
	WHERE occ = @occ1
		AND kol_day_add IS NOT NULL;

	IF @no_is_counter = 1
		AND @serv_one1 IS NOT NULL
	BEGIN
		DECLARE @service_id2 VARCHAR(10) = ''

		IF @serv_one1 = 'гвс2'
			SET @service_id2 = 'гвод'

		IF @serv_one1 = 'ото2'
			SET @service_id2 = 'отоп'
		--if EXISTS(SELECT * FROM dbo.View_PAYM AS vp WHERE occ=@occ1 AND fin_id=@fin_id1 AND is_counter>0 ) --AND metod IN (2,3))

		IF EXISTS (
				SELECT 1
				FROM dbo.View_counter_all AS vca 
				WHERE occ = @occ1
					AND fin_id = @fin_id1
					AND service_id IN (@serv_one1, @service_id2)
			)
			RETURN

	END

	IF EXISTS (
			SELECT 1
			FROM dbo.Occupations 
			WHERE occ = @occ1
				AND status_id <> 'закр'
		)
	BEGIN
		EXEC k_raschet_2 @occ1 = @occ1
					   , @fin_id1 = @fin_id1
					   , @added = 1
					   , @alladd = 0
					   , @debug = 1 --,@serv_one1 = @serv_one1 ,

		EXEC ka_add_occ @occ1 = @occ1
					  , @fin_id1 = @fin_id1
					  , @serv_one1 = @serv_one1
					  , @doc1 = @doc1
					  , @add_type1 = @add_type1
					  , @kol_added = @kol_added OUTPUT

	END
go

