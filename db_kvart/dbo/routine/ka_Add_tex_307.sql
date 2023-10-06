CREATE   PROCEDURE [dbo].[ka_Add_tex_307]
(
	@occ1			INT
	,@value_str1	VARCHAR(4000) -- строка формата: код услуги:сумма;код услуги:сумма
	,@doc1			VARCHAR(100)
	,@add_type1		SMALLINT		= 11 -- тип тех.корректировки по 307 пост.
	,@doc_no1		VARCHAR(15)		= NULL
	,@doc_date1		SMALLDATETIME	= NULL
	,@comments		VARCHAR(70)		= NULL-- комментарий к разовому
)
AS
	--
	--  Ввод технической корректировки на лицевом по 307 постановлению
	--

	SET NOCOUNT ON

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

	IF dbo.Fun_AccessEditLic(@occ1) = 0
	BEGIN
		RAISERROR ('Изменения запрещены!', 16, 1)
		RETURN
	END

BEGIN TRY

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
	FROM USERS 
	WHERE login = system_user

	BEGIN TRAN

		IF @add_type1 = 11
		BEGIN

			INSERT
			INTO ADDED_PAYMENTS
			(	occ
				,service_id
				,add_type
				,value
				,doc
				,doc_no
				,doc_date
				,user_edit
				,comments)
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
				FROM @t1
				WHERE new_value <> 0

		END

	COMMIT TRAN

	-- сохраняем в историю изменений
	EXEC k_write_log	@occ1
						,'раз!'

END TRY
BEGIN CATCH
	EXEC dbo.k_err_messages
END CATCH
go

