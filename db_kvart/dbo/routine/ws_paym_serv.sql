-- =============================================
-- Author:		Пузанов
-- Create date: 29.12.07
-- Description:	для веб-сервисов
-- =============================================
CREATE   PROCEDURE [dbo].[ws_paym_serv](
    @occ INT = NULL
, @bldn_id INT = NULL
, @source_id INT = NULL
, @tip_id INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @occ = 0 SET @occ = NULL
    IF @bldn_id = 0 SET @bldn_id = NULL
    IF @source_id = 0 SET @source_id = NULL
    IF @tip_id = 0 SET @tip_id = NULL

    IF @occ IS NULL
        AND @bldn_id IS NULL
        AND @source_id IS NULL
        AND @tip_id IS NULL
        RETURN

    DECLARE @fin_id SMALLINT
    SELECT @fin_id = dbo.Fun_GetFinCurrent(@tip_id, @bldn_id, NULL, @occ)

    IF @occ IS NOT NULL
        BEGIN
            SELECT CASE
                       WHEN (GROUPING(pl.service_id) = 1) THEN 'Итого:'
                       ELSE COALESCE(pl.service_id, '????')
                       END               AS 'service_id',
                   SUM(saldo)            AS saldo,
                   SUM(VALUE)            AS VALUE,
                   0                     AS discount,
                   SUM(added)            AS added,
                   0                     AS compens,
                   SUM(paid)             AS paid,
                   SUM(paymaccount)      AS paymaccount,
                   SUM(paymaccount_peny) AS paymaccount_peny,
                   SUM(debt)             AS debt
            FROM dbo.PAYM_LIST AS pl
            WHERE occ = @occ
              AND (pl.saldo <> 0 OR pl.paid <> 0 OR pl.paymaccount > 0 OR pl.debt <> 0)
            GROUP BY service_id
            WITH ROLLUP
            RETURN
        END

    IF @bldn_id IS NOT NULL
        BEGIN
            SELECT CASE
                       WHEN (GROUPING(pl.service_id) = 1) THEN 'Итого:'
                       ELSE COALESCE(pl.service_id, '????')
                       END                  AS 'service_id',
                   SUM(pl.saldo)            AS saldo,
                   SUM(pl.value)            AS VALUE,
                   0                        AS discount,
                   SUM(pl.added)            AS added,
                   0                        AS compens,
                   SUM(pl.paid)             AS paid,
                   SUM(pl.paymaccount)      AS paymaccount,
                   SUM(pl.paymaccount_peny) AS paymaccount_peny,
                   SUM(pl.debt)             AS debt
            FROM dbo.VIEW_PAYM AS pl,
                 dbo.OCCUPATIONS AS o,
                 dbo.FLATS AS f
            WHERE pl.occ = o.occ
              AND pl.fin_id = @fin_id
              AND o.flat_id = f.id
              AND f.bldn_id = @bldn_id
              AND (pl.saldo <> 0 OR pl.paid <> 0 OR pl.paymaccount > 0 OR pl.debt <> 0)
            GROUP BY pl.service_id
            WITH ROLLUP
            RETURN
        END

    IF (@source_id IS NOT NULL) OR (@tip_id IS NOT NULL)
        BEGIN
            SELECT CASE
                       WHEN (GROUPING(pl.service_id) = 1) THEN 'Итого:'
                       ELSE COALESCE(pl.service_id, '????')
                       END                  AS 'service_id',
                   SUM(pl.saldo)            AS saldo,
                   SUM(pl.value)            AS VALUE,
                   0                        AS discount,
                   SUM(pl.added)            AS added,
                   0                        AS compens,
                   SUM(pl.paid)             AS paid,
                   SUM(pl.paymaccount)      AS paymaccount,
                   SUM(pl.paymaccount_peny) AS paymaccount_peny,
                   SUM(pl.debt)             AS debt
            FROM dbo.VIEW_PAYM AS pl,
                 dbo.CONSMODES_LIST AS cl,
                 dbo.OCCUPATIONS AS o
            WHERE pl.occ = cl.occ
              AND pl.fin_id = @fin_id
              AND pl.service_id = cl.service_id
              AND pl.occ = o.occ
              AND cl.source_id = CASE
                                     WHEN @source_id IS NULL THEN cl.source_id
                                     ELSE @source_id
                END
              AND o.tip_id = CASE
                                 WHEN @tip_id IS NULL THEN o.tip_id
                                 ELSE @tip_id
                END
            GROUP BY pl.service_id
            WITH ROLLUP
            RETURN
        END


END
go

