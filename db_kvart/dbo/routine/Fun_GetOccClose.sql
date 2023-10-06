CREATE   FUNCTION [dbo].[Fun_GetOccClose]
(
	@occ1 INT
)
RETURNS BIT
AS
BEGIN
	--
	-- Проверка закрыт заданный лицевой или нет
	--
	-- 0 - Закрыт   1 - открыт 
	--
	DECLARE @result1 BIT

	IF EXISTS (SELECT
				1
			FROM dbo.Occupations
			WHERE Occ = @occ1
			AND STATUS_ID = 'закр')
		SET @result1 = 0
	ELSE
		SET @result1 = 1

	RETURN @result1

END
go

