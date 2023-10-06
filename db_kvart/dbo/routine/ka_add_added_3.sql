CREATE   PROCEDURE [dbo].[ka_add_added_3]
(
	@occ1			INT -- лицевой счет 
	,@service_id1	VARCHAR(10) -- код услуги
	,@add_type1		INT -- тип разового
	,@doc1			VARCHAR(100) -- документ
	,@value1		DECIMAL(15, 2) -- сумма
	,@doc_no1		VARCHAR(15)		= NULL -- номер акта
	,@doc_date1		SMALLDATETIME	= NULL -- дата акта
	,@dsc_owner_id1	INT				= NULL -- код льготника из DSC_OWNERS
	,@comments		VARCHAR(70)		= NULL -- комментарий к разовому
	,@kol			DECIMAL(9, 4)	= NULL
	,@data1			SMALLDATETIME	= NULL
	,@data2			SMALLDATETIME	= NULL
	,@sup_id		INT				= NULL
	,@addyes		BIT				OUTPUT-- если 1 то разовые добавили
)
AS
	/*
		--  Ввод разовых: просто ввод суммы (Возврат по льготам)
	*/
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	
	SET @addyes = 0

	IF @value1 = 0
		RETURN 0
	IF @sup_id IS NULL
		SET @sup_id = dbo.Fun_GetSup_idOcc(@occ1,@service_id1)
		
	IF dbo.Fun_AccessAddLic(@occ1) = 0
	BEGIN
		RAISERROR ('Для Вас работа с Разовыми запрещена', 16, 1)
		RETURN
	END

	IF dbo.Fun_GetRejimOcc(@occ1) <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	IF dbo.Fun_GetOccClose(@occ1) = 0
	BEGIN
		--raiserror('Лицевой счет %d закрыт! Работа с ним запрещена',16,1,@occ1)
		RETURN
	END

	IF @dsc_owner_id1 = 0
		SET @dsc_owner_id1 = NULL

	IF (@add_type1 = 6)
		AND (@dsc_owner_id1 IS NULL) -- Возврат по льготам
	BEGIN
		RAISERROR ('Введите льготника!', 16, 1)
		RETURN
	END

	DECLARE @summa1 DECIMAL(10, 4)

	-- Проверяем есть ли такая услугя на этом лицевом
	IF NOT EXISTS (SELECT
				1
			FROM dbo.CONSMODES_LIST AS cl 
			WHERE cl.occ = @occ1
			AND cl.service_id = @service_id1
			AND cl.sup_id=@sup_id
			AND ((cl.mode_id % 1000 != 0) OR (cl.source_id % 1000 != 0))
			)
	BEGIN
		RAISERROR ('У лицевого нет режима потребления по услуге: %s ', 16, 1, @service_id1)
		RETURN
	END


	--*******************************************************************
	DECLARE	@user_edit1		SMALLINT
			,@fin_current	SMALLINT
	SELECT
		@user_edit1 = dbo.Fun_GetCurrentUserId()
		,@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	BEGIN TRAN

		SET @summa1 = @value1

		-- Добавить в таблицу added_payments
		INSERT
		INTO dbo.ADDED_PAYMENTS
		(	occ
			,service_id
			,sup_id
			,add_type
			,doc
			,value
			,doc_no
			,doc_date
			,user_edit
			,dsc_owner_id
			,comments
			,kol
			,fin_id
			,data1
			,data2)
		VALUES (@occ1, @service_id1, @sup_id, @add_type1, @doc1, @summa1, @doc_no1, @doc_date1, @user_edit1, @dsc_owner_id1, @comments, @kol, @fin_current, @data1, @data2)

		-- Изменить значения в таблице paym_list
		UPDATE pl
			SET added = COALESCE(t_add.val, 0), kol_added = COALESCE(t_add.kol,0)
			FROM dbo.Paym_list AS pl
				CROSS APPLY (SELECT SUM(ap.value) as val, sum(coalesce(ap.kol,0)) AS kol
					FROM dbo.Added_Payments ap
					WHERE ap.occ = pl.occ
						AND ap.service_id = pl.service_id
						AND ap.fin_id = pl.fin_id
						AND ap.sup_id = pl.sup_id) AS t_add
			WHERE pl.occ = @occ1
				AND pl.fin_id = @fin_current;

		SET @addyes = 1; -- добавление разового прошло успешно

	COMMIT TRAN

	-- сохраняем в историю изменений
	EXEC k_write_log	@occ1
						,'раз!'

	UPDATE dbo.PEOPLE WITH (ROWLOCK)
	SET	kol_day_add		= NULL
		,kol_day_lgota	= NULL
	WHERE occ = @occ1
go

