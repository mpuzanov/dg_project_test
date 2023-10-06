CREATE TRIGGER [dbo].[tr_add_bank_dbf]
   ON  [dbo].[Bank_Dbf]
   AFTER  INSERT,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
	
	UPDATE b
	SET sysuser=SUSER_SNAME()
		,date_edit = CURRENT_TIMESTAMP
	FROM [dbo].BANK_DBF AS b 
	JOIN inserted AS i ON b.id=i.id

END
go

