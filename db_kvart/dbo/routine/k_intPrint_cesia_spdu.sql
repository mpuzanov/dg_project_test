-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[k_intPrint_cesia_spdu]
(
	@occ		INT
	,@fin_id	SMALLINT
	,@sup_id	INT	= NULL
)
AS
-- exec k_intPrint_cesia_spdu 700236541,150,300
BEGIN
	SET NOCOUNT ON;

	DECLARE	@SumPaym			DECIMAL(9, 2)	= 0
			,@SumPaymSup		DECIMAL(9, 2)	= 0
			,@SumPaymPeny		DECIMAL(9, 2)	= 0
			,@SumPaymSupPeny	DECIMAL(9, 2)	= 0
			,@DB_NAME			VARCHAR(20)		= UPPER(DB_NAME())
			,@occ_sup			INT

	SELECT
		@occ_sup = OS.occ_sup
	FROM dbo.OCC_SUPPLIERS OS
	WHERE fin_id = @fin_id
	AND occ = @occ
	AND SUP_ID = @sup_id

	SELECT
		@SumPaym = COALESCE(SUM(value),0)
		,@SumPaymPeny = COALESCE(SUM(COALESCE(paymaccount_peny, 0)),0)
	FROM dbo.View_PAYINGS 
	WHERE fin_id = @fin_id
	AND occ = @occ
	AND SUP_ID=0
	AND ((tip_paym_id IN ('1014') --'Отмена уступки долга'
	AND @DB_NAME IN ('KOMP', 'ARX_KOMP'))
	OR (tip_paym_id IN ('1013') --'Отмена уступки долга'
	AND @DB_NAME IN ('KVART', 'ARX_KVART')))

	--PRINT @SumPaym

	SELECT
		@SumPaymSup = COALESCE(SUM(value),0)
		,@SumPaymSupPeny = COALESCE(SUM(COALESCE(paymaccount_peny, 0)),0)
	FROM dbo.View_PAYINGS 
	WHERE fin_id = @fin_id
	AND occ = @occ
	AND SUP_ID = @sup_id
	AND ((tip_paym_id IN ('1014') --'Отмена уступки долга'
	AND @DB_NAME IN ('KOMP', 'ARX_KOMP'))
	OR (tip_paym_id IN ('1013') --'Отмена уступки долга'
	AND @DB_NAME IN ('KVART', 'ARX_KVART')))

	--PRINT @SumPaymSup

	SELECT
		@SumPaymPeny = @SumPaymPeny + @SumPaymSupPeny
	SELECT
		@occ AS occ
		,@occ_sup AS occ_sup
		,@SumPaym AS SumPaym
		,@SumPaymSup AS SumPaymSup
		,@SumPaymPeny AS SumPaymPeny
		,(@SumPaym+@SumPaymSup) AS SumPaymAll

END
go

