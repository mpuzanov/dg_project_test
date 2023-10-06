CREATE   PROCEDURE [dbo].[b_bank_dbf2_port]

(
	@data1 DATETIME = NULL
   ,@data2 DATETIME = NULL
   ,@bank1 INT		= NULL
)
AS

	/*
	 Показываем список файлов банков по фильтру (для программы: DBANK)
	 используется в форме платежей из ОРГАНИЗАЦИЙ
	*/

	SET NOCOUNT ON

	IF @data1 IS NULL
		AND @data2 IS NULL
		SELECT
			@data1 = current_timestamp - 60
		   ,@data2 = current_timestamp

	SELECT
		ROW_NUMBER() OVER (ORDER BY [FILENAMEDBF]) AS ID
	   ,FILENAMEDBF
	   ,datafile
	   ,bank_id
	   ,datavvoda
	   ,forwarded
	   ,kol
	   ,summa
	   ,t2.bank_name AS Name_bank
	   ,BS2.filedbf_id
	   ,U.Initials AS SYSUSER
	FROM dbo.View_BANK_TBL_SPISOK AS BS2
		LEFT JOIN dbo.USERS AS U 
			ON BS2.SYSUSER = U.[login]
		JOIN (SELECT DISTINCT
			ext
		   ,PO.bank_name
		FROM dbo.View_PAYCOLL_ORGS AS PO 
		WHERE PO.is_bank = 0
			AND PO.BANK BETWEEN COALESCE(@bank1, 0) AND COALESCE(@bank1, 10000)) AS t2
		ON BS2.bank_id = t2.ext
	WHERE datafile BETWEEN @data1 AND @data2
--AND DBF_TIP=2
go

