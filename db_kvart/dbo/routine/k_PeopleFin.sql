CREATE   PROCEDURE [dbo].[k_PeopleFin](@occ1 INT,
                                     @fin_id1 SMALLINT,
                                     @paym1 SMALLINT = 0)
AS
BEGIN
    --
    -- Выдаем информацию по людям зарегистрированным в заданном фин.периоде
    -- для других хранимых процедур
    --
    -- Если paym1=0 то выдаем информацию по людям с учетом изменений
    -- Если paym1=1 то выдаем информацию по людям которые использовались 
    -- в начислених в файле PEOPLE_HISTORY
    --
    /*
declare @occ1 INT= 33001, @fin_id1 SMALLINT = 244
drop table if exists #p1
create table #p1(fin_id smallint, occ int, owner_id  int, people_uid  UNIQUEIDENTIFIER, lgota_id smallint, 
    status_id tinyint, status2_id VARCHAR(10) COLLATE database_default, birthdate  smalldatetime, doxod decimal(9,2),
    KolDayLgota  tinyint, data1 smalldatetime,  data2 smalldatetime, kolday tinyint, DateEnd SMALLDATETIME)
insert into #p1 
exec k_PeopleFin @occ1, @fin_id1, 0
   
  */

    SET NOCOUNT ON
    SET LOCK_TIMEOUT 5000

    DECLARE @CurrentFin_id SMALLINT = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)
           ,@CurDate DATETIME = CURRENT_TIMESTAMP

	IF @paym1 IS NULL 
		SET @paym1=0

    DECLARE @TablePeopleFin TABLE
                            (
                                fin_id      SMALLINT,
                                occ         INT,
                                owner_id    INT              NOT NULL,
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
								DateEnd     SMALLDATETIME DEFAULT NULL
                            )

    IF (@paym1 = 1)
        AND (@fin_id1 < @CurrentFin_id)
        BEGIN
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

            SELECT ph.fin_id
                 , ph.occ
                 , ph.owner_id
                 , p.people_uid
                 , ph.lgota_id
                 , ph.status_id
                 , ph.status2_id
                 , p.birthdate
                 , 0
                 , KolDayLgota
                 , ph.data1
                 , ph.data2
                 , ph.kol_day
				 , ph.DateEnd
            FROM dbo.people AS p 
            JOIN dbo.people_history AS ph ON 
				p.id = ph.owner_id
            WHERE ph.occ = @occ1
              AND ph.fin_id = @fin_id1

        END
    ELSE
        BEGIN
            --if not exists(select owner_id from @TablePeopleFin)
            DECLARE @start_date SMALLDATETIME
                ,@end_date SMALLDATETIME
            SELECT @start_date = start_date
                 , @end_date = end_date
            FROM global_values 
            WHERE fin_id = @fin_id1

            DECLARE @TableVar TABLE
                              (
                                  owner_id    INT PRIMARY KEY,
                                  people_uid  UNIQUEIDENTIFIER,
                                  dateReg     SMALLDATETIME,
                                  DateDel     SMALLDATETIME,
                                  DateEnd     SMALLDATETIME,
                                  lgota_id    SMALLINT,
                                  status_id   TINYINT,
                                  status2_id  VARCHAR(10) COLLATE database_default,
                                  birthdate   SMALLDATETIME,
                                  doxod       DECIMAL(9, 2),
                                  KolDayLgota TINYINT,
                                  KolDay      TINYINT,
                                  dsc_start   SMALLDATETIME,
                                  dsc_end     SMALLDATETIME,
                                  lgota_kod   INT
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
            FROM dbo.people AS p 
            WHERE p.occ = @occ1
              AND (dateDel >= @start_date
                OR DateDel IS NULL)
              AND (DateReg <= @end_date
                OR DateReg IS NULL)


            UPDATE @TableVar
            SET dateReg = @start_date
            WHERE dateReg IS NULL
               OR DateReg < @start_date

            UPDATE @TableVar
            SET dateDel = @end_date
            WHERE dateDel IS NULL
               OR dateDel > @end_date

            UPDATE @TableVar
            SET dateDel = DateEnd
            WHERE DateEnd IS NOT NULL
              AND DateEnd < dateDel --@end_date   -- 07/09/2010
              AND (status2_id = N'врем'
                OR status2_id = '1016')

            --select * from @TableVar

            UPDATE @TableVar
            SET KolDay = DATEDIFF(DAY, dateReg, DateDel) + 1
            WHERE dateReg <= DateDel


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
                 , dateDel
                 , KolDay
				 , DateEnd
            FROM @TableVar

            --select * from @TableVar 

        END -- not exists(select owner_id from @TablePeopleFin)

        SELECT *
        FROM @TablePeopleFin


    END
go

