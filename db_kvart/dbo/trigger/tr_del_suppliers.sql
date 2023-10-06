-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       TRIGGER [dbo].[tr_del_suppliers]
ON [dbo].[Suppliers]
FOR DELETE
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE	@id				INT
			,@msg			VARCHAR(100)
			,@service_id	VARCHAR(10)

	SELECT
		@id = d.id
		,@service_id = service_id
	FROM DELETED AS d

	IF EXISTS (SELECT
				null
			FROM dbo.CONSMODES_LIST AS cl
			WHERE cl.source_id = @id
			AND cl.service_id = @service_id)
	BEGIN
		SELECT
			@msg = 'Поставщика удалить нельзя! Т.к. он используется'
		RAISERROR (@msg, 16, 10)
		ROLLBACK TRAN
		RETURN
	END

END
go

