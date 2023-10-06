-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[k_payings_vozvrat_add]
(
	  @paying_id_vozvrat1 INT -- платёж для возврата
	, @data1 DATETIME = NULL
	, @source_id1 INT = NULL -- вид платежа
	, @comment1 VARCHAR(100) = NULL
	, @occ_to INT = NULL -- перенос платежа на этот лицевой
	, @paying_id_new INT = 0 OUTPUT
	, @is_success BIT = 0 OUTPUT
	, @strerror VARCHAR(4000) = '' OUTPUT
)
AS
BEGIN
	SET XACT_ABORT, NOCOUNT ON

	DECLARE @RC INT
		  , @docsnum1 INT = 1
		  , @total_pack1 MONEY
		  , @total1 MONEY
		  , @blocked1 BIT
		  , @sup_id_to INT = NULL -- перенос платежа на поставщика
		  , @tip_id SMALLINT
		  , @commission DECIMAL(9, 2)
		  , @commission_pack1 DECIMAL(9, 2)
		  , @paymaccount_peny DECIMAL(9, 2)
		  , @sup_id INT
		  , @pack_id_new INT
		  , @occ1 INT
		  , @peny_save BIT
		  , @paying_manual BIT
		  , @kolPacksClose INT = 0

	SELECT @tip_id = p.tip_id
		 , @sup_id = p.sup_id
		 , @total1 = p.value * -1                      -- меняем знак
		 , @commission = p.commission * -1             -- меняем знак
		 , @paymaccount_peny = p.paymaccount_peny * -1 -- меняем знак
		 , @occ1 = p.occ
		 , @data1 = CASE
                        WHEN @data1 IS NULL THEN p.day
                        ELSE @data1
        END
		 , @peny_save = p.peny_save
		 , @paying_manual = p.paying_manual
		 , @comment1 = CASE
                           WHEN @comment1 IS NULL THEN p.comment
                           ELSE @comment1
        END
	FROM dbo.View_payings p
	WHERE p.id = @paying_id_vozvrat1

	DECLARE @tran_count INT
		  , @tran_name VARCHAR(50) = 'k_payings_vozvrat_add'
	SET @tran_count = @@trancount;

	SELECT @docsnum1 = 1
		 , @total_pack1 = @total1
		 , @commission_pack1 = @commission

	BEGIN TRY

		IF @occ_to > 0
		BEGIN
			-- проверить существования лицевого
			IF NOT EXISTS (
					SELECT *
					FROM dbo.Occupations o
					WHERE occ = @occ_to
				)
			BEGIN
				SELECT TOP (1) @sup_id_to = sup_id
							 , @occ_to = occ
				FROM dbo.Occ_Suppliers
				WHERE occ_sup = @occ_to
				ORDER BY fin_id DESC

				IF @sup_id_to IS NULL
				BEGIN
					RAISERROR (N'Лицевой %d не найден!', 16, 1, @occ_to)
				END
			END
			ELSE
				SELECT @sup_id_to = @sup_id -- поставщик совпадает

		END

		IF @tran_count = 0
			BEGIN TRANSACTION
		ELSE
			SAVE TRANSACTION @tran_name;

		-- создаём пачку
		EXECUTE @RC = [dbo].[k_paydoc_add] @data1 = @data1
										 , @docsnum1 = @docsnum1
										 , @total1 = @total_pack1
										 , @source_id1 = @source_id1
										 , @blocked1 = 0
										 , @tip_id = @tip_id
										 , @commission = @commission_pack1
										 , @sup_id = @sup_id
										 , @id = @pack_id_new OUTPUT
										 , @occ1 = NULL

		IF COALESCE(@pack_id_new, 0) = 0
		BEGIN
			RAISERROR (N'Ошибка добавления пачки!', 16, 1)
			RETURN -1;
		END

		-- добавляем платёж в пачку
		EXECUTE @RC = [dbo].[k_payings_add] @occ1 = @occ1
										  , @pack_id1 = @pack_id_new
										  , @value1 = @total1
										  , @service_id = NULL
										  , @scan1 = 0
										  , @sup_id = @sup_id
										  , @commission = @commission
										  , @paying_vozvrat = @paying_id_vozvrat1
										  , @paymaccount_peny = @paymaccount_peny
										  , @peny_save = @peny_save
										  , @paying_manual = @paying_manual
										  , @comment = @comment1
										  , @id1 = @paying_id_new OUTPUT
		IF COALESCE(@paying_id_new, 0) = 0
		BEGIN
			RAISERROR (N'Ошибка добавления платежа на лицевой %d', 16, 1, @occ1)
			RETURN -1;
		END

		-- закрываем пачку
		EXECUTE @RC = [dbo].[adm_CloseDay] @pack_id = @pack_id_new
										 , @kolPacksClose = @kolPacksClose OUTPUT
		SET @pack_id_new = NULL

		IF @occ_to > 0
		BEGIN
			SELECT @total1 = ABS(@total1)
				 , @commission = ABS(@commission)
				 , @paymaccount_peny = ABS(@paymaccount_peny)

			-- 			if @sup_id_to <> @sup_id
			-- 			begin
			-- создаём пачку
			EXECUTE @RC = [dbo].[k_paydoc_add] @data1 = @data1
											 , @docsnum1 = @docsnum1
											 , @total1 = @total1
											 , @source_id1 = @source_id1
											 , @blocked1 = 0
											 , @tip_id = @tip_id
											 , @commission = @commission
											 , @sup_id = @sup_id_to
											 , @id = @pack_id_new OUTPUT
											 , @occ1 = NULL --@occ_to

			IF COALESCE(@pack_id_new, 0) = 0
			BEGIN
				RAISERROR (N'Ошибка добавления пачки!', 16, 1)
				RETURN -1;
			END
			--             END    

			EXECUTE @RC = [dbo].[k_payings_add] @occ1 = @occ_to
											  , @pack_id1 = @pack_id_new
											  , @value1 = @total1
											  , @service_id = NULL
											  , @scan1 = 0
											  , @sup_id = @sup_id_to
											  , @commission = @commission
											  , @paying_vozvrat = NULL --@paying_id_vozvrat1
											  , @paymaccount_peny = @paymaccount_peny
											  , @peny_save = @peny_save
											  , @paying_manual = @paying_manual
											  , @comment = @comment1
											  , @id1 = @paying_id_new OUTPUT
			IF COALESCE(@paying_id_new, 0) = 0
			BEGIN
				RAISERROR (N'Ошибка добавления платежа на лицевой %d', 11, 1, @occ_to)
				RETURN -1;
			END

			-- закрываем пачку
			EXECUTE @RC = [dbo].[adm_CloseDay] @pack_id = @pack_id_new
											 , @kolPacksClose = @kolPacksClose OUTPUT
		END


		IF @kolPacksClose > 0
			SET @is_success = 1


		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH

		DECLARE @xstate INT;
		SELECT @xstate = XACT_STATE();

		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @tran_count = 0
			ROLLBACK
		IF @xstate = 1
			AND @tran_count > 0
			ROLLBACK TRANSACTION @tran_name;

		EXECUTE k_GetErrorInfo @visible = 0--@debug
							 , @strerror = @strerror OUT
		RAISERROR (@strerror, 16, 1)

	END CATCH;

END
go

