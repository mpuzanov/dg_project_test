-- =============================================
-- Author:		Пузанов
-- Create date: 12.10.2011
-- Description:	
-- =============================================
CREATE     TRIGGER [dbo].[PAYDOC_UPDATE]
ON [dbo].[Paydoc_packs]
FOR INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS(SELECT 1 FROM INSERTED WHERE tip_id IS NULL)
	BEGIN
		RAISERROR ('Не заполнен Тип фонда!', 16, 10)
		ROLLBACK TRAN
		RETURN
	END

END
go

