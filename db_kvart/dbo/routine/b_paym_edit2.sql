CREATE   PROCEDURE [dbo].[b_paym_edit2]
(
	@id1		 INT -- код платежа
   ,@occ2		 INT -- новый лицевой
   ,@occ1		 INT		   = NULL -- старый лицевой (NULL)
   ,@comments1	 VARCHAR(50)   = NULL
   ,@service_id1 VARCHAR(10)   = NULL -- услуга
   ,@sup_id1	 INT		   = NULL -- поставщик	
   ,@pdate2		 SMALLDATETIME = NULL -- дата платежа
)
AS
	--
	--  Редактирование платежа из банка
	--
	SET NOCOUNT ON

	IF @occ2 > 0
		AND NOT EXISTS (SELECT
				1
			FROM dbo.OCCUPATIONS 
			WHERE occ = @occ2)
	BEGIN
		RAISERROR ('Ошибка! Лицевого  %d  не существует!', 16, 1, @occ2)
		RETURN
	END

	IF NOT EXISTS (SELECT
				1
			FROM dbo.BANK_DBF 
			WHERE id = @id1)
	BEGIN
		RAISERROR ('Ошибка! Платежа с кодом: %d  не существует!', 16, 1, @id1)
		RETURN
	END

	IF NOT EXISTS (SELECT
				1
			FROM dbo.BANK_DBF 
			WHERE id = @id1
			AND pack_id IS NULL)
	BEGIN
		RAISERROR ('Ошибка! Платеж с кодом пачки редактировать нельзя!', 16, 1, @id1)
		RETURN
	END

	IF @service_id1 IS NOT NULL
	BEGIN

		IF NOT EXISTS (SELECT
					*
				FROM dbo.CONSMODES_LIST 
				WHERE occ = @occ2
				AND service_id = @service_id1
				AND is_counter = 1)
		BEGIN
			RAISERROR ('Ошибка! Счетчика по этой услуге нет!', 16, 1, @id1)
			RETURN
		END

	END

	IF @occ2 = 0
		SET @occ2 = NULL

	DECLARE @user_id1 SMALLINT
		   ,@date1	  SMALLDATETIME

	SET @date1 = dbo.Fun_GetOnlyDate(current_timestamp)
	SELECT
		@user_id1 = dbo.Fun_GetCurrentUserId()

	DECLARE @adres1	 VARCHAR(50)
		   ,@adres2	 VARCHAR(50)
		   ,@serv	 VARCHAR(10)
		   ,@sup	 INT
		   ,@pdate1	 SMALLDATETIME
		   ,@occ_sup INT

	SELECT
		@adres1 = adres
	   ,@serv = service_id
	   ,@sup = sup_id
	   ,@pdate1 = pdate
	FROM dbo.BANK_DBF 
	WHERE id = @id1
	SELECT
		@adres2 = address
	FROM dbo.OCCUPATIONS 
	WHERE occ = @occ2

	IF COALESCE(@serv, '') <> COALESCE(@service_id1, '')
		SET @comments1 = @comments1 + ' (смена услуги)'

	IF @pdate2 IS NOT NULL
		SET @comments1 = @comments1 + ' (смена даты оплаты)'

	IF COALESCE(@sup, '') <> COALESCE(@sup_id1, '')
	BEGIN
		SET @comments1 = @comments1 + ' (смена поставщика)'

		SELECT TOP 1
			@occ_sup = occ_sup
		FROM dbo.OCC_SUPPLIERS AS OS 
		WHERE occ = @occ1
		AND sup_id = @sup_id1
		ORDER BY OS.fin_id DESC

	END

	BEGIN TRAN

		UPDATE dbo.BANK_DBF
		SET occ		   = @occ2
		   ,date_edit  = @date1
		   ,adres	   = @adres2
		   ,service_id = @service_id1
		   ,sup_id	   = COALESCE(@sup_id1, 0)
		   ,sch_lic	   =
				CASE
					WHEN @occ_sup IS NOT NULL THEN @occ_sup
					ELSE sch_lic
				END
		   ,pdate	   = @pdate2
		WHERE id = @id1

		INSERT INTO dbo.BANK_DBF_LOG
		(user_id
		,dateEdit
		,kod_paym
		,occ1
		,adres1
		,occ2
		,adres2
		,comments
		,pdate1
		,PDATE2)
		VALUES (@user_id1
			   ,@date1
			   ,@id1
			   ,@occ1
			   ,@adres1
			   ,@occ2
			   ,@adres2
			   ,@comments1
			   ,@pdate1
			   ,@pdate2)

		COMMIT TRAN
go

