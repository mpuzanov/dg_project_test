CREATE   PROCEDURE [dbo].[adm_Copy_occ_build2](
  @build1 INT
, @build2 INT
, @debug BIT = 0
, @is_counter BIT = 1-- перенос счётчиков
)
AS
/*

Процедура создает новые лицевые счета в доме с кодом @build2
на основе лицевых из дома @build1
и копирует туда людей, режимы

автор: Пузанов
21.03.2012

*/
SET NOCOUNT ON
SET XACT_ABORT ON

DECLARE
    @fin_id1          SMALLINT
	, @fin_id_new     SMALLINT
    , @err_str        VARCHAR(400)
    , @occ1           INT
    , @occ_new        INT
    , @flat_id1       INT
    , @nom_kvr1       VARCHAR(20)
    , @counter_id1    INT
    , @counter_id_new INT

DECLARE
    @tip_id1      SMALLINT
    , @jeu1       SMALLINT
    , @schtl1     INT
    , @people_new INT
    , @people_id  INT
    , @CountOcc   INT = 0
    , @rang_max   INT = 0
    , @tip_name   VARCHAR(50)
    , @pred_value DECIMAL(10, 4)
    , @pred_date  SMALLDATETIME
    , @people_uid UNIQUEIDENTIFIER
    
IF @build1 = @build2
    BEGIN
        RAISERROR (N'Дома должны быть разные!', 16, 1)
    END

IF @is_counter IS NULL
    SET @is_counter = 1

SELECT @fin_id1 = dbo.Fun_GetFinCurrent(NULL, @build2, NULL, NULL)

SELECT @tip_id1 = tip_id
     , @tip_name = tip_name
	 , @fin_id_new = vb.fin_current
FROM dbo.View_buildings AS vb
WHERE id = @build2

    -- перенесём в новый дом технические характеристики старого(это тот же дом только в другой УК)
UPDATE b2
SET levels          = CASE
                          WHEN COALESCE(b2.levels, 0) = 0 THEN b1.levels
                          ELSE b2.levels
    END
  , godp            = CASE
                          WHEN COALESCE(b2.godp, 0) = 0 THEN b1.godp
                          ELSE b2.godp
    END
  , seria           = CASE
                          WHEN COALESCE(b2.seria, '') = '' THEN b1.seria
                          ELSE b2.seria
    END
  , kol_sekcia      = CASE
                          WHEN COALESCE(b2.kol_sekcia, 0) = 0 THEN b1.kol_sekcia
                          ELSE b2.kol_sekcia
    END
  , kol_musor       = CASE
                          WHEN COALESCE(b2.kol_musor, 0) = 0 THEN b1.kol_musor
                          ELSE b2.kol_musor
    END
  , kod_fias        = CASE
                          WHEN COALESCE(b2.kod_fias, '') = '' THEN b1.kod_fias
                          ELSE b2.kod_fias
    END
  , CadastralNumber = CASE
                          WHEN COALESCE(b2.CadastralNumber, '') = '' THEN b1.CadastralNumber
                          ELSE b2.CadastralNumber
    END
FROM dbo.Buildings b1
         CROSS JOIN dbo.Buildings b2
WHERE b1.id = @build1
  AND b2.id = @build2


DECLARE @t TABLE
(
    occ      INT, -- PRIMARY KEY,           
    build1   INT,
    build2   INT,
    nom_kvr  VARCHAR(20),
    tip_id   SMALLINT,
    jeu      SMALLINT,
    schtl    INT,
    flat_id  INT,
    occ_new  INT DEFAULT 0,
    flat_new INT DEFAULT 0
)

DECLARE @t_id TABLE
(
    id      INT,
    flat_id INT default  NULL,
    uid UNIQUEIDENTIFIER default  NULL
)

INSERT INTO @t ( occ
               , build1
               , build2
               , nom_kvr
               , tip_id
               , jeu
               , schtl
               , flat_id)
SELECT o.occ
     , @build1
     , @build2
     , f.nom_kvr
     , @tip_id1
     , o.jeu
     , o.schtl
     , o.flat_id
