CREATE   FUNCTION [dbo].[Fun_GetScaner_2D_SBER](
    @occ1 BIGINT
, @fin_id1 SMALLINT = NULL
, @sup_id1 INT = NULL -- код поставщика
, @summa1 DECIMAL(12, 2) = 0 -- сумма к оплате
, @address NVARCHAR(100) = ''
, @Initials NVARCHAR(100) = ''
, @nameBank NVARCHAR(110) = ''
, @bik VARCHAR(9) = NULL
, @kschetBank VARCHAR(20) = NULL
, @name2 NVARCHAR(110) = ''
, @rschet VARCHAR(20) = NULL
, @inn VARCHAR(20) = NULL
, @kpp VARCHAR(20) = NULL
, @vid_serv_bank BIGINT = NULL
, @Last_name NVARCHAR(50) = ''
, @First_name NVARCHAR(30) = ''
, @Second_name NVARCHAR(30) = ''
, @CBC VARCHAR(20) = ''
, @OKTMO VARCHAR(11) = ''
, @UIN VARCHAR(25) = ''
, @dop_params NVARCHAR(100) = ''
)
    RETURNS NVARCHAR(2000)
AS
/*
Автор изменения: Пузанов М.А.

Описание используемого штрих-кода в счетах-извещениях
Формат  - двух мерный штрих-код например PDF417, QR

select dbo.Fun_GetScaner_2D_SBER(210042001, 246, NULL, 9999, 'АДРЕС', 'ФИО', 'БАНК','1111','2222222222222','ФИРМА' COLLATE Cyrillic_General_CI_AS, '3333333333333','444444444','55555', 0, 'Фамилия', 'Имя', 'Отчество', 9999, 99999, 'id_jku_pd_gis', 'dop_params')

select dbo.Fun_GetScaner_2D_SBER(t.occ_false, @fin_id1, NULL, i.SumPaym, t.adres, i.Initials, t.bank, t.bik, t.korscht, t.NameFirma, t.rasscht, t.inn, t.kpp, t.licbank)

*/
BEGIN
    DECLARE @Kod1 NVARCHAR(2000)
        ,@strschtl VARCHAR(25)
        ,@start_date SMALLDATETIME
        ,@paymPeriod VARCHAR(8)
        ,@strsumma1 VARCHAR(12) = '0'
        ,@tip_id1 SMALLINT
        ,@tip_name NVARCHAR(50)
        ,@fin_current SMALLINT
        ,@Lang CHAR(1) = '2' -- 1-1251, 2-UTF8, 3-KOI8
        ,@DB_NAME VARCHAR(20) = UPPER(DB_NAME())

    SELECT @Last_name = CASE
                            WHEN @Last_name IS NULL THEN ''
                            ELSE UPPER(RTRIM(@Last_name))
        END
         , @First_name = CASE
                             WHEN @First_name IS NULL THEN ''
                             ELSE UPPER(RTRIM(@First_name))
        END
         , @Second_name = CASE
                              WHEN @Second_name IS NULL THEN ''
                              ELSE UPPER(RTRIM(@Second_name))
        END
         , @vid_serv_bank = CASE
                                WHEN @vid_serv_bank IS NULL THEN 0
                                ELSE @vid_serv_bank
        END
         , @rschet = CASE
                         WHEN COALESCE(@rschet, '') = '' THEN '00000000000000000000'
                         ELSE @rschet
        END
         , @kschetBank = CASE
                             WHEN COALESCE(@kschetBank, '') = '' THEN '0'
                             ELSE @kschetBank
        END
         , @bik = CASE
                      WHEN COALESCE(@bik, '') = '' THEN '000000000'
                      ELSE @bik
        END
         , @inn = CASE
                      WHEN COALESCE(@inn, '') = '' THEN '0'
                      ELSE @inn
        END
         , @kpp = CASE
                      WHEN COALESCE(@kpp, '') = '' THEN '0'
                      ELSE @kpp
        END
         , @UIN = CASE
                      WHEN @UIN IS NULL THEN ''
                      ELSE @UIN
        END
         , @strschtl = LTRIM(STR(@occ1)) 
         , @DOP_Params = coalesce(@DOP_Params, '')

    -- Определяем тип жилого фонда
    SELECT @tip_id1 = tip_id
         , @tip_name = tip_name --COLLATE Cyrillic_General_CI_AS
         , @fin_current = V.fin_id
         , @Lang = ot.barcode_charset
    FROM dbo.VOcc AS V 
		JOIN dbo.Occupation_Types AS ot ON V.tip_id = ot.id
    WHERE occ = @occ1

    IF @sup_id1 IS NOT NULL
        BEGIN
            SELECT TOP (1) @strschtl = occ_sup
                       , @tip_name = sa.name --COLLATE Cyrillic_General_CI_AS
            FROM dbo.Occ_Suppliers AS os 
                     JOIN dbo.Suppliers_all AS sa 
                          ON os.sup_id = sa.id
            WHERE occ = @occ1
              AND sup_id = @sup_id1
              AND fin_id = @fin_id1

        END

    IF @fin_id1 IS NULL
        SET @fin_id1 = @fin_current

    SELECT @start_date = start_date FROM dbo.GLOBAL_VALUES WHERE fin_id = @fin_id1

    SET @paymPeriod = CONCAT(RIGHT('0' + RTRIM(MONTH(@start_date)), 2) , LEFT(CONVERT(VARCHAR(2),@start_date,2),2) ) --'MMyy'

    IF @summa1 = 0
        SET @strsumma1 = '0'
    ELSE
        SET @strsumma1 = REPLACE(LTRIM(STR(@summa1, 12, 2)), '.', '')

    -- | char(124)


    SET @Kod1 = N'ST0001'
    SET @Kod1 = concat(@Kod1, @Lang)
    SET @Kod1 = concat(@Kod1, N'|Name=', RTRIM(LTRIM(@name2)), N'|PersonalAcc=', @rschet, N'|BankName=', @nameBank,
                N'|BIC=', @bik, N'|CorrespAcc=', @kschetBank)
    SET @Kod1 = concat(@Kod1, N'|PayeeINN=', @inn)
    SET @Kod1 = concat(@Kod1, N'|PersAcc=', @strschtl, N'|Sum=', @strsumma1)
    --SET @Kod1 = @Kod1 + '|Purpose=Оплата ЖКУ'
    SET @Kod1 = concat(@Kod1, N'|PayerAddress=', UPPER(RTRIM(@address)))
    SET @Kod1 = concat(@Kod1, N'|PaymPeriod=', @paymPeriod)
    IF @Last_name <> ''
        SET @Kod1 = concat(@Kod1, N'|LastName=', @Last_name)
    IF @First_name <> ''
        SET @Kod1 = concat(@Kod1, N'|FirstName=' + @First_name)
    IF @Second_name <> ''
        SET @Kod1 = concat(@Kod1, N'|MiddleName=', @Second_name)

    IF @CBC <> ''
        SET @Kod1 = concat(@Kod1, N'|CBC=', @CBC)
    IF @OKTMO <> ''
        SET @Kod1 = concat(@Kod1, N'|OKTMO=', @OKTMO)

    IF dbo.strpos('NAIM', @DB_NAME) > 0
        BEGIN
            --SELECT @UIN = COALESCE(dbo.Fun_GetNumUIN_NAIM(@occ1, @fin_id1), '')
			SELECT @UIN = ''
        END

    IF @UIN <> ''
        SET @Kod1 = concat(@Kod1, N'|UIN=', @UIN)


    --SET @Kod1 = @Kod1 + '|CBC=91111109044040012120|OKTMO=94701000|Purpose=Найм'

    --IF dbo.strpos('KOMP', @DB_NAME) > 0 AND (@tip_id1 = 218) -- УК Спутник
    --    SET @Kod1 = @Kod1 + '|TechCode=01'
    --ELSE
    SET @Kod1 = concat(@Kod1, N'|TechCode=02')

    if @DOP_Params<>''
        SET @Kod1 = concat(@Kod1, N'|', @DOP_Params)

    --SET @Kod1 = @Kod1 + ' |Кол-во символов='+LTRIM(STR(LEN(@Kod1)+17))
    --SET @Kod1 = @Kod1 COLLATE Cyrillic_General_CI_AS		

    --IF @Lang = '1'
        --SET @Kod1 = dbo.ToCodepage1251(@Kod1)
    --IF @Lang = '3'
    --    SET @Kod1 = dbo.ToCodepageKOI8R(@Kod1)


    RETURN @Kod1
END
go

