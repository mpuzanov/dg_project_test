CREATE   PROCEDURE [dbo].[adm_packs_show]
(
	@forwarded1 BIT		 = 1
   ,@fin_id1	SMALLINT = NULL
)
AS
/*
Показываем список закрытых или нет пачек в заданном фин.периоде

adm_packs_show 1, 182
*/
	SET NOCOUNT ON

	IF @forwarded1 IS NULL
		SET @forwarded1 = CAST(1 AS BIT)

	SELECT
		pd.id
	   ,cp.StrFinPeriod AS fin_id
	   ,pd.day
	   ,pd.docsnum
	   ,pd.total
	   ,SUM(pd.docsnum) OVER (PARTITION BY pd.fin_id, pd.forwarded, pd.tip_id) AS 'docsnum_itogo'
	   ,pd.commission
	   ,rp.PaymaccountPeny
	   ,t.tip_name AS tip_name   	   
	   ,sa.name AS sup_name
	   ,CONCAT(bank.short_name , '(' , pt.name , ')') AS source
	   ,dbo.Fun_GetFileNamePack_id(pd.id) AS FileNamePacks
	   ,u.Initials AS [USER]	   
	   ,CAST(CAST(pd.date_edit AS DATE) AS SMALLDATETIME) AS date_edit
	   ,pd.forwarded
	   ,pd.checked	   
	   ,pd.sup_id
	   ,pd.fin_id AS fin_int
	   ,pd.pack_uid	   
	FROM dbo.Paydoc_packs AS pd 
	JOIN (
		SELECT DISTINCT tip_id, 
			CASE WHEN @fin_id1 IS NULL THEN b.fin_current ELSE @fin_id1 END as fin_id
			, ot.name as tip_name 
		FROM dbo.Buildings b
		JOIN dbo.Occupation_Types AS ot ON 
			b.tip_id=ot.id
		) as t ON 
		t.tip_id=pd.tip_id 
		AND t.fin_id=pd.fin_id
	JOIN dbo.Calendar_period cp ON 
		pd.fin_id = cp.fin_id
	LEFT JOIN dbo.Users u ON 
		pd.user_edit = u.id
	LEFT JOIN dbo.Suppliers_all AS sa ON 
		pd.sup_id = sa.id
	LEFT JOIN dbo.Paycoll_orgs AS po ON 
		pd.source_id = po.id
	JOIN dbo.bank AS bank ON 
		po.bank = bank.id
	JOIN dbo.Paying_types AS pt ON 
		po.vid_paym = pt.id
	CROSS APPLY (SELECT
			SUM(p.paymaccount_peny) AS PaymaccountPeny
		FROM dbo.Payings AS p 
		WHERE pack_id = pd.id) AS rp
	WHERE 
		forwarded = @forwarded1
		--AND EXISTS(SELECT 1
		--	 FROM dbo.Buildings as b
		--	 WHERE b.tip_id=pd.tip_id
		--	 AND ((@fin_id1 IS NULL and pd.fin_id = b.fin_current) OR pd.fin_id = @fin_id1)
		--)
	ORDER BY date_edit DESC, pd.id DESC
go

