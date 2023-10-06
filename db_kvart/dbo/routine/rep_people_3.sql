CREATE   PROCEDURE [dbo].[rep_people_3](@tip_id SMALLINT = NULL
, @div_id SMALLINT = NULL
, @build_id INT = NULL
)
AS
/*

  Выборка людей по адресам

дата: 21.10.2010

*/
    SET NOCOUNT ON
    
    IF @tip_id IS NULL AND @div_id IS NULL AND @build_id IS NULL
        SET @tip_id = 0

SELECT s.name                                                          AS streets,
       b.nom_dom,
       o.nom_kvr,
       COUNT(*) OVER (PARTITION BY o.flat_id)                          AS CountPeople,
       ROW_NUMBER() OVER (PARTITION BY o.flat_id ORDER BY p.birthdate) AS NumPeople,
       p.birthdate,
       CASE
           WHEN p.sex = 0 THEN 'женский'
           ELSE 'мужской'
           END                                                         AS sex
FROM dbo.VOCC AS o
         JOIN dbo.buildings AS b ON o.bldn_id = b.id
         JOIN dbo.people AS p ON o.occ = p.occ
         JOIN dbo.VSTREETS AS s ON b.street_id = s.id
WHERE p.del = 0
  AND b.id = COALESCE(@build_id, b.id)
  AND b.div_id = COALESCE(@div_id, b.div_id)
  AND (o.tip_id = @tip_id OR @tip_id IS NULL)
ORDER BY s.name, b.nom_dom_sort, o.nom_kvr_sort
OPTION (RECOMPILE)
go

