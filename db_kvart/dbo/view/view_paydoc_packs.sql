-- dbo.view_paydoc_packs source

CREATE   VIEW [dbo].[view_paydoc_packs]
AS
SELECT  pd.id
	   ,pd.day
	   ,pd.docsnum
	   ,pd.total
	   ,pd.commission AS commission
	   ,t.name AS tip_name
	   ,cp.StrFinPeriod AS fin_name
	   ,b.short_name AS organplat
	   ,pt.name AS tipplat
	   ,sa.name AS sup_name
	   ,CAST(pd.DATE_EDIT AS DATE) AS date_edit
	   ,pd.tip_id
	   ,pd.sup_id
	   ,pd.fin_id
	   ,pd.source_id
	   ,pd.pack_uid
	   ,pc.bank AS bank_id
	FROM dbo.PAYDOC_PACKS AS pd 
	JOIN dbo.PAYCOLL_ORGS AS pc 
		ON pd.source_id = pc.id
	JOIN dbo.PAYING_TYPES AS pt
		ON pc.vid_paym = pt.id
	JOIN dbo.bank AS b 
		ON pc.bank = b.id
	JOIN dbo.CALENDAR_PERIOD cp 
		ON pd.fin_id = cp.fin_id
	LEFT JOIN dbo.VOCC_TYPES AS t 
		ON pd.tip_id = t.id
	LEFT JOIN dbo.SUPPLIERS_ALL AS sa
		ON pd.sup_id = sa.id;
go