FROM dbo.Occupations AS o
         JOIN dbo.Flats AS f ON 
			o.flat_id = f.id
WHERE o.Status_id <> 'закр'
  AND f.bldn_id = @build1
ORDER BY f.nom_kvr_sort;

SELECT @CountOcc = COUNT(occ) FROM @t;

IF @CountOcc = 0
	RETURN -- лицевых для копирования нет

-- проверяем хватит ли диапазона для создания лицевых
EXEC dbo.k_occ_new @tip_id1
    , @occ_new = 0
    , @rang_max = @rang_max OUTPUT

IF @CountOcc > @rang_max
BEGIN
    RAISERROR (N'Не хватает диапазона в типе фонда %s для создания лицевых счетов. Нужно %i, а свободно %i', 16, 1, @tip_name, @CountOcc, @rang_max)
END
    -- *********************************************************

RAISERROR (N'добавляем режимы по дому', 10, 1) WITH NOWAIT;

DELETE FROM dbo.Build_mode WHERE build_id = @build2
INSERT INTO dbo.Build_mode ( build_id
                           , service_id
                           , mode_id)
SELECT @build2
     , service_id
     , mode_id
FROM dbo.Build_mode
WHERE build_id = @build1

-- *********************************************************
RAISERROR (N'добавляем поставщиков по дому', 10, 1) WITH NOWAIT;

DELETE FROM dbo.Build_source WHERE build_id = @build2;

INSERT INTO dbo.Build_source ( build_id
                             , service_id
                             , source_id)
SELECT @build2
     , service_id
     , source_id
FROM dbo.Build_source
WHERE build_id = @build1;

