-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[b_bank_tbl_FindFile]
(
	@FileNameDbf NVARCHAR(100)
)
AS
/*
exec b_bank_tbl_FindFile @FileNameDbf='mu9107031.pos'
exec b_bank_tbl_FindFile @FileNameDbf='mu9107031'

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @t TABLE
		(
			[datafile]	  [SMALLDATETIME]  NOT NULL
		   ,[filenamedbf] [VARCHAR](100)   NOT NULL
		   ,[datavvoda]	  [SMALLDATETIME]  NOT NULL
		   ,[kol]		  [INT]			   NOT NULL
		   ,[summa]		  [DECIMAL](15, 2) NOT NULL
		   ,[filedbf_id]  [INT]			   NOT NULL
		   ,[commission]  [DECIMAL](9, 2)  NOT NULL
		   ,[dbf_tip]	  [TINYINT]		   NOT NULL
		)

	INSERT
	INTO @t
	(datafile
	,filenamedbf
	,datavvoda
	,kol
	,summa
	,filedbf_id
	,commission
	,dbf_tip)
		SELECT
			datafile
		   ,filenamedbf
		   ,datavvoda
		   ,kol
		   ,summa
		   ,filedbf_id
		   ,commission
		   ,dbf_tip
		FROM dbo.BANK_TBL_SPISOK
		WHERE filenamedbf = @FileNameDbf

	IF @@rowcount = 0
	BEGIN
		-- продолжаем поиск

		-- убираем расширение файла(если есть)
		SET @FileNameDbf = CASE
                               WHEN dbo.strpos('.', @FileNameDbf) > 0
                                   THEN LEFT(@FileNameDbf, dbo.strpos('.', @FileNameDbf) - 1)
                               ELSE @FileNameDbf
            END
		--PRINT @FileNameDbf

		-- ищем без расширения файла
		INSERT
		INTO @t
		(datafile
		,filenamedbf
		,datavvoda
		,kol
		,summa
		,filedbf_id
		,commission
		,dbf_tip)
			SELECT
				datafile
			   ,filenamedbf
			   ,datavvoda
			   ,kol
			   ,summa
			   ,filedbf_id
			   ,commission
			   ,dbf_tip
			FROM dbo.BANK_TBL_SPISOK
			WHERE CASE
				WHEN dbo.strpos('.', [filenamedbf]) > 0 THEN LEFT([filenamedbf], dbo.strpos('.', [filenamedbf]) - 1)
				ELSE [filenamedbf]
			END = @FileNameDbf

	END

	SELECT
		*
	FROM @t
	ORDER BY datafile DESC
END
go

