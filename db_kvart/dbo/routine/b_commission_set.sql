-- =============================================
-- Author:		Пузанов
-- Create date: 15.10.2011
-- Description:	Установка комиссии банка на все платежи в файле
-- =============================================
CREATE     PROCEDURE [dbo].[b_commission_set]
(
	@filedbf_id		INT
	,@commission	DECIMAL(9, 2) = 0
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE	@sumOpl		DECIMAL(9, 2)
			,@koef		DECIMAL(16, 8) -- коэф. для раскидки
			,@ostatok	DECIMAL(9, 2)

	DECLARE @t TABLE
		(
			id			INT
			,sum_opl	DECIMAL(9, 2) DEFAULT 0
			,commission	DECIMAL(9, 2) DEFAULT 0
		)

	INSERT INTO @t
		SELECT
			id
			,sum_opl
			,commission
		FROM dbo.Bank_Dbf
		WHERE filedbf_id = @filedbf_id;

	SELECT
		@sumOpl = SUM(SUM_OPL)
	FROM @t;

	SET @koef = @commission / @sumOpl;

	UPDATE @t
	SET COMMISSION = SUM_OPL * @koef;

	SELECT
		@ostatok = SUM(COMMISSION)
	FROM @t;
	--print @ostatok

	IF @ostatok <> @commission
	BEGIN
		SET @ostatok = @commission - @ostatok
		--print @ostatok
		;with cte as (
		SELECT TOP (1) * FROM @t WHERE COMMISSION > @ostatok
		)
		UPDATE cte
		SET COMMISSION = COMMISSION + @ostatok;
		
	END;

	UPDATE b
	SET commission = t.commission
	FROM dbo.Bank_Dbf AS b
	JOIN @t AS t
		ON b.id = t.id
	WHERE filedbf_id = @filedbf_id;

	UPDATE dbo.Bank_tbl_spisok
	SET COMMISSION = @commission
	WHERE filedbf_id = @filedbf_id

END
go

