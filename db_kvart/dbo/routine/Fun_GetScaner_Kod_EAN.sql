CREATE   FUNCTION [dbo].[Fun_GetScaner_Kod_EAN]
(
	@occ1			BIGINT
	,@service_id1	VARCHAR(10)		= NULL -- код услуги
	,@fin_id1		SMALLINT		= 0
	,@summa1		DECIMAL(9, 2)	= 0 -- сумма к оплате
	,@id_barcode	VARCHAR(50)		= ''-- код оргганизации для Сбербанка
	,@barcode_type	SMALLINT		= 1 -- тип штрих-кода из справочника
	,@inn			VARCHAR(12)		= '0'
)
RETURNS VARCHAR(50)
AS
/*
Дата изменения: 26.04.07
Автор изменения: Пузанов М.А.

Формируем штрих-код разных форматов

select dbo.Fun_GetScaner_Kod_EAN(343630,null,182,123.00,0545,2,0)
select dbo.Fun_GetScaner_Kod_EAN(680002331,null,182,0.00,'0545_AA',2,0)
select dbo.Fun_GetScaner_Kod_EAN(700040058,null,132,1190.35,0545,3,'0')

*/
BEGIN
	DECLARE	@Kod1				VARCHAR(50)
			,@org1				VARCHAR(10) = ''
			,@kod				VARCHAR(3)
			,@strschtl			VARCHAR(15)
			,@start_date		SMALLDATETIME
			,@mes				VARCHAR(2)	= ''
			,@god				VARCHAR(4)	= ''
			,@strsumma1			VARCHAR(10)	= ''
			,@db_name			VARCHAR(20) = DB_NAME()
			,@len_occ			TINYINT		= 9
			,@len_mes			TINYINT		= 2
			,@len_god			TINYINT		= 1
			,@len_sum			TINYINT		= 8
			,@len_inn			TINYINT		= 0
			,@is_period_print	BIT			= 0

	IF @barcode_type IS NULL
		OR @barcode_type = 0
	BEGIN
		SELECT TOP 1
			@barcode_type = BARCODE_TYPE
		FROM dbo.GLOBAL_VALUES AS GV
		ORDER BY fin_id DESC

		IF @barcode_type IS NULL
			SET @barcode_type = 2
	END

	SELECT
		@len_occ = len_occ
		,@len_mes = len_mes
		,@len_god = len_god
		,@is_period_print = is_period_print
		,@len_sum = len_sum
		,@len_inn = len_inn
	FROM dbo.BARCODE_TYPE
	WHERE id = @barcode_type

	IF @len_inn = 0	AND @id_barcode<>'' AND PATINDEX('%[^0-9]%', @id_barcode)=0
		SELECT
			@org1 = dbo.Fun_AddLeftZero(@id_barcode, 4)
	ELSE
		SELECT
			@org1 = dbo.Fun_AddLeftZero(COALESCE(@inn, '0'), @len_inn) -- 10 знаков ИНН обычно

	SELECT
		@strschtl = dbo.Fun_AddLeftZero(@occ1, @len_occ)
		,@mes = dbo.Fun_AddLeftZero(@mes, @len_mes)
		,@god = dbo.Fun_AddLeftZero(@god, @len_god)

	IF @is_period_print = 1
	BEGIN
		IF @fin_id1 <> 0
		BEGIN
			SELECT
				@start_date = start_date
			FROM dbo.GLOBAL_VALUES 
			WHERE fin_id = @fin_id1

			IF @start_date IS NULL
			BEGIN
				SELECT
					@start_date = start_date
				FROM dbo.GLOBAL_VALUES 
				WHERE closed = 0
			END

			SET @mes = DATEPART(MONTH, @start_date)
			SET @mes = dbo.Fun_AddLeftZero(@mes, @len_mes)
			-- берем @len_god последних цифры года
			SET @god = SUBSTRING(LTRIM(STR(DATEPART(YEAR, @start_date))), 5 - @len_god, @len_god)
		END

	END

	SET @strsumma1 = LTRIM(STR(COALESCE(@summa1, 0), @len_sum, 2))
	SET @strsumma1 = REPLACE(@strsumma1, '.', '')
	SET @strsumma1 = dbo.Fun_AddLeftZero(@strsumma1, @len_sum)

	SET @Kod1 = @org1 + @strschtl + @god + @mes + @strsumma1

	RETURN @Kod1
END
go

