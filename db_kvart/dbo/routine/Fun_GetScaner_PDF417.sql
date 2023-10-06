CREATE   FUNCTION [dbo].[Fun_GetScaner_PDF417]
(
    @occ1          BIGINT,
    @fin_id1       SMALLINT           = NULL,
    @sup_id1       INT                = NULL, -- код поставщика
    @summa1        DECIMAL(12, 2)     = 0, -- сумма к оплате
    @address       VARCHAR(50)        = '',
    @Initials      VARCHAR(50)        = '',
    @nameBank      VARCHAR(110)       = '',
    @bik           VARCHAR(9)         = NULL,
    @kschetBank    VARCHAR(20)        = NULL,
    @name2         VARCHAR(110)       = '',
    @rschet        VARCHAR(20)        = NULL,
    @inn           VARCHAR(20)        = NULL,
    @kpp           VARCHAR(20)        = NULL,
    @vid_serv_bank BIGINT             = NULL
)
RETURNS VARCHAR(1000)
AS
/*
Дата создания: 01.02.2010
Автор изменения: Пузанов М.А.

Описание используемого штрих-кода в счетах-извещениях
Формат  - двух мерный штрих-код например PDF417

*/
BEGIN
	DECLARE @Kod1        VARCHAR(1000),
            @strschtl    VARCHAR(25),
            @start_date  SMALLDATETIME,
            @mes         VARCHAR(2),
            @strsumma1   VARCHAR(12),
            @tip_id1     SMALLINT,
            @tip_name    VARCHAR(50),
            @fin_current SMALLINT

	IF @vid_serv_bank IS NULL
		SET @vid_serv_bank = 0

	IF @rschet IS NULL
		SET @rschet = '00000000000000000000'

	IF @kschetBank IS NULL
		SET @kschetBank = '00000000000000000000'

	IF @bik IS NULL
		SET @bik = '000000000'

	IF @inn IS NULL
		SET @inn = '0'

	IF @kpp IS NULL
		SET @kpp = '0'

	SET @strschtl = ltrim(str(@occ1))

	-- Определяем тип жилого фонда
	SELECT @tip_id1 = tip_id
		 , @tip_name = tip_name
		 , @fin_current = fin_id
	FROM dbo.VOCC AS V
	WHERE occ = @occ1

	IF @sup_id1 IS NOT NULL
		SELECT TOP 1 @strschtl = occ_sup
		FROM
			dbo.OCC_SUPPLIERS
		WHERE
			occ = @occ1
			AND sup_id = @sup_id1
			AND fin_id=@fin_id1
			
	SET @strschtl = 'Л/СЧ: ' + @strschtl

	SELECT @mes = '00'
	SET @strsumma1 = '0'

	IF @fin_id1 IS NULL
		SET @fin_id1 = @fin_current

	SELECT @start_date = start_date
	FROM dbo.GLOBAL_VALUES
	WHERE fin_id = @fin_id1

	SET @mes = datepart (MONTH, @start_date)
	SET @mes = dbo.Fun_AddLeftZero(@mes, 2)

	SET @strsumma1 = ltrim(str(@summa1, 12, 2))

	SET @Kod1 = 'PD4V1.0|CP1251||' + @strsumma1 + char(124) + '0' + char(124) + ltrim(str(@vid_serv_bank)) + char(124)
	SET @Kod1 = @Kod1 + @nameBank + char(124) + @bik + char(124) + @kschetBank + char(124)
	SET @Kod1 = @Kod1 + @name2 + char(124) + @rschet + char(124) + @inn + char(124) + @kpp + char(124)
	SET @Kod1 = @Kod1 + 'Для ' + @tip_name + ' за жилое помещение и комм.услуги' + char(124)
	SET @Kod1 = @Kod1 + @strschtl + '; АДРЕС: ' + upper(rtrim(@address)) + '; ПЕРИОД: ' + @mes + ';' + char(124)

	RETURN @Kod1
END
go

