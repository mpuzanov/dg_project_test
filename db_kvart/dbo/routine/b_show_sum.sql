CREATE   PROCEDURE [dbo].[b_show_sum]
AS
	/*
	Показываем сводный список платежей без пачек

	exec b_show_sum

	дата создания: 26.03.2004
	автор: Пузанов М.А.
	
	дата последней модификации:
	автор изменений:
	
	*/
	SET NOCOUNT ON

	SELECT
		bd.pdate
	   ,MIN(bts.DataFile) AS DataFile
	   ,MIN(bts.DataVvoda) AS DataVvoda
	   ,MIN(bts.FileNameDbf) AS FileNameDbf
	   ,bts.filedbf_id
	   ,bts.block_import
	   ,V.tip_name
	   ,sa.name AS sup_name
	   ,MAX(bts.kol) AS kol
	   ,MAX(bts.summa) AS sum_opl
	   ,SUM(CASE
			WHEN (bd.occ IS NULL OR
			bd.error_num > 0) THEN 1
			ELSE 0
		END) AS kol_error
	   ,SUM(CASE
			WHEN (bd.occ IS NULL OR
			bd.error_num > 0) THEN bd.sum_opl
			ELSE 0
		END) AS sum_error
	   ,'' AS [description]
	FROM dbo.BANK_DBF AS bd 
	JOIN dbo.BANK_TBL_SPISOK AS bts
		ON bd.filedbf_id = bts.filedbf_id
	JOIN dbo.VPAYCOL_USER vu
		ON bd.bank_id = vu.ext
	LEFT JOIN dbo.VOCC AS V 
		ON bd.occ = V.occ
	LEFT JOIN dbo.SUPPLIERS_ALL AS sa 
		ON bd.sup_id = sa.id
	WHERE bd.pack_id IS NULL
	GROUP BY bd.pdate
			,bts.filedbf_id
			,bts.block_import
			,V.tip_name
			,sa.name
	ORDER BY pdate DESC, kol, bts.filedbf_id
go

