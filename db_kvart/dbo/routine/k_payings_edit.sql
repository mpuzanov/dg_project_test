CREATE   PROCEDURE [dbo].[k_payings_edit]
(
	  @id1 INT
	, @value1 MONEY
	, @service_id VARCHAR(10) = NULL
	, @sup_id INT = NULL
	, @commission DECIMAL(9, 2) = NULL
	, @paying_vozvrat INT = NULL
	, @occ1 INT = NULL
	, @paymaccount_peny DECIMAL(9, 2) = NULL
	, @peny_save BIT = 0 -- оплата пени как в платеже
	, @paying_manual BIT = 0 -- ручное изменение по услугам
	, @comment VARCHAR(100) = NULL
)
AS
	/*
	
	Ручное изменение суммы платежа
	дата создания: 11.03.2004
	автор: Пузанов М.А.
	
	*/
	SET NOCOUNT ON
	SET XACT_ABORT ON

	IF @occ1 IS NULL
		SELECT @occ1 = occ
		FROM dbo.Payings
		WHERE id = @id1

	IF @paying_vozvrat = 0
		SET @paying_vozvrat = NULL

	IF @service_id = ''
		SET @service_id = NULL

	IF @peny_save IS NULL
		SET @peny_save = 0
	IF @paying_manual IS NULL
		SET @paying_manual = 0

	IF (COALESCE(@paymaccount_peny, 0) <> 0)
		AND (ABS(COALESCE(@paymaccount_peny, 0)) > ABS(@value1))
	BEGIN
		RAISERROR ('Ошибка! Оплата пени больше платежа!', 16, 1)
		RETURN
	END

BEGIN TRY

	DECLARE @pack_id1 INT
		  , @service_id2 VARCHAR(10)
		  , @sup_name VARCHAR(50)
		  , @occ_sup INT

	IF @sup_id IS NOT NULL
	BEGIN
		IF NOT EXISTS (
				SELECT 1
				FROM dbo.Consmodes_list 
				WHERE occ = @occ1
					AND sup_id = @sup_id
			)
		BEGIN
			SELECT @sup_name = name
			FROM dbo.Suppliers_all 
			WHERE id = @sup_id
			RAISERROR ('Поставщика <%s> на лицевом %d с отдельной квитанцией нет!', 16, 1, @sup_name, @occ1)
			RETURN
		END

		SELECT TOP 1 @occ_sup = occ_sup
		FROM dbo.Occ_Suppliers AS OS 
		WHERE occ = @occ1
			AND sup_id = @sup_id
		ORDER BY OS.fin_id DESC

	END

	IF @sup_id IS NULL
		AND NOT EXISTS (
			SELECT 1
			FROM dbo.Occupations 
			WHERE occ = @occ1
		)
	BEGIN
		RAISERROR ('Лицевого счета %d нет!', 16, 10, @occ1)
		RETURN (1)
	END

	SELECT @pack_id1 = pack_id
		 , @service_id2 = service_id
	FROM dbo.Payings 
	WHERE id = @id1

	IF @paying_manual = 0
	BEGIN
		DELETE FROM dbo.Paying_serv
		WHERE paying_id = @id1
	END
	--BEGIN -- проверяем сходятся ли суммы по услугам и в платеже
	--	DECLARE @SumServ1 DECIMAL(9, 2)
	--		   ,@SumServ2 DECIMAL(9, 2)
	--		   ,@SumServ3 DECIMAL(9, 2)

	--	SELECT
	--		@SumServ1 = SUM(ps.value)
	--	   ,@SumServ2 = SUM(ps.PaymAccount_peny)
	--	   ,@SumServ3 = SUM(ps.commission)
	--	FROM PAYING_SERV ps
	--	WHERE ps.paying_id = @id1

	--	IF (@SumServ1 <> @value1)
	--		OR (@SumServ2 <> @paymaccount_peny)
	--		OR (@SumServ3 <> @commission)
	--	BEGIN
	--		RAISERROR ('Не сходятся суммы к оплате в платеже и по услугам!', 16, 10, @occ1)
	--		RETURN (1)
	--	END
	--END

	BEGIN TRAN
		IF @sup_id IS NULL
			SET @sup_id = 0

		UPDATE dbo.Payings 
		SET value = @value1
		  , scan = 0
		  , service_id = @service_id
		  , sup_id = COALESCE(@sup_id, 0)
		  , commission = COALESCE(@commission, 0)
		  , paying_vozvrat = @paying_vozvrat
		  , paymaccount_peny = COALESCE(@paymaccount_peny, 0)
		  , peny_save = @peny_save
		  , paying_manual = @paying_manual
		  , occ = @occ1
		  , occ_sup =
						 CASE
							 WHEN COALESCE(occ_sup, occ) <> COALESCE(@occ_sup, @occ1) THEN COALESCE(@occ_sup, @occ1)
							 ELSE occ_sup
						 END
		  , comment = @comment
		WHERE id = @id1

		-- Проверяем равна ли заявленная сумма в пачке и количество платежей
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

		-- обновляем правильность(или нет) пачки или нет у всех платежей
		UPDATE P 
		SET checked = PP.checked
		FROM dbo.Payings AS P
			JOIN dbo.Paydoc_packs AS PP ON P.pack_id = PP.id
		WHERE PP.id = @pack_id1

		COMMIT TRAN

		EXEC k_paydoc_log @pack_id1 = @pack_id1

		EXEC b_UpdateSupPack @pack_id = @pack_id1

		-- сохраняем в историю изменений
		IF COALESCE(@service_id, '') <> COALESCE(@service_id2, '')
			EXEC k_write_log @occ1 = @occ1
						   , @oper1 = 'плат'
						   , @comments1 = 'изменение в услуге'
		ELSE
			EXEC k_write_log @occ1 = @occ1
						   , @oper1 = 'плат'

END TRY
BEGIN CATCH
	EXEC dbo.k_err_messages
END CATCH
go