DECLARE
    curs_1 CURSOR LOCAL FOR
        SELECT occ
             , nom_kvr
             , tip_id
             , jeu
             , schtl
        FROM @t
    OPEN curs_1
    FETCH NEXT FROM curs_1 INTO @occ1, @nom_kvr1, @tip_id1, @jeu1, @schtl1
    WHILE (@@fetch_status = 0)
        BEGIN
            --PRINT 'Лиц: '+STR(@occ1) +'  Кв:'+@nom_kvr1 
            -- создаем квартиру   
            SET @flat_id1 = NULL

            -- ищем есть ли квартира с заданным номером уже в новом доме 
            SELECT TOP 1 @flat_id1 = f.id
            FROM dbo.Flats AS f
            WHERE f.nom_kvr = @nom_kvr1
              AND f.bldn_id = @build2

            -- если нет, то создаем квартиру
            IF @flat_id1 IS NULL
                BEGIN
                    INSERT INTO Flats ( bldn_id
                                      , nom_kvr
                                      , floor
                                      , approach
                                      , telephon
                                      , nom_kvr_sort
                                      , is_flat
                                      , is_unpopulated
                                      , area)
                    SELECT @build2
                         , f.nom_kvr
                         , f.floor
                         , f.approach
                         , f.telephon
                         , f.nom_kvr_sort
                         , f.is_flat
                         , f.is_unpopulated
                         , f.area
                    FROM dbo.Occupations AS o
                             JOIN dbo.Flats AS f ON 
								o.flat_id = f.id
                    WHERE o.occ = @occ1
                      AND f.bldn_id = @build1

                    SELECT @flat_id1 = cast(SCOPE_IDENTITY() as int)

                END
            --if @flat_id1 is NULL

            --PRINT 'Код Кв.: '+STR(@flat_id1)

            SET @occ_new = NULL
            SELECT @occ_new = occ
            FROM Occupations
            WHERE flat_id = @flat_id1
              AND (COALESCE(schtl, @occ1) = @occ1 OR schtl = 0) -- ввода по коммуналкам

            IF @occ_new IS NULL
                BEGIN
                    BEGIN TRAN

                        -- Создаем единый код лицевого счета     
                        --EXEC @occ_new = dbo.k_occ_new @tip_id1
                        EXEC dbo.k_occ_new @tip_id1
                            , @occ_new = @occ_new OUTPUT
                            , @rang_max = @rang_max OUTPUT

                        IF (@occ_new IS NULL)
                            OR @occ_new = 0
                            BEGIN
                                ROLLBACK TRAN
                                SET @err_str = N'Не удалось создать лицевой счёт! в типе фонда: %s.'
                                RAISERROR (@err_str, 16, 1, @tip_name)
                            END

                        PRINT N'Нов. Лиц.: ' + STR(@occ_new)

                        INSERT INTO [dbo].[Occupations] ( [occ]
														, fin_id
                                                        , [jeu]
                                                        , [schtl]
                                                        , [flat_id]
                                                        , [tip_id]
                                                        , [roomtype_id]
                                                        , [proptype_id]
                                                        , [Status_id]
                                                        , [living_sq]
                                                        , [Total_sq]
                                                        , [teplo_sq]
                                                        , [norma_sq]
                                                        , [socnaim]
                                                        , [SALDO]
                                                        , [saldo_serv]
                                                        , [saldo_edit]
                                                        , [value]
                                                        , [Discount]
                                                        , [Compens]
                                                        , [Compens_ext]
                                                        , [Added]
                                                        , [Added_ext]
                                                        , [PaymAccount]
                                                        , [PaymAccount_peny]
                                                        , [Paid]
                                                        , [Paid_minus]
                                                        , [Paid_old]
                                                        , [Penalty_calc]
                                                        , [Penalty_value]
                                                        , [Penalty_old_new]
                                                        , [Penalty_old]
                                                        , [Penalty_old_edit]
                                                        , [address]
                                                        , [Data_rascheta]
                                                        , [comments]
                                                        , [comments2]
                                                        , Rooms
                                                        , telephon
														, schtl_old)
                        SELECT @occ_new
							 , @fin_id_new
                             , @jeu1
                             , @occ1 -- сохраняем лицевой от куда создан
                             , @flat_id1
                             , @tip_id1
                             , [roomtype_id]
                             , [proptype_id]
                             , [Status_id]
                             , [living_sq]
                             , [Total_sq]
                             , [teplo_sq]
                             , [norma_sq]
                             , [socnaim]
                             , [SALDO]
                             , [saldo_serv]
                             , [saldo_edit]
                             , [value]
                             , [Discount]
                             , [Compens]
                             , [Compens_ext]
                             , [Added]
                             , [Added_ext]
                             , 0
                             , 0
                             , [Paid]
                             , [Paid_minus]
                             , [Paid_old]
                             , [Penalty_calc]
                             , 0
                             , 0
                             , 0
                             , [Penalty_old_edit]
                             , [address]
                             , [Data_rascheta]
                             , [comments]
                             , [comments2]
                             , Rooms
                             , telephon
							 , LTRIM(str(@occ1)) AS schtl_old
                        FROM [dbo].[Occupations]
                        WHERE occ = @occ1

                        UPDATE @t
                        SET occ_new  = @occ_new
                          , flat_new = @flat_id1
                        WHERE occ = @occ1

                        EXEC k_update_address @occ_new

                        DELETE
                        FROM dbo.Consmodes_list
                        WHERE occ = @occ_new

                        -- переносим режимы потребления
                        INSERT dbo.Consmodes_list ( occ
                                                  , service_id
                                                  , sup_id
                                                  , fin_id
                                                  , source_id
                                                  , mode_id
                                                  , subsid_only
                                                  , is_counter
                                                  , account_one
                                                  , koef
                                                  , lic_source
                                                  , occ_serv
                                                  )
                        SELECT @occ_new
                             , service_id
                             , sup_id
                             , @fin_id_new
                             , source_id
                             , mode_id
                             , subsid_only
                             , is_counter
                             , account_one
                             , koef
                             , lic_source
                             , occ_serv							  
                        FROM dbo.Consmodes_list 
                        WHERE occ = @occ1
                          AND ((mode_id % 1000 <> 0)
                            OR (source_id % 1000 <> 0))

                        -- переносим людей
                        DELETE FROM @t_id;

                        INSERT INTO @t_id (id, uid)
                        SELECT id, people_uid
                        FROM dbo.People
                        WHERE occ = @occ1
                          AND Del = 0

                        WHILE EXISTS(SELECT * FROM @t_id)
                            BEGIN
                                SELECT TOP (1) @people_id = id, @people_uid = uid
                                FROM @t_id

                                --EXEC @people_new = [dbo].[k_people_next]
                                SET @people_new = NEXT VALUE FOR dbo.GeneratePeolpleSequence;

                                INSERT INTO dbo.People ( id
                                                       , occ
                                                       , Del
                                                       , Last_name
                                                       , First_name
                                                       , Second_name
                                                       , Lgota_id
                                                       , Status_id
                                                       , Status2_id
                                                       , Fam_id
                                                       , doxod
                                                       , KolMesDoxoda
                                                       , dop_norma
                                                       , Reason_extract
                                                       , Birthdate
                                                       , DateReg
                                                       , DateDel
                                                       , dateEnd
                                                       , DateDeath
                                                       , sex
                                                       , Military
                                                       , Criminal
                                                       , comments
                                                       , Dola_priv
                                                       , kol_day_add
                                                       , kol_day_lgota
                                                       , lgota_kod
                                                       , Citizen
                                                       , OwnerParent
                                                       , Nationality
                                                       , Dola_priv1
                                                       , Dola_priv2
                                                       , dateoznac
                                                       , datesoglacie
                                                       , DateRegBegin
                                                       , doc_privat
                                                       , AutoDelPeople
                                                       , DateBeginPrivat)
                                SELECT @people_new
                                     , @occ_new
                                     , Del
                                     , Last_name
                                     , First_name
                                     , Second_name
                                     , Lgota_id
                                     , Status_id
                                     , Status2_id
                                     , Fam_id
                                     , doxod
                                     , KolMesDoxoda
                                     , dop_norma
                                     , Reason_extract
                                     , Birthdate
                                     , DateReg
                                     , DateDel
                                     , dateEnd
                                     , DateDeath
                                     , sex
                                     , Military
                                     , Criminal
                                     , comments
                                     , Dola_priv
                                     , kol_day_add
                                     , kol_day_lgota
                                     , lgota_kod
                                     , Citizen
                                     , OwnerParent
                                     , Nationality
                                     , Dola_priv1
                                     , Dola_priv2
                                     , dateoznac
                                     , datesoglacie
                                     , DateRegBegin
                                     , doc_privat
                                     , AutoDelPeople
                                     , DateBeginPrivat
                                FROM dbo.People AS p
                                WHERE id = @people_id
                                  AND Del = 0
                                
                                -- перенос документов
                                INSERT INTO dbo.Iddoc ( owner_id
                                                      , active
                                                      , DOCTYPE_ID
                                                      , doc_no
                                                      , PASSSER_NO
                                                      , ISSUED
                                                      , DOCORG
                                                      , user_edit
                                                      , date_edit
                                                      , kod_pvs)
                                SELECT @people_new
                                     , active
                                     , DOCTYPE_ID
                                     , doc_no
                                     , PASSSER_NO
                                     , ISSUED
                                     , DOCORG
                                     , user_edit
                                     , date_edit
                                     , kod_pvs
                                FROM dbo.Iddoc 
                                WHERE owner_id = @people_id
                                  AND active = 1
                                  AND NOT EXISTS(
                                        SELECT *
                                        FROM dbo.Iddoc 
                                        WHERE owner_id = @people_new
                                    )

                                -- перенос истории проживания
                                INSERT INTO dbo.People_2 ( owner_id
                                                         , KraiOld
                                                         , RaionOld
                                                         , TownOld
                                                         , VillageOld
                                                         , StreetOld
                                                         , Nom_domOld
                                                         , Nom_kvrOld
                                                         , KraiNew
                                                         , RaionNew
                                                         , TownNew
                                                         , VillageNew
                                                         , StreetNew
                                                         , Nom_domNew
                                                         , Nom_kvrNew
                                                         , KraiBirth
                                                         , RaionBirth
                                                         , TownBirth
                                                         , VillageBirth)
                                SELECT @people_new
                                     , KraiOld
                                     , RaionOld
                                     , TownOld
                                     , VillageOld
                                     , StreetOld
                                     , Nom_domOld
                                     , Nom_kvrOld
                                     , KraiNew
                                     , RaionNew
                                     , TownNew
                                     , VillageNew
                                     , StreetNew
                                     , Nom_domNew
                                     , Nom_kvrNew
                                     , KraiBirth
                                     , RaionBirth
                                     , TownBirth
                                     , VillageBirth
                                FROM dbo.People_2 
                                WHERE owner_id = @people_id
                                  AND NOT EXISTS(
                                        SELECT *
                                        FROM dbo.People_2 
                                        WHERE owner_id = @people_new
                                    )
                                PRINT N'Добавили гражданина ' + STR(@people_new)
                                
                                DELETE
                                FROM @t_id
                                WHERE id = @people_id
                            END
                    COMMIT TRAN
                END
            ELSE
                UPDATE @t
                SET occ_new = @occ1
                WHERE occ = @occ1

            EXEC k_write_log @occ_new
                , N'дблс'
                , @occ1

            --IF @debug=1 PRINT 'Кв: '+STR(@nom_kvr1)+'  Лиц: '+STR(@occ1)+' Нов.Лиц:'+STR(@occ_new)+' Код Кв.: '+STR(@flat_id1)
            IF @debug = 1
                RAISERROR (N'Кв: %s Лиц: %d Нов.Лиц:%d Код Кв.:%d', 10, 1, @nom_kvr1, @occ1, @occ_new, @flat_id1) WITH NOWAIT;

            FETCH NEXT FROM curs_1 INTO @occ1, @nom_kvr1, @tip_id1, @jeu1, @schtl1
        END

    CLOSE curs_1
    DEALLOCATE curs_1

