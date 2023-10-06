CREATE   PROCEDURE [dbo].[k_del_occ_sup]
(
	@occ	INT
   ,@sup_id INT
   ,@blocked_value BIT = 0  -- больше не начислять (убираем режим)
)
AS
	/*

  Процедура удаления лицевого счета по поставщику
  
*/
	SET NOCOUNT ON
	SET XACT_ABORT ON


	IF dbo.Fun_AccessDelLic(@occ) = 0
	BEGIN
		RAISERROR ('Вам запрещено удалять этот лицевой счет', 16, 1)
		RETURN
	END

	IF dbo.Fun_GetRejimOcc(@occ) <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	BEGIN TRY

		DECLARE @fin_current SMALLINT
			   ,@occ_sup	 INT
			   ,@msg		 VARCHAR(50)

		SELECT
			@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ)
		SELECT
			@occ_sup = occ_sup
		FROM dbo.OCC_SUPPLIERS
		WHERE occ = @occ
		AND sup_id = @sup_id
		AND fin_id = @fin_current

		BEGIN TRAN

			DELETE pl
				FROM dbo.PAYM_LIST AS pl
			WHERE pl.occ = @occ
				AND pl.fin_id = @fin_current
				AND EXISTS (SELECT
						1
					FROM dbo.SUPPLIERS AS sup
					WHERE sup.sup_id = @sup_id
					AND sup.service_id = pl.service_id)

			UPDATE cl
			SET occ_serv	= NULL
			   ,account_one = 0
			   ,lic_source  = ''			   
			   ,sup_id = CASE WHEN @blocked_value>0 THEN 0 ELSE cl.sup_id END
			   ,dog_int = CASE WHEN @blocked_value>0 THEN NULL ELSE cl.dog_int END
			FROM dbo.Consmodes_list cl
			WHERE cl.occ = @occ
			AND EXISTS (SELECT
					1
				FROM dbo.Suppliers AS sup
				WHERE sup.sup_id = @sup_id
				AND sup.service_id = cl.service_id)


			DELETE FROM dbo.Occ_Suppliers
			WHERE occ_sup = @occ_sup
				AND fin_id = @fin_current

		COMMIT TRAN

		-- сохраняем в историю изменений
		SET @msg = 'Удаление лицевого поставщика ' + STR(@occ_sup)
		EXEC k_write_log @occ
						,'удлс'
						,@msg
	END TRY
	BEGIN CATCH
		EXEC dbo.k_err_messages
	END CATCH
go

