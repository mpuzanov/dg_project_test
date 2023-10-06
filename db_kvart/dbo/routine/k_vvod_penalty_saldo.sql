CREATE   PROCEDURE [dbo].[k_vvod_penalty_saldo]
(
	@occ1	INT
	,@debug	BIT	= 0
)
AS
	/*
	
	Корректировка пени и начального сальдо
	Когда есть переплата и пени за прошлый месяц
	
	дата последней модификации: 09.06.11
	автор изменений: Пузанов М.А.
	
	*/
	SET NOCOUNT ON

	RETURN
	-- *********************************************************************************
	-- Отключил временно. Сальдо менять нельзя 02.04.2012
	-- *********************************************************************************





	DECLARE	@err		INT
			,@fin_id1	SMALLINT
			,@user_id1	SMALLINT
			,@date1		SMALLDATETIME
			,@comments1	VARCHAR(50)	= 'Корректировка пени и сальдо'

	DECLARE	@SumPenyOld				DECIMAL(9, 2)
			,@SumSaldoOld			DECIMAL(9, 2)
			,@SumPenalty_old_new	DECIMAL(9, 2)
			,@SumPenyNew			DECIMAL(9, 2)
			,@SumSaldoNew			DECIMAL(9, 2)
			,@SumValue				DECIMAL(9, 2)
			,@SumSaldoServ			DECIMAL(9, 2)	= 0


	--IF dbo.Fun_AccessPenaltyLic(@occ1)=0
	--BEGIN
	--   RAISERROR('Для Вас работа с Пени запрещена',16,1)
	--   RETURN
	--END

	IF dbo.Fun_GetOccClose(@occ1) = 0
	BEGIN
		--RAISERROR('Лицевой счет %d закрыт! Работа с ним запрещена',16,1,@occ1)
		RETURN
	END

	IF NOT EXISTS (SELECT
				1
			FROM dbo.OCCUPATIONS
			WHERE occ = @occ1)
	BEGIN
		--RAISERROR('Лицевой счет %d не найден',16,10,@occ1)
		RETURN 1
	END

	SELECT
		@fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	SET @date1 = dbo.Fun_GetOnlyDate('Режим')
	SELECT
		@user_id1 = dbo.Fun_GetCurrentUserId()

	SELECT
		@SumSaldoOld = saldo
		,@SumPenyOld = Penalty_old
		,@SumPenalty_old_new = Penalty_old_new
		,@SumValue = value
	FROM dbo.OCCUPATIONS 
	WHERE occ = @occ1

	SELECT
		@SumSaldoServ = SUM(saldo)
	FROM dbo.PAYM_LIST AS p
	WHERE occ = @occ1

	IF @debug = 1
		SELECT
			@SumPenyOld AS PenyOld
			,@SumPenalty_old_new AS Penalty_old_new
			,@SumSaldoOld AS Saldo
			,@SumSaldoServ AS SumSaldoServ
			,@SumValue AS SumValue

	IF @SumValue = 0
		AND @SumPenyOld > 0
		AND @SumSaldoOld < 0
		AND (ABS(@SumSaldoOld) >= @SumPenyOld)
		AND @SumSaldoOld = @SumSaldoServ
	BEGIN
		SET @SumSaldoNew = @SumSaldoOld + @SumPenyOld
		SET @SumPenyNew = 0
		IF @SumPenalty_old_new >= @SumPenyOld
			SET @SumPenalty_old_new = @SumPenalty_old_new - @SumPenyOld
	END
	ELSE
	BEGIN

		RETURN
	END

	IF @debug = 1
		SELECT
			@SumSaldoNew AS SumSaldoNew
			,@SumPenyNew AS SumPenyNew

	BEGIN TRAN
		IF @debug = 1
			PRINT 'Изменяем сальдо по услугам'
		IF EXISTS (SELECT
					1
				FROM dbo.PAYM_LIST
				WHERE occ = @occ1
				AND saldo < 0)
			BEGIN
				;WITH cte AS (
					SELECT TOP (1) * 
					FROM dbo.PAYM_LIST AS p 
					WHERE occ = @occ1
						AND saldo < 0
				)
				UPDATE cte
				SET saldo = saldo + @SumPenyOld;				
			END
		ELSE
			BEGIN
				;WITH cte AS (
					SELECT TOP (1) * 
					FROM dbo.PAYM_LIST AS p 
					WHERE occ = @occ1
						AND saldo > 0
				)
				UPDATE cte
				SET saldo = saldo - @SumPenyOld;
			END

		UPDATE dbo.Occupations 
		SET	saldo				= @SumSaldoNew
			,saldo_edit			= 1
			,Penalty_old		= @SumPenyNew  -- новое пени
			,Penalty_old_new	= @SumPenalty_old_new
			,Penalty_old_edit	= 2 -- изменение пени и сальдо
		WHERE occ = @occ1

		INSERT
		INTO dbo.PENALTY_LOG 
		(	occ
			,data
			,user_id
			,sum_old
			,sum_new
			,comments
			,fin_id)
		VALUES (@occ1
				,@date1
				,@user_id1
				,@SumPenyOld
				,@SumPenyNew
				,@comments1
				,@fin_id1)

	COMMIT TRAN

	-- сохраняем в историю изменений
	EXEC k_write_log	@occ1
						,'пеня'
						,'Корректировка пени и сальдо'
go

