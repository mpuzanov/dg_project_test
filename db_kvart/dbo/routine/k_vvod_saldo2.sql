CREATE   PROCEDURE [dbo].[k_vvod_saldo2]
(
	@occ1		INT
   ,@saldo_str1 VARCHAR(4000) -- строка формата: код услуги,код поставщика,сумма сальдо;код услуги,код поставщика,сумма сальдо
   ,@debug BIT =0
)
AS
	/*
	
	Редактирование сальдо	
	
	дата последней модификации:  28.11.18
	автор изменений: Пузанов М.А.
	
	*/
	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE @err		   INT
		   ,@fin_id1	   SMALLINT
		   ,@SumSaldo1	   DECIMAL(9, 2)
		   ,@SumSaldo2	   DECIMAL(9, 2)
		   ,@tip_id		   SMALLINT
		   ,@SaldoEditTrue BIT = 1
		   ,@s			   VARCHAR(50)
		   ,@SumSaldoOld   DECIMAL(9, 2)
		   ,@msg		   VARCHAR(100)
		   ,@sup_id		   INT

	IF dbo.Fun_AccessSaldoLic(@occ1) = 0
	BEGIN
		RAISERROR ('Для Вас работа с Сальдо запрещена', 16, 1)
		RETURN
	END

	IF dbo.Fun_GetOccClose(@occ1) = 0
	BEGIN
		RAISERROR ('Лицевой счет %d закрыт! Работа с ним запрещена', 16, 1, @occ1)
		RETURN
	END

	IF NOT EXISTS (SELECT
				1
			FROM dbo.OCCUPATIONS 
			WHERE occ = @occ1)
	BEGIN
		RAISERROR ('Лицевой счет %d не найден', 16, 10, @occ1)
		RETURN 1
	END

BEGIN TRY

	SELECT
		@tip_id = o.tip_id
	   ,@SaldoEditTrue = ot.SaldoEditTrue
	   ,@fin_id1 = o.fin_id
	FROM dbo.OCCUPATIONS AS o 
	JOIN dbo.OCCUPATION_TYPES AS ot 
		ON o.tip_id = ot.id
	WHERE occ = @occ1

	-- проверяем запрет изменения сальдо если есть история
	IF @SaldoEditTrue = 0
		AND EXISTS (SELECT
				1
			FROM dbo.OCC_HISTORY
			WHERE occ = @occ1)
	BEGIN
		SET @msg = N'У Лицевого счета %d есть история начислений. ' + NCHAR(13) + NCHAR(10) + N'Сальдо менять нельзя! Используйте перерасчёты.'
		RAISERROR (@msg, 16, 10, @occ1)
		RETURN 1
	END

	IF @debug=1 PRINT 'готовим Таблицу с новыми значениями сальдо'
	-- Таблица с новыми значениями сальдо
	DECLARE @t1 TABLE
		(
			service_id VARCHAR(10)
		   ,sup_id	   INT DEFAULT 0
		   ,new_saldo  DECIMAL(9, 2)
		   ,PRIMARY KEY (service_id, sup_id)
		)

	INSERT INTO @t1
		SELECT
			*
		FROM dbo.Fun_split_Id3(@saldo_str1, ';', ',')

	IF @debug=1 select * from @t1

	-- Проверяем все ли правильные услуги(есть код в SERVICES)
	IF EXISTS (SELECT
				1
			FROM @t1
			WHERE NOT EXISTS (SELECT
					1
				FROM dbo.View_SERVICES
				WHERE id = service_id))
	BEGIN
		RAISERROR ('Ошибка в формирование строки услуг для сальдо!', 16, 1)
		RETURN 1
	END

	SELECT
		@SumSaldo1 = COALESCE(SUM(new_saldo), 0)
	FROM @t1

	SELECT
		@SumSaldoOld = COALESCE(SUM(saldo), 0)
	FROM dbo.PAYM_LIST 
	WHERE occ = @occ1
	AND fin_id = @fin_id1
	SET @s = STR(@SumSaldoOld, 9, 2)
	--Raiserror (@s,11,1)

	BEGIN TRAN


		MERGE dbo.PAYM_LIST AS p USING @t1 AS p1
		ON p.occ = @occ1
			AND p.fin_id = @fin_id1
			AND p.service_id = p1.service_id
			AND p.sup_id = p1.sup_id
		WHEN MATCHED
			THEN UPDATE
				SET p.saldo = p1.new_saldo
		WHEN NOT MATCHED
			THEN INSERT
				(occ
				,fin_id				
				,service_id
				,sup_id
				,subsid_only
				,account_one
				,tarif
				,KOEF
				,kol
				,saldo)
				VALUES (@occ1
					   ,@fin_id1
					   ,p1.service_id
					   ,p1.sup_id
					   ,0
					   ,0
					   ,0
					   ,1
					   ,0
					   ,p1.new_saldo);

		SELECT
			@SumSaldo2 = COALESCE(SUM(saldo), 0)
		FROM dbo.PAYM_LIST 
		WHERE occ = @occ1
		AND fin_id = @fin_id1
		SET @s = @s + ' -> ' + STR(@SumSaldo2, 9, 2)

		UPDATE dbo.OCCUPATIONS 
		SET saldo	   = @SumSaldo2 -- новое сальдо
		   ,saldo_edit = 1 -- ручное изменение сальдо
		WHERE occ = @occ1

		-- сохраняем в историю изменений
		EXEC k_write_log @occ1
						,'слдо'
						,@s

		COMMIT TRAN

		EXEC k_raschet_1 @occ1 = @occ1
						,@fin_id1 = @fin_id1

END TRY
BEGIN CATCH
	EXEC dbo.k_err_messages
END CATCH
go

