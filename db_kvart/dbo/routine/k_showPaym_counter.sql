CREATE   PROCEDURE [dbo].[k_showPaym_counter]
(
	@occ1		INT
	,@fin_id1	SMALLINT	= NULL
	,@s1		SMALLINT  -- сейчас не используется а клиенте есть
)
AS
	SET NOCOUNT ON

	SELECT
		p.fin_id
		,cp.StrFinPeriod as strfin
		,s.short_name
		,s.service_no
		,p.occ
		,p.service_id
		,p.subsid_only
		,tarif =
			CASE
				WHEN p.tarif = 0.0000 THEN NULL
				ELSE p.tarif
			END
		,koef = CAST(0.0000 AS DECIMAL(10, 4))
		,saldo =
			CASE
				WHEN p.saldo = 0.00 THEN NULL
				ELSE p.saldo
			END
		,socvalue = 0.00
		,VALUE =
			CASE
				WHEN p.VALUE = 0.00 THEN NULL
				ELSE p.VALUE
			END
		,discount =
			CASE
				WHEN p.discount = 0 THEN NULL
				ELSE p.discount
			END
		,added =
			CASE
				WHEN p.added = 0 THEN NULL
				ELSE p.added
			END
		,compens =
			CASE
				WHEN p.compens = 0.00 THEN NULL
				ELSE p.compens
			END
		,paid =
			CASE
				WHEN p.paid = 0.00 THEN NULL
				ELSE p.paid
			END
		,paymaccount =
			CASE
				WHEN p.paymaccount = 0.00 THEN NULL
				ELSE p.paymaccount
			END
		,paymaccount_peny =
			CASE
				WHEN p.paymaccount_peny = 0.00 THEN NULL
				ELSE p.paymaccount_peny
			END
		,p.debt
		,kol =
			CASE
				WHEN p.kol = 0 THEN NULL
				ELSE p.kol
			END
		,p.avg_vday
	FROM dbo.View_PAYM_COUNTER AS p 
	JOIN dbo.View_SERVICES AS s
		ON p.service_id = s.id
	INNER JOIN dbo.CALENDAR_PERIOD cp
		ON cp.fin_id = p.fin_id
	WHERE (occ = @occ1)
	AND (p.fin_id = @fin_id1 OR @fin_id1 IS NULL)
	ORDER BY p.fin_id DESC
go

