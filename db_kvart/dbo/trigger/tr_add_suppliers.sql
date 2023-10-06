-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[tr_add_suppliers]
ON [dbo].[Suppliers]
FOR INSERT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE	@service_id		VARCHAR(10)
			,@service_no	SMALLINT
			,@kod INT

	SELECT
		@service_no = s.service_no
	FROM INSERTED AS i
	JOIN dbo.SERVICES AS s ON s.id = i.service_id	
	--PRINT @service_no

	SELECT
		@kod = MAX(id) + 1
	FROM dbo.SUPPLIERS
	WHERE id BETWEEN (@service_no * 1000) AND ((@service_no + 1) * 1000)-1
		
	IF @kod IS NULL
		SET @kod = @service_no * 1000
	
	--PRINT @kod

	UPDATE s
	SET	id		= @kod
		,name	= sa.name
		,account_one=COALESCE(sa.account_one,0)
	FROM dbo.Suppliers AS s
	JOIN INSERTED AS i ON s.id_key=i.id_key
	JOIN dbo.SUPPLIERS_ALL AS sa
		ON s.sup_id = sa.id
	--PRINT @@rowcount
END
go

