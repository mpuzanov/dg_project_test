-- =============================================
-- Author:		Пузанов
-- Create date: 7.05.07
-- Description:	
/*
Создание новых лицевых для ТСЖ

нужно ввести дом вручную код->@build_new1

используется в форме дома - вкладка - Сервис

переносяться режимы, ПУ, показания ПУ в новый дом
*/
-- =============================================
CREATE         PROCEDURE [dbo].[adm_Create_occ_tsg](
  @build_old1 INT
, @build_new1 INT
, @is_counter BIT = 1
, @debug BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON

    IF @build_old1 = @build_new1
        BEGIN
            RAISERROR (N'Дома должны быть разные!', 16, 1)
        END

    IF @is_counter IS NULL
        SET @is_counter = 1

    DECLARE @id1 INT
    DECLARE @flat_new INT
        , @nom_kvr VARCHAR(20)
        , @total_sq DECIMAL(10, 4)
        , @total_sq_new DECIMAL(10, 4)
        , @kolPeople INT
        , @kolPeople_new INT
        , @pred_value DECIMAL(10, 4)
        , @pred_date SMALLDATETIME

    DECLARE @occ1 INT
        , @occ_new INT
        , @fin_id1 SMALLINT
        , @i INT
        , @err_str VARCHAR(400)
        , @start_date1 SMALLDATETIME
        , @nom_dom_new VARCHAR(7)
        , @CountOcc INT = 0
        , @rang_max INT = 0
        , @tip_name VARCHAR(50)

    IF @build_new1 IS NULL
        RETURN

BEGIN TRY

    DECLARE @t TABLE
               (
                   occ      INT, -- PRIMARY KEY,
                   build1   INT,
                   build2   INT,
                   nom_kvr  VARCHAR(20),
                   tip_id   SMALLINT,
                   jeu      SMALLINT,
                   schtl    INT,
                   total_sq DECIMAL(10, 4),
                   flat_id  INT,
                   occ_new  INT DEFAULT 0,
                   flat_new INT DEFAULT 0
               )

    DECLARE @sector_id1 INT
        , @tip_id1 INT

    SELECT @sector_id1 = vb.sector_id
         , @tip_id1 = vb.tip_id
         , @nom_dom_new = vb.nom_dom
         , @tip_name = vb.tip_name
         , @fin_id1 = vb.fin_current
         , @start_date1 = cp.[start_date]
    FROM View_buildings AS vb
         JOIN Calendar_period AS cp ON 
			cp.fin_id=vb.fin_current
    WHERE vb.id = @build_new1

    IF EXISTS(
            SELECT 1
            FROM dbo.Buildings
            WHERE id = @build_old1
              AND (tip_id = @tip_id1 AND nom_dom = @nom_dom_new)
        )
        BEGIN
            RAISERROR (N'Тип жилого фонда или адрес в домах должен быть различный!', 16, 1)
        END

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
    FROM Buildings b1
             CROSS JOIN Buildings b2
    WHERE b1.id = @build_old1
      AND b2.id = @build_new1

    INSERT INTO @t ( occ
                   , build1
                   , build2
                   , nom_kvr
                   , tip_id
                   , jeu
                   , schtl
                   , total_sq
                   , flat_id)
    SELECT o.occ
         , @build_old1
         , @build_new1
         , f.nom_kvr
         , @tip_id1
         , o.jeu
         , o.schtl
         , o.total_sq
         , o.flat_id
    FROM dbo.Occupations AS o
             JOIN dbo.Flats AS f ON 
				o.flat_id = f.id
    WHERE 
		o.status_id <> N'закр'
		AND f.bldn_id = @build_old1
    ORDER BY f.nom_kvr_sort

    -- *********************************************************
    SELECT @CountOcc = COUNT(occ)
    FROM @t

    IF @CountOcc = 0
        RETURN
    -- лицевых для копирования нет

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
    DELETE
    FROM dbo.Build_mode
    WHERE build_id = @build_new1
    INSERT INTO dbo.Build_mode ( build_id
                               , service_id
                               , mode_id)
    SELECT @build_new1
         , service_id
         , mode_id
    FROM dbo.Build_mode
    WHERE build_id = @build_old1

    -- *********************************************************
    RAISERROR (N'добавляем поставщиков по дому', 10, 1) WITH NOWAIT;
    DELETE
    FROM dbo.Build_source
    WHERE build_id = @build_new1
    INSERT INTO dbo.Build_source ( build_id
                                 , service_id
                                 , source_id)
    SELECT @build_new1
         , service_id
         , source_id
    FROM dbo.Build_source
    WHERE build_id = @build_old1
    -- *********************************************************

    SET @i = 0

    DECLARE curs CURSOR LOCAL FOR
        SELECT t.occ
             , t.nom_kvr
             , t.total_sq
        FROM @t AS t
        ORDER BY t.occ

    OPEN curs
    FETCH NEXT FROM curs INTO @occ1, @nom_kvr, @total_sq

    WHILE (@@fetch_status = 0)
        BEGIN
            SET @flat_new = NULL
            SET @i = @i + 1

            -- запоминаем кол-во людей на лицевом счете
            SELECT @kolPeople = COUNT(id)
            FROM dbo.People AS p
            WHERE p.occ = @occ1
              AND (DateDel IS NULL OR DateDel >= @start_date1);

            BEGIN TRAN
                SELECT @flat_new = id
                FROM dbo.Flats
                WHERE bldn_id = @build_new1
                  AND nom_kvr = @nom_kvr

                IF @flat_new IS NULL
                    BEGIN
                        INSERT INTO dbo.Flats ( bldn_id
                                              , nom_kvr
                                              , floor
                                              , approach)
                        SELECT @build_new1
                             , f.nom_kvr
                             , f.floor
                             , f.approach
                        FROM dbo.Occupations AS o
                                 JOIN dbo.Flats AS f ON o.flat_id = f.id
                        WHERE o.occ = @occ1

                        SELECT @id1 = SCOPE_IDENTITY()
                        SET @flat_new = @id1

                        IF @flat_new IS NULL
                            BEGIN
                                ROLLBACK TRAN
                                RAISERROR (N'Ошибка добавления новой квартиры!', 16, 1)
                            END

                    END

                --print 'Кв.: '+str(@flat_new)

                --exec @occ_new=dbo.k_occ_next
                --EXEC @occ_new = dbo.k_occ_new @tip_id1
                EXEC dbo.k_occ_new @tip_id1
                    , @occ_new = @occ_new OUTPUT
                    , @rang_max = @rang_max OUTPUT

                IF (@occ_new IS NULL)
                    OR @occ_new = 0
                    BEGIN
                        ROLLBACK TRAN
                        SET @err_str = N'Не удалось создать лицевой счёт! в типе фонда с кодом: %i.' + CHAR(13)

                        IF @rang_max = 0
                            SET @err_str = @err_str + N'Закончился диапазон чисел для него!'

                        RAISERROR (@err_str, 16, 1, @tip_id1)
                    END
                --print 'Лицевой: '+str(@occ_new)

                -- Добавляем в файл лицевых счетов
                INSERT dbo.Occupations ( occ
                                       , jeu
                                       , schtl
                                       , flat_id
                                       , tip_id
                                       , total_sq
                                       , roomtype_id
                                       , proptype_id
                                       , status_id
                                       , living_sq
                                       , teplo_sq
                                       , norma_sq
                                       , comments
                                       , comments2
                                       , rooms
                                       , telephon)
                SELECT @occ_new
                     , COALESCE(@sector_id1, jeu)
                     , @occ1 --schtl -- сохраняем лицевой от куда создан
                     , @flat_new
                     , COALESCE(@tip_id1, tip_id)
                     , total_sq
                     , roomtype_id
                     , proptype_id
                     , status_id
                     , living_sq
                     , teplo_sq
                     , norma_sq
                     , comments
                     , comments2
                     , rooms
                     , telephon
                FROM dbo.Occupations AS o
                WHERE occ = @occ1

                UPDATE @t
                SET occ_new  = @occ_new
                  , flat_new = @flat_new
                WHERE occ = @occ1

                EXEC k_update_address @occ_new

                RAISERROR (N'добавляем режимы по лиц/сч: %d', 10, 1, @occ_new) WITH NOWAIT;
                DELETE
                FROM dbo.Consmodes_list
                WHERE occ = @occ_new

                -- переносим режимы потребления
                INSERT INTO dbo.Consmodes_list ( occ
                                               , service_id
                                               , sup_id
                                               , fin_id
                                               , source_id
                                               , mode_id
                                               , koef
                                               , subsid_only
                                               , is_counter
                                               , account_one
                                               , lic_source
                                               , occ_serv)
                SELECT @occ_new
                     , service_id
                     , sup_id
                     , fin_id
                     , source_id
                     , mode_id
                     , koef
                     , subsid_only
                     , is_counter
                     , account_one
                     , lic_source
                     , occ_serv
                FROM dbo.Consmodes_list
                WHERE occ = @occ1
                  AND ((mode_id % 1000 <> 0)
                    OR (source_id % 1000 <> 0))

                RAISERROR (N'переносим людей по лиц/сч: %d', 10, 1, @occ_new) WITH NOWAIT;
                UPDATE p 
                SET occ = @occ_new
                FROM dbo.People AS p
                WHERE p.occ = @occ1
                  AND (DateDel IS NULL OR DateDel >= @start_date1)

                -- Перенос Субсидий
                UPDATE c
                SET c.occ = @occ_new
                FROM dbo.Compensac_all AS c
                WHERE c.occ = @occ1
                  AND fin_id = @fin_id1

                UPDATE c
                SET c.occ = @occ_new
                FROM dbo.Comp_serv_all AS c
                WHERE c.occ = @occ1
                  AND fin_id = @fin_id1

                -- Проверяем
                SELECT @kolPeople_new = COUNT(id)
                FROM dbo.People AS p
                WHERE p.occ = @occ_new
                  AND (DateDel IS NULL OR DateDel >= @start_date1)
                SELECT @total_sq_new = total_sq
                FROM dbo.Occupations AS o
                WHERE occ = @occ_new

                IF @kolPeople_new = @kolPeople
                    AND @total_sq_new = @total_sq
                    COMMIT TRAN
                ELSE
                    BEGIN
                        ROLLBACK TRAN
                        RAISERROR (N'Ошибка переноса лицевого счета: %d!', 16, 1, @occ1)
                    END

                UPDATE o
                SET total_sq  = 0
                  , living_sq = 0
                  , teplo_sq  = 0
                FROM dbo.Occupations AS o
                WHERE occ = @occ1

                if @debug = 1
                    PRINT STR(@i) + N' Кв.: ' + LTRIM(STR(@flat_new)) + N' Ст.лиц. ' + LTRIM(STR(@occ1)) +
                          N' Нов.лиц: ' +
                          LTRIM(STR(@occ_new))

                FETCH NEXT FROM curs INTO @occ1, @nom_kvr, @total_sq
        END

    CLOSE curs
    DEALLOCATE curs

    --**********************************************************************************
    IF @is_counter = 1
        BEGIN
            RAISERROR (N'Переносим счетчики', 10, 1) WITH NOWAIT;

            DECLARE @t_id TABLE
                          (
                              id      INT,
                              flat_id INT
                          )

            DECLARE @flat_id1 INT
                , @counter_id1 INT
                , @counter_id_new INT

            IF NOT EXISTS(
                    SELECT 1
                    FROM dbo.Counters
                    WHERE build_id = @build_new1
                      AND date_del IS NULL
                )
                BEGIN
                    DECLARE @flat_id_new INT

                    INSERT INTO @t_id ( id
                                      , flat_id)
                    SELECT id
                         , flat_id
                    FROM dbo.Counters
                    WHERE build_id = @build_old1
                      AND date_del IS NULL

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
                                                     , counter_uid
                                                     , count_tarif
                                                     , value_serv_many_pu)
                            SELECT service_id
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
                                 , counter_uid
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
                            SELECT @pred_date = dbo.Fun_GetCounterDate_pred(@counter_id1, @fin_id1)

                            IF @pred_date IS NOT NULL
                                BEGIN
                                    DELETE
                                    FROM dbo.Counter_inspector
                                    WHERE counter_id = @counter_id_new
                                      AND tip_value = 1
                                      AND fin_id = @fin_id1 - 1

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
                                           , @fin_id1 - 1
                                           , 0
                                           , NULL
                                           , NULL)

                                    IF @@rowcount > 0
                                        PRINT N'Добавили показание по адресу: ' + dbo.Fun_GetAdresFlat(@flat_id_new)
                                    ELSE
                                        PRINT N'!!! не смогли добавить показание по адресу: ' +
                                              dbo.Fun_GetAdresFlat(@flat_id_new)

                                END

                            DELETE
                            FROM @t_id
                            WHERE id = @counter_id1
                        END

                END
        END --	IF @is_counter = 1	

END TRY

BEGIN CATCH
   IF @@trancount > 0 ROLLBACK TRANSACTION
   ;THROW   
END CATCH

END
go

