CREATE   PROCEDURE [dbo].[b_paym_edit]
(
	  @id1 INT -- код платежа
	, @occ2 INT -- новый лицевой
	, @occ1 INT = NULL -- старый лицевой (NULL)
	, @comments1 VARCHAR(100) = NULL
	, @service_id1 VARCHAR(10) = NULL -- услуга
	, @sup_id1 INT = NULL -- поставщик
	, @pdate2 SMALLDATETIME = NULL -- дата платежа
	, @rasschet2 VARCHAR(20) = NULL -- новый расчётный счёт
)
AS
	--
	--  Редактирование платежа из банка
	--
	SET NOCOUNT ON;


	IF @occ2 > 0
		AND NOT EXISTS (
			SELECT 1
			FROM dbo.Occupations 
			WHERE occ = @occ2
		)
	BEGIN
		RAISERROR ('Ошибка! Лицевого  %d  не существует!', 16, 1, @occ2)
		RETURN
	END

	IF NOT EXISTS (
			SELECT id
			FROM dbo.Bank_Dbf
			WHERE id = @id1
		)
	BEGIN
		RAISERROR ('Ошибка! Платежа с кодом: %d  не существует!', 16, 1, @id1)
		RETURN
	END

	IF NOT EXISTS (
			SELECT 1
			FROM dbo.Bank_Dbf 
			WHERE id = @id1
				AND pack_id IS NULL
		)
	BEGIN
		RAISERROR ('Ошибка! Платеж с кодом пачки редактировать нельзя!', 16, 1, @id1)
		RETURN
	END

	IF @service_id1 IS NOT NULL
	BEGIN

		IF NOT EXISTS (
				SELECT 1
				FROM dbo.Consmodes_list 
				WHERE occ = @occ2
					AND service_id = @service_id1
					AND is_counter = 1
			)
		BEGIN
			RAISERROR ('Ошибка! Счетчика по этой услуге нет!', 16, 1, @id1)
			RETURN
		END

	END

	IF @occ2 = 0
		SET @occ2 = NULL

	DECLARE @user_id1 SMALLINT
		  , @date1 SMALLDATETIME
		  , @pdate1 SMALLDATETIME
		  , @occ_sup INT
		  , @rasschet_old VARCHAR(20) = NULL

	SET @date1 = dbo.Fun_GetOnlyDate(current_timestamp)
	SELECT @user_id1 = dbo.Fun_GetCurrentUserId()

	DECLARE @adres1 VARCHAR(100)
		  , @adres2 VARCHAR(100)

	DECLARE @serv VARCHAR(10)
		  , @sup INT

	SELECT @adres1 = adres
		 , @serv = service_id
		 , @sup = sup_id
		 , @pdate1 = pdate
		 , @rasschet_old = rasschet
	FROM dbo.Bank_Dbf 
	WHERE id = @id1

	SELECT @adres2 = address
	FROM dbo.Occupations 
	WHERE occ = @occ2

	IF COALESCE(@serv, '') <> COALESCE(@service_id1, '')
		SET @comments1 = @comments1 + ' (смена услуги)'

	IF @pdate2 IS NOT NULL
		AND @pdate1 <> @pdate2
		SET @comments1 = @comments1 + ' (смена даты оплаты)'

	IF COALESCE(@sup, '') <> COALESCE(@sup_id1, '')
	BEGIN
		SET @comments1 = @comments1 + ' (смена поставщика)'

		SELECT TOP 1 @occ_sup = occ_sup
		FROM dbo.Occ_Suppliers AS OS 
		WHERE occ = @occ1
			AND sup_id = @sup_id1
		ORDER BY OS.fin_id DESC

	END

	IF @occ2 IS NULL
		AND @occ1 IS NOT NULL
		SET @comments1 = @comments1 + ' (смена ед.лицевого)'

	IF COALESCE(@rasschet_old, '') <> COALESCE(@rasschet2, '')
		SET @comments1 = @comments1 + ' (смена расч.счёта)'

	BEGIN TRAN

		UPDATE dbo.Bank_Dbf 
		SET occ = @occ2
		  , date_edit = @date1
		  , adres = COALESCE(@adres2, adres)
		  , service_id = @service_id1
		  , sup_id = COALESCE(@sup_id1, 0)
		  , sch_lic =
						 CASE
							 WHEN @occ_sup IS NOT NULL THEN @occ_sup
							 ELSE sch_lic
						 END
		  , pdate = @pdate2
		  , rasschet = @rasschet2
		WHERE id = @id1

		INSERT INTO dbo.Bank_Dbf_Log (user_id
									, DateEdit
									, kod_paym
									, occ1
									, adres1
									, occ2
									, adres2
									, Comments
									, pdate1
									, pdate2
									, rasschet1
									, rasschet2)
		VALUES(@user_id1
			 , @date1
			 , @id1
			 , @occ1
			 , @adres1
			 , @occ2
			 , COALESCE(@adres2, @adres1)
			 , @comments1
			 , @pdate1
			 , @pdate2
			 , @rasschet_old
			 , @rasschet2)

		-- Проверяем правильность расч/счёта	
		UPDATE bd
		SET error_num = 0
		FROM dbo.Bank_Dbf bd
		WHERE id = @id1

		UPDATE bd
		SET error_num = 1
		  , occ =
					 CASE
						 WHEN @occ2 IS NOT NULL THEN occ
						 ELSE NULL
					 END
		FROM dbo.Bank_Dbf bd
		WHERE id = @id1
			AND (COALESCE(bd.rasschet, '') <> '')
			AND EXISTS (
				SELECT 1
				FROM dbo.Occ_Suppliers os1 
				WHERE os1.occ = bd.occ
					AND os1.sup_id = bd.sup_id
			)
			AND NOT EXISTS (
				SELECT 1
				FROM dbo.Occ_Suppliers os2 
				WHERE os2.occ = bd.occ
					AND os2.sup_id = bd.sup_id
					AND os2.rasschet = bd.rasschet
			)
		COMMIT TRAN
go

