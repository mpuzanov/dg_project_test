CREATE   PROCEDURE [dbo].[rep_pay_1]
(
	  @date1 DATETIME
	, @date2 DATETIME = NULL
	, @bank_id1 INT = NULL
)
AS
	--
	--  Реестр пачек ввода платежей
	--
	SET NOCOUNT ON

	IF @date2 IS NULL
		SET @date2 = @date1

	SELECT b.short_name AS orgs
		 , p1.id
		 , p1.day
		 , p1.docsnum
		 , p1.total
		 , fact_docsnum = (
			   SELECT COUNT(p.id)
			   FROM dbo.Payings AS p
			   WHERE p.pack_id = p1.id
		   )
		 , fact_total = (
			   SELECT SUM(p.value)
			   FROM dbo.Payings AS p
			   WHERE p.pack_id = p1.id
		   )
	FROM dbo.Paydoc_packs AS p1
	   , dbo.Paycoll_orgs AS po
	   , dbo.bank AS b
	WHERE 
		p1.source_id = po.id
		AND p1.checked = 1
		AND p1.forwarded = 1
		AND po.fin_id = p1.fin_id
		AND po.bank = b.id
		AND b.id = COALESCE(@bank_id1, b.id)
		AND p1.day BETWEEN @date1 AND @date2
	ORDER BY p1.day
		   , b.short_name
go

