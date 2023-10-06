CREATE   PROCEDURE [dbo].[adm_packs_show_fin]
(
	@fin_id1 SMALLINT
)
AS
/*

  Показываем список закрытых пачек в заданном фин.периоде

  EXEC adm_packs_show_fin 245
*/
	SET NOCOUNT ON


	SELECT
		pd.id
	   ,cp.StrFinPeriod AS fin_id
	   ,pd.day
	   ,pd.docsnum
	   ,pd.total	   	   
	   ,CONCAT(b.short_name , '(' , pt.name , ')') AS source
	   ,t.name AS tip_name
	   ,pd.commission
	   ,SUM(pd.docsnum) OVER (PARTITION BY pd.fin_id, pd.forwarded) AS 'docsnum_itogo'
	   ,SUM(pd.docsnum) OVER (PARTITION BY pd.fin_id, pd.forwarded, pd.tip_id) AS 'docsnum_itogo_tip'	   
	   ,sa.name AS sup_name
	   ,pd.sup_id
	   ,u.Initials AS [USER]
	   ,pd.date_edit
	   ,pd.forwarded
	   ,pd.checked
	   ,pd.fin_id AS fin_int
	   ,pd.pack_uid
	   ,pd.tip_id
	   ,pd.source_id
	   ,dbo.Fun_GetFileNamePack_id(pd.id) AS FileNamePacks
	FROM dbo.Paydoc_packs AS pd 
	JOIN dbo.vocc_types AS t 
		ON pd.tip_id = t.id
	JOIN dbo.Calendar_period cp
		ON pd.fin_id = cp.fin_id
	LEFT JOIN dbo.view_suppliers_all AS sa
		ON pd.sup_id = sa.id
	LEFT JOIN USERS u
		ON pd.user_edit = u.id
	LEFT JOIN dbo.Paycoll_orgs AS po 
		ON pd.source_id = po.id
	JOIN dbo.bank AS b 
		ON po.bank = b.id
	JOIN dbo.Paying_types AS pt 
		ON po.vid_paym = pt.id
	WHERE 
		pd.fin_id = @fin_id1
	ORDER BY pd.date_edit DESC, pd.id DESC
go

