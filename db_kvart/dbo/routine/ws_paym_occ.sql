-- =============================================
-- Author:		Пузанов
-- Create date: 29.12.07
-- Description:	для веб-сервисов
-- =============================================
CREATE     PROCEDURE [dbo].[ws_paym_occ]
(
	@occ		INT	= NULL
	,@bldn_id	INT	= NULL
	,@source_id	INT	= NULL
	,@tip_id	INT	= NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @fin_id SMALLINT
	SELECT
		@fin_id = dbo.Fun_GetFinCurrent(@tip_id, @bldn_id, NULL, @occ)

	IF @occ = 0
		SET @occ = NULL
	IF @bldn_id = 0
		SET @bldn_id = NULL
	IF @source_id = 0
		SET @source_id = NULL
	IF @tip_id = 0
		SET @tip_id = NULL

	IF @occ IS NULL
		AND @bldn_id IS NULL
		AND @source_id IS NULL
		AND @tip_id IS NULL
		RETURN

	IF @occ IS NOT NULL
	BEGIN
		SELECT
			 dbo.Fun_NameFinPeriod(fin_id) AS fin_period
			,SALDO
			,value
			,Discount
			,Added
			,Compens
			,Paid
			,PaymAccount
			,paymaccount_peny
			,Debt
			,CASE
					WHEN Paid_old = 0 THEN 100
					ELSE CONVERT(DECIMAL(6, 2), PaymAccount * 100 / Paid_old)
			END AS procent
			,(SALDO - Paid_old) AS dolg
			,(Penalty_value + Penalty_old_new) AS penalty
		FROM dbo.OCCUPATIONS 
		WHERE occ = @occ
		RETURN
	END

	IF @bldn_id IS NOT NULL
	BEGIN
		SELECT
			dbo.Fun_NameFinPeriod(@fin_id) AS fin_period
			,SUM(saldo) AS saldo
			,SUM(VALUE) AS VALUE
			,SUM(discount) AS discount
			,SUM(added) AS added
			,SUM(compens) AS compens
			,SUM(paid) AS paid
			,SUM(paymaccount) AS paymaccount
			,SUM(paymaccount_peny) AS paymaccount_peny
			,SUM(debt) AS debt
			,CASE
					WHEN SUM(Paid_old) = 0 THEN 100
					ELSE CONVERT(DECIMAL(6, 2), SUM(paymaccount) * 100 / SUM(Paid_old))
			END AS procent
			,(SUM(saldo - Paid_old)) AS dolg
			,(SUM(Penalty_value + Penalty_old_new)) AS penalty
		FROM dbo.Occupations AS o 
			JOIN dbo.Flats AS f ON o.flat_id = f.id
		WHERE f.bldn_id = @bldn_id

		RETURN
	END

	IF (@source_id IS NOT NULL)
		AND (@tip_id IS NOT NULL)
	BEGIN
		SELECT
			dbo.Fun_NameFinPeriod(@fin_id) AS fin_period
			, SUM(pl.saldo) AS saldo
			, SUM(pl.VALUE) AS VALUE
			, 0 AS discount
			, SUM(pl.added) AS added
			, 0 AS compens
			, SUM(pl.paid) AS paid
			, SUM(pl.paymaccount) AS paymaccount
			, SUM(pl.paymaccount_peny) AS paymaccount_peny
			, SUM(pl.debt) AS debt
			, CASE
					WHEN SUM(pl.paid) = 0 THEN 100
					ELSE CONVERT(DECIMAL(6, 2), SUM(pl.paymaccount) * 100 / SUM(pl.paid))
			 END AS procent
			, (SUM(pl.saldo) - SUM(pl.paid)) AS dolg  -- ,берем Paid так как нет Paid_old
			, 0 AS penalty
		FROM	dbo.View_PAYM AS pl
				,dbo.CONSMODES_LIST AS cl 
				,dbo.OCCUPATIONS AS o 
		WHERE pl.occ = cl.occ
		AND pl.fin_id = @fin_id
		AND pl.service_id = cl.service_id
		AND pl.occ = o.occ
		AND cl.source_id =
			CASE
				WHEN @source_id IS NULL THEN cl.source_id
				ELSE @source_id
			END
		AND o.tip_id =
			CASE
				WHEN @tip_id IS NULL THEN o.tip_id
				ELSE @tip_id
			END

		RETURN
	END


	IF @tip_id IS NOT NULL
	BEGIN
		SELECT
			  dbo.Fun_NameFinPeriod(@fin_id) AS fin_period
			, SUM(saldo) AS saldo
			, SUM(VALUE) AS VALUE
			, SUM(discount) AS discount
			, SUM(added) AS added
			, SUM(compens) AS compens
			, SUM(paid) AS paid
			, SUM(paymaccount) AS paymaccount
			, SUM(paymaccount_peny) AS paymaccount_peny
			, SUM(debt) AS debt
			, CASE
					WHEN SUM(Paid_old) = 0 THEN 100
					ELSE CONVERT(DECIMAL(6, 2), SUM(paymaccount) * 100 / SUM(Paid_old))
			  END AS procent
			, (SUM(saldo) - SUM(Paid_old)) AS dolg
			, (SUM(Penalty_value + Penalty_old_new)) AS penalty
		FROM dbo.Occupations AS o 
		WHERE o.tip_id = @tip_id

		RETURN
	END

END
go

