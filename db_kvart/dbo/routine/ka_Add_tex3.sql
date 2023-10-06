CREATE   PROCEDURE [dbo].[ka_Add_tex3]
(
	@occ1				INT
	,@value_str1		VARCHAR(4000) -- строка формата: код услуги:сумма;код услуги:сумма
	,@kol_str1			VARCHAR(4000) -- строка формата: код услуги:количество;код услуги:количество
	,@doc1				VARCHAR(100)
	,@add_type1			SMALLINT		= 2 -- тип тех.корректировки (по умолчанию по норме)
	,@doc_no1			VARCHAR(10)		= NULL
	,@doc_date1			SMALLDATETIME	= NULL
	,@comments			VARCHAR(70)		= NULL -- комментарий к разовому
	,@new				BIT				= 0 -- создавать новые разовые
	,@repeat_for_fin	SMALLINT		= NULL-- повтор перерасчета по заданные период
	,@sup_id INT = 0
	,@debug BIT = 0

)
AS
	/*

Ввод технической корректировки

добавил ввод количества
*/
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

	IF @sup_id IS NULL SET @sup_id=0

	-- удаляем пробелы
	SET @value_str1=REPLACE(@value_str1,CHAR(32),'') 
	SET @value_str1=REPLACE(@value_str1,CHAR(9),'') 
	SET @value_str1=REPLACE(@value_str1,CHAR(160),'') 

	SET @kol_str1=REPLACE(@kol_str1,CHAR(32),'')
	SET @kol_str1=REPLACE(@kol_str1,CHAR(9),'')
	SET @kol_str1=REPLACE(@kol_str1,CHAR(160),'')
	--IF @debug=1 PRINT @value_str1

	-- Таблица с новыми значениями суммы
	DECLARE @t1 TABLE
		(
			service_id	VARCHAR(10)			
			,new_value	DECIMAL(9, 2)
			,sup_id INT DEFAULT 0
		)

	INSERT
	INTO @t1(service_id,new_value)
		SELECT
			id
			,val
		FROM dbo.Fun_split_IdValue(@value_str1, ';')

	-- Таблица с новыми значениями количества
	DECLARE @t2 TABLE
		(
			service_id	VARCHAR(10)
			,new_kol	DECIMAL(9, 4)
			,sup_id INT DEFAULT 0
		)
	INSERT
	INTO @t2(service_id,new_kol)
		SELECT
			id
			,val
		FROM dbo.Fun_split_IdValue(@kol_str1, ';')

	--select * from @t1

	DECLARE @user_edit1 SMALLINT
	SELECT
		@user_edit1 = dbo.Fun_GetCurrentUserId()

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
				,value
				,doc
				,doc_no
				,doc_date
				,user_edit
				,comments
				,repeat_for_fin
				,kol
				,fin_id
				,sup_id)
				SELECT
					@occ1
					,t.service_id
					,@add_type1
					,new_value
					,@doc1
					,@doc_no1
					,@doc_date1
					,@user_edit1
					,@comments
					,@repeat_for_fin
					,t2.new_kol
					,@fin_current
					,@sup_id
				FROM @t1 AS t
				LEFT JOIN @t2 AS t2
					ON t.service_id = t2.service_id
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
				,value
				,doc
				,doc_no
				,doc_date
				,user_edit
				,sup_id)
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
					,@sup_id
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
				,value
				,doc
				,doc_no
				,doc_date
				,user_edit
				,comments
				,repeat_for_fin
				,kol
				,fin_id
				,sup_id)
				SELECT
					@occ1
					,t.service_id
					,@add_type1
					,new_value
					,@doc1
					,@doc_no1
					,@doc_date1
					,@user_edit1
					,@comments
					,@repeat_for_fin
					,t2.new_kol
					,@fin_current
					,@sup_id
				FROM @t1 AS t
				LEFT JOIN @t2 AS t2
					ON t.service_id = t2.service_id
				WHERE new_value <> 0

		END

	COMMIT TRAN

	IF @add_type1 IN (2, 13)
		UPDATE pl 
		SET added = COALESCE((SELECT
				SUM(value)
			FROM dbo.ADDED_PAYMENTS ap 
			WHERE ap.occ = @occ1
			AND ap.service_id = pl.service_id
			AND ap.sup_id = pl.sup_id)
		, 0)
		FROM dbo.PAYM_LIST AS pl
		WHERE pl.occ = @occ1		


	IF @add_type1 = 10
		UPDATE pl 
		SET added = COALESCE((SELECT
				SUM(value)
			FROM dbo.ADDED_COUNTERS_ALL AS ac 
			WHERE ac.occ = @occ1
			AND ac.service_id = pl.service_id
			AND ac.fin_id = @fin_current)
		, 0)
		FROM dbo.PAYM_COUNTER_ALL AS pl
		WHERE occ = @occ1
		AND fin_id = @fin_current

	-- сохраняем в историю изменений
	EXEC k_write_log	@occ1
						,'раз!'

END TRY
BEGIN CATCH
	EXEC dbo.k_err_messages
END CATCH
go

