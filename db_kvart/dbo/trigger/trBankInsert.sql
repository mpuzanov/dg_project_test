-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[trBankInsert]
   ON  [dbo].[Bank]
   FOR INSERT
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE b
	SET bank_uid = dbo.fn_newid()
	FROM INSERTED AS i
	JOIN dbo.bank AS b ON 
		i.id = b.id
	WHERE i.bank_uid IS NULL
END
go

