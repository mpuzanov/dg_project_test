CREATE   FUNCTION [dbo].[Fun_GetScaner_Kod_EAN_SBER]
(
	  @occ1 BIGINT
	, @fin_id1 SMALLINT = NULL -- 
	, @summa1 DECIMAL(9, 2) = 0 -- сумма к оплате
	, @inn VARCHAR(10) = '0000000000'
)
RETURNS VARCHAR(34)
AS
/*
Дата изменения: 14.07.12
Автор изменения: Пузанов М.А.

Описание используемого штрих-кода в счетах-извещениях
Формат  - Interleaved 2/5 
34 значащих цифр
9999999999 - ИНН организации(тип жил.фонда) 10 знаков
99999999999 - единый лицевой счет (11 знаков)
9999 - год(2)месяц(2)
999999999 - сумма к оплате (9 знаков)


select [dbo].[Fun_GetScaner_Kod_EAN_SBER] (110041111,Null,999.99,NULL)

*/
BEGIN
	DECLARE @Kod1 VARCHAR(34)
		  , @strschtl VARCHAR(12)
		  , @start_date SMALLDATETIME
		  , @mes VARCHAR(2)
		  , @god VARCHAR(4)
		  , @strsumma1 VARCHAR(8)

	IF @inn IS NULL
		SET @inn = '0000000000'
	SELECT @mes = '00'
		 , @god = '00'
		 , @strsumma1 = ''
	SET @inn = dbo.Fun_AddLeftZero(@inn, 10)

	SET @strschtl = dbo.Fun_AddLeftZero(@occ1, 12)

	IF @fin_id1 IS NULL
		SELECT @fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	SELECT @start_date = start_date
	FROM dbo.Global_values
	WHERE fin_id = @fin_id1
	IF @start_date IS NULL
	BEGIN
		SELECT @god = '00'
			 , @mes = '00'
	END
	ELSE
	BEGIN
		SET @mes = DATEPART(MONTH, @start_date)
		SET @mes = dbo.Fun_AddLeftZero(@mes, 2)
		-- берем последие 2 цифры года
		SET @god = SUBSTRING(LTRIM(STR(DATEPART(YEAR, @start_date))), 3, 2)
	END

	SET @strsumma1 = STR(COALESCE(@summa1, 0), 8, 2)
	SET @strsumma1 = REPLACE(@strsumma1, '.', '')
	SET @strsumma1 = dbo.Fun_AddLeftZero(@strsumma1, 8)

	SET @Kod1 = @inn + @strschtl + @god + @mes + @strsumma1

	RETURN @Kod1
END
go

