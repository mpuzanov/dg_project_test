CREATE   PROCEDURE [dbo].[k_payings_del]
(
	  @id1 INT
)
/*

 Удаление платежа


 Очищаем поле пачки  13/09/2010

*/
AS

	SET NOCOUNT ON 
	SET XACT_ABORT ON

	BEGIN TRY

		DECLARE @pack_id1 INT
			  , @occ1 INT

		BEGIN TRAN

		SELECT @pack_id1 = pack_id
			 , @occ1 = occ
		FROM dbo.Payings
		WHERE id = @id1

		IF @pack_id1 IS NOT NULL
		BEGIN
			DELETE FROM dbo.Payings
			WHERE id = @id1

			-- Проверяем равна ли заявленная сумма в пачке и кол-во платежей
			-- сумме введенных платежей по ней
			-- Checked=1 - равна
			DECLARE @SumPacks MONEY
				  , @kolpaym INT
			SELECT @SumPacks = SUM(value)
				 , @kolpaym = COUNT(id)
			FROM dbo.Payings
			WHERE pack_id = @pack_id1

			UPDATE dbo.Paydoc_packs
			SET checked =
						 CASE
							 WHEN (@SumPacks = total) AND
								 (@kolpaym = docsnum) THEN 1
							 ELSE 0
						 END
			WHERE id = @pack_id1

			-- Очищаем поле пачки  13/09/2010
			UPDATE bd
			SET pack_id = NULL
			FROM dbo.Bank_Dbf AS bd
			WHERE bd.occ = @occ1
				AND bd.pack_id = @pack_id1


			-- сохраняем в историю изменений
			EXEC k_write_log @occ1
						   , 'плат'

			EXEC k_paydoc_log @pack_id1

		END   --@pack_id1 is not null

		COMMIT TRAN

	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			ROLLBACK TRANSACTION
			;
		THROW
	END CATCH
go

