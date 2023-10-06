CREATE   PROCEDURE [dbo].[rep_show_add](
    @fin_id SMALLINT = NULL
, @sector_id INT = NULL
, @build_id INT = NULL -- код дома
, @service_id VARCHAR(10) = NULL
, @vin1 INT = NULL
, @vin2 INT = NULL
, @tip_id SMALLINT = NULL
, @div_id SMALLINT = NULL
, @Type_id1 INT = NULL
, @fin_id2 SMALLINT = NULL
, @sup_id INT = NULL
)
AS
    /*
    автор:			Антропов С.В.
    дата создания:	20.05.04
    
    дата изменения:	1.06.09
    автор изменеия:	Пузанов
    
    04.5.2010  добавил часы
    
    используется в:	отчёт №9.3 "Список перерасчетов по виновникам"
    файл отчета:	show_add.frf
    
    exec rep_show_add @fin_id=171,@tip_id=28

    */
    SET NOCOUNT ON;


    IF (@fin_id IS NULL)
        AND (@fin_id2 IS NULL)
        AND @tip_id IS NULL
        AND @service_id IS NULL
        SELECT @fin_id = 0
             , @fin_id2 = 0
             , @tip_id = 0
             , @service_id = ''; -- при разработки отчёта чтобы не думал долго

    IF (@fin_id IS NULL)
        SET @fin_id = [dbo].[Fun_GetFinCurrent](@tip_id, @build_id, NULL, NULL);
    IF @fin_id2 IS NULL
        SET @fin_id2 = @fin_id;


SELECT f.bldn_id
     , ap.start_date
     , s.name                       AS name
     , b.nom_dom
     , MAX(b.nom_dom_sort)          AS nom_dom_sort
     , ap.doc_no                    AS doc_no
     , ap.doc_date                  AS doc_date
     , ap.data1                     AS data1
     , ap.data2                     AS data2
     , s1.name                      AS Vin1
     , s2.name                      AS Vin2
     , ap.Hours
     , ap.tnorm2
     , CAST(SUM(ap.value) AS MONEY) AS Summa
     , SUM(o.Total_sq)              AS Total_sq
     , SUM(o.kol_people)            AS kol_people
     , CASE
           WHEN ap.data1 IS NULL THEN NULL
           ELSE (SELECT TOP 1 start_date
                 FROM dbo.GLOBAL_VALUES gv
                 WHERE ap.data1 BETWEEN start_date AND end_date
                 ORDER BY start_date)
    END
                                    AS fin_paym
FROM dbo.View_ADDED AS ap
    JOIN dbo.OCCUPATIONS AS o
        ON o.occ = ap.occ
    JOIN dbo.flats AS f
        ON o.flat_id = f.id
    JOIN dbo.View_services vs
        ON ap.service_id = vs.id
    JOIN dbo.Buildings AS b
        ON f.bldn_id = b.id
    JOIN dbo.VSTREETS AS s
        ON b.street_id = s.id
    LEFT JOIN dbo.View_SUPPLIERS AS s2
        ON ap.Vin2 = s2.id
    LEFT JOIN dbo.SECTOR AS s1
        ON ap.Vin1 = s1.id
WHERE 
	ap.fin_id BETWEEN @fin_id AND @fin_id2
	AND (ap.service_id = @service_id OR @service_id IS NULL)
	AND (ap.add_type = @Type_id1 OR @Type_id1 IS NULL)
	AND (b.sector_id = @sector_id OR @sector_id IS NULL)
	AND (f.bldn_id = @build_id OR @build_id IS NULL)
	AND COALESCE(ap.Vin1, 0) = COALESCE(@vin1, COALESCE(ap.Vin1, 0))
	AND COALESCE(ap.Vin2, 0) = COALESCE(@vin2, COALESCE(ap.Vin2, 0))
	AND (b.tip_id = @tip_id OR @tip_id IS NULL)
	AND (b.div_id = @div_id OR @div_id IS NULL)
	AND (ap.sup_id = @sup_id OR @sup_id IS NULL)
GROUP BY f.bldn_id
       , ap.start_date
       , s.name
       , b.nom_dom
       , doc_no
       , doc_date
       , data1
       , data2
       , s1.name
       , s2.name
       , ap.Hours
       , ap.tnorm2
ORDER BY ap.start_date, s.name, nom_dom_sort
OPTION (RECOMPILE);
go

