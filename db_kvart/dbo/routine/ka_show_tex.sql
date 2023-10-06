CREATE   PROCEDURE [dbo].[ka_show_tex](
    @occ1 INT
)
AS
/*
    Показываем техническую корректировку	
    exec ka_show_tex 680004069
*/
    SET NOCOUNT ON

DECLARE
    @v1     BIT
    , @sum1 DECIMAL(9, 2)

SELECT @sum1 = SUM(pl.value)
FROM dbo.PAYM_LIST AS pl
WHERE pl.occ = @occ1
    IF @sum1 = 0
        SET @v1 = 1
    ELSE
        SET @v1 = 0

SELECT cl.service_id
     , cl.sup_id
     , s.name                             AS serv_name
     , sa.name                            AS sup_name
     , CONCAT(s.name, ' (', sa.name, ')') AS name
     , COALESCE(pl.saldo, 0)              AS saldo
     , CASE
           WHEN @v1 = 1 THEN -- САЛЬДО
               COALESCE(pl.saldo, 0)
           ELSE COALESCE(pl.value, 0)
    END                                   AS calcvalue
     , COALESCE(ap2.sum1, 0)              AS sum1
     , COALESCE(ap2.sum2, 0)              AS sum2
     , COALESCE(ap2.sum3, 0)              AS sum3
     , COALESCE(ap.doc, '')               AS doc
     , COALESCE(ap.doc_no, '')            AS doc_no
     , COALESCE(ap.doc_date, NULL)        AS doc_date
FROM dbo.CONSMODES_LIST AS cl
         JOIN dbo.View_SERVICES AS s
              ON cl.service_id = s.id
         JOIN dbo.SUPPLIERS_ALL sa
              ON cl.sup_id = sa.id
         LEFT JOIN dbo.PAYM_LIST AS pl
                   ON cl.occ = pl.occ
                       AND cl.service_id = pl.service_id
                       AND cl.sup_id = pl.sup_id
         OUTER APPLY (SELECT TOP 1 doc
                                 , doc_no
                                 , doc_date
                      FROM dbo.ADDED_PAYMENTS AS ap
                      WHERE ap.occ = @occ1
                        AND ap.sup_id = cl.sup_id
                        AND ap.add_type = 2) AS ap
         OUTER APPLY (SELECT SUM(value) AS sum1
                           , SUM(CASE
                                     WHEN ap2.add_type <> 2 THEN ap2.value
                                     ELSE 0
        END)                            AS sum2
                           , SUM(CASE
                                     WHEN ap2.add_type = 2 THEN ap2.value
                                     ELSE 0
        END)                            AS sum3
                      FROM dbo.ADDED_PAYMENTS AS ap2
                      WHERE ap2.occ = @occ1
                        AND ap2.service_id = cl.service_id
                        AND ap2.sup_id = cl.sup_id) AS ap2
WHERE cl.occ = @occ1
  AND ((cl.mode_id % 1000) != 0
    OR (cl.source_id % 1000) != 0
    OR s.is_build = 1
    OR pl.saldo <> 0)
ORDER BY serv_name
go

