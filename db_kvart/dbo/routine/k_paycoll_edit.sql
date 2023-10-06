CREATE   PROCEDURE [dbo].[k_paycoll_edit]
(
	  @id1 INT
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

DECLARE @is_bank1 BIT = 0
		, @bank_double INT = NULL

IF @ext1 IS NULL
	OR LTRIM(@ext1) = ''
BEGIN
	SELECT @is_bank1 = is_bank
	FROM dbo.BANK
	WHERE id = @bank1

	SELECT @ext1 = dbo.Fun_GetNewExt(@is_bank1)
END

SELECT TOP (1) @bank_double = BANK
FROM dbo.Paycoll_orgs 
WHERE ext = @ext1
	AND BANK <> @bank1
IF @bank_double IS NOT NULL
BEGIN
	RAISERROR (N'Расширение %s используется в банке %d', 16, 1, @ext1, @bank_double)
END

UPDATE dbo.Paycoll_orgs
SET BANK = @bank1
	, vid_paym = @vid_paym1
	, comision = @comision1
	, ext = @ext1
	, [description] = @descr1
	, sup_processing = COALESCE(@sup_processing, 0)
	, paying_order_metod = @paying_order_metod
WHERE id = @id1
go

