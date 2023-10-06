CREATE FUNCTION [dbo].[Fun_GetNumUIN25]
(
	@uin VARCHAR(25)
)
RETURNS VARCHAR(25)
AS
BEGIN
	/*
	
	Функция формирования 25 контрльного разряда
	
	select dbo.Fun_GetNumUIN25('000082770000770000013345')
	select dbo.Fun_GetNumUIN25('000082770000770000013368')
	select dbo.Fun_GetNumUIN25('000082770000770000013354')
	select dbo.Fun_GetNumUIN25('000082770000770000013336')

по УИН: 
(1-8 символ): УРН участника, сформировавшего начисление. УРН указывается в десятичном представлении. Для этого его необходимо предварительно перевести из шестнадцатиричного представления и десятичное.
Например, УРН участника равен значению <aa11b4>; после перевода в десятичное представление получается <11145652>. Если при переводе УРН участника в десятичное представление получается менее восьми символов, то значение дополняется нулями слева до 8 цифр.
(9-24 символ):Уникальный номер начисления - 16 цифр. Алгоритм формирования, обеспечивающий уникальность номера, определяется информационной системой.
(25 символ): Контрольный разряд. Алгоритм расчета описан в разделе 3.1.3.

	*/
	DECLARE	@ves		INT			= 1
			,@textpos	INT			= 1
			,@tmpstr	CHAR(1)
			,@sum1		INT			= 0
			,@sum_itog	INT			= 0
			,@ostatok	INT			= 0
			,@kol		SMALLINT	= 1

LABEL1:
	SET @sum_itog = 0	
	SET @textpos = 1
	WHILE @textpos <=24
	BEGIN
		SELECT
			@tmpstr = SUBSTRING(@uin, @textpos, 1)

		SET @sum1 = CAST(@tmpstr AS INT) * @ves

		SET @sum_itog = @sum_itog + @sum1

		--PRINT @tmpstr + '  textpos:' + LTRIM(STR( @textpos))+ ' ves:' + LTRIM(STR(@ves)) + ' sum1:' + LTRIM(STR(@sum1)) + ' sum_itog:' + STR(@sum_itog)

		SET @ves = @ves + 1
		IF @ves > 10
			SET @ves = 1
		SET @textpos = @textpos + 1
	END

	SET @ostatok = @sum_itog % 11
	IF @ostatok = 10
		AND @kol = 1
	BEGIN
		SELECT
			@ves = 3
			,@kol += 1
		GOTO LABEL1
	END
	IF @kol = 2 AND @ostatok = 10
		SET @ostatok = 0

	SELECT
		@uin = @uin + LTRIM(STR(@ostatok))

	RETURN @uin

END
go

