-- =============================================
-- Author:		Пузанов
-- Create date: 24.01.08
-- Description:	Функция возвращает строку для квитанции по Лучшему платильщику
-- =============================================
CREATE   FUNCTION [dbo].[Fun_GetPrintStrPaymDiscount]
(
	@occ		INT
	,@fin_id	SMALLINT
	,@sup_id	INT	= NULL
)
RETURNS VARCHAR(100)
AS
BEGIN
	-- Declare the return variable here
	DECLARE	@StrResult		VARCHAR(100)	= ''
			,@DB_NAME		VARCHAR(30)		= DB_NAME()
			,@StrFinPeriod	VARCHAR(20)

	IF (@DB_NAME IN ('KVART', 'KOMP'))
	BEGIN
		SELECT
			@StrFinPeriod = StrMes
		FROM dbo.GLOBAL_VALUES GV
		WHERE fin_id = @fin_id

		DECLARE	@Sum5	DECIMAL(9, 2)	= 0
				,@Sum50	DECIMAL(9, 2)	= 0

		SELECT
			@Sum5 = SUM(value)
		FROM dbo.View_PAYINGS 
		WHERE fin_id = @fin_id
		AND occ = @occ
		AND tip_paym_id = '1017'  -- Скидка лучшему плательщику 5 %
		AND sup_id = COALESCE(@sup_id, 0)
		GROUP BY occ

		SELECT
			@Sum50 = SUM(value)
		FROM dbo.View_PAYINGS 
		WHERE fin_id = @fin_id
		AND occ = @occ
		AND tip_paym_id = '1018'  -- Скидка лучшему плательщику 50 %
		AND sup_id = COALESCE(@sup_id, 0)
		GROUP BY occ

		IF @Sum5 > 0
		BEGIN
			SELECT
				@StrResult = 'Скидка лучшему плательшику 5% - ' + LTRIM(STR(@Sum5, 9, 2)) + ' за ' + @StrFinPeriod + ' (учтена в оплате)'
		END
		IF @Sum50 > 0
		BEGIN
			SELECT
				@StrResult = 'Скидка лучшему плательшику ' + STR(@Sum50, 9, 2) + ' руб за ' + @StrFinPeriod + ' (учтена в оплате)'
		END
	END

	-- Return the result of the function
	RETURN @StrResult

END
go

