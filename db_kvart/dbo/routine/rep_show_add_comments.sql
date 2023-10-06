-- =============================================
-- Author:		Пузанов
-- Create date: 16.01.2012
-- Description:	Пояснения к перерасчётам по 307 постановлению
-- =============================================
CREATE     PROCEDURE [dbo].[rep_show_add_comments](
    @fin_id1 SMALLINT,
    @fin_id2 SMALLINT,
    @build_id INT = NULL,
    @occ1 INT = NULL,
    @debug BIT = 0
)
AS
/*

-- Разбор строки комментария перерасчётов

*/
BEGIN

    SET NOCOUNT ON;


    IF @occ1 = 0 SET @occ1 = NULL;

    DECLARE @t TABLE
               (
                   fin_name     VARCHAR(15),
                   fin_period   VARCHAR(15),
                   occ          INT,
                   serv_name    VARCHAR(20),
                   nom_kvr      VARCHAR(20),
                   sum_add      DECIMAL(9, 2),
                   comments     VARCHAR(70),
                   doc          VARCHAR(100),
                   descriptions VARCHAR(400)
               )

    DECLARE cur CURSOR FOR
        SELECT ap.fin_id,
               ap.fin_id_paym,
               ap.occ,
               s.name,
               ap.value,
               ap.comments,
               f.nom_kvr,
               ap.doc
        FROM dbo.View_ADDED AS ap 
            JOIN dbo.GLOBAL_VALUES AS gb  
				ON ap.fin_id = gb.fin_id
            JOIN dbo.VIEW_SERVICES AS s  
				ON ap.service_id = s.id
            JOIN dbo.OCCUPATIONS AS o 
				ON ap.occ = o.Occ
            JOIN dbo.FLATS AS f 
				ON o.flat_id = f.id
        WHERE 
			ap.fin_id BETWEEN @fin_id1 AND @fin_id2
			AND ap.add_type = 11
			--AND ap.comments IS NOT NULL
			AND f.bldn_id = COALESCE(@build_id, f.bldn_id)
			AND ap.occ = COALESCE(@occ1, ap.occ)
        ORDER BY ap.fin_id

    OPEN cur
    DECLARE @occ INT,
        @comments VARCHAR(70),
        @comments1 VARCHAR(70),
        @description VARCHAR(400),
        @fin_id SMALLINT,
        @fin_period SMALLINT, -- период за который начислялись разовые
        @serv_name VARCHAR(20),
        @sum_add DECIMAL(9, 2),
        @nom_kvr VARCHAR(7),
        @doc VARCHAR(100)

    DECLARE @Vd VARCHAR(10), @Vnp VARCHAR(10), @Vnn VARCHAR(10), @Vip VARCHAR(10), @tarif VARCHAR(10),
        @M VARCHAR(10),@P1 VARCHAR(30), @P2 VARCHAR(30)
        
    FETCH NEXT FROM cur INTO @fin_id, @fin_period, @occ, @serv_name, @sum_add, @comments, @nom_kvr, @doc
    WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @comments1 = @comments
            SET @description = ''
            --PRINT @comments1

            IF dbo.strpos('Ф9:', @comments) > 0
                BEGIN
                    -- ka_add_F9
                    SET @comments = REPLACE(@comments, 'Ф9:', '')
                    SET @comments = REPLACE(@comments, '(', '')
                    SET @comments = REPLACE(@comments, ')', '')
                    SET @Vd = SUBSTRING(@comments, 0, dbo.strpos('/', @comments));
                    SET @comments = REPLACE(@comments, @Vd + '/', '')
                    SET @Vnn = SUBSTRING(@comments, 0, dbo.strpos('+', @comments));
                    SET @comments = REPLACE(@comments, @Vnn + '+', '')
                    SET @Vnp = SUBSTRING(@comments, 0, dbo.strpos('*', @comments));
                    SET @comments = REPLACE(@comments, @Vnp + '*', '')
                    SET @Vip = SUBSTRING(@comments, 0, dbo.strpos('*', @comments));
                    SET @comments = REPLACE(@comments, @Vip + '*', '')
                    SET @tarif = SUBSTRING(@comments, 0, dbo.strpos('-', @comments));
                    SET @comments = REPLACE(@comments, @tarif + '-', '')

                    --SET @description = 'Сумма: '+LTRIM(STR(@sum_add,9,2))+' за '+@serv_name+' по л.сч:' +LTRIM(STR(@occ))+'; ' 
                    SET @description = 'Расчёт по Формуле 9 Постановления 307; Объем поставщика на дом: ' + @Vd +
                                       '; Начисленный объём по норме: ' + @Vnn + '; объём по счетчику: ' +
                                       @Vnp + '; объём по л.сч: ' + @Vip + '; по тарифу: ' + @tarif
                END
            ELSE
                IF dbo.strpos('Раскидка:', @comments) > 0
                    BEGIN
                        -- ka_add_added_6, ka_add_added_7
                        SET @comments = REPLACE(@comments, 'Раскидка:', '')
                        --set @comments=REPLACE(@comments,'(','')
                        --set @comments=REPLACE(@comments,')','')
                        SET @Vd = SUBSTRING(@comments, 0, dbo.strpos('М', @comments));
                        SET @comments = REPLACE(@comments, @Vd, '')
                        SET @M = SUBSTRING(@comments, 0, dbo.strpos('(', @comments));
                        SET @comments = REPLACE(@comments, @M + '(', '')
                        IF @M = 'М:1'
                            BEGIN
                                SET @P1 = SUBSTRING(@comments, 0, dbo.strpos(':', @comments));
                                SET @comments = REPLACE(@comments, @P1 + ':', '')
                                SET @P1 = ' Площадь дома:' + @P1
                                SET @P2 = SUBSTRING(@comments, 0, dbo.strpos(')', @comments));
                                SET @comments = REPLACE(@comments, @P2 + ')', '')
                                SET @P2 = '; Площадь лиц.сч:' + @P2
                            END
                        IF @M = 'М:2'
                            BEGIN
                                SET @P1 = SUBSTRING(@comments, 0, dbo.strpos(':', @comments));
                                SET @comments = REPLACE(@comments, @P1 + ':', '')
                                SET @P1 = ' Кол.во человек в доме:' + @P1
                                SET @P2 = SUBSTRING(@comments, 0, dbo.strpos(')', @comments));
                                SET @comments = REPLACE(@comments, @P2 + ')', '')
                                SET @P2 = '; Человек на лиц.сч:' + @P2
                            END

                        --SET @description = 'Сумма: '+LTRIM(STR(@sum_add,9,2))+' за '+@serv_name+' по Л.сч: ' +LTRIM(STR(@occ))+'; '
                        SET @description =
                                    'Раскидка cуммы на дом: ' + @Vd + ' по доли площади л.сч. в доме; ' + @P1 + @P2
                    END
                ELSE
                    BEGIN
                        --print @comments
                        IF LEFT(@comments, 1) = '('
                            BEGIN
                                -- процедура ka_add_added_5   Квартальная корректировка по 307	по другим услугам 
                                SET @comments = REPLACE(@comments, '(', '')
                                SET @comments = REPLACE(@comments, ')', '')
                                SET @Vd = SUBSTRING(@comments, 0, dbo.strpos('-', @comments));
                                SET @comments = REPLACE(@comments, @Vd + '-', '')
                                SET @Vnp = SUBSTRING(@comments, 0, dbo.strpos('*', @comments));
                                SET @comments = REPLACE(@comments, @Vnp + '*', '')
                                SET @Vnn = SUBSTRING(@comments, 0, dbo.strpos('/', @comments));
                                SET @comments = REPLACE(@comments, @Vnn + '/', '')
                                SET @Vip = SUBSTRING(@comments, 0, LEN(@comments))
                                SET @description = 'Начисленно поставщиком: ' + @Vd + '; Начисленно по дому: ' + @Vnp +
                                                   '; Площадь л.сч: ' + @Vnn + '; Площадь дома: ' + @Vip
                                --PRINT @description
                            END
                        ELSE
                            BEGIN
                                IF dbo.strpos('*', @comments) > 0
                                    BEGIN
                                        -- процедура ka_add_added_5   Квартальная корректировка по 307	по отоплению
                                  SET @Vd = SUBSTRING(@comments, 0, dbo.strpos('*', @comments));
                                        SET @comments = REPLACE(@comments, @Vd + '*', '')
                                        SET @Vnn = SUBSTRING(@comments, 0, dbo.strpos('/', @comments));
                                        SET @comments = REPLACE(@comments, @Vnn + '/', '')
                                        SET @Vnp = SUBSTRING(@comments, 0, dbo.strpos('-', @comments));
                                        SET @comments = REPLACE(@comments, @Vnp + '-', '')
                                        SET @Vip = SUBSTRING(@comments, 0, LEN(@comments))
                                        SET @description = 'Начисленно поставщиком: ' + @Vd + '; Площадь л.сч: ' +
                                                           @Vnn +
                                                           '; Площадь дома: ' + @Vnp + '; Начисленно по л.сч: ' + @Vip
                                        --PRINT @description
                                    END
                            END
                    END

            IF @debug = 1 PRINT @description

            --IF @comments1 IS NULL SET @comments1=@doc

            INSERT INTO @t(fin_name, fin_period, occ, serv_name, nom_kvr, sum_add, comments, doc, descriptions)
            VALUES (dbo.Fun_NameFinPeriod(@fin_id), dbo.Fun_NameFinPeriod(@fin_period),
                    @occ, @serv_name, @nom_kvr, @sum_add, @comments1, @doc, @description)

            FETCH NEXT FROM cur INTO @fin_id, @fin_period, @occ, @serv_name, @sum_add, @comments, @nom_kvr, @doc
        END
    CLOSE cur
    DEALLOCATE cur

    SELECT t1.*, o.address
    FROM @t AS t1
    	JOIN dbo.Occupations o 
             ON t1.occ = o.occ
    ORDER BY dbo.Fun_SortDom(nom_kvr);

END
go

