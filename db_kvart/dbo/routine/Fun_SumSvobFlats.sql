-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       FUNCTION [dbo].[Fun_SumSvobFlats]
(
	@fin_id		SMALLINT
	,@occ		INT
	,@sup_id	INT	= NULL
)
RETURNS @t_out TABLE
(
	dolg			DECIMAL(9, 2)	DEFAULT 0
	,Paid			DECIMAL(9, 2)	DEFAULT 0
	,PaymAccount	DECIMAL(9, 2)	DEFAULT 0
)
AS
/*
select * from Fun_SumSvobFlats(139,910000741,null)
select * from Fun_SumSvobFlats(181,680002361,324)
select * from Fun_SumSvobFlats(188,680001078,347)  --1078 4614
*/
BEGIN

	DECLARE	@fin_end	SMALLINT	= @fin_id - 1
			,@fin_start	SMALLINT

	SELECT
		@fin_start = COALESCE((SELECT TOP (1)
				oh.fin_id
			FROM dbo.OCC_HISTORY oh 
			WHERE occ = @occ
			AND fin_id < @fin_id
			AND oh.status_id <> 'своб'
			ORDER BY fin_id DESC)
		, 0) + 1

	;with cte AS (
			SELECT
				CASE
					WHEN @sup_id > 0 THEN SUM(COALESCE(os.paid, 0)	- COALESCE(os.Paymaccount_serv, 0))
					WHEN @sup_id = 0 THEN SUM(COALESCE(o.paid, 0)	- COALESCE(o.Paymaccount_serv, 0))
					ELSE SUM(o.paid + COALESCE(os.paid, 0) - (o.Paymaccount_serv + COALESCE(os.Paymaccount_serv, 0)))
				END AS dolg
				,CASE
					WHEN @sup_id > 0 THEN SUM(COALESCE(os.paid, 0))
					WHEN @sup_id = 0 THEN SUM(COALESCE(o.paid, 0))
					ELSE SUM(o.PaidAll)
				END AS paid
				,CASE
					WHEN @sup_id > 0 THEN SUM(COALESCE(os.paymaccount, 0))
					WHEN @sup_id = 0 THEN SUM(COALESCE(o.paymaccount, 0))
					ELSE SUM(o.paymaccount + COALESCE(os.paymaccount, 0))
				END AS paymaccount
			FROM dbo.OCC_HISTORY AS o 
			CROSS APPLY (SELECT
					SUM(Saldo) AS Saldo
					,SUM(os.PaymAccount_serv) AS PaymAccount_serv
					,SUM(os.PaymAccount) AS PaymAccount
					,SUM(os.paid) AS paid
					,SUM(os.value) AS value
				FROM dbo.OCC_SUPPLIERS os
				WHERE os.occ = o.occ
				AND os.fin_id = o.fin_id
				AND (sup_id = @sup_id
				OR @sup_id IS NULL)) AS os
			WHERE o.occ = @occ
			AND o.fin_id BETWEEN @fin_start AND @fin_end
	)
	INSERT INTO @t_out(dolg, Paid, PaymAccount)
	SELECT CASE
               WHEN dolg < 0 THEN 0
               ELSE dolg
        END as dolg
		, CASE
              WHEN Paid < 0 THEN 0
              ELSE Paid
        END AS Paid
		, CASE
              WHEN PaymAccount < 0 THEN 0
              ELSE PaymAccount
        END AS PaymAccount
	FROM cte;

	RETURN
END
go

