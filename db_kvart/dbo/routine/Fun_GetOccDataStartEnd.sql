-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	Возвращаем таблицу дата начала и окончания расчетов
-- Пример вызова:  
-- select * from Fun_GetOccDataStartEnd(910003358, 235, 1)
-- select * from Fun_GetOccDataStartEnd(910003358, 235, 0)
-- =============================================
CREATE       FUNCTION [dbo].[Fun_GetOccDataStartEnd](
    @occ1 INT
, @fin_id1 INT
, @only_current_fin BIT = 1
)
    RETURNS @result TABLE
                    (
                        Occ            INT,
                        fin_id         SMALLINT,
                        service_id     VARCHAR(10),
                        date_ras_start DATETIME     default null,
                        date_ras_end   DATETIME     default null,
                        comments       VARCHAR(100) default null
                    )
AS
BEGIN
    /*
    даты могут быть
    -- по дому	05.08.2021
    -- по лицевому 06.08.2021
    -- по типу фонда по услугам втбо по 24.08.2021
    -- по дому по услугам втбо 08.08.2021
    -- по лицевому по услугам  площ до 29.08.2021

    для тестирования:
    --ООО "УК "Италмас", 4
    --г.Ижевск, ул. 40 лет Победы д.71 кв.68
    select * from Fun_GetOccDataStartEnd(910003358, 235)

    */
    IF @only_current_fin is null
        set @only_current_fin = 1

    DECLARE @date_start_build SMALLDATETIME
        , @date_end_build SMALLDATETIME
        , @date_start_occ SMALLDATETIME
        , @date_end_occ SMALLDATETIME
        , @tip_id SMALLINT
        , @build_id INT
        , @start_date SMALLDATETIME
        , @end_date SMALLDATETIME

    SELECT @date_start_build = b.date_start
         , @date_end_build = b.date_end
         , @date_start_occ = o.date_start
         , @date_end_occ = o.date_end
         , @tip_id = o.tip_id
         , @build_id = f.bldn_id
         , @start_date = gv.start_date
         , @end_date = gv.end_date
    FROM dbo.Occupations o
        JOIN dbo.Flats f ON 
			o.flat_id = f.id
        JOIN dbo.Buildings b ON 
			f.bldn_id = b.id
        JOIN dbo.Global_values gv ON 
			gv.fin_id = @fin_id1
    WHERE 
		Occ = @occ1;

    -- заполним таблицу по умолчанию
    INSERT INTO @result ( Occ
                        , service_id
                        , fin_id)
    SELECT @occ1
         , s.id
         , @fin_id1
    FROM Services s

    -- по дому 
    UPDATE r
    SET date_ras_start = @date_start_build
      , date_ras_end   = @date_end_build
    FROM @result AS r

    -- по лицевому 
    UPDATE r
    SET date_ras_start =
        CASE
            WHEN date_ras_start is null or @date_start_occ >= date_ras_start THEN @date_start_occ
            ELSE date_ras_start
            END
      , date_ras_end   =
        CASE
            WHEN date_ras_end is null or @date_end_occ <= date_ras_end THEN @date_end_occ
            ELSE date_ras_end
            END
    FROM @result AS r

    -- по типу фонда по услугам
    UPDATE r
    SET date_ras_start =
        CASE
            WHEN r.date_ras_start is NULL OR st.date_ras_start >= r.date_ras_start THEN st.date_ras_start
            ELSE r.date_ras_start
            END
      , date_ras_end   =
        CASE
            WHEN r.date_ras_end is NULL OR st.date_ras_end <= r.date_ras_end THEN st.date_ras_end
            ELSE r.date_ras_end
            END
      , comments       = st.comments
    FROM @result AS r
         JOIN dbo.Services_types st 
			ON r.service_id = st.service_id
    WHERE st.tip_id = @tip_id
      AND (st.date_ras_start IS NOT NULL OR st.date_ras_end IS NOT NULL OR st.comments is not null)

    -- по дому по услугам
    UPDATE r
    SET date_ras_start =
        CASE
            WHEN r.date_ras_start is NULL OR sb.date_ras_start >= r.date_ras_start THEN sb.date_ras_start
            ELSE r.date_ras_start
            END
      , date_ras_end   =
        CASE
            WHEN r.date_ras_end is NULL OR sb.date_ras_end <= r.date_ras_end THEN sb.date_ras_end
            ELSE r.date_ras_end
            END
      , comments       = coalesce(sb.comments, r.comments)
    FROM @result AS r
        JOIN dbo.Services_build sb 
			ON r.service_id = sb.service_id
    WHERE sb.build_id = @build_id
      AND (sb.date_ras_start IS NOT NULL OR sb.date_ras_end IS NOT NULL OR sb.comments is not null)

    -- по лицевому по услугам
    UPDATE r
    SET date_ras_start =
        CASE
            WHEN r.date_ras_start is null OR cl.date_start >= r.date_ras_start THEN cl.date_end
            ELSE r.date_ras_start
            END
      , date_ras_end   =
        CASE
            WHEN r.date_ras_end is null OR cl.date_end < r.date_ras_end THEN cl.date_end
            ELSE r.date_ras_end
            END
    FROM @result AS r
             JOIN dbo.Consmodes_list cl ON r.Occ = cl.Occ
        AND r.service_id = cl.service_id
    WHERE cl.Occ = @occ1
      AND cl.date_end IS NOT NULL

    -- там где выходит за пределы фин.периода заменяем
    IF @only_current_fin = 1
        UPDATE r
        SET date_ras_start = CASE
                                 WHEN coalesce(date_ras_start, @start_date) <= @start_date THEN @start_date
                                 ELSE date_ras_start
            END
          , date_ras_end   = CASE
                                 WHEN coalesce(date_ras_end, @end_date) >= @end_date THEN @end_date
                                 ELSE date_ras_end
            END
        FROM @result AS r

    -- для тестирования
    DELETE
    FROM @result
    WHERE (coalesce(date_ras_start, @start_date) = @start_date
        AND coalesce(date_ras_end, @end_date) = @end_date)
      AND comments is null

    RETURN
END
go

