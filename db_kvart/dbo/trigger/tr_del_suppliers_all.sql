-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     TRIGGER [dbo].[tr_del_suppliers_all]
ON [dbo].[Suppliers_all]
FOR DELETE
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE	@id				INT
			,@msg			VARCHAR(100)

	SELECT
		@id = d.id
	FROM DELETED AS d

	IF EXISTS (SELECT
				NULL
			FROM dbo.SUPPLIERS AS s
			WHERE s.sup_id = @id)
	BEGIN
		SELECT
			@msg = 'Поставщика удалить нельзя! Т.к. он есть в поставщиках по услугам'
		RAISERROR (@msg, 16, 10)
		ROLLBACK TRAN
		RETURN
	END

END
go

