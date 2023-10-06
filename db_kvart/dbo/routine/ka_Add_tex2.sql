CREATE   PROCEDURE [dbo].[ka_Add_tex2]
(
	@occ1				INT
	,@value_str1		VARCHAR(4000) -- строка формата: код услуги:сумма;код услуги:сумма
	,@doc1				VARCHAR(100)
	,@add_type1			SMALLINT		= 2 -- тип тех.корректировки (по умолчанию по норме)
	,@doc_no1			VARCHAR(15)		= NULL
	,@doc_date1			SMALLDATETIME	= NULL
	,@comments			VARCHAR(70)		= NULL -- комментарий к разовому
	,@new				BIT				= 0 -- создавать новые разовые
	,@repeat_for_fin	SMALLINT		= NULL-- повтор перерасчета по заданные период
)
AS
	--
	--  Ввод технической корректировки
	--

	SET NOCOUNT ON

	IF @new IS NULL
		SET @new = 0

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

	IF NOT EXISTS (SELECT 1
			FROM dbo.OCCUPATIONS AS O 
			WHERE occ = @occ1)
	BEGIN
		RAISERROR ('Лицевой: %i не найден в базе!', 16, 1, @occ1)
		RETURN
	END

	IF dbo.Fun_AccessEditLic(@occ1) = 0
	BEGIN
		RAISERROR ('Изменения запрещены!', 16, 1)
		RETURN
	END

BEGIN TRY

	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = [dbo].[Fun_GetFinCurrent](NULL, NULL, NULL, @occ1)

	-- Таблица с новыми значениями 
	DECLARE @t1 TABLE
		(
			service_id	VARCHAR(10)
			,new_value	DECIMAL(9, 2)
		)

	INSERT
	INTO @t1
		SELECT
			id
			,val
		FROM dbo.Fun_split_IdValue(@value_str1, ';')

	--select * from @t1

	DECLARE @user_edit1 SMALLINT
	SELECT
		@user_edit1 = id
	FROM dbo.USERS 
	WHERE login = system_user

	BEGIN TRAN

		IF @add_type1 IN (2, 13) -- тех.корректировка по норме или корректировка оплаты
		BEGIN

			DELETE FROM dbo.ADDED_PAYMENTS
			WHERE occ = @occ1
				AND add_type = @add_type1
				AND @new = 0

			INSERT
			INTO dbo.ADDED_PAYMENTS
			(	occ
				,service_id
				,add_type
				,Value
				,doc
				,doc_no
				,doc_date
				,user_edit
				,comments
				,repeat_for_fin
				,fin_id)
				SELECT
					@occ1
					,service_id
					,@add_type1
					,new_value
					,@doc1
					,@doc_no1
					,@doc_date1
					,@user_edit1
					,@comments
					,@repeat_for_fin
					,@fin_current
				FROM @t1
				WHERE new_value <> 0
		END
		ELSE
		IF @add_type1 = 10 -- тех.корректировка по счетчикам
		BEGIN

			DELETE FROM dbo.ADDED_COUNTERS_ALL
			WHERE occ = @occ1
				AND add_type = @add_type1
				AND fin_id = @fin_current
				AND @new = 0

			INSERT
			INTO dbo.ADDED_COUNTERS_ALL
			(	fin_id
				,occ
				,service_id
				,add_type
				,Value
				,doc
				,doc_no
				,doc_date
				,user_edit)
				SELECT
					@fin_current
					,@occ1
					,service_id
					,@add_type1
					,new_value
					,@doc1
					,@doc_no1
					,@doc_date1
					,@user_edit1
				FROM @t1
				WHERE new_value <> 0

		END
		ELSE
		BEGIN
			INSERT
			INTO dbo.ADDED_PAYMENTS
			(	occ
				,service_id
				,add_type
				,Value
				,doc
				,doc_no
				,doc_date
				,user_edit
				,comments
				,repeat_for_fin
				,fin_id)
				SELECT
					@occ1
					,service_id
					,@add_type1
					,new_value
					,@doc1
					,@doc_no1
					,@doc_date1
					,@user_edit1
					,@comments
					,@repeat_for_fin
					,@fin_current
				FROM @t1
				WHERE new_value <> 0

		END
	COMMIT TRAN

	IF @add_type1 IN (2, 13)
		UPDATE pl
		SET Added = COALESCE((SELECT
				SUM(Value)
			FROM dbo.ADDED_PAYMENTS ap
			WHERE ap.occ = @occ1
			AND ap.service_id = pl.service_id
			AND ap.fin_id = pl.fin_id)
		, 0)
		FROM dbo.PAYM_LIST AS pl
		WHERE pl.occ = @occ1
		AND pl.fin_id = @fin_current


	IF @add_type1 = 10
		UPDATE pl
		SET Added = COALESCE((SELECT
				SUM(Value)
			FROM dbo.ADDED_COUNTERS_ALL AS ac
			WHERE ac.occ = @occ1
			AND ac.service_id = pl.service_id
			AND ac.fin_id = pl.fin_id)
		, 0)
		FROM dbo.PAYM_COUNTER_ALL AS pl
		WHERE pl.occ = @occ1
		AND pl.fin_id = @fin_current

	-- сохраняем в историю изменений
	EXEC k_write_log	@occ1
						,'раз!'

END TRY
BEGIN CATCH
	EXEC dbo.k_err_messages
END CATCH
go

