CREATE   FUNCTION [dbo].[Fun_GetDatePaymClosed]()
    RETURNS DATETIME
AS
BEGIN
    /*
        Возвращаем дату первого не закрытого платежа
    */
    RETURN (SELECT TOP (1) bd.PDATE
            FROM dbo.BANK_DBF AS bd
                     JOIN dbo.BANK_TBL_SPISOK AS bts
                          ON bd.filedbf_id = bts.filedbf_id
                     JOIN dbo.VPAYCOL_USER vu
                          ON bts.bank_id = vu.ext
            WHERE bd.PACK_ID IS NULL
              AND bts.block_import = CAST(0 AS BIT)
            GROUP BY bd.PDATE
            ORDER BY PDATE)

END
go

