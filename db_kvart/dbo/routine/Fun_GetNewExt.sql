CREATE   FUNCTION [dbo].[Fun_GetNewExt]
(
	@is_bank1 BIT
)
RETURNS VARCHAR(10)
AS
/*
   Формирование нового расширения файла
   для файлов платежей, приходящих из банков
   Анализируется таблица: PAYCOLL_ORGS

select dbo.Fun_GetNewExt(1)
select dbo.Fun_GetNewExt(0)

*/
BEGIN

	DECLARE @t1 TABLE
		(
			ext VARCHAR(10)
		)

	INSERT
	INTO @t1
			SELECT DISTINCT
				ext
			FROM PAYCOLL_ORGS

	--select ext from @t1
	--select cast(rand()*99 as int) -- генерация случайного числа из 2 знаков

	DECLARE	@i			INT			= 0
			,@y			INT
			,@ext1		VARCHAR(10)
			,@ext_out	VARCHAR(10)	= ''

	IF @is_bank1 = 1
	BEGIN  --  Если банк то расширение SXX
		WHILE @i < 999
		BEGIN
			SET @i = @i + 1
			SET @ext1 = CONCAT('S', RIGHT('00'+ CAST(@i AS VARCHAR), 2))
			IF NOT EXISTS (SELECT
						1
					FROM @t1
					WHERE ext = @ext1)
			BEGIN
				SET @ext_out = @ext1
				--print @ext_out
				BREAK
			END
		END
	END

	IF (@is_bank1 = 0
		OR @ext_out = '')
	BEGIN --  Если организация то расширение XXX
		WHILE @i < 999
		BEGIN
			SET @i = @i + 1
			SET @ext1 = RIGHT('000'+ CAST(@i AS VARCHAR), 3) --('%03i',@i)
			IF NOT EXISTS (SELECT
						1
					FROM @t1
					WHERE ext = @ext1)
			BEGIN
				SET @ext_out = @ext1
				--print @ext_out
				BREAK
			END
		END
	END

	IF @ext_out = ''
		SET @ext_out = '999'
	RETURN @ext_out

END
go

