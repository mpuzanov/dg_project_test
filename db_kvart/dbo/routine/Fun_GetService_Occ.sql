CREATE   FUNCTION [dbo].[Fun_GetService_Occ]
(
	@occ1			INT
	,@service_id1	VARCHAR(10)
)
RETURNS INT
AS
BEGIN
/*
	Получение лицевого счета услуги с
	Расчётом контрольной цифры (EAN-8)

	автор:		Антропов С.В.
	дата создания:	10.08.04
	
	select dbo.Fun_GetService_Occ(240085, 'гвод')  --42400851
*/
	DECLARE	@strResult		VARCHAR(15)
			,@sumCHet		SMALLINT
			,@sumNEchet		SMALLINT
			,@i				SMALLINT
			,@a				SMALLINT
			,@service_kod1	TINYINT

	IF @occ1 > 99999999
		RETURN @occ1

	SELECT
		@service_kod1 = service_kod
	FROM dbo.SERVICES 
	WHERE id = @service_id1

	IF @service_kod1 IS NULL
		SET @service_kod1 = 0

	SET @strResult = CONCAT(@service_kod1, RIGHT('000000' + CAST(@occ1 AS VARCHAR), 6))   --'%06i'

	IF DATALENGTH(@strResult) < 9
	BEGIN
		-- Вычисляем контрольное число
		SET @i = LEN(@strResult)
		SET @sumCHet = 0
		SET @sumNEchet = 0
		WHILE @i >= 1
		BEGIN
			IF @i = 1
			BEGIN
				SET @sumCHet = @sumCHet + CONVERT(INT, SUBSTRING(@strResult, @i, 1))
			END
			ELSE
			BEGIN
				SET @sumCHet = @sumCHet + CONVERT(INT, SUBSTRING(@strResult, @i, 1))
				SET @sumNEchet = @sumNEchet + CONVERT(INT, SUBSTRING(@strResult, @i - 1, 1))
			END
			SET @i = @i - 2
		END

		SET @a = @sumCHet * 3 + @sumNEchet
		SET @i = ((CONVERT(INT, SUBSTRING(LTRIM(STR(@a)), 1, LEN(@a) - 1))) + 1) * 10
		IF (@i - @a) = 10
			SET @strResult = @strResult + '0'
		ELSE
			SET @strResult = @strResult + LTRIM(STR(@i - @a))
	END

	RETURN CAST(@strResult AS INT)

END
go

