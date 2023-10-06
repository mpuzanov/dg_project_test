CREATE   PROCEDURE [dbo].[ka_add_occ]
(
	  @occ1 INT -- код лицевого счета 
	, @fin_id1 SMALLINT -- код фин.периода
	, @serv_one1 VARCHAR(10) = NULL -- код услуги
	, @doc1 VARCHAR(100) = NULL
	, @add_type1 INT = 9 -- общий перерасчёт
	, @sup_id INT = NULL
	, @kol_added INT = 0 OUTPUT
)
AS
	--
	--  Берем расчитанные суммы из PAYM_ADD
	--  и заносим их в разовые  
	--
	SET NOCOUNT ON

	IF dbo.Fun_GetRejimOcc(@occ1) <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	IF @add_type1 IS NULL
		SELECT @add_type1 = 9 --Перерасчет по всей базе

	SET @kol_added = 0;

	DECLARE @tbl_add TABLE (
		  service_id VARCHAR(10)
		, sup_id INT
		, value_add DECIMAL(15, 2)
		, fin_id_paym SMALLINT DEFAULT NULL
	)

	INSERT INTO @tbl_add (service_id
						, value_add
						, sup_id
						, fin_id_paym)
	SELECT pa.service_id
		 , pa.value AS value_add
		 , pa.sup_id
		 , pa.fin_id_paym
	FROM dbo.Paym_add AS pa
	WHERE pa.occ = @occ1
		AND (pa.service_id = @serv_one1 OR @serv_one1 IS NULL)

	UPDATE t
	SET value_add = value_add - ph.value --- ph.discount - ph.compens)
	FROM @tbl_add AS t
		JOIN dbo.Paym_history AS ph ON t.service_id = ph.service_id
			AND t.sup_id = ph.sup_id
	WHERE ph.fin_id = @fin_id1
		AND ph.occ = @occ1

	IF @doc1 IS NULL
		SET @doc1 = 'Общий перерасчет'

	DECLARE @user_edit1 SMALLINT
	SELECT @user_edit1 = dbo.Fun_GetCurrentUserId()

	BEGIN TRAN

		IF @add_type1 = 9
			DELETE ap
			FROM dbo.Added_Payments ap 
				JOIN dbo.View_services AS s ON ap.service_id = s.id -- для ограничения досупа к услугам
			WHERE occ = @occ1
				AND add_type = @add_type1
				AND (ap.sup_id = @sup_id
				OR @sup_id IS NULL)
				AND (service_id = @serv_one1
				OR @serv_one1 IS NULL)
				AND (ap.doc = @doc1
				OR @doc1 IS NULL)

		-- Добавить в таблицу added_payments
		INSERT INTO dbo.Added_Payments (occ
									  , service_id
									  , sup_id
									  , add_type
									  , doc
									  , value
									  , user_edit
									  , fin_id_paym)
		SELECT @occ1
			 , TA.service_id
			 , TA.sup_id
			 , @add_type1
			 , @doc1
			 , value_add
			 , @user_edit1
			 , fin_id_paym
		FROM @tbl_add AS TA
		WHERE value_add <> 0
		SET @kol_added = @@rowcount

		-- Изменить значения в таблице paym_list
		IF @kol_added > 0
			UPDATE pl
			SET added = COALESCE((
				SELECT SUM(value)
				FROM dbo.Added_Payments ap
				WHERE ap.occ = @occ1
					AND ap.service_id = pl.service_id
					AND ap.sup_id = pl.sup_id
			), 0)
			FROM dbo.Paym_list AS pl
			WHERE occ = @occ1

		COMMIT TRAN
go

