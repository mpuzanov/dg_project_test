-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   FUNCTION [dbo].[Fun_GetCounterAlertServValueInDay]
()
RETURNS @t_max TABLE (
	  service_id VARCHAR(10)
	, max_value_vday DECIMAL(14, 8)
	, max_value_month DECIMAL(14, 8)
)
AS
/*
--DECLARE @t_max TABLE (service_id varchar(10), max_value_vday DECIMAL(14,8), max_value_month DECIMAL(14, 8))
select service_id, max_value_vday, max_value_month from Fun_GetCounterAlertServValueInDay()
*/
BEGIN

	DECLARE @json NVARCHAR(MAX)

	SELECT TOP (1) @json = COALESCE(gb.settings_json, '')
	FROM dbo.Global_values AS gb
	ORDER BY gb.fin_id DESC

	IF @json <> ''
	BEGIN
		INSERT @t_max (service_id
					 , max_value_vday
					 , max_value_month)
		SELECT service_id
			 , max_value_vday
			 , max_value_month
		FROM OPENJSON(@json, '$.ppu.alert_ppu')
		WITH (
		service_id VARCHAR(10) '$.service_id',
		max_value_vday DECIMAL(14, 8) '$.max_value_vday',
		max_value_month DECIMAL(14, 8) '$.max_value_month'
		)
	END

	IF NOT EXISTS (SELECT * FROM @t_max)
	BEGIN
		INSERT @t_max (service_id
					 , max_value_vday
					 , max_value_month)
		VALUES('хвод'
			 , 5
			 , 50)
			, ('гвод'
			 , 5
			 , 50)
			, ('элек'
			 , 50
			 , 1000)
	END


	RETURN
END
go

