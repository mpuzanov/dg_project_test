-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[adm_load_value_history]
(
	@occ1				INT
	,@start_date1		SMALLDATETIME
	,@service_id1		VARCHAR(10)		= ''
	,@tarif1			DECIMAL(10, 4)  = 0
	,@kol1				DECIMAL(12, 6)	= 0
	,@saldo1			DECIMAL(9, 2)	= 0
	,@value1			DECIMAL(9, 2)	= 0
	,@added1			DECIMAL(9, 2)	= 0
	,@paymaccount1		DECIMAL(9, 2)	= 0
	,@paymaccount_peny1	DECIMAL(9, 2)	= 0
	,@penalty_serv1		DECIMAL(9, 2)	= 0
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE	@fin_id1	SMALLINT
			,@paid1		DECIMAL(9, 2)

	SELECT
		@fin_id1 = cp.fin_id
	FROM CALENDAR_PERIOD cp
	WHERE cp.start_date = @start_date1

	SET @paid1 = @saldo1 + @value1 + @added1

	INSERT INTO PAYM_HISTORY
	(	fin_id
		,occ
		,service_id
		,tarif
		,kol
		,saldo
		,value
		,added
		,paymaccount
		,PaymAccount_peny
		,paid)
	VALUES (@fin_id1
			,@occ1
			,@service_id1
			,@tarif1
			,@kol1
			,@saldo1
			,@value1
			,@added1
			,@paymaccount1
			,@paymaccount_peny1
			,@paid1)

END
go

