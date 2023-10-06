CREATE   PROCEDURE [dbo].[k_occ_sup_new]
(
	  @occ INT
	, @dog_int INT
	, @occ_sup INT = 0
	, @group_add BIT = 0
	, @saldo DECIMAL(9, 2) = 0
	, @add_cessia BIT = 0
	, @dolg_mes_start SMALLINT = 0
	, @peny DECIMAL(9, 2) = 0
	, @auto_occ_sup BIT = 0
	, @schtl_old VARCHAR(15) = NULL
)
AS
	/*
  Процедура создания лицевого счёта поставщика по отдельным квитанциям

*/
	SET NOCOUNT ON
	SET XACT_ABORT ON

	IF @group_add IS NULL
		SET @group_add = 0
	IF @auto_occ_sup IS NULL
		SET @auto_occ_sup = 0

	DECLARE @fin_id SMALLINT
		  , @service_id VARCHAR(10)
		  , @build_id INT = NULL
		  , @sup_id INT

	SELECT @fin_id = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ)

	SELECT @sup_id = sup_id
	FROM dbo.Dog_sup AS DS 
	WHERE id = @dog_int

	SELECT TOP 1 @build_id = bldn_id
	FROM dbo.View_occ_all voa 
	WHERE occ = @occ

	IF @auto_occ_sup = 1
	BEGIN
		SELECT @occ_sup = dbo.Fun_GetOccSUP(@occ, @sup_id, @dog_int)
	END
	IF @occ_sup=0
	BEGIN
	IF @group_add = 0
			RAISERROR ('Лицевой счёт поставщика <%i> не удалось создать!', 16, 1, @occ_sup) WITH NOWAIT;

		RETURN -1
	END

	IF EXISTS (
			SELECT 1
			FROM dbo.Occupations 
			WHERE occ = @occ_sup
		)
	BEGIN

		IF @group_add = 0
			RAISERROR ('Лицевой счёт поставщика %i совпадает с единым л/сч!', 16, 1, @occ_sup) WITH NOWAIT;

		RETURN -1
	END

	DELETE dbo.Occ_Suppliers
	WHERE occ_sup = @occ_sup
		AND occ <> @occ
		AND fin_id = @fin_id
		AND sup_id = @sup_id

	PRINT @occ_sup

	IF NOT EXISTS (
			SELECT 1
			FROM dbo.Occ_Suppliers 
			WHERE fin_id = @fin_id
				AND occ = @occ
				AND sup_id = @sup_id
		)
	BEGIN
		INSERT INTO dbo.Occ_Suppliers (fin_id
									 , occ
									 , sup_id
									 , occ_sup
									 , SALDO
									 , Penalty_old
									 , dog_int
									 , schtl_old)
		VALUES(@fin_id
			 , @occ
			 , @sup_id
			 , @occ_sup
			 , @saldo
			 , COALESCE(@peny, 0)
			 , @dog_int
			 , @schtl_old)
	END
	ELSE
	BEGIN
		--	if @group_add=0 
		--	BEGIN
		--		RAISERROR('Лицевой счёт у поставщика уже есть!',16,1) WITH NOWAIT;
		--		RETURN -1
		--	END

		UPDATE Occ_Suppliers WITH (ROWLOCK)
		SET occ_sup = @occ_sup
		WHERE fin_id = @fin_id
			AND occ = @occ
			AND sup_id = @sup_id
			AND occ_sup = 0

		UPDATE Occ_Suppliers WITH (ROWLOCK)
		SET SALDO = @saldo
		  , Penalty_old = COALESCE(@peny, 0)
		  , dog_int = @dog_int
		WHERE fin_id = @fin_id
			AND occ = @occ
			AND sup_id = @sup_id

	END

	-- Добавляем Цессию
	IF @add_cessia = 1
	BEGIN
		IF EXISTS (
				SELECT 1
				FROM dbo.Cessia 
				WHERE occ_sup = @occ_sup
					AND occ <> @occ
			)
			DELETE FROM dbo.Cessia
			WHERE occ_sup = @occ_sup
				AND occ <> @occ

		IF NOT EXISTS (
				SELECT 1
				FROM dbo.Cessia
				WHERE occ_sup = @occ_sup
			)
			-- добавляем цессию по лицевому
			INSERT INTO dbo.Cessia (occ_sup
								  , dolg_mes_start
								  , occ
								  , saldo_start
								  , dog_int)
			VALUES(@occ_sup
				 , COALESCE(@dolg_mes_start, 0)
				 , @occ
				 , @saldo
				 , @dog_int)
		ELSE
			UPDATE dbo.Cessia
			SET dolg_mes_start = @dolg_mes_start
			  , saldo_start = @saldo
			  , dog_int = @dog_int
			WHERE occ_sup = @occ_sup

		-- добавляем сальдо на услугу 'цеся'
		SET @service_id = 'цеся'

		IF EXISTS (
				SELECT 1
				FROM dbo.Paym_list 
				WHERE occ = @occ
					AND service_id = @service_id
			)
			UPDATE dbo.Paym_list
			SET SALDO = @saldo
			  , account_one = 1
			WHERE occ = @occ
				AND service_id = @service_id
		ELSE
			INSERT INTO dbo.Paym_list (occ
									 , service_id
									 , SALDO
									 , account_one
									 , fin_id)
			VALUES(@occ
				 , @service_id
				 , @saldo
				 , 1
				 , @fin_id)

		DECLARE @mode_id INT
			  , @source_id INT
		SELECT @mode_id = (
				SELECT id
				FROM dbo.Cons_modes AS cm 
				WHERE cm.service_id = @service_id
					AND id % 1000 = 0
			)
		SELECT @source_id = (
				SELECT id
				FROM dbo.View_suppliers AS cm 
				WHERE cm.service_id = @service_id
					AND id % 1000 <> 0
					AND sup_id = @sup_id
			)

		-- добавляем режим потребления и поставщика на лицевой по услуге 'цеся'
		IF EXISTS (
				SELECT 1
				FROM dbo.Consmodes_list 
				WHERE occ = @occ
					AND service_id = @service_id
			)
			UPDATE dbo.Consmodes_list
			SET mode_id = @mode_id
			  , source_id = @source_id
			  , account_one = 1
			  , sup_id = @sup_id
			WHERE occ = @occ
				AND service_id = @service_id
		ELSE
			INSERT INTO dbo.Consmodes_list (occ
										  , service_id
										  , mode_id
										  , source_id
										  , account_one
										  , sup_id)
			VALUES(@occ
				 , @service_id
				 , @mode_id
				 , @source_id
				 , 1
				 , @sup_id)
		-- Проверяем есть ли такой режим на доме

		IF NOT EXISTS (
				SELECT 1
				FROM dbo.Build_mode 
				WHERE build_id = @build_id
					AND service_id = @service_id
					AND mode_id = @mode_id
			)
			INSERT INTO dbo.Build_mode (build_id
									  , service_id
									  , mode_id)
			VALUES(@build_id
				 , @service_id
				 , @mode_id)

		-- Проверяем есть ли такой поставщик на доме
		IF NOT EXISTS (
				SELECT 1
				FROM dbo.Build_source 
				WHERE build_id = @build_id
					AND service_id = @service_id
					AND source_id = @source_id
			)
			INSERT INTO dbo.Build_source (build_id
										, service_id
										, source_id)
			VALUES(@build_id
				 , @service_id
				 , @source_id)

	END
go

