/*

дата создания:
автор: 

дата последней модификации:  10.06.05
автор изменений:  Кривобоков А.В.
увеличен промежуток для PO.BANK был до 100 сделал 200
*/

CREATE   PROCEDURE [dbo].[b_show_bank_dbf2_2]
(
	@data1 DATE
   ,@data2 DATE
   ,@bank1 INT = NULL
)
AS
	/*
		Выборка по таблице BANK_DBF по организациям
	*/
	SET NOCOUNT ON


	SELECT
		BD.*
	   ,bs2.*
	   ,s.name AS sup_name
	   ,o.status_id
	FROM dbo.BANK_DBF AS BD
	JOIN dbo.[View_BANK_TBL_SPISOK] AS bs2
		ON BD.filedbf_id = bs2.filedbf_id
	LEFT JOIN dbo.SUPPLIERS_ALL AS s 
		ON BD.sup_id = s.id
	LEFT JOIN dbo.OCCUPATIONS AS o 
		ON BD.occ = o.occ
	JOIN (SELECT DISTINCT
			ext
		FROM dbo.View_PAYCOLL_ORGS AS PO 
		WHERE PO.is_bank = 0
		AND PO.BANK BETWEEN COALESCE(@bank1, 0) AND COALESCE(@bank1, 10000)
		) AS po
		ON BD.bank_id = po.ext
	WHERE datafile BETWEEN @data1 AND @data2
	OPTION (RECOMPILE)
go

