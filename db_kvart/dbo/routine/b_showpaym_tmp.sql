CREATE   PROCEDURE [dbo].[b_showpaym_tmp]
AS
	/*
	 Список платежей из одного файла
	*/
	SET NOCOUNT ON

	SELECT
		ID
	   ,FILENAMEDBF
	   ,DATA_PAYM
	   ,BANK_ID
	   ,SUM_OPL
	   ,PDATE
	   ,GRP
	   ,OCC
	   ,SERVICE_ID
	   ,SCH_LIC
	   ,PACK_ID
	   ,P_OPL
	   ,ADRES
	   ,FIO
	   ,SUP_ID
	   ,COMMISSION
	   ,DOG_INT
	   ,rasschet
	   ,data_edit
	   ,sysuser
	FROM dbo.BANK_DBF_TMP
	WHERE sysuser = SUSER_SNAME()
go

