-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[ws_show_payings]
(
	@occ	   INT
   ,@startDate SMALLDATETIME = NULL
   ,@endDate   SMALLDATETIME = NULL
   ,@row1   INT		 = 6	  -- кол-во последних месяцев
)
AS
/*
exec ws_show_payings @occ=33100
exec ws_show_payings @occ=350033100
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @fin_current SMALLINT
		   ,@tip_id		 SMALLINT
		   ,@sup_id INT = 0

	IF @startDate IS NULL
		SET @startDate = '20150101'
	IF @endDate IS NULL
		SET @endDate = '20500101'

	SELECT
		@fin_current = o.fin_id
	   ,@tip_id = o.tip_id
	FROM dbo.Occupations o 
	WHERE o.occ = @occ

	IF @fin_current IS NULL
		SELECT
			@occ = o.occ
		   ,@fin_current = o.fin_id
		   ,@tip_id = o.tip_id
		   ,@sup_id = os.sup_id
		FROM dbo.Occ_Suppliers os 
		JOIN dbo.Occupations AS o 
			ON os.occ=o.occ 
			AND os.fin_id=o.fin_id
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
	print @occ
	SELECT TOP (@row1)
		p.fin_name AS 'fin_str' --'Фин_период'
	   ,@occ AS 'lic' --'Лицевой'
	   ,CONVERT(VARCHAR(10), p.[day], 104) AS 'date'  --'Дата_платежа'
	   ,p.value AS 'summa'  --'Сумма'
	   ,p.paymaccount_peny AS 'paymaccount_peny' -- 'Оплач_пени'
	   ,COALESCE(sa.name, '') AS sup_name  -- оплата по поставщику
	FROM dbo.View_payings_lite AS p 
	LEFT JOIN dbo.SUPPLIERS_ALL sa 
		ON sa.id = p.sup_id
	WHERE p.occ = @occ
	AND p.[day] BETWEEN @startDate AND @endDate
	AND p.sup_id = @sup_id
	ORDER BY p.fin_id DESC
	, p.[day] DESC
	, p.id DESC

END
go

