-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	Обновление поставщика в пачке
-- =============================================
CREATE   PROCEDURE [dbo].[b_UpdateSupPack]
(
	@pack_id INT
)
AS
/*
b_UpdateSupPack 36576
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE	@sup_id	INT
			,@kol	INT	= 0;

	UPDATE p
	SET @sup_id = sup_id = COALESCE(dbo.Fun_GetSUPFromSchetl(occ_sup), 0)
	FROM dbo.PAYINGS AS p
	WHERE p.pack_id = @pack_id;

	SELECT
		@kol = COUNT(DISTINCT sup_id)
	FROM dbo.PAYINGS AS p 
	WHERE p.pack_id = @pack_id;

	--PRINT @kol
	IF @kol = 1
		UPDATE dbo.PAYDOC_PACKS
		SET sup_id = COALESCE(@sup_id, 0)
		WHERE id = @pack_id
		AND sup_id <> @sup_id;

END;
go

