-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Накопление средств на расч.счёте по домам
-- =============================================
CREATE   PROCEDURE [dbo].[rep_account_sup]
(
	@tip_id		SMALLINT
	,@sup_id	INT
)
/*
rep_account_sup 28,345
*/
AS
BEGIN
	SET NOCOUNT ON;

	SELECT
		sa.name AS sup_name
		,MIN(vb.adres) AS adres
		,os.rasschet
		,SUM(os.paid) AS paid
		,SUM(os.paymaccount - os.paymaccount_peny) AS paymaccount
		,SUM(os.paid) - SUM(os.paymaccount - os.paymaccount_peny) AS ostatok_paym
		,CASE
			WHEN SUM(os.paid) > 0 THEN CAST(SUM(os.paymaccount - os.paymaccount_peny) * 100 / SUM(os.paid) AS DECIMAL(15, 2))
			ELSE 0
		END
		AS procent_paym
	FROM dbo.OCC_SUPPLIERS AS os 
	JOIN dbo.OCCUPATIONS AS o 
		ON os.occ = o.occ
	JOIN dbo.FLATS AS f 
		ON o.flat_id = f.ID
	JOIN dbo.View_BUILDINGS AS vb 
		ON f.bldn_id = vb.ID
	JOIN dbo.SUPPLIERS_ALL AS sa 
		ON os.sup_id = sa.ID
	WHERE o.tip_id = @tip_id
	AND os.rasschet IS NOT NULL
	AND os.sup_id = @sup_id
	--AND os.paid>0
	GROUP BY	sa.name
				,os.rasschet
				,vb.street_name
				,vb.nom_dom_sort
	ORDER BY vb.street_name, vb.nom_dom_sort
END
go

