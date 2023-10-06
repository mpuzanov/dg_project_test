-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Показ платежа для чека фискализации
-- =============================================
CREATE       PROCEDURE [dbo].[k_pay_cash_show]
(
	  @occ1 INT
	, @paying_id1 INT = NULL-- код платежа для раскидки по чеку
)
AS
/*
k_pay_cash_show @occ1=680001025, @paying_id1=null
k_pay_cash_show @occ1=680001025, @paying_id1=828102
*/
BEGIN
	SET NOCOUNT ON;

	SELECT p.occ
		 , pc.paying_id
		 , pc.service_name
		 , pc.value_cash
	FROM dbo.Paying_cash pc
	JOIN dbo.Payings as p ON pc.paying_id=p.id
	WHERE p.occ = @occ1
		AND (p.id = @paying_id1 OR @paying_id1 IS NULL)
	ORDER BY p.occ
		   , pc.paying_id
		   , pc.value_cash DESC

END
go

