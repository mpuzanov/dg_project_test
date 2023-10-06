CREATE   PROCEDURE [dbo].[k_spisokDayPaym]
(
	@tip_id		SMALLINT	= NULL --  тип фонда
	,@sup_id	INT			= NULL
	,@bank_id	INT			= NULL
)
AS
/*
		
Выводим список не закрытых дней в текущем фин. периоде 
		
k_spisokDayPaym 28,323
	
*/
SET NOCOUNT ON

SELECT
	day
	,CONVERT(VARCHAR(10), day, 104) AS strday
	,STR(SUM(total), 15, 2) AS total_sum
	,SUM(total) AS total
	,SUM(docsnum) AS total_kol
	,COUNT(pd.id) AS kol_packs
	,SUM(CASE WHEN pd.blocked = 1 THEN 1 ELSE 0 END) AS blocked
FROM dbo.PAYDOC_PACKS AS pd
	JOIN dbo.View_PAYCOLL_ORGS AS po 
		ON pd.fin_id = po.fin_id
		AND pd.source_id = po.id
	JOIN dbo.VOCC_TYPES AS VT 
		ON pd.tip_id = VT.id -- для ограничения доступа по типам фонда
		AND pd.fin_id = VT.fin_id
WHERE forwarded = 0
	AND (pd.tip_id = @tip_id or @tip_id IS NULL)
	AND (pd.sup_id = @sup_id OR @sup_id IS NULL)
	AND (po.bank_id = @bank_id OR @bank_id IS NULL)
GROUP BY day
ORDER BY day
go

