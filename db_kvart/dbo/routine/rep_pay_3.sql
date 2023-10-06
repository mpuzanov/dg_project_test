CREATE   PROCEDURE [dbo].[rep_pay_3]
(
	  @date1 DATETIME
	, @date2 DATETIME
	, @bank_id1 INT = 0 --код банка
	, @tip SMALLINT = NULL
	, @tipbank SMALLINT = NULL --банки или организации
	, @sup_id INT = NULL
)
AS
	/*
	  Ежедневный отчет по поступлениям за ЖКУ по банкам
	*/

	SET NOCOUNT ON


	IF @tipbank IS NULL
	BEGIN
		SELECT pd.day
			 , b.short_name
			 , p.scan
			 , COUNT(p.id) AS kol
			 , SUM(p.value) AS sum_value
		FROM dbo.Payings AS p
			JOIN dbo.Paydoc_packs pd ON 
				p.pack_id = pd.id
			JOIN dbo.Paycoll_orgs AS po ON 
				pd.source_id = po.id
				AND pd.fin_id = po.fin_id
			JOIN dbo.bank AS b ON 
				po.bank = b.id
			JOIN dbo.VOcc AS o ON 
				p.occ = o.occ
		WHERE 
			pd.checked = 1
			AND o.tip_id = COALESCE(@tip, o.tip_id)
			AND pd.forwarded = 1
			AND b.id = COALESCE(@bank_id1, b.id)
			AND pd.day BETWEEN @date1 AND @date2
			AND (pd.sup_id = @sup_id OR @sup_id IS NULL)
		GROUP BY pd.day
			   , b.short_name
			   , p.scan
		ORDER BY pd.day
	END

	ELSE
		SELECT pd.day
			 , b.short_name
			 , p.scan
			 , COUNT(p.id) AS kol
			 , SUM(p.value) AS sum_value
		FROM dbo.Payings AS p
			JOIN dbo.Paydoc_packs pd ON 
				p.pack_id = pd.id
			JOIN dbo.Paycoll_orgs AS po ON 
				pd.source_id = po.id
				AND pd.fin_id = po.fin_id
			JOIN dbo.bank AS b ON 
				po.bank = b.id
			JOIN dbo.VOcc AS o ON 
				p.occ = o.occ
		WHERE 
			pd.checked = 1
			AND o.tip_id = COALESCE(@tip, o.tip_id)
			AND pd.forwarded = 1
			AND b.is_bank = @tipbank
			AND b.id BETWEEN 0 AND 99999
			AND pd.day BETWEEN @date1 AND @date2
			AND (pd.sup_id = @sup_id OR @sup_id IS NULL)
		GROUP BY pd.day
			   , b.short_name
			   , p.scan
		ORDER BY pd.day
go

