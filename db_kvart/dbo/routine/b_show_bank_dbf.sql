/*
дата создания: 
автор: 

дата последней модификации:

*/

CREATE   PROCEDURE [dbo].[b_show_bank_dbf]
(
	@filedbf_id	INT
	,@isdouble	BIT	= 0  --для прверки повторяющихся лицевых
)
AS
	/*
	exec b_show_bank_dbf 80279,1
	*/
	SET NOCOUNT ON

	IF @isdouble IS NULL
		SET @isdouble = 0

	SELECT
		t.*
		,o.STATUS_ID
		,s.name AS sup_name
		,vb.adres AS adres_dom
		,vb.tip_name AS tip_name
		,bc.comments

	FROM (SELECT
			b.id
			,bs.DataFile AS DATA_PAYM
			,bs.datavvoda
			,bs.DataFile
			,b.bank_id
			,b.sum_opl
			,b.commission
			,CASE
				WHEN b.sum_opl > 0 THEN CAST(ROUND(b.commission / b.sum_opl * 100, 1) AS DECIMAL(9, 1))
				ELSE 0
			END AS Proc_commission
			,b.pdate
			,b.grp
			,b.Occ
			,b.service_id
			,b.sch_lic
			,b.pack_id
			,b.p_opl
			,b.adres
			,b.date_edit
			,b.filedbf_id
			,b.sup_id
			,bs.FileNameDbf
			,b.rasschet
			,b.error_num
			,COUNT(COALESCE(b.Occ,0)) OVER (PARTITION BY b.occ, b.sum_opl) AS kol_occ
			,b.fio
		FROM dbo.Bank_dbf AS b 
		JOIN dbo.View_bank_tbl_spisok AS bs
			ON b.filedbf_id = bs.filedbf_id
		WHERE b.filedbf_id = @filedbf_id) AS t
	LEFT JOIN dbo.Occupations AS o 
		ON t.Occ = o.Occ
	LEFT JOIN dbo.Flats AS f 
		ON o.flat_id = f.id
	LEFT JOIN dbo.View_buildings_lite AS vb 
		ON f.bldn_id = vb.id
	LEFT JOIN dbo.Bankdbf_comments AS bc 
		ON t.id = bc.id
	LEFT JOIN dbo.Suppliers_alL AS s
		ON t.sup_id = s.id
	WHERE (@isdouble = 0
		OR (@isdouble = 1 -- Показываем только дубли
		AND t.kol_occ > 1))
	OPTION (RECOMPILE)
go

