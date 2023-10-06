-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[tr_add_bank_table]
	ON [dbo].[Bank_tbl_spisok]
	AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE b
	SET sysuser = COALESCE((
			SELECT TOP(1) [login]
			FROM dbo.Users u
			WHERE [login] = SUSER_SNAME()
		), b.sysuser)
	  , data_edit = current_timestamp
	FROM [dbo].Bank_tbl_spisok AS b
		JOIN INSERTED AS i ON b.filedbf_id = i.filedbf_id
	WHERE b.kol <> i.kol
		OR b.summa <> i.summa
		OR b.commission <> i.commission
		OR b.bank_id <> i.bank_id

END
go

