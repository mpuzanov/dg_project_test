CREATE   PROCEDURE [dbo].[k_paydoc_add]
(
	  @data1 DATETIME
	, @docsnum1 INT -- кол-во документов в пачке
	, @total1 MONEY -- общая сумма по пачке
	, @source_id1 INT
	, @blocked1 BIT = 0
	, @tip_id SMALLINT
	, @commission DECIMAL(9, 2) = NULL
	, @sup_id INT = NULL
	, @id INT = 0 OUTPUT
	, @occ1 INT = NULL
	, @is_close_pack BIT = 0
	, @comment1 VARCHAR(100) = NULL  -- комментарий к платежу если задан лицевой
)
AS
/*
	Ввод новой пачки
*/

	SET NOCOUNT ON

	DECLARE @fin_id1 INT
		  , @RC INT
		  , @paying_id_new INT
		  , @kolPacksClose INT = 0

	SELECT @fin_id1 = dbo.Fun_GetFinCurrent(@tip_id, NULL, NULL, NULL)

	SELECT @data1 = CAST(@data1 AS DATE)
		 , @is_close_pack = COALESCE(@is_close_pack, 0)

	--*********************
	--  exec @id1=dbo.k_paydoc_next
	--*********************

	BEGIN TRY

		IF @occ1 > 0
		BEGIN
			-- Проверяем есть ли такой лицевой в базе
			SELECT @occ1 = dbo.Fun_GetFalseOccIn(@occ1)

			IF NOT EXISTS (
					SELECT 1
					FROM dbo.Occupations o
					WHERE occ = @occ1
				)
			BEGIN
				-- ищем в поставщиках
				IF NOT EXISTS (
						SELECT 1
						FROM dbo.Occ_Suppliers os
						WHERE os.occ_sup = @occ1
					)
				BEGIN
					RAISERROR (N'Лицевого счета %d нет!', 16, 10, @occ1)
				END
				ELSE
					SELECT TOP (1) @occ1 = occ
								 , @sup_id = sup_id
					FROM dbo.Occ_Suppliers os
					WHERE os.occ_sup = @occ1
					ORDER BY os.fin_id DESC
			END
		END

		SELECT @fin_id1 =
               CASE
                   WHEN (ot.ras_paym_fin_new = 1) AND
                        (ot.PaymClosed = 1) THEN ot.fin_id + 1
                   ELSE ot.fin_id
                   END
		FROM dbo.Occupation_Types AS ot
		WHERE id = @tip_id

		BEGIN TRAN

		INSERT INTO dbo.Paydoc_packs (fin_id
									, source_id
									, day
									, docsnum
									, total
									, blocked
									, tip_id
									, commission
									, sup_id)
		VALUES(@fin_id1
			 , @source_id1
			 , @data1
			 , @docsnum1
			 , @total1
			 , @blocked1
			 , @tip_id
			 , @commission
			 , COALESCE(@sup_id, 0))

		SELECT @id = SCOPE_IDENTITY()

		IF @occ1 > 0
		BEGIN
			-- добавляем платёж в пачку
			EXEC k_payings_add @occ1 = @occ1
							 , @pack_id1 = @id
							 , @value1 = @total1
							 , @scan1 = 0
							 , @sup_id = @sup_id
							 , @commission = @commission
							 , @paying_vozvrat = NULL
							 , @paymaccount_peny = NULL
							 , @peny_save = 0
							 , @paying_manual = 0
							 , @id1 = @paying_id_new OUTPUT
							 , @comment = @comment1

			IF COALESCE(@paying_id_new, 0) = 0
			BEGIN
				RAISERROR (N'Ошибка добавления платежа на лицевой %d', 16, 1, @occ1)
				RETURN -1;
			END

		END

		COMMIT TRAN

		EXEC k_paydoc_log @pack_id1 = @id

		IF @is_close_pack = 1 -- закрываем пачку				
			EXECUTE @RC = dbo.adm_CloseDay @pack_id = @id, @kolPacksClose = @kolPacksClose OUTPUT

	END TRY
	BEGIN CATCH

		IF @@trancount > 0
			ROLLBACK TRANSACTION;
		THROW

	END CATCH
go

