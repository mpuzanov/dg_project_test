CREATE   PROCEDURE [dbo].[b_bank_tmp_dbf_del]
AS
	delete from dbo.bank_dbf_tmp where sysuser=SUSER_SNAME()
go

