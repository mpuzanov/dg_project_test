CREATE   PROCEDURE [dbo].[adm_create_dolg2](
    @debt1 BIT = 1 -- выдаем дебет иначе сальдо
	, @fin_id1 SMALLINT = NULL
	, @tip_str VARCHAR(2000) = ''
	, @only_dolg SMALLINT = 0 -- 0 - все, 1 - только долги, 2 - только переплата, 3-переплату=0 
	, @sup_id SMALLINT = NULL
	, @is_pu_out BIT = 0 -- выдавать показания ПУ
	, @is_commission_uk BIT = NULL  -- Банковская комиссия по дому
)
AS
    /*
    Формирование файла по долгам на лицевых для банков
    
    adm_create_dolg2 0,211,'28',0,323,0
    adm_create_dolg2 1,171,'28',0,323,1
    adm_create_dolg2 0,171,'28',0,null
    
    */
    SET NOCOUNT ON

    IF @only_dolg IS NULL
        SET @only_dolg = 0;
       
    IF @is_pu_out IS NULL
        SET @is_pu_out = 0;
       
    IF @fin_id1 IS NULL
        SELECT @fin_id1 = fin_id
        FROM dbo.Global_values
        WHERE closed = 0;
       
    IF @sup_id = 0
        SET @sup_id = NULL

	DECLARE
		@StrMes       VARCHAR(15)
		, @start_date SMALLDATETIME
		, @end_date   SMALLDATETIME
		, @DB_NAME    VARCHAR(20) = UPPER(DB_NAME())

    IF @debt1 = 1
        BEGIN
            -- берём текущий период
            SELECT @StrMes = STRMES
                 , @start_date = START_DATE
                 , @end_date = END_DATE
            FROM dbo.Global_values
            WHERE fin_id = @fin_id1;
        END
    ELSE
        BEGIN
            -- берём прошлый период
            SELECT @StrMes = STRMES
                 , @start_date = START_DATE
                 , @end_date = END_DATE
            FROM dbo.Global_values
            WHERE fin_id = @fin_id1 - 1;
        END


	DECLARE @tip TABLE(tip_id   INT PRIMARY KEY, tip_name VARCHAR(50) COLLATE database_default)
	INSERT INTO @tip (tip_id)
	SELECT *
	FROM STRING_SPLIT(@tip_str, ',')
	WHERE RTRIM(value) <> ''

    CREATE TABLE #t1
    (
        OCC                 INT PRIMARY KEY,
        SUM_DOLG            DECIMAL(15, 2),
        TOWN_NAME           VARCHAR(50) COLLATE database_default,
        STREETS             VARCHAR(60) COLLATE database_default,
        NOM_DOM             VARCHAR(12) COLLATE database_default,
        NOM_KVR             VARCHAR(20) COLLATE database_default,
        tip_id              SMALLINT,
        STRMES              VARCHAR(15) COLLATE database_default,
        PROPTYPE_ID         VARCHAR(10) COLLATE database_default,
        BANK                VARCHAR(50) COLLATE database_default  DEFAULT NULL,
        [START_DATE]        SMALLDATETIME,
        END_DATE            SMALLDATETIME,
        OCC1                INT           DEFAULT NULL,
        RASSCHT             VARCHAR(20) COLLATE database_default  DEFAULT NULL,
        DOG_INT             INT           DEFAULT NULL,
        NAME_str1           VARCHAR(100) COLLATE database_default  DEFAULT NULL,
        tip_name            VARCHAR(50) COLLATE database_default  DEFAULT NULL,
        ID_BARCODE          VARCHAR(50) COLLATE database_default  DEFAULT '',
        FIO                 VARCHAR(120) COLLATE database_default  DEFAULT '',
        FORMAT_OUT_ID       SMALLINT DEFAULT 0,
        --[ADDRESS]           AS (TOWN_NAME + ', ' + STREETS + ', д. ' + NOM_DOM + ', кв. ' + NOM_KVR)
        [ADDRESS]	  AS CAST(CONCAT(TOWN_NAME,', ',STREETS,', ',NOM_DOM,', ',NOM_KVR) AS VARCHAR(200))
        ,
        INN                 VARCHAR(12) COLLATE database_default  DEFAULT NULL,
        bank_file_out       VARCHAR(30) COLLATE database_default  DEFAULT NULL,
        INN_TIP             VARCHAR(12) COLLATE database_default  DEFAULT NULL,
        CBC                 VARCHAR(20) COLLATE database_default  DEFAULT NULL,
        OKTMO               VARCHAR(11) COLLATE database_default  DEFAULT NULL,
        TOTAL_SQ            DECIMAL(10, 4) DEFAULT NULL,
        PU_STR              VARCHAR(2000) COLLATE database_default DEFAULT NULL,
        BUILD               AS NOM_DOM,
        KVR                 AS NOM_KVR,
        ELS                 VARCHAR(10) COLLATE database_default  DEFAULT NULL,
        FIAS                VARCHAR(56) COLLATE database_default  DEFAULT NULL, -- kod_fias + ,nom_kvr
        UIN                 VARCHAR(25) COLLATE database_default  DEFAULT NULL,
        Bank_commission_num varchar(2)  COLLATE database_default  default ''
    )
    --CREATE INDEX Idx1 ON #t1(OCC1);

    IF @sup_id IS NOT NULL
        BEGIN
            INSERT INTO #t1 ( OCC
                            , SUM_DOLG
                            , TOWN_NAME
                            , STREETS
                            , NOM_DOM
                            , NOM_KVR
                            , tip_id
                            , STRMES
                            , PROPTYPE_ID
                            , [START_DATE]
                            , END_DATE
                            , OCC1
                            , DOG_INT
                            , tip_name
                            , FIO
                            , FORMAT_OUT_ID
                            , bank_file_out
                            , INN_TIP
                            , TOTAL_SQ
                            , PU_STR
                            , ELS
                            , FIAS)
            SELECT os.occ_sup AS occ
                 ,       CASE
                             WHEN @debt1 = 1 THEN os.Debt + os.Penalty_old_new + os.penalty_value
                             ELSE os.saldo + os.Penalty_old
                             END      AS SUM_DOLG
                 ,       t.name       AS TOWN_NAME
                 ,       s.short_name AS STREETS
                 ,       b.NOM_DOM    AS NOM_DOM
                 ,       o.NOM_KVR    AS NOM_KVR
                 ,       o.tip_id
                 ,       @StrMes      AS StrMes
                 ,       PROPTYPE_ID
                 ,       @start_date  AS [START_DATE]
                 ,       @end_date
                 ,       o.occ
                 ,       os.DOG_INT
                 ,       o.tip_name
                 ,       CONCAT(RTRIM(p.Last_name), ' ', RTRIM(p.First_name), ' ', RTRIM(p.Second_name)) AS FIO
                 ,       ot.bank_format_out
                 ,       ot.bank_file_out
                 ,       ot.INN
                 ,       o.TOTAL_SQ
                 ,       CASE
                             WHEN @is_pu_out = 0 THEN ''
                             WHEN @debt1 = 1 THEN dbo.Fun_GetCounterValue_sber(o.fin_id, o.occ, @sup_id, 0, 1)
                             ELSE dbo.Fun_GetCounterValue_sber(o.fin_id - 1, o.occ, @sup_id, 0, 1)
                             END      AS PU_STR
                 ,       o.id_els_gis
                 ,       CASE
                             WHEN b.build_type = 4 THEN b.kod_fias -- жилой дом (без № квартиры)
                             ELSE concat(b.kod_fias , ',' , o.NOM_KVR)
                             END  AS FIAS
            FROM dbo.View_occ_all_lite AS o 
                JOIN dbo.Buildings AS b ON 
					o.bldn_id = b.Id
                JOIN dbo.VStreets AS s ON 
					b.street_id = s.Id
                JOIN dbo.Occ_Suppliers AS os ON 
					o.occ = os.occ  
					AND o.fin_id = os.fin_id
                JOIN dbo.Towns AS t ON 
					b.town_id = t.Id
                JOIN dbo.Occupation_Types ot ON 
					b.tip_id = ot.Id
                JOIN @tip AS tip ON 
					tip.tip_id = o.tip_id
                LEFT JOIN dbo.Intprint AS i ON 
					o.occ = i.occ 
					AND o.fin_id = i.fin_id
                LEFT JOIN dbo.People p ON 
					i.Initials_owner_id = p.Id
            WHERE 
				o.fin_id = @fin_id1
				AND o.status_id <> N'закр'
				AND b.blocked_house = CAST(0 AS BIT)
				AND os.fin_id = @fin_id1
				AND os.sup_id = @sup_id
				AND os.occ_sup <> 0
        END
    ELSE
        BEGIN
            INSERT INTO #t1 ( OCC
                            , SUM_DOLG
                            , TOWN_NAME
                            , STREETS
 							, NOM_DOM
                            , NOM_KVR
                            , tip_id
                            , STRMES
                            , PROPTYPE_ID
                            , [START_DATE]
                            , END_DATE
                            , OCC1
                            , tip_name
                            , FIO
                            , FORMAT_OUT_ID
                            , bank_file_out
                            , INN_TIP
                            , TOTAL_SQ
                            , PU_STR
                            , ELS
                            , FIAS
                            , Bank_commission_num)
            SELECT dbo.Fun_GetFalseOccOut(o.occ, o.tip_id) AS occ
                 , CASE
                       WHEN @debt1 = 1 THEN o.Debt + o.Penalty_old_new + o.penalty_value
                       ELSE o.saldo + o.Penalty_old
                END                                        AS SUM_DOLG
                 , t.name                                  AS TOWN_NAME
                 , s.short_name                            AS STREETS
                 , b.NOM_DOM                               AS NOM_DOM
                 , o.NOM_KVR                               AS NOM_KVR
                 , o.tip_id
                 , @StrMes                                 AS StrMes
                 , PROPTYPE_ID
                 , @start_date                             AS [START_DATE]
                 , @end_date
                 , o.occ
                 , o.tip_name
                 , CONCAT(RTRIM(p.Last_name), ' ', RTRIM(p.First_name), ' ', RTRIM(p.Second_name)) AS FIO
                 , ot.bank_format_out
                 , ot.bank_file_out
                 , ot.INN
                 , o.TOTAL_SQ
                 , CASE
                       WHEN @is_pu_out = 0 THEN ''
                       WHEN @debt1 = 1 THEN dbo.Fun_GetCounterValue_sber(o.fin_id, o.occ, @sup_id, 0, 1)
                       ELSE dbo.Fun_GetCounterValue_sber(o.fin_id - 1, o.occ, @sup_id, 0, 1)
                END                                        AS PU_STR
                 , o.id_els_gis
                 , CASE
                       WHEN b.build_type = 4 THEN b.kod_fias -- жилой дом (без № квартиры)
                       ELSE concat(b.kod_fias , ',' , o.NOM_KVR)
                END                                        AS FIAS
                 , dbo.Fun_GetPosStringSplit(ot.commission_bank_code, ',', CASE
                                                                               WHEN b.is_commission_uk = 0 THEN 1
                                                                               ELSE 2
                END)
            FROM dbo.View_occ_all_lite AS o 
                JOIN dbo.Buildings AS b ON 
					o.bldn_id = b.Id
                JOIN dbo.VStreets AS s ON 
					b.street_id = s.Id
                JOIN dbo.Towns AS t ON 
					b.town_id = t.Id
                JOIN dbo.Occupation_Types ot ON 
					b.tip_id = ot.Id
                JOIN @tip AS tip ON 
					tip.tip_id = o.tip_id
                LEFT JOIN dbo.Intprint AS i ON 
					o.occ = i.occ AND 
					o.fin_id = i.fin_id
                LEFT JOIN dbo.People p ON 
					i.Initials_owner_id = p.Id
            WHERE 
				o.fin_id = @fin_id1
				AND o.status_id <> N'закр'
				AND b.blocked_house = CAST(0 AS BIT)
				AND (@is_commission_uk is null OR b.is_commission_uk = @is_commission_uk)

        END

    IF dbo.strpos('NAIM', @DB_NAME) > 0
        BEGIN
            -- удаляем приватизированные квартиры с переплатой
            DELETE
            FROM #t1
            WHERE PROPTYPE_ID <> N'непр'
              AND SUM_DOLG <= 0

            IF @debt1 = 1
                UPDATE t
                SET UIN = COALESCE(dbo.Fun_GetNumUIN_NAIM(OCC, @fin_id1), '')
                FROM #t1 AS t
            ELSE
                UPDATE t
                SET UIN = COALESCE(dbo.Fun_GetNumUIN_NAIM(OCC, @fin_id1 - 1), '')
         FROM #t1 AS t

        END

