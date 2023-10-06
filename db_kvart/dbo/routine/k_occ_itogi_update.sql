-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Обновление итогов по л/сч (берём из услуг)
-- =============================================
CREATE PROCEDURE [dbo].[k_occ_itogi_update]
(
	@occ		INT
	,@fin_id	SMALLINT
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ)

	-- обновить на лицевом итоги
	IF @fin_id < @fin_current
		UPDATE oh
		SET	saldo			= p.saldo
			,value			= p.value
			,paid			=
				CASE
					WHEN p.paid < 0 THEN 0
				ELSE p.paid
				END
			,Paid_minus		=
				CASE
					WHEN p.paid < 0 THEN p.paid
				ELSE 0
				END
		FROM dbo.OCC_HISTORY AS oh
		JOIN (SELECT
				pl.occ
				,SUM(saldo) AS saldo
				,SUM(VALUE) AS VALUE
				,SUM(added) AS added
				,SUM(paid) AS paid
				,SUM(Debt) AS Debt
			FROM dbo.PAYM_HISTORY AS pl
			WHERE pl.occ = @occ
			AND pl.fin_id = @fin_id
			AND pl.account_one = 0
			GROUP BY pl.occ) AS p
			ON oh.occ = p.occ
		WHERE oh.occ = @occ
		AND oh.fin_id = @fin_id

	ELSE

		UPDATE o
		SET	saldo			= p.saldo
			,value			= p.value
			,paid			=
				CASE
					WHEN p.paid < 0 THEN 0
				ELSE p.paid
				END
			,Paid_minus		=
				CASE
					WHEN p.paid < 0 THEN p.paid
				ELSE 0
				END
		FROM dbo.OCCUPATIONS AS o
		JOIN (SELECT
				pl.occ
				,SUM(saldo) AS saldo
				,SUM(VALUE) AS VALUE
				,SUM(added) AS added
				,SUM(paid) AS paid
				,SUM(Debt) AS Debt
			FROM dbo.PAYM_LIST AS pl
			WHERE pl.occ = @occ
			AND pl.fin_id = @fin_id
			AND pl.account_one = 0
			GROUP BY pl.occ) AS p
			ON o.occ = p.occ
		WHERE o.occ = @occ





END
go

