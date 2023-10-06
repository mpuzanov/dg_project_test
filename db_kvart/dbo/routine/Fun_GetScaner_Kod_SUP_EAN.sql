CREATE   FUNCTION [dbo].[Fun_GetScaner_Kod_SUP_EAN]
(
	@occ1			BIGINT
	,@sup_id1		INT				= NULL  -- код поставщика
	,@fin_id1		SMALLINT		= 0
	,@summa1		DECIMAL(9, 2)	= 0	-- сумма к оплате
	,@id_barcode	VARCHAR(50)		= ''
)
RETURNS VARCHAR(24)
AS
/*
Дата изменения: 24.08.11
Автор изменения: Пузанов М.А.

Описание используемого штрих-кода в счетах-извещениях
Формат  - Interleaved 2/5 
24 значащих цифр
9999 - код организации(тип жил.фонда)
999999999 - единый лицевой счет (9 знаков)
999 - год(1)месяц(2)
99999999 - сумма к оплате (8 знаков)
select dbo.Fun_GetScaner_Kod_SUP_EAN(342132, 0, 180, 2419.90, 585)
*/
BEGIN
	DECLARE	@Kod1			VARCHAR(24)
			,@org1			VARCHAR(4)
			,@kod			VARCHAR(3)	= '000'
			,@strschtl		VARCHAR(9)	= ''
			,@start_date	SMALLDATETIME
			,@mes			VARCHAR(2)
			,@god			VARCHAR(4)
			,@strsumma1		VARCHAR(8)

	IF @sup_id1 = 0
		SET @sup_id1 = NULL
	SET @org1 = ''
	IF PATINDEX('%[^0-9]%', @id_barcode)>0 OR @id_barcode='' SET @id_barcode='0'
	SET @org1 = RIGHT('0000'+ @id_barcode, 4)

	IF @sup_id1 IS NOT NULL
		SELECT TOP 1
			@strschtl = occ_sup
		FROM dbo.OCC_SUPPLIERS 
		WHERE occ = @occ1
		AND sup_id = @sup_id1
		AND fin_id = @fin_id1
	ELSE
	BEGIN
		IF LEN(@occ1) = 9
			SET @strschtl = @occ1
		ELSE
			SET @strschtl = CONCAT(@kod , RIGHT('000000'+ CAST(@occ1 AS VARCHAR), 6)) --'%06s'
	END


	SET @strschtl = RIGHT('000000000'+ @strschtl, 9) --'%09s'

	SELECT
		@mes = '00'
		,@god = '0'
	SET @strsumma1 = ''

	SET @strsumma1 = LTRIM(STR(COALESCE(@summa1, 0), 8, 2))
	SET @strsumma1 = REPLACE(@strsumma1, '.', '')
	SET @strsumma1 = RIGHT('00000000'+ @strschtl, 8) -- '%08s' 

	SET @Kod1 = @org1 + @strschtl + @god + @mes + @strsumma1

	RETURN SUBSTRING(@Kod1, 1, 24)
END
go

