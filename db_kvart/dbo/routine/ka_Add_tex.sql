CREATE   PROCEDURE [dbo].[ka_Add_tex]
(
	  @occ1 INT
	, @service_id1 VARCHAR(10)
	, @add_value1 DECIMAL(10, 4)
	, @doc1 VARCHAR(100) = NULL
	, @comments VARCHAR(100) = NULL-- комментарий к разовому
)
AS
	--
	--  Ввод технической корректировки
	--
	SET NOCOUNT ON
	SET XACT_ABORT ON

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


	SET NOCOUNT ON

	IF @add_value1 = 0
	BEGIN
		RETURN
	END

	DECLARE @add_type1 INT
		  , @doc_current VARCHAR(50)
		  , @added_id INT -- код разовой тех. кор. по услуге

	SELECT @add_type1 = 2 -- тип тех.корректировки

	SELECT @added_id = ap.id
		 , @doc_current = doc
	FROM dbo.Added_Payments ap
	JOIN dbo.Occupations o ON ap.occ = o.Occ AND ap.fin_id=o.fin_id	
	WHERE ap.occ = @occ1
		AND ap.service_id = @service_id1
		AND ap.add_type = 2		

	BEGIN TRAN

		IF (@added_id IS NULL)
		BEGIN
			INSERT Added_Payments (occ
								 , service_id
								 , add_type
								 , value
								 , doc
								 , comments)
			VALUES(@occ1
				 , @service_id1
				 , @add_type1
				 , @add_value1
				 , @doc1
				 , @comments)
		END
		ELSE
		BEGIN
			UPDATE dbo.Added_Payments
			SET value = @add_value1
			  , doc =
						 CASE
							 WHEN @doc1 IS NOT NULL THEN @doc1
							 ELSE @doc_current
						 END
			WHERE id = @added_id
		END

		UPDATE pl
		SET added = COALESCE((
			SELECT SUM(value)
			FROM dbo.Added_Payments
			WHERE occ = @occ1
				AND service_id = pl.service_id
				AND fin_id = pl.fin_id
		), 0)
		FROM dbo.Paym_list AS pl
		WHERE occ = @occ1

		-- сохраняем в историю изменений
		EXEC k_write_log @occ1
					   , 'раз!'

		COMMIT TRAN
go

