-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   FUNCTION [dbo].[Fun_GetCounterServValueInDay]()
    RETURNS @t_max TABLE
                   (
                       service_id      VARCHAR(10),
                       max_value_vday  DECIMAL(14, 8),
                       max_value_month DECIMAL(14, 8)
                   )
AS
/*
--DECLARE @t_max TABLE (service_id varchar(10), max_value_vday DECIMAL(14,8), max_value_month DECIMAL(14,8))
select service_id, max_value_vday, max_value_month from Fun_GetCounterServValueInDay()
*/
BEGIN

    DECLARE @json NVARCHAR(MAX)

    SELECT TOP (1) @json = COALESCE(gb.settings_json, '')
    FROM dbo.Global_values AS gb
    ORDER BY gb.fin_id DESC

    IF @json = ''
        SET @json = N'{"ppu": {"max_ppu":[
		{"service_id":"хвод", "max_value_vday":5, "max_value_month": 100},
		{"service_id":"гвод", "max_value_vday":5, "max_value_month": 100},
		{"service_id":"элек", "max_value_vday":180, "max_value_month": 2000}
		]}}'

    INSERT @t_max ( service_id
                  , max_value_vday
                  , max_value_month)
    SELECT service_id
         , max_value_vday
         , COALESCE(max_value_month, 2000)
    FROM OPENJSON(@json, '$.ppu.max_ppu')
                  WITH (
                      service_id VARCHAR(10) '$.service_id',
                      max_value_vday DECIMAL(14, 8) '$.max_value_vday',
                      max_value_month DECIMAL(14, 8) '$.max_value_month'
                      )

    IF NOT EXISTS(SELECT * FROM @t_max)
        BEGIN
            INSERT @t_max ( service_id
                          , max_value_vday)
            VALUES ( 'хвод'
                   , 5)
                 , ( 'гвод'
                   , 5)
                 , ( 'элек'
                   , 200)
                , ( 'отоп'
                   , 2)
        END

    RETURN
END
go

