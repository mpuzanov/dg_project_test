/*
-- =============================================
-- Author:		Пузанов
-- Create date: 12/07/2012
-- Description:	Возвращаем размер государственной пошлины
-- =============================================
select dbo.Fun_GetGosposhlina(2541,1)
select dbo.Fun_GetGosposhlina(15700,1)
select dbo.Fun_GetGosposhlina(25000,1)
*/
CREATE FUNCTION [dbo].[Fun_GetGosposhlina]
(
	@SummaIska DECIMAL(9,2),
	@tipSuda TINYINT = 1  -- 1-суд общей юрисдикции, 2 - арбитражный суд
)
RETURNS DECIMAL(9,2)
AS
BEGIN
	DECLARE @SumItog DECIMAL(9,2)=0, @sum1 decimal(9,2)

	IF @tipSuda=1
	BEGIN
		-- ===== до 20 000 
		IF @SummaIska<=20000
		BEGIN
			SET @SumItog=@SummaIska*4*0.01   -- 4 %
			IF @SumItog<400 SET @SumItog=400
		END
		-- ===== от 20 000 до 100 000
		IF 20000<@SummaIska AND @SummaIska<=100000
		BEGIN
			SELECT @SumItog=800 
			SET @sum1=@SummaIska-20000
			
			SET @sum1=@sum1*3*0.01   -- 3%
			SET @SumItog=@SumItog+@sum1
		END
		-- ===== от 100 000 до 200 000
		IF 100000<@SummaIska AND @SummaIska<=200000
		BEGIN
			SELECT @SumItog=3200
			SET @sum1=@SummaIska-100000
			
			SET @sum1=@sum1*2*0.01   -- 2%
			SET @SumItog=@SumItog+@sum1
		END
		-- ===== от 200 000 до 1 000 000
		IF 200000<@SummaIska AND @SummaIska<=1000000
		BEGIN
			SELECT @SumItog=5200
			SET @sum1=@SummaIska-200000
			
			SET @sum1=@sum1*1*0.01    -- 1%
			SET @SumItog=@SumItog+@sum1
		END
		-- ===== от 1 000 000
		IF 1000000<@SummaIska
		BEGIN
			SELECT @SumItog=13200
			SET @sum1=@SummaIska-1000000
			
			SET @sum1=@sum1*0.5*0.01    -- 0.5%
			SET @SumItog=@SumItog+@sum1
		END		
	END
-- ******************* Арбитражные суды
	IF @tipSuda=2
	BEGIN
		-- ===== до 100 000 
		IF @SummaIska<=100000
		BEGIN
			SET @SumItog=@SummaIska*4*0.01   -- 4 %
			IF @SumItog<2000 SET @SumItog=2000
		END
		-- ===== от 100 000 до 200 000
		IF 100000<@SummaIska AND @SummaIska<=200000
		BEGIN
			SELECT @SumItog=4000
			SET @sum1=@SummaIska-100000
			
			SET @sum1=@sum1*3*0.01   -- 3%
			SET @SumItog=@SumItog+@sum1
		END
		-- ===== от 200 000 до 1 000 000
		IF 200000<@SummaIska AND @SummaIska<=1000000
		BEGIN
			SELECT @SumItog=7000
			SET @sum1=@SummaIska-200000
			
			SET @sum1=@sum1*2*0.01   -- 2%
			SET @SumItog=@SumItog+@sum1
		END
		-- ===== от 1 000 000 до 2 000 000
		IF 1000000<@SummaIska AND @SummaIska<=2000000
		BEGIN
			SELECT @SumItog=23000
			SET @sum1=@SummaIska-1000000
			
			SET @sum1=@sum1*1*0.01    -- 1%
			SET @SumItog=@SumItog+@sum1
		END
		-- ===== от 2 000 000
		IF 2000000<@SummaIska
		BEGIN
			SELECT @SumItog=33000
			SET @sum1=@SummaIska-2000000
			
			SET @sum1=@sum1*0.5*0.01    -- 0.5%
			SET @SumItog=@SumItog+@sum1
		END		
	END

	RETURN @SumItog

END
go

