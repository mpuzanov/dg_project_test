CREATE   PROCEDURE [dbo].[ka_add_subsid2]
(
	@occ1			INT
	,@value_str1	VARCHAR(2000)
	, -- строка формата: код услуги:сумма;код услуги:сумма
	@doc1			VARCHAR(50)		= NULL
	,@doc_no1		VARCHAR(10)		= NULL
	,@doc_date1		SMALLDATETIME	= NULL
	,@dsc_owner_id1	INT				= NULL-- код получателя субсидии
)
AS
	--
	--  Ввод разовых по субсидиям тип 4
	--
	IF dbo.Fun_AccessAddLic(@occ1) = 0
	BEGIN
		RAISERROR ('Для Вас работа с Разовыми запрещена', 16, 1)
		RETURN
	END

	IF dbo.Fun_AccessSubsidLic(@occ1) = 0
	BEGIN
		RAISERROR ('Для Вас работа с субсидиями запрещена', 16, 1)
		RETURN
	END

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	IF dbo.Fun_AccessEditLic(@occ1) = 0
	BEGIN
		RAISERROR ('Изменения запрещены!', 16, 1)
		RETURN
	END

	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE	@add_type1	SMALLINT
			,@id1		INT
	SET @add_type1 = 4

BEGIN TRY

	-- Таблица с новыми значениями 
	DECLARE @t1 TABLE
		(
			service_id	VARCHAR(10)
			,new_value	DECIMAL(9, 2)
		)

	INSERT INTO @t1
		SELECT
			pole1
			,pole2
		FROM dbo.Fun_charlist_to_table(@value_str1, ';')

	-- Проверяем все ли правильные услуги(есть код в SERVICES)
	IF EXISTS (SELECT
				*
			FROM @t1
			WHERE NOT EXISTS (SELECT
					1
				FROM dbo.View_SERVICES
				WHERE id = service_id))
	BEGIN
		RAISERROR ('Ошибка в формирование строки услуг для разовых!', 11, 1)
		RETURN 1
	END


	DECLARE @user_edit1 SMALLINT
	SELECT
		@user_edit1 = id
	FROM dbo.USERS 
	WHERE login = system_user

	BEGIN TRAN

		DELETE dbo.ADDED_PAYMENTS 
		WHERE occ = @occ1 AND add_type = @add_type1

		INSERT INTO ADDED_PAYMENTS
		(	occ
			,service_id
			,add_type
			,value
			,doc
			,doc_no
			,doc_date
			,user_edit
			,dsc_owner_id)
			SELECT
				@occ1
				,service_id
				,@add_type1
				,new_value
				,@doc1
				,@doc_no1
				,@doc_date1
				,@user_edit1
				,@dsc_owner_id1
			FROM @t1
			WHERE new_value <> 0

	COMMIT TRAN

	-- сохраняем в историю изменений
	EXEC k_write_log	@occ1
						,'раз!'

END TRY
BEGIN CATCH
	EXEC dbo.k_err_messages
END CATCH
go

