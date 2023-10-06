CREATE   PROCEDURE [dbo].[k_payings_add]
(
	  @occ1 INT
	, @pack_id1 INT
	, @value1 MONEY
	, @service_id VARCHAR(10) = NULL
	, @scan1 SMALLINT
	, @sup_id INT = NULL
	, @commission DECIMAL(9, 2) = NULL
	, @paying_vozvrat INT = NULL
	, @paymaccount_peny DECIMAL(9, 2) = NULL
	, @peny_save BIT = 0 -- оплата пени как в платеже
	, @paying_manual BIT = 0 -- ручное изменение по услугам
	, @comment VARCHAR(100) = NULL
	, @id1 INT = 0 OUTPUT -- код нового платежа
)
AS
	/*
		Добавляем платеж в пачку
			
	
	дата создания: 11.03.2004
	автор: Пузанов М.А.
	
	дата последней модификации:12.08.2013
	автор изменений:Пузанов
	Добавил @paying_vozvrat
	
	*/

	SET NOCOUNT ON
	SET XACT_ABORT ON

	IF @value1 = 0
	BEGIN
		RETURN
	END

	IF @peny_save IS NULL
		SET @peny_save = 0
	IF @paying_vozvrat = 0
		SET @paying_vozvrat = NULL
	IF @paying_manual IS NULL
		SET @paying_manual = 0

	DECLARE @service_kod1 TINYINT
		  , @tip_id SMALLINT -- тип фонда платежа
		  , @tip_pack SMALLINT -- тип жилого фонда в пачке
		  , @sup_name VARCHAR(50)
		  , @occ_sup INT
		  , @fin_id1 SMALLINT
		  , @pack_uid UNIQUEIDENTIFIER
		  , @strerror VARCHAR(4000)
		  , @build_id INT


	SELECT @occ1 = dbo.Fun_GetFalseOccIn(@occ1)

	IF EXISTS(SELECT * FROM dbo.Occ_Suppliers WHERE occ_sup=@occ1)
	BEGIN
		SELECT TOP(1) @occ1=occ, @sup_id=sup_id
		FROM dbo.Occ_Suppliers 
		WHERE occ_sup=@occ1
	END

	IF COALESCE(@sup_id, 0) = 0
		AND NOT EXISTS (
			SELECT 1
			FROM dbo.Occupations 
			WHERE occ = @occ1
		)
	BEGIN
		IF (@occ1 > 9999999)
			AND (@occ1 <= 99999999) -- 8 значный код
		BEGIN
			SELECT @service_kod1 = @occ1 / 10000000
			SELECT @occ1 = (@occ1 % 10000000) / 10
			SELECT @service_id = id
			FROM dbo.Services 
			WHERE service_kod = @service_kod1
		END

		IF NOT EXISTS (
			SELECT 1 FROM dbo.Occupations WHERE occ = @occ1
		)
		BEGIN
			RAISERROR ('Лицевого счета %d нет!', 16, 10, @occ1)
			RETURN (1)
		END
	END

	IF COALESCE(@sup_id, 0) > 0
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
			RAISERROR ('Поставщика(с кодом %d) на лиц/сч %d с отдельной квитанцией нет!', 16, 1, @sup_id, @occ1)
			RETURN
		END

		SELECT TOP 1 @occ_sup = occ_sup
		FROM dbo.Occ_Suppliers AS OS 
		WHERE occ = @occ1
			AND sup_id = @sup_id
		ORDER BY OS.fin_id DESC

	END

	SELECT @tip_id = tip_id, @build_id=f.bldn_id
	FROM dbo.Occupations as o 
		JOIN dbo.Flats f  ON o.flat_id=f.id
	WHERE occ = @occ1

	SELECT @tip_pack = tip_id
		 , @fin_id1 = fin_id
		 , @pack_uid = pack_uid
	FROM dbo.Paydoc_packs 
	WHERE id = @pack_id1

	IF @tip_id <> @tip_pack
	BEGIN
		RAISERROR ('Тип фонда пачки не совпадает с типом фонда платежа!', 16, 1)
		RETURN
	END

	if Exists(SELECT * FROM dbo.Buildings WHERE id=@build_id AND blocked_house=1)
	BEGIN
		RAISERROR ('На доме стоит блокировка оплаты!', 16, 1)
		RETURN
	END
	--********************* 
	--exec @id1=dbo.k_payings_next
	--********************* 

	BEGIN TRAN

		IF @sup_id IS NULL
			SET @sup_id = 0

		INSERT INTO dbo.Payings (pack_id
								, occ
								, value
								, fin_id
								, service_id
								, scan
								, sup_id
								, commission
								, paying_vozvrat
								, occ_sup
								, paymaccount_peny
								, peny_save
								, paying_manual
								, comment)
		VALUES(@pack_id1
			 , @occ1
			 , @value1
			 , @fin_id1
			 , @service_id
			 , @scan1
			 , COALESCE(@sup_id, 0)
			 , COALESCE(@commission, 0)
			 , @paying_vozvrat
			 , @occ_sup
			 , COALESCE(@paymaccount_peny, 0)
			 , @peny_save
			 , @paying_manual
			 , @comment)

		SELECT @id1 = SCOPE_IDENTITY() -- код платежа

		-- Проверяем равна ли заявленная сумма в пачке и кол-во платежей
		-- сумме введенных платежей по ней
		-- Checked=1 - равна
		DECLARE @SumPacks MONEY
			  , @kolpaym INT
		SELECT @SumPacks = SUM(value)
			 , @kolpaym = COUNT(id)
			 , @commission = SUM(COALESCE(commission, 0))
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

		-- обновляем правильность пачки или нет у всех платежей
		UPDATE P 
		SET checked = PP.checked
		FROM dbo.Payings AS P
			JOIN dbo.Paydoc_packs AS PP ON P.pack_id = PP.id
		WHERE PP.id = @pack_id1

		COMMIT TRAN

		EXEC dbo.k_paydoc_log @pack_id1 = @pack_id1

		EXEC b_UpdateSupPack @pack_id = @pack_id1

		-- сохраняем в историю изменений
		EXEC k_write_log @occ1 = @occ1
					   , @oper1 = 'плат'
go

