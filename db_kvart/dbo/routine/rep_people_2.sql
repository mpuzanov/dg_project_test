CREATE   PROCEDURE [dbo].[rep_people_2](
    @jeu1 SMALLINT = NULL
, @birthdate1 DATETIME = NULL
, @birthdate2 DATETIME = NULL
, @sex TINYINT = NULL --0-жен 1-муж
, @tip_id SMALLINT = NULL
, @div_id SMALLINT = NULL
, @build_id INT = NULL
, @is_value BIT = NULL -- признак начисления
)
AS
/*
 Выборка по людям
 
 rep_people_2 @birthdate1='20100101',@birthdate2='20160101',@tip_id=28, @is_value=1
 
*/
    SET NOCOUNT ON
    
    IF @birthdate1 IS NOT NULL
        AND YEAR(@birthdate1) = 1900
        SET @birthdate1 = NULL
    IF @birthdate2 IS NOT NULL
        AND YEAR(@birthdate1) = 2050
        SET @birthdate1 = NULL
    IF @tip_id IS NULL
        AND @div_id IS NULL
        AND @jeu1 IS NULL
        AND @build_id IS NULL
        AND (@birthdate1 IS NULL AND @birthdate2 IS NULL)
        SET @tip_id = 0

SELECT p.Last_name
     , p.First_name
     , p.Second_name
     , p.Birthdate
     , o.address
     , CONCAT(rtrim(s.name), ' д.', b.nom_dom) AS build
     , COALESCE(p.sex, 2)                      AS sex
     , Lgota_id
     , p.occ
FROM dbo.PEOPLE AS p
         JOIN dbo.VOCC AS o
              ON o.occ = p.occ
         JOIN dbo.BUILDINGS AS b
              ON o.bldn_id = b.id
         JOIN dbo.VSTREETS AS s
              ON b.street_id = s.id
WHERE p.Del = 0
  AND o.STATUS_ID <> 'закр'
  AND (b.id = @build_id OR @build_id IS NULL)
  AND b.sector_id = COALESCE(@jeu1, b.sector_id)
  AND b.div_id = COALESCE(@div_id, b.div_id)
  AND (b.tip_id = @tip_id OR @tip_id IS NULL)
  AND COALESCE(sex, 2) = COALESCE(@sex, COALESCE(sex, 2))
  AND COALESCE(p.Birthdate, '19000101') BETWEEN COALESCE(@birthdate1, '18990101') AND COALESCE(@birthdate2, '20500101')
  AND COALESCE(o.PaidAll, 0) >
      CASE
          WHEN COALESCE(@is_value, 0) = 1 THEN 0
          ELSE -999999
          END
ORDER BY s.name, b.nom_dom_sort, o.nom_kvr_sort
OPTION (RECOMPILE)
go

