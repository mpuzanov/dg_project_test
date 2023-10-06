CREATE   PROCEDURE [dbo].[k_paycoll_add]
(
	  @fin_id1 SMALLINT
	, @bank1 INT
	, @vid_paym1 VARCHAR(10)
	, @comision1 DECIMAL(15, 4) = 0
	, @descr1 VARCHAR(50) = NULL
	, @ext1 VARCHAR(10) = NULL
	, @sup_processing SMALLINT = 0 -- обработка всех платежей, 1-обработка только поставщиков, 2-обработка то единых лицевых    
	, @paying_order_metod VARCHAR(10) = NULL -- метод оплаты пени (пени1 или пени2)
)
AS
	/*
	
	*/
	SET NOCOUNT ON

	IF @descr1 IS NULL
		SET @descr1 = ''

	DECLARE @is_bank1 BIT = 0
		  , @bank_double INT = NULL
		  , @bank_uid UNIQUEIDENTIFIER

	IF @ext1 IS NULL
		OR LTRIM(@ext1) = ''
	BEGIN
		SELECT 
			@is_bank1 = is_bank
		FROM dbo.BANK
		WHERE id = @bank1

		SELECT @ext1 = dbo.Fun_GetNewExt(@is_bank1)
	END

	-- поиск двойных расширений 
	SELECT TOP (1) @bank_double = BANK
	FROM dbo.Paycoll_orgs 
	WHERE ext = @ext1
		AND BANK <> @bank1

	IF @bank_double IS NOT NULL
	BEGIN
		RAISERROR (N'Расширение %s используется в банке %d', 16, 1, @ext1, @bank_double)
	END

	SELECT 
		@bank_uid = bank_uid
	FROM dbo.BANK
	WHERE id = @bank1

	DECLARE @paycoll_uid UNIQUEIDENTIFIER = dbo.fn_newid()

	INSERT INTO dbo.Paycoll_orgs (fin_id
								, paycoll_uid
								, BANK
								, vid_paym
								, comision
								, ext
								, description
								, sup_processing
								, paying_order_metod
								, bank_uid)
	VALUES(@fin_id1
		 , @paycoll_uid
		 , @bank1
		 , @vid_paym1
		 , @comision1
		 , @ext1
		 , @descr1
		 , COALESCE(@sup_processing, 0)
		 , @paying_order_metod
		 , @bank_uid)
go

