CREATE   PROCEDURE [dbo].[rep_pay_6]
(
	  @fin_id1 SMALLINT
	, @tip_id1 SMALLINT = NULL
	, @sup_id INT = NULL
)
AS
	/*
 Поступления по дням в заданном фин.периоде

 Изменил: 07.09.2009 
*/

	SET NOCOUNT ON


	SELECT pd.day AS 'День'
		 , po.bank_name AS 'Банк'
		 , po.description
		 , SUM(total) AS [SUM]
		 , SUM(docsnum) AS kol
		 , SUM(COALESCE(commission, 0)) AS commission
	FROM dbo.Paydoc_packs AS pd 
		JOIN dbo.View_paycoll_orgs AS po 
			ON pd.source_id = po.id
			AND pd.fin_id = po.fin_id
	WHERE 
		pd.forwarded = CAST(1 AS BIT) -- признак закрытой пачки
		AND pd.fin_id = @fin_id1
		AND (pd.tip_id = @tip_id1 OR @tip_id1 IS NULL)
		AND (pd.sup_id = @sup_id OR @sup_id IS NULL)
	GROUP BY day
		   , po.bank_name
		   , po.description
	ORDER BY day
go

