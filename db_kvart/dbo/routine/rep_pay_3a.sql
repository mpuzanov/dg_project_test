CREATE   PROCEDURE [dbo].[rep_pay_3a]
(
	  @date1 DATETIME
	, @date2 DATETIME
	, @bank_id1 INT = NULL --код банка 
	, @tip SMALLINT = NULL
	, @tipplat VARCHAR(10) = NULL --вид платежа
	, @sup_id INT = NULL
)
AS
	/*
--
--  Ежедневный отчет по поступлениям за ЖКУ по банкам
--
*/
	SET NOCOUNT ON


	SELECT pd.day
		 , po.bank_name AS short_name
		 , p.scan
		 , COUNT(p.id) AS kol
		 , SUM(p.value) AS sum_value
		 , SUM(COALESCE(p.commission, 0)) AS commission
	FROM dbo.Paydoc_packs pd 
		JOIN dbo.Payings AS p  ON pd.id = p.pack_id
		JOIN dbo.VOcc AS o  ON p.occ = o.occ
		JOIN dbo.View_paycoll_orgs AS po  ON pd.fin_id = po.fin_id
			AND pd.source_id = po.id
	WHERE pd.checked = 1
		AND (o.tip_id = @tip OR @tip IS NULL)
		AND pd.forwarded = 1
		AND po.bank_id = COALESCE(@bank_id1, po.bank_id)
		AND pd.day BETWEEN @date1 AND @date2
		AND po.tip_paym_id = COALESCE(@tipplat, po.tip_paym_id)
		AND (pd.sup_id = @sup_id OR @sup_id IS NULL)
	GROUP BY po.tip_paym_id
		   , pd.day
		   , po.bank_name
		   , p.scan
	ORDER BY pd.day
		   , po.bank_name
go

