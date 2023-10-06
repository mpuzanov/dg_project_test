CREATE   PROCEDURE [dbo].[k_paydoc]
AS
	/*
--
--  Вывод пачек для редактирования  --в текущем финансовом периоде(не закрытых)
--

k_paydoc

*/
	SET NOCOUNT ON

	SELECT
		pd.id
	   ,pt.name AS tipplat
	   ,pd.day
	   ,pd.blocked
	   ,pd.docsnum
	   ,pd.total
	   ,pd.checked
	   ,pd.source_id
	   ,b.short_name AS organplat
	   ,CAST(CAST(pd.DATE_EDIT AS DATE) AS SMALLDATETIME) AS DATE_EDIT
	   ,u.Initials AS user_edit
	   ,t.name AS tip_name
	   ,pd.tip_id
	   ,pd.forwarded
	   ,pd.commission AS commission
	   ,cp.StrFinPeriod AS fin_name
	   ,CASE
			WHEN pd.total = rp.RSumma AND
			COALESCE(pd.commission, 0) = rp.RCommission THEN CAST(0 AS BIT)
			ELSE CAST(1 AS BIT)
		END AS Error_pack
	   ,pd.sup_id
	   ,sa.name AS sup_name
	   ,rp.PaymaccountPeny
	   ,pd.fin_id
	   ,pd.pack_uid
	   ,dbo.Fun_GetFileNamePack_id(pd.id) AS FileNamePacks
	FROM dbo.Paydoc_packs AS pd 
	LEFT OUTER JOIN dbo.Users AS u 
		ON pd.user_edit = u.id
	JOIN dbo.View_paycoll_orgs AS pc 
		ON pd.source_id = pc.id
	JOIN dbo.Paying_types AS pt 
		ON pc.vid_paym = pt.id
	JOIN dbo.bank AS b 
		ON pc.bank = b.id
	LEFT JOIN dbo.Vocc_types AS t
		ON pd.tip_id = t.id
	LEFT JOIN dbo.Suppliers_all AS sa 
		ON pd.sup_id = sa.id
	JOIN dbo.Calendar_period cp 
		ON pd.fin_id = cp.fin_id
	CROSS APPLY (SELECT
			RSumma = COALESCE(SUM(p.value), 0)
		   ,RCommission = COALESCE(SUM(p.commission), 0)
		   ,PaymaccountPeny = COALESCE(SUM(p.paymaccount_peny), 0)
		FROM dbo.PAYINGS AS p 
		WHERE p.pack_id = pd.id) AS rp
	WHERE pd.forwarded = 0

	ORDER BY pd.day
go

