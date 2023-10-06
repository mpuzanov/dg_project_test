CREATE   PROCEDURE [dbo].[k_raschet_saldo]
(
	  @occ1 INT
	, @debug BIT = 0
)
AS
	--
	--   Раскидываем сальдо по услугам
	--
	/*
	Корретируем сальдо по услугам где есть сальдо
	и нет начисления
	
	09/06/2011
	дата изменений: 28.06.2006
	*/

	SET NOCOUNT ON
	--print '1'
	DECLARE @SumSaldoMinus DECIMAL(9, 2)
		  , @SaldoMinus DECIMAL(9, 2)
		  , @SumSaldoPlus DECIMAL(9, 2)
		  , @SumSaldoItogo DECIMAL(9, 2)
		  , @SumPaid DECIMAL(9, 2)
		  , @SumValue DECIMAL(9, 2)
		  , @ostatok DECIMAL(15, 2)
		  , @service_id1 VARCHAR(10)
		  , @koef DECIMAL(9, 4)
		  , @Saldo_edit SMALLINT
		  , @fin_id1 SMALLINT
		  , @fin_pred1 SMALLINT
		  , @err INT
		  , @saldo_edit_new SMALLINT = NULL

	DECLARE @saldo_new DECIMAL(15, 2)

	SELECT @fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	SET @fin_pred1 = @fin_id1 - 1

	SELECT @SaldoMinus = saldo
		 , @Saldo_edit = saldo_edit
	FROM dbo.Occupations AS o 
	WHERE occ = @occ1


	DECLARE @t1 TABLE (
		  occ INT
		, service_id VARCHAR(10)
		, saldo_history DECIMAL(9, 2)
		, saldo DECIMAL(9, 2)
		, VALUE DECIMAL(9, 2)
		, paid DECIMAL(9, 2)
		, s_plus DECIMAL(9, 2) DEFAULT 0
		, saldo_new DECIMAL(9, 2) DEFAULT 0
		, PRIMARY KEY (occ, service_id)
	)

	INSERT INTO @t1
	SELECT p.occ
		 , p.service_id
		 , saldo_history = COALESCE((
			   SELECT Debt
			   FROM dbo.Paym_history AS ph 
			   WHERE occ = @occ1
				   AND fin_id = @fin_pred1
				   AND ph.service_id = p.service_id
				   AND ph.sup_id = p.sup_id
		   ), 0)
		 , p.saldo
		 , p.VALUE
		 , p.paid
		 , 0
		 , 0
	FROM dbo.Paym_list AS p 
	WHERE p.occ = @occ1
		AND p.account_one = 0

	--IF @Saldo_edit=2   -- 09/06/2011
	--BEGIN
	--  UPDATE @t1
	--  SET saldo=saldo_history
	--END

	--if @SaldoMinus>=0 set @SaldoMinus=0

	SELECT @SumSaldoMinus = COALESCE(SUM(saldo), 0)
	FROM @t1
	WHERE saldo < 0
		AND paid = 0
		AND VALUE = 0
	SELECT @SumSaldoPlus = COALESCE(SUM(saldo), 0)
	FROM @t1
	WHERE saldo > 0
		AND paid = 0
		AND VALUE = 0

	SELECT @SumSaldoItogo = COALESCE(SUM(saldo), 0)
		 , @SumPaid = COALESCE(SUM(paid), 0)
		 , @SumValue = COALESCE(SUM(VALUE), 0)
	FROM @t1

	IF @debug = 1
		SELECT @Saldo_edit AS Saldo_edit
			 , @SaldoMinus AS SaldoMinus
			 , @SumSaldoMinus AS SumSaldoMinus
			 , @SumSaldoPlus AS SumSaldoPlus
			 , @SumSaldoItogo AS SumSaldoItogo
			 , @SumPaid AS SumPaid
			 , @SumValue AS SumValue

	IF (@SumSaldoItogo = 0
		AND @SumPaid = 0
		AND (@SumSaldoMinus <> 0
		OR @SumSaldoPlus <> 0))
		OR (@SaldoMinus = 0
		AND @SumSaldoItogo <> 0) -- обнуляем сальдо на услугах
	BEGIN

		UPDATE dbo.Paym_list 
		SET saldo = 0
		WHERE occ = @occ1

		-- было автоматическое изменение сальдо
		SET @saldo_edit_new = 2

		GOTO LABEL_END
	END


	IF (@SumSaldoMinus <> 0)
		OR (@SumSaldoPlus > 0)
		OR (@SaldoMinus < 0)
		OR (@SaldoMinus <> @SumSaldoMinus)
	BEGIN

		BEGIN TRAN

		-- Если есть переплата по услугам по которым нет начислений
		-- то переносим переплату на услугу где есть начисления
		IF (@SumSaldoMinus <> 0)
			AND (@SumPaid > 0)
		BEGIN

			SELECT TOP 1 @service_id1 = service_id
			FROM @t1
			WHERE paid > 0
			ORDER BY paid DESC

			UPDATE @t1
			SET saldo = 0
			WHERE saldo < 0
				AND paid = 0

			UPDATE @t1
			SET saldo = saldo + @SumSaldoMinus
			WHERE service_id = @service_id1

			--print @service_id1
			SET @SumSaldoMinus = 0
			SELECT @SaldoMinus = SUM(t.saldo)
			FROM @t1 AS t

			-- было автоматическое изменение сальдо
			SET @saldo_edit_new = 2

			IF @debug = 1
				SELECT '@SumSaldoMinus' = @SumSaldoMinus
					 , @SaldoMinus AS SaldoMinus
			IF @debug = 1
				SELECT *
				FROM @t1

		END

		-- Если есть долг по услугам по которым нет начислений
		-- то раскидываем его на услуги где есть начисления
		IF (@SumSaldoPlus > 0)
			AND (@SumValue > 0)
			AND (@SaldoMinus > 0) -- общее сальдо с "+"
		BEGIN
			IF @debug = 1
				PRINT 'Вариант 1'
			SET @koef = @SumSaldoPlus / @SumValue
			IF ROUND(@koef, 2) <> 0
				UPDATE @t1
				SET s_plus = VALUE * @koef --WHERE VALUE>0
			ELSE
			BEGIN -- когда  saldo очень маленькая(0.01), пишем его на одну услугу         
				;WITH cte AS (
					SELECT TOP (1) * FROM @t1 WHERE VALUE > 0
				)
				UPDATE cte
				SET s_plus = @SumSaldoPlus;				
			END

			-- Проверяем остатки
			SELECT @ostatok = @SumSaldoPlus - SUM(s_plus)
			FROM @t1

			IF @ostatok <> 0
			BEGIN
				;WITH cte AS (
					SELECT TOP (1) * FROM @t1 WHERE s_plus > ABS(@ostatok)
				)
				UPDATE cte				
				SET s_plus = s_plus + @ostatok;
			END

			IF @debug = 1
				SELECT *
				FROM @t1

			UPDATE @t1
			SET saldo_new = saldo + s_plus
			WHERE VALUE > 0
				OR paid <> 0

			IF @debug = 1
				SELECT *
				FROM @t1

			UPDATE @t1
			SET saldo = saldo_new

			-- было автоматическое изменение сальдо
			SET @saldo_edit_new = 2
		END

		-- Если переплата раскидываем пропорционально текущим начислениям
		IF (@SaldoMinus <> 0
			AND @SumValue > 0)
			OR (@SaldoMinus <> @SumSaldoMinus
			AND @SumValue > 0
			AND @SumSaldoMinus <> 0)
		BEGIN
			IF @debug = 1
				PRINT 'Вариант 2'
			SET @koef = @SaldoMinus / @SumValue
			IF @debug = 1
				PRINT '@SaldoMinus: ' + STR(@SaldoMinus, 9, 2) + '  @SumValue: ' + STR(@SumValue, 9, 2) + '  @koef: ' + STR(@koef, 9, 2)
			IF ROUND(@koef, 2) <> 0
			BEGIN
				UPDATE @t1
				SET saldo = 0
				UPDATE @t1
				SET saldo = VALUE * @koef
				WHERE VALUE > 0
			END
			ELSE
			BEGIN -- когда  saldo очень маленькая(0.01), пишем его на одну услугу
				UPDATE @t1 SET saldo = 0;

				WITH cte AS (
					SELECT TOP (1) * FROM @t1 WHERE VALUE > 0
				)
				UPDATE cte
				SET saldo = @SaldoMinus;				
			END

			-- Проверяем остатки
			SELECT @ostatok = @SaldoMinus - SUM(saldo)
			FROM @t1
			IF @debug = 1
				PRINT @ostatok		
			IF @debug = 1
				PRINT @SaldoMinus --@ostatok

			IF @ostatok <> 0
			BEGIN
				;WITH cte AS (
					SELECT TOP(1) * FROM @t1 WHERE ABS(saldo) > ABS(@ostatok)
				)
				UPDATE cte
				SET saldo = saldo + @ostatok;				
			END

			-- было автоматическое изменение сальдо
			SET @saldo_edit_new = 2
		END

		-- проверяем сальдо (были случаи очень большого)
		SELECT @saldo_new = ABS(SUM(t.saldo))
		FROM @t1 AS t
		IF @saldo_new > 1000000
		BEGIN
			UPDATE @t1
			SET saldo = saldo_history
			FROM @t1 AS p

			-- было автоматическое изменение сальдо
			SET @saldo_edit_new = 2
		END

		IF @saldo_edit_new = 2 -- было автоматическое изменение сальдо
		BEGIN
			UPDATE dbo.Paym_list
			SET saldo = t.saldo
			FROM dbo.Paym_list AS p
			   , @t1 AS t
			WHERE p.occ = @occ1
				AND p.service_id = t.service_id

			-- было автоматическое изменение сальдо
			UPDATE dbo.Occupations
			SET saldo_edit = 2
			WHERE occ = @occ1
		END


		COMMIT TRAN

	END

LABEL_END:
	IF @debug = 1
		SELECT *
		FROM @t1
	IF @debug = 1
		SELECT *
		FROM Paym_list
		WHERE occ = @occ1
	RETURN

QuitRollBack:
	IF @@trancount > 0
		ROLLBACK TRAN
	RAISERROR (N'Ошибка %d в процедуре k_raschet_saldo. Все изменения отменены!', 16, 1, @err)
go