-- *************************************************
IF @is_counter = 1
BEGIN
    RAISERROR (N'Переносим счетчики', 10, 1) WITH NOWAIT;

	UPDATE t set occ_new=t2.Occ, flat_new=t2.flat_id
	FROM @t as t
	CROSS APPLY (
	SELECT o.occ, o.flat_id
	FROM dbo.Occupations AS o
		JOIN dbo.Flats AS f ON o.flat_id = f.id
	WHERE f.bldn_id=@build2 
	AND f.nom_kvr=t.nom_kvr
	AND o.schtl=t.occ
	) t2

	if @debug=1 SELECT * from @t

	DECLARE @flat_id_new INT

	DELETE FROM @t_id;
    
	INSERT INTO @t_id ( id, flat_id)
	SELECT id, flat_id
	FROM dbo.Counters
	WHERE build_id = @build1
		--  AND service_id='элек'
		AND date_del IS NULL

	--SELECT * from @t_id
IF EXISTS(
	SELECT *
	FROM dbo.Counters c1
	JOIN @t_id t ON c1.id=t.id
	WHERE c1.build_id = @build1
		AND NOT EXISTS(SELECT 1	FROM dbo.Counters as c2	WHERE c2.build_id = @build2 and c2.serial_number=c1.serial_number)
    )
        BEGIN
            WHILE EXISTS(SELECT 1 FROM @t_id)
            BEGIN
                SELECT TOP (1) @counter_id1 = id
                                , @flat_id1 = flat_id
                FROM @t_id

                SELECT @flat_id_new = flat_new
                FROM @t
                WHERE flat_id = @flat_id1

                INSERT INTO dbo.Counters ( service_id
                                            , serial_number
                                            , type
                                            , build_id
                                            , flat_id
                                            , max_value
                                            , koef
                                            , unit_id
                                            , count_value
                                            , date_create
                                            , CountValue_del
                                            , date_del
                                            , PeriodCheck
                                            , user_edit
                                            , date_edit
                                            , comments
                                            , internal
                                            , is_build
                                            , checked_fin_id
                                            , mode_id
                                            , PeriodCheckOld
                                            , PeriodCheckEdit
                                            , PeriodLastCheck
                                            , PeriodInterval
                                            , is_sensor_temp
                                            , is_sensor_press
                                            , is_remot_reading
                                            , count_tarif
                                            , value_serv_many_pu)
                SELECT service_id
                        , serial_number
                        , type
                        , @build2
						, case when is_build=1 then null else @flat_id_new end as flat_id
                        , max_value
                        , koef
                        , unit_id
                        , count_value
                        , date_create
                        , CountValue_del
                        , date_del
                        , PeriodCheck
                        , user_edit
                        , date_edit
                        , comments
                        , internal
                        , is_build
                        , checked_fin_id
                        , mode_id
                        , PeriodCheckOld
                        , PeriodCheckEdit
                        , PeriodLastCheck
                        , PeriodInterval
                        , is_sensor_temp
                        , is_sensor_press
                        , is_remot_reading
                        , count_tarif
                        , value_serv_many_pu
                FROM dbo.Counters
                WHERE id = @counter_id1

                SELECT @counter_id_new = SCOPE_IDENTITY()

                -- Переносим лицевые по счетчикам
                INSERT INTO dbo.Counter_list_all ( fin_id
                                                    , counter_id
                                                    , occ
                                                    , service_id
                                                    , occ_counter
                                                    , internal
                                                    , no_vozvrat
                                                    , KolmesForPeriodCheck
                                                    , kol_occ
                                                    , avg_vday)
                SELECT fin_id
                        , @counter_id_new
                        , t.occ_new
                        , service_id
                        , occ_counter
                        , internal
                        , no_vozvrat
                        , KolmesForPeriodCheck
                        , kol_occ
                        , avg_vday
                FROM dbo.Counter_list_all AS cl
                            JOIN @t AS t ON cl.occ = t.occ
                WHERE counter_id = @counter_id1

                -- Переносим последние показания в предыдущий фин.период

                SELECT @pred_value = 0
                        , @pred_date = NULL
                SELECT @pred_value = dbo.Fun_GetCounterValue_pred(@counter_id1, @fin_id1)
                        , @pred_date = dbo.Fun_GetCounterDate_pred(@counter_id1, @fin_id1)

                IF @pred_date IS NOT NULL
                    BEGIN
                        DELETE
                        FROM dbo.Counter_inspector
                        WHERE counter_id = @counter_id_new
                            AND tip_value = 1
                            AND fin_id = @fin_id_new - 1

                        INSERT INTO [dbo].[Counter_inspector] ( [counter_id]
                                                                , [tip_value]
                                                                , [inspector_value]
                                                                , [inspector_date]
                                                                , [blocked]
                                                                , [user_edit]
                                                                , [date_edit]
                                                                , [kol_day]
                                                                , [actual_value]
                                                                , [value_vday]
                                                                , [comments]
                                                                , [fin_id]
                                                                , [mode_id]
                                                                , [tarif]
                                                                , [value_paym])
                        VALUES ( @counter_id_new
                                , 1
                                , @pred_value
                                , @pred_date
                                , 0
                                , 0
                                , dbo.Fun_GetOnlyDate(current_timestamp)
                                , 0
                                , 0
                                , 0
                                , NULL
                                , @fin_id_new - 1
                                , 0
                                , NULL
                                , NULL)

                        IF @@rowcount > 0
                            PRINT N'Добавили показание по адресу: ' + dbo.Fun_GetAdresFlat(@flat_id_new)
                        ELSE
                            PRINT N'!!! не смогли добавить показание по адресу: ' +
                                    dbo.Fun_GetAdresFlat(@flat_id_new)

                    END

                -- ================================================
                DELETE
                FROM @t_id
                WHERE id = @counter_id1
            END

        END -- IF @is_counter=1

END
go

