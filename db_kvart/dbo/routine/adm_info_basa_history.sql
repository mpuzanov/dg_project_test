CREATE   PROCEDURE [dbo].[adm_info_basa_history](
    @fin_id1 SMALLINT = NULL
, @tip_id1 SMALLINT = NULL
)
AS
    --
    --  Процедура обновления общей информации по базе
    --  
    /*
    adm_info_basa_history 151, 137
    adm_info_basa_history 183, null
    adm_info_basa_history 182, 28
    */

    SET NOCOUNT ON

    -- 30 сек ждем блокировку  в этой сесии пользователя
    SET LOCK_TIMEOUT 30000
    IF dbo.Fun_GetRejim() = 'стоп'
        RETURN 0

DECLARE
    @KolLic                  INT
    , @KolBuilds             INT
    , @KolFlats              INT
    , @KolPeople             INT
    , @StrFinPeriod          VARCHAR(15)
    , @SumOplata1            DECIMAL(15, 2) -- сумма к оплате в текущем периоде
    , @SumValue1             DECIMAL(15, 2) -- сумма начислений в текущем периоде
    , @SumLgota1             DECIMAL(15, 2) -- сумма льгот в текущем периоде
    , @SumSubsidia1          DECIMAL(15, 2) = 0 -- сумма субсидий в текущем периоде
    , @SumAdded1             DECIMAL(15, 2) -- сумма разовых в текущем периоде
    , @SumPaymAccount1       DECIMAL(15, 2) -- сумма платежей в текущем периоде
    , @SumPaymAccount_Peny1  DECIMAL(15, 2) -- из них оплачено пени
    , @SumPaymAccountCounter DECIMAL(15, 2) -- оплачено по счетчикам
    , @SumPenalty1           DECIMAL(15, 2) -- сумма пени в текущем периоде
    , @SumSaldo1             DECIMAL(15, 2) -- сумма сальдо в текущем периоде
    , @SumOplataMes1         DECIMAL(15, 2)
    , @SumTotal_SQ           DECIMAL(15, 2) -- Общая площадь
    , @SumDolg               DECIMAL(15, 2) -- сумма долга
    , @SumDebt               DECIMAL(15, 2) -- конечное сальдо
    , @SumPaid_old           DECIMAL(15, 2) -- Начисление предыдущего месяца
    , @ProcentOplata         DECIMAL(15, 4) -- Процент оплаты 
    , @msg                   VARCHAR(100)


