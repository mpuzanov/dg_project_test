CREATE   PROCEDURE [dbo].[k_del_payings]
(
	@id1 INT
)
/*

 Удаление платежа
*/
AS

	SET NOCOUNT ON
	SET XACT_ABORT ON;

	DECLARE @trancount INT;
	SET @trancount = @@trancount;


	DECLARE @pack_id1 INT
		   ,@occ1	  INT

	BEGIN TRY
		IF @trancount = 0
			BEGIN TRANSACTION
			ELSE
				SAVE TRANSACTION k_del_payings;

			SELECT
				@pack_id1 = pack_id
			   ,@occ1 = occ
			FROM dbo.PAYINGS
			WHERE id = @id1

			IF dbo.Fun_GetRejimOcc(@occ1) <> 'норм'
			BEGIN
				RAISERROR ('База закрыта для редактирования!', 16, 1)
				RETURN
			END

			IF @pack_id1 IS NOT NULL
			BEGIN
				DELETE FROM PAYINGS
				WHERE id = @id1

				-- Проверяем равна ли заявленная сумма в пачке
				-- сумме введенных платежей по ней
				-- Checked=1 - равна
				DECLARE @SumPacks DECIMAL(10, 4)
				SELECT
					@SumPacks = SUM(value)
				FROM PAYINGS
				WHERE pack_id = @pack_id1

				UPDATE PAYDOC_PACKS
				SET checked =
					CASE @SumPacks
						WHEN total THEN 1
						ELSE 0
					END
				WHERE id = @pack_id1

				-- сохраняем в историю изменений
				EXEC k_write_log @occ1
								,'плат'

			END --@pack_id1 is not null

			IF @trancount = 0
			COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
		DECLARE @xstate INT;
		SELECT
			@xstate = XACT_STATE();
		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @trancount = 0
			ROLLBACK;
		IF @xstate = 1
			AND @trancount > 0
			ROLLBACK TRANSACTION k_del_payings;

		EXEC dbo.k_err_messages
	END CATCH
go

