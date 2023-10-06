CREATE   PROCEDURE [dbo].[k_editpayings]
(
	@id1	INT
   ,@value1 DECIMAL(10, 4)
)
--
--  Ручное изменение суммы платежа
--
AS

	SET NOCOUNT ON

	BEGIN TRY

		DECLARE @pack_id1 INT
			   ,@occ	  INT
		SELECT
			@pack_id1 = pack_id
		   ,@occ = occ
		FROM PAYINGS
		WHERE id = @id1

		IF dbo.Fun_GetRejimOcc(@occ) <> 'норм'
		BEGIN
			RAISERROR ('База закрыта для редактирования!', 16, 1)
			RETURN
		END

		UPDATE PAYINGS
		SET value = @value1
		   ,scan  = 0
		WHERE id = @id1

		-- Проверяем равна ли заявленная сумма в пачке и количество платежей
		-- сумме введенных платежей по ней
		-- Checked=1 - равна
		DECLARE @SumPacks DECIMAL(10, 4)
			   ,@kolpaym  SMALLINT
		SELECT
			@SumPacks = SUM(value)
		   ,@kolpaym = COUNT(id)
		FROM PAYINGS
		WHERE pack_id = @pack_id1

		UPDATE PAYDOC_PACKS
		SET checked =
			CASE
				WHEN (@SumPacks = total) AND
				(@kolpaym = docsnum) THEN 1
				ELSE 0
			END
		WHERE id = @pack_id1

	END TRY
	BEGIN CATCH
		EXEC dbo.k_err_messages
	END CATCH
go