DECLARE
    curs CURSOR FOR
        SELECT Id
             , Fin_id
        FROM dbo.OCCUPATION_TYPES 
        WHERE Id = COALESCE(@tip_id1, Id)
          AND Fin_id = COALESCE(@fin_id1, Fin_id)

    OPEN curs
    FETCH NEXT FROM curs INTO @tip_id1, @fin_id1
    WHILE (@@fetch_status = 0)
        BEGIN
            SELECT @StrFinPeriod = dbo.Fun_NameFinPeriod(@fin_id1)

            SELECT @msg = CONCAT('Обработка тип фонда: ', LTRIM(STR(@tip_id1)), ' фин.период:', LTRIM(STR(@fin_id1)))
            RAISERROR (@msg, 10, 1) WITH NOWAIT;

            SELECT @KolBuilds = COALESCE(COUNT(bldn_id), 0)
            FROM dbo.View_BUILD_ALL 
            WHERE tip_id = @tip_id1
              AND Fin_id = @fin_id1

            SELECT @KolLic = COALESCE(COUNT(DISTINCT Occ), 0)
                 , @KolPeople = COALESCE(SUM(COALESCE(o.kol_people, 0)), 0)
                 , @KolFlats = COALESCE(COUNT(DISTINCT o.flat_id), 0)
            FROM dbo.View_OCC_ALL_LITE AS o
            WHERE o.tip_id = @tip_id1
              AND o.STATUS_ID <> 'закр'
              AND o.Fin_id = @fin_id1

            SELECT @SumOplata1 = 0
                 , @SumSaldo1 = 0
                 , @SumPaymAccount1 = 0
                 , @SumPaymAccount_Peny1 = 0
                 , @SumValue1 = 0
                 , @SumAdded1 = 0
                 , @SumPaid_old = 0
                 , @SumOplataMes1 = 0
                 , @SumDolg = 0
                 , @SumPenalty1 = 0
                 , @SumDebt = 0

            --  Находим суммы по поставщикам
            SELECT @SumOplata1 = COALESCE(SUM(COALESCE(os.Whole_payment, 0)), 0)
                 , @SumSaldo1 = COALESCE(SUM(os.SALDO), 0)
                 , @SumPaymAccount1 = COALESCE(SUM(os.PaymAccount), 0)
                 , @SumPaymAccount_Peny1 = COALESCE(SUM(os.PaymAccount_peny), 0)
                 , @SumValue1 = COALESCE(SUM(os.Value), 0)
                 , @SumAdded1 = COALESCE(SUM(os.Added), 0)
                 , @SumPaid_old = COALESCE(SUM(COALESCE(os.Paid_old, 0)), 0)
                 , @SumOplataMes1 = COALESCE(SUM(os.Paid), 0)
                 , @SumDolg = SUM(os.SALDO - (COALESCE(os.PaymAccount, 0) - COALESCE(os.PaymAccount_peny, 0)))
                 , @SumPenalty1 = SUM(COALESCE(os.Penalty_value, 0) + COALESCE(os.Penalty_old_new, 0))
                 , @SumDebt = SUM(COALESCE(os.Debt, 0))
            FROM dbo.View_OCC_ALL_LITE AS o 
            JOIN dbo.VOCC_SUPPLIERS AS os 
                ON o.Occ = os.Occ
                    AND o.Fin_id = os.Fin_id
            WHERE 
				o.tip_id = @tip_id1
				AND o.STATUS_ID <> 'закр'
				AND o.Fin_id = @fin_id1

            SELECT @SumOplata1 = SUM(o.Whole_payment) + COALESCE(@SumOplata1, 0)
                 , @SumSaldo1 = SUM(o.SALDO) + COALESCE(@SumSaldo1, 0)
                 , @SumPaymAccount1 = SUM(o.PaymAccount) + COALESCE(@SumPaymAccount1, 0)
                 , @SumPaymAccount_Peny1 = SUM(o.PaymAccount_peny) + COALESCE(@SumPaymAccount_Peny1, 0)
                 , @SumValue1 = SUM(o.Value) + COALESCE(@SumValue1, 0)
                 , @SumLgota1 = 0
                 , @SumAdded1 = SUM(o.Added) + COALESCE(@SumAdded1, 0)
                 , @SumTotal_SQ = SUM(o.TOTAL_SQ)
                 , @SumPaid_old = SUM(o.Paid_old) + COALESCE(@SumPaid_old, 0)
                 , @SumOplataMes1 = SUM(o.Paid + o.Paid_minus) + COALESCE(@SumOplataMes1, 0)
                 , @SumDolg = SUM(o.SALDO - o.Paymaccount_Serv) + COALESCE(@SumDolg, 0)
                 , @SumPenalty1 = SUM(o.Penalty_value + o.Penalty_old_new) + COALESCE(@SumPenalty1, 0)
                 , @SumDebt = SUM(o.Debt) + COALESCE(@SumDebt, 0)
            FROM dbo.View_occ_all_lite AS o 
            WHERE 
				o.tip_id = @tip_id1
				AND o.STATUS_ID <> 'закр'
				AND o.Fin_id = @fin_id1

            SELECT @ProcentOplata = 0

            SELECT @SumPaymAccountCounter = COALESCE(SUM(cp.PaymAccount), 0)
            FROM dbo.COUNTER_PAYM2 AS cp 
            JOIN dbo.View_OCC_ALL_LITE AS o 
                ON cp.Occ = o.Occ
                    AND cp.Fin_id = o.Fin_id
            WHERE 
				cp.Fin_id = @fin_id1
				AND tip_value = 0
				AND tip_id = @tip_id1
				AND STATUS_ID <> 'закр'

            IF EXISTS(SELECT 1
                      FROM dbo.INFO_BASA 
                      WHERE Fin_id = @fin_id1
                        AND tip_id = @tip_id1)
                BEGIN
                    UPDATE dbo.INFO_BASA
                    SET StrFinId              = @StrFinPeriod
                      , KolLic                = @KolLic
                      , KolBuilds             = @KolBuilds
                      , KolFlats              = @KolFlats
                      , KolPeople             = @KolPeople
                      , SumOplata             = @SumOplata1
                      , SumOplataMes          = @SumOplataMes1
                      , SumValue              = @SumValue1
                      , SumLgota              = @SumLgota1
                      , SumSubsidia           = @SumSubsidia1
                      , SumAdded              = @SumAdded1
                      , SumPaymAccount        = @SumPaymAccount1
                      , SumPaymAccount_peny   = @SumPaymAccount_Peny1
                      , SumPaymAccountCounter = @SumPaymAccountCounter
                      , SumPenalty            = @SumPenalty1
                      , SumSaldo              = @SumSaldo1
                      , SumTotal_SQ           = @SumTotal_SQ
                      , SumDolg               = @SumDolg
                      , ProcentOplata         = @ProcentOplata
                      --,SumDebt				= @SumDebt
                    WHERE Fin_id = @fin_id1
                      AND tip_id = @tip_id1
                END

            ELSE
                BEGIN
                    INSERT INFO_BASA
                    ( Fin_id
                    , tip_id
                    , StrFinId
                    , KolLic
                    , KolBuilds
                    , KolFlats
                    , KolPeople
                    , SumOplata
                    , SumOplataMes
                    , SumValue
                    , SumLgota
                    , SumSubsidia
                    , SumAdded
                    , SumPaymAccount
                    , SumPaymAccount_peny
                    , SumPaymAccountCounter
                    , SumPenalty
                    , SumSaldo
                    , SumTotal_SQ
                    , SumDolg
                    , ProcentOplata
                        --,SumDebt
                    )
                    VALUES ( @fin_id1
                           , @tip_id1
                           , @StrFinPeriod
                           , @KolLic
                           , @KolBuilds
                           , @KolFlats
                           , @KolPeople
                           , @SumOplata1
                           , @SumOplataMes1
                           , @SumValue1
                           , @SumLgota1
                           , @SumSubsidia1
                           , @SumAdded1
                           , @SumPaymAccount1
                           , @SumPaymAccount_Peny1
                           , @SumPaymAccountCounter
                           , @SumPenalty1
                           , @SumSaldo1
                           , @SumTotal_SQ
                           , @SumDolg
                           , @ProcentOplata
                               --,@SumDebt
                           )
                END

            FETCH NEXT FROM curs INTO @tip_id1, @fin_id1
        END
    CLOSE curs
    DEALLOCATE curs
go

