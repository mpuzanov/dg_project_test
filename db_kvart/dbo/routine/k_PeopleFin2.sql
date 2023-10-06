CREATE   PROCEDURE [dbo].[k_PeopleFin2](
    @occ1 INT
, @fin_id1 SMALLINT
, @data1 DATETIME = NULL
, @data2 DATETIME = NULL
, @paym1 SMALLINT = 0
)
AS
BEGIN
    --
    -- Выдаем информацию по людям зарегистрированным в заданном фин.периоде
    -- для других хранимых процедур
    --
    -- Если paym1=0 то выдаем информацию по людям с учетом изменений
    -- Если paym1=1 то выдаем информацию по людям которые использовались
    -- в начислених в файле PEOPLE_HISTORY
    /*
	declare @occ1 INT= 33001, @fin_id1 SMALLINT = 244
	drop table if exists #p1
    create table #p1(fin_id smallint, occ int, owner_id  int, people_uid  UNIQUEIDENTIFIER, lgota_id smallint,
      status_id tinyint, status2_id VARCHAR(10) COLLATE database_default, birthdate  smalldatetime, doxod decimal(9,2),
      kolDayLgota  tinyint, data1 smalldatetime,  data2 smalldatetime, kolday tinyint, DateEnd SMALLDATETIME)
    insert into #p1 exec k_PeopleFin2 @occ1,@fin_id1

    */

    SET NOCOUNT ON
    SET LOCK_TIMEOUT 5000

    DECLARE @CurrentFin_id SMALLINT
    SELECT @CurrentFin_id = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

    DECLARE @start_date SMALLDATETIME
        ,@end_date SMALLDATETIME
    SELECT @start_date = start_date
         , @end_date = end_date
    FROM Global_values 
    WHERE fin_id = @fin_id1

    IF (@data1 IS NULL)
        OR (@data1 > @end_date)
        SET @data1 = @start_date
    IF (@data2 IS NULL)
        OR (@data2 < @data1)
        SET @data2 = @end_date

    DECLARE @TablePeopleFin TABLE
                            (
                                fin_id      SMALLINT,
                                occ         INT,
                                owner_id    INT,
                                people_uid  UNIQUEIDENTIFIER NOT NULL,
                                lgota_id    SMALLINT,
                                status_id   TINYINT,
                                status2_id  VARCHAR(10) COLLATE database_default,
                                birthdate   SMALLDATETIME,
                                doxod       DECIMAL(9, 2),
                                KolDayLgota TINYINT,
                                data1       SMALLDATETIME,
                                data2       SMALLDATETIME,
                                KolDay      TINYINT,
								DateEnd SMALLDATETIME DEFAULT NULL
                            )

    IF (@paym1 = 1)
        AND (@fin_id1 < @CurrentFin_id)
        BEGIN
            --  print '@paym1=1'
            INSERT INTO @TablePeopleFin ( fin_id
                                        , occ
                                        , owner_id
                                        , people_uid
                                        , lgota_id
                                        , status_id
                                        , status2_id
                                        , birthdate
                                        , doxod
                                        , KolDayLgota
                                        , data1
                                        , data2
                                        , KolDay
										, DateEnd)

            SELECT fin_id
                 , ph.occ
                 , owner_id
                 , p.people_uid
                 , ph.lgota_id
                 , ph.status_id
                 , ph.status2_id
                 , p.birthdate
                 , 0
                 , KolDayLgota
                 , data1
                 , data2
                 , kol_day
				 , ph.DateEnd
            FROM dbo.people AS p 
            JOIN dbo.people_history AS ph ON 
				p.id = ph.owner_id
            WHERE ph.occ = @occ1
              AND ph.fin_id = @fin_id1

            IF EXISTS(SELECT 1
                      FROM @TablePeopleFin)
                AND (@data1 <= @data2)
                BEGIN
                    UPDATE @TablePeopleFin
                    SET KolDay      = 0
                      , KolDayLgota = 0

                    UPDATE @TablePeopleFin
                    SET data1 = @data1
                    WHERE @data1 BETWEEN data1 AND data2

                    UPDATE @TablePeopleFin
                    SET data2 = @data2
                    WHERE @data2 BETWEEN data1 AND data2

                    UPDATE @TablePeopleFin
                    SET KolDay = DATEDIFF(DAY, data1, data2) + 1
                    WHERE data1 <= data2
                      AND ((@data1 BETWEEN data1 AND data2)
                        OR (@data2 BETWEEN data1 AND data2))

                    UPDATE @TablePeopleFin
                    SET KolDayLgota = KolDay
                    WHERE lgota_id > 0

                END -- if exists(select owner_id from @TablePeopleFin)

        END --if @paym1=1
    ELSE

        BEGIN
            --if @paym1=0
            --print '@paym1=0'
            DECLARE @TableVar TABLE
                              (
                                  owner_id    INT PRIMARY KEY,
                                  people_uid  UNIQUEIDENTIFIER,
                                  dateReg     SMALLDATETIME,
                                  DateDel     SMALLDATETIME,
                                  DateEnd     SMALLDATETIME,
                                  lgota_id    SMALLINT DEFAULT 0,
                                  status_id   TINYINT,
                                  status2_id  VARCHAR(10) COLLATE database_default,
                                  birthdate   SMALLDATETIME,
                                  doxod       DECIMAL(9, 2),
                                  KolDayLgota TINYINT       DEFAULT 0,
                                  KolDay      TINYINT,
                                  dsc_start   SMALLDATETIME DEFAULT NULL,
                                  dsc_end     SMALLDATETIME DEFAULT NULL,
                                  lgota_kod   INT           DEFAULT NULL
                              )

            INSERT INTO @TableVar
            SELECT p.id as owner_id
                 , people_uid
                 , dateReg
                 , DateDel
                 , DateEnd
                 , lgota_id
                 , status_id
                 , status2_id
                 , birthdate
                 , doxod
                 , 0    as KolDayLgota
                 , 0    as KolDay
                 , NULL as dsc_start
                 , NULL as dsc_end
                 , lgota_kod
            FROM dbo.People AS p 
            WHERE p.occ = @occ1
              AND (DateDel >= @start_date
                OR DateDel IS NULL)
              AND (dateReg <= @end_date
                OR dateReg IS NULL)

            IF (@data1 > @start_date)
                SET @start_date = @data1
            IF (@data2 < @end_date)
                SET @end_date = @data2

            UPDATE @TableVar
            SET dateReg =
                CASE
                    WHEN dateReg IS NULL OR
                         dateReg < @start_date THEN @start_date
                    ELSE dateReg
                    END
              , DateDel =
                CASE
                    WHEN DateDel IS NULL OR
                         DateDel > @end_date THEN @end_date
                    ELSE DateDel
                    END


            UPDATE @TableVar
            SET DateDel = DateEnd
            WHERE DateEnd IS NOT NULL
              AND DateEnd < @end_date
              AND (status2_id = N'врем'
                OR status2_id = '1016')


            UPDATE @TableVar
            SET KolDay = DATEDIFF(DAY, dateReg, DateDel) + 1
            WHERE dateReg <= DateDel

            INSERT INTO @TablePeopleFin
            SELECT @fin_id1
                 , @occ1
                 , owner_id
                 , people_uid
                 , lgota_id
                 , status_id
                 , status2_id
                 , birthdate
                 , doxod
                 , KolDayLgota
                 , dateReg
                 , DateDel
                 , KolDay
				 , DateEnd
            FROM @TableVar

        END -- not exists(select owner_id from @TablePeopleFin)

    SELECT *
    FROM @TablePeopleFin

END
go

