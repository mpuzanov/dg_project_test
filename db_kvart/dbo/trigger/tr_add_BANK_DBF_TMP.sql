
CREATE TRIGGER [dbo].[tr_add_BANK_DBF_TMP]
	ON [dbo].[Bank_dbf_tmp]
	FOR INSERT, UPDATE
	AS
	BEGIN
		SET NOCOUNT ON;
	
		UPDATE b
		SET sysuser=SUSER_SNAME()
			,data_edit = CURRENT_TIMESTAMP
		FROM [dbo].BANK_DBF_TMP AS b 
		JOIN inserted AS i ON b.id=i.id
	END
go

