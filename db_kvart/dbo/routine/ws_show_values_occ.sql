-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	для веб-сервисов
-- =============================================
CREATE     PROCEDURE [dbo].[ws_show_values_occ] 
(
	@fin_id SMALLINT = NULL
   ,@occ	INT
   ,@row1   INT		 = 6	  -- кол-во последних месяцев
)
/*
 exec ws_show_values_occ @occ=111038
 exec ws_show_values_occ @occ=350111038
 exec ws_show_values_occ @occ=33100
 exec ws_show_values_occ @occ=350033100
*/
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @fin_current SMALLINT
		   ,@tip_id		 SMALLINT
		   ,@sup_id INT = 0

	SELECT
		@fin_current = o.fin_id
	   ,@tip_id = o.tip_id
	FROM Occupations o
	WHERE o.occ = @occ

	IF @fin_current IS NULL
		SELECT
			@occ = o.occ
		   ,@fin_current = o.fin_id
		   ,@tip_id = o.tip_id
		   ,@sup_id = os.sup_id
		FROM Occ_Suppliers os 
		JOIN Occupations AS o ON 
			os.occ=o.occ AND 
			os.fin_id=o.fin_id
		WHERE os.occ_sup = @occ
	IF @@rowcount = 0
	BEGIN
		SELECT
			@occ = dbo.Fun_GetFalseOccIn(@occ)
		SELECT
			@fin_current = o.fin_id
		   ,@tip_id = o.tip_id
		FROM dbo.Occupations o
		WHERE o.occ = @occ
	END

	SELECT TOP (@row1)
		dbo.Fun_GetNameFinPeriod(p.fin_id) AS 'fin_str'
	   ,@occ AS 'lic'
	   ,CAST(SUM(p.saldo) AS MONEY) AS 'saldo'
	   ,CAST(SUM(p.value) AS MONEY) AS 'value'
	   ,CAST(SUM(p.added) AS DECIMAL(10, 4)) AS 'added'
	   ,CAST(SUM(p.paid) AS MONEY) AS 'paid'
	   ,CAST(SUM(p.paymaccount) AS DECIMAL(10, 4)) AS 'paymaccount'
	   ,CAST(SUM(p.paymaccount_peny) AS DECIMAL(10, 4)) AS 'paymaccount_peny'
	   ,CAST(SUM(p.paymaccount - p.paymaccount_peny) AS DECIMAL(10, 4)) AS 'paymaccount_serv'
	   ,CAST(SUM(p.debt) AS MONEY) AS 'debt'
	   ,COALESCE(sa.name, '') AS sup_name  -- оплата по поставщику
	FROM dbo.View_paym AS p 
	LEFT JOIN dbo.SUPPLIERS_ALL sa 
		ON sa.id = p.sup_id
	WHERE 1=1
		AND p.occ = @occ
		AND (p.fin_id = @fin_id OR @fin_id IS NULL)
		AND p.sup_id = @sup_id
	GROUP BY p.fin_id
			,sa.name
	ORDER BY p.fin_id DESC

END
go

