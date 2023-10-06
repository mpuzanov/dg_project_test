CREATE   FUNCTION [dbo].[Fun_GetSumIntPrint]
(
	@occ1		INT
	,@fin_id	SMALLINT	= NULL
)
RETURNS VARCHAR(50)
AS
BEGIN
	/*
	 Возвращаем строку с суммами для единой квитанции Сбербанка
	 
	 select dbo.Fun_GetSumIntPrint (680003671, 148)
	 
	*/
	IF @fin_id IS NULL
		SELECT
			@fin_id = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	DECLARE	@SumResult	VARCHAR(50)
			,@Sum1		DECIMAL(9, 2)
			,@Sum2		DECIMAL(9, 2)
			,@Sum3		DECIMAL(9, 2)
			,@Sum4		DECIMAL(9, 2)
			,@Sum5		DECIMAL(9, 2)

	SELECT
		@Sum1 = SUM(o.Whole_payment)
	FROM dbo.View_OCC_ALL AS o 
	WHERE o.occ = @occ1
	AND o.fin_id=@fin_id

	SELECT
		@Sum2 = SUM(os.Whole_payment)
	FROM dbo.VOcc_Suppliers AS os 
	JOIN dbo.SUPPLIERS_ALL AS sa 
		ON os.sup_id = sa.id
	WHERE os.occ = @occ1
		AND os.fin_id = @fin_id
		AND sa.account_one=1
		AND sa.type_sum_intprint=1
	
	SELECT @Sum1 = @Sum1+COALESCE(@Sum2,0)
	
	SELECT
		@Sum2 = SUM(os.Whole_payment)
	FROM dbo.VOCC_SUPPLIERS AS os 
	JOIN dbo.SUPPLIERS_ALL AS sa 
		ON os.sup_id = sa.id
	WHERE os.occ = @occ1
		AND os.fin_id = @fin_id
		AND sa.account_one=1
		AND sa.type_sum_intprint=2

	SELECT
		@Sum3 = SUM(os.Whole_payment)
	FROM dbo.VOCC_SUPPLIERS AS os
	JOIN dbo.SUPPLIERS_ALL AS sa 
		ON os.sup_id = sa.id
	WHERE os.occ = @occ1
		AND os.fin_id = @fin_id
		AND sa.account_one=1
		AND sa.type_sum_intprint=3

	SELECT
		@Sum4 = SUM(os.Whole_payment)
	FROM dbo.VOCC_SUPPLIERS AS os 
	JOIN dbo.SUPPLIERS_ALL AS sa 
		ON os.sup_id = sa.id
	WHERE os.occ = @occ1
		AND os.fin_id = @fin_id
		AND sa.account_one=1
		AND sa.type_sum_intprint=4

	SELECT
		@Sum5 = SUM(os.Whole_payment)
	FROM dbo.VOcc_Suppliers AS os
	JOIN dbo.SUPPLIERS_ALL AS sa
		ON os.sup_id = sa.id
	WHERE os.occ = @occ1
		AND os.fin_id = @fin_id
		AND sa.account_one=1
		AND sa.type_sum_intprint=5
	
	SELECT
		@SumResult = 'SUM1:'+STR(@Sum1, 9, 2)+';'

	IF COALESCE(@Sum2,0)<>0
		SELECT @SumResult=@SumResult+'SUM2:'+STR(@Sum2, 9, 2)+';'
	IF COALESCE(@Sum3,0)<>0
		SELECT @SumResult=@SumResult+'SUM3:'+STR(@Sum3, 9, 2)+';'
	IF COALESCE(@Sum4,0)<>0
		SELECT @SumResult=@SumResult+'SUM4:'+STR(@Sum4, 9, 2)+';'
	IF COALESCE(@Sum5,0)<>0
		SELECT @SumResult=@SumResult+'SUM5:'+STR(@Sum5, 9, 2)+';'
						
	RETURN @SumResult

END
go

