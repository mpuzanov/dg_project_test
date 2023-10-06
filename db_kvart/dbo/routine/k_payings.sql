CREATE   PROCEDURE [dbo].[k_payings]
(
	  @pack_id1 INT
)
AS
	/*
	
	  Показываем платежи по заданной пачке
	
	*/
	SET NOCOUNT ON

	SELECT CAST(ROW_NUMBER() OVER (ORDER BY p.id) AS INT) AS RowNum
		 , p.id
		 , p.pack_id
		 , p.fin_id
		 , p.occ
		 , p.service_id
		 , o.jeu
		 , p.occ_sup AS schtl
		 , p.value
		 , o.address
		 , p.sup_id
		 , sup.name AS sup_name
		 , p.forwarded
		 , p.paymaccount_peny
		 , p.commission
		 , p.[day] AS [day]
		 , p.paying_vozvrat
		 , p.peny_save
		 , p.paying_manual
		 , p.paying_uid
		 , p.pack_uid
		   --,dbo.Fun_GetFileNamePaying(p.id) AS file_paym
		 , COALESCE(bs.filenamedbf, '') AS file_paym
		 , COALESCE(bs.rasschet, '') AS rasschet
		 , OT.name AS tip_name
		 , p.comment
	FROM dbo.View_payings AS p 
		LEFT JOIN dbo.Occupations AS o ON p.occ = o.occ
		LEFT JOIN dbo.Suppliers_all AS sup ON p.sup_id = sup.id
		LEFT JOIN dbo.Occupation_Types OT ON p.tip_id = OT.id
		LEFT JOIN dbo.Bank_tbl_spisok AS bs ON p.filedbf_id = bs.filedbf_id
	WHERE p.pack_id = @pack_id1
go

