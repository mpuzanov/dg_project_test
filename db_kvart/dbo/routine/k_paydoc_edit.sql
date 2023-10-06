CREATE   PROCEDURE [dbo].[k_paydoc_edit]
(
	@pack_id1		INT
	,@data1			DATETIME
	,@docsnum1		INT
	,@total1		MONEY
	,@source_id1	INT
	,@blocked1		BIT
	,@tip_id		SMALLINT		= NULL
	,@commission	DECIMAL(9, 2)	= NULL
	,@sup_id		INT				= NULL
)
AS
	/*
Редактирование реквизитов  пачки
27/01/09 -- добавлен блок BEGIN TRY

*/
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	IF @sup_id IS NULL
		SET @sup_id=0

	SELECT
		@data1 = dbo.Fun_GetOnlyDate(@data1)

	-- Проверяем равна ли заявленная сумма в пачке и кол-во платежей
	-- сумме введенных платежей по ней
	-- Checked=1 - равна
	DECLARE	@SumPacks	MONEY
			,@kolpaym	INT

	BEGIN TRY
		SELECT
			@SumPacks = SUM(Value)
			,@kolpaym = COUNT(id)
		FROM dbo.PAYINGS
		WHERE pack_id = @pack_id1

		UPDATE dbo.PAYDOC_PACKS 
		SET	source_id	= @source_id1
			,day		= @data1
			,docsnum	= @docsnum1
			,total		= @total1
			,checked	=
				CASE
					WHEN (@SumPacks = @total1) AND
					(@kolpaym = @docsnum1) THEN 1
					ELSE 0
				END
			,blocked	= @blocked1
			,tip_id		= @tip_id
			,commission	= @commission
			,sup_id		= @sup_id
		WHERE id = @pack_id1

		--  заносим историю изменений заданной пачки 
		EXEC k_paydoc_log @pack_id1

	END TRY
	BEGIN CATCH

		RAISERROR ('Ошибка редактирования пачки!', 11, 1)
		RETURN 1

	END CATCH
go