DELETE
FROM #t1
WHERE TOTAL_SQ = 0
  AND SUM_DOLG <= 0

DECLARE @t myTypeTableOcc

INSERT INTO @t (OCC)
SELECT OCC1
FROM #t1
    IF @sup_id IS NULL
        UPDATE t
        SET BANK       = ban.BANK
          , RASSCHT    = ban.rasschet
          , NAME_str1  = ban.NAME_str1
          , ID_BARCODE = ban.ID_BARCODE
          , INN        = ban.INN
          , CBC        = ban.CBC
          , OKTMO      = ban.OKTMO
        FROM #t1 AS t
            JOIN dbo.Fun_GetAccount_ORG_Table(@t) AS ban ON 
				t.OCC1 = ban.OCC;
    ELSE
        UPDATE t
        SET BANK       = ao.BANK
          , RASSCHT    = ao.rasschet
          , NAME_str1  = ao.NAME_str1
          , ID_BARCODE = ao.ID_BARCODE
          , INN        = ao.INN
          , CBC        = ao.CBC
          , OKTMO      = ao.OKTMO
        FROM #t1 AS t
                 JOIN dbo.Dog_sup AS dg ON 
					t.DOG_INT = dg.Id
                 JOIN dbo.Account_org AS ao ON 
					dg.bank_account = ao.Id;
    
IF @only_dolg = 3
    UPDATE #t1
    SET SUM_DOLG = 0
    WHERE SUM_DOLG < 0

SELECT *
FROM #t1
WHERE (@only_dolg IN (0, 3))
   OR (@only_dolg = 1 AND SUM_DOLG > 0) -- 1 - только долги
   OR (@only_dolg = 2 AND SUM_DOLG < 0) -- 2 - только переплата
ORDER BY tip_id
	   , ID_BARCODE
       , NAME_str1
       , RASSCHT
       , Bank_commission_num
       , OCC
go

