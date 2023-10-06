CREATE   PROCEDURE [dbo].[k_vvod_penalty]
(
	  @occ1 INT
	, @Peny_old1 DECIMAL(9, 2) = 0 -- новое пени
	, @comments1 VARCHAR(50)
	, @sup_id1 INT = NULL -- Поставщик
	, @debug BIT = 0
)
AS
	/*
	
	Редактирование пени
	
	дата последней модификации:  2.01.05
	автор изменений: Пузанов М.А.
	
	*/
	SET NOCOUNT ON

	IF @sup_id1 = 0
		SET @sup_id1 = NULL

	--IF @Peny_old1 < 0
	--	SET @Peny_old1 = 0

	DECLARE @err INT
		  , @SumpenyOld DECIMAL(9, 2)
		  , @fin_id1 SMALLINT
		  , @user_id1 SMALLINT
		  , @date1 SMALLDATETIME
		  , @PaymClosed1 BIT

	IF dbo.Fun_AccessPenaltyLic(@occ1) = 0
	BEGIN
		RAISERROR ('Для Вас работа с Пени запрещена', 16, 1)
		RETURN
	END

	IF dbo.Fun_GetOccClose(@occ1) = 0
	BEGIN
		RAISERROR ('Лицевой счет %d закрыт! Работа с ним запрещена', 16, 1, @occ1)
		RETURN
	END

	IF NOT EXISTS (
			SELECT 1
			FROM dbo.Occupations
			WHERE occ = @occ1
		)
	BEGIN
		RAISERROR ('Лицевой счет %d не найден', 16, 10, @occ1)
		RETURN 1
	END

BEGIN TRY

	SELECT @fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	SELECT @PaymClosed1 = ot.PaymClosed
	FROM dbo.Occupations AS o 
		JOIN dbo.Occupation_Types AS ot ON o.tip_id = ot.id
	WHERE occ = @occ1

	--SET @date1=dbo.Fun_GetOnlyDate (current_timestamp) 
	SET @date1 = current_timestamp
	SELECT @user_id1 = dbo.Fun_GetCurrentUserId()

	IF @sup_id1 IS NULL
	BEGIN
		BEGIN TRAN
		INSERT INTO dbo.Penalty_log (occ
									, data
									, user_id
									, sum_old
									, sum_new
									, comments
									, fin_id)
		SELECT @occ1
			 , @date1
			 , @user_id1
			 , Penalty_old
			 , @Peny_old1
			 , @comments1
			 , @fin_id1
		FROM (
		UPDATE dbo.Occupations 
		SET Penalty_old = @Peny_old1 -- новое пени
		  , Penalty_old_new =
							 CASE
								 WHEN @PaymClosed1 = 1 AND
									 (@Peny_old1 - PaymAccount_peny) >= 0 THEN @Peny_old1 - PaymAccount_peny
								 ELSE Penalty_old_new
							 END
		  , Penalty_old_edit = 1 -- ручное изменение пени
		OUTPUT DELETED.Penalty_old
		WHERE occ = @occ1) AS T

		COMMIT TRAN
		-- сохраняем в историю изменений
		EXEC k_write_log @occ1
					   , 'пеня'
	END
	ELSE
	BEGIN -- Изменение пени по поставщику

		BEGIN TRAN

		INSERT INTO dbo.Penalty_log (occ
												  , data
												  , [user_id]
												  , sum_old
												  , sum_new
												  , comments
												  , fin_id)
		SELECT occ_sup
			 , @date1
			 , @user_id1
			 , Penalty_old
			 , @Peny_old1
			 , @comments1
			 , @fin_id1
		FROM (
		UPDATE dbo.Occ_Suppliers 
		SET Penalty_old = @Peny_old1 -- новое пени
		  , Penalty_old_new =
							 CASE
								 WHEN @PaymClosed1 = 1 AND
									 (@Peny_old1 - PaymAccount_peny) >= 0 THEN @Peny_old1 - PaymAccount_peny
								 ELSE Penalty_old_new
							 END
		  , Penalty_old_edit = 1 -- ручное изменение пени
		OUTPUT DELETED.Penalty_old, DELETED.occ_sup
		WHERE occ = @occ1
			AND sup_id = @sup_id1
			AND fin_id = @fin_id1) AS T

		COMMIT TRAN
		-- сохраняем в историю изменений
		EXEC k_write_log @occ1
					   , 'пеня'
					   , 'по поставщику'
	END

	EXEC dbo.k_raschet_peny_serv_old @occ1
								   , @fin_id1
								   , @sup_id1

END TRY
BEGIN CATCH
	EXEC dbo.k_err_messages
END CATCH
go

