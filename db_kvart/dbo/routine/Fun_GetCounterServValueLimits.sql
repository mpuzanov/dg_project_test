-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   FUNCTION [dbo].[Fun_GetCounterServValueLimits]
()
RETURNS @t_max TABLE (
	  service_id VARCHAR(10)
	, max_value_vday DECIMAL(14, 8)
	, max_value_month DECIMAL(14, 8)
	, alert_value_vday DECIMAL(14, 8)
	, alert_value_month DECIMAL(14, 8)
)
AS
/*
DECLARE @t_max TABLE (service_id varchar(10), max_value_vday DECIMAL(14,8), max_value_month DECIMAL(14,8),
	alert_value_vday DECIMAL(14,8), alert_value_month DECIMAL(14,8) )
insert into @t_max
select * from Fun_GetCounterServValueLimits()
select * from @t_max
*/
BEGIN

	DECLARE @json NVARCHAR(MAX)

	SELECT TOP (1) @json = COALESCE(gb.settings_json, '')
	FROM dbo.Global_values AS gb
	ORDER BY gb.fin_id DESC

	IF @json = ''
		SET @json = N'{"ppu": { "max_ppu":[
		{"service_id":"хвод", "max_value_vday":5, "max_value_month": 100},
		{"service_id":"гвод", "max_value_vday":5, "max_value_month": 100},
		{"service_id":"элек", "max_value_vday":180, "max_value_month": 2000}
		],
		"alert_ppu":[
		{"service_id":"хвод", "max_value_vday":5, "max_value_month": 50},
		{"service_id":"гвод", "max_value_vday":5, "max_value_month": 30},
		{"service_id":"элек", "max_value_vday":180, "max_value_month": 2000}
		]}}'

	INSERT @t_max (service_id
				 , max_value_vday
				 , max_value_month
				 , alert_value_vday
				 , alert_value_month)
	SELECT max_ppu.service_id
		 , max_ppu.max_value_vday
		 , max_ppu.max_value_month
		 , alert.alert_value_vday
		 , alert.alert_value_month
	FROM (
		SELECT service_id
			 , max_value_vday
			 , COALESCE(max_value_month, 2000) AS max_value_month
		FROM OPENJSON(@json, '$.ppu.max_ppu')
		WITH (
		service_id VARCHAR(10) '$.service_id',
		max_value_vday DECIMAL(14, 8) '$.max_value_vday',
		max_value_month DECIMAL(14, 8) '$.max_value_month'
		)
	) AS max_ppu
		LEFT JOIN (
			SELECT service_id
				 , alert_value_vday
				 , COALESCE(alert_value_month, 2000) AS alert_value_month
			FROM OPENJSON(@json, '$.ppu.alert_ppu')
			WITH (
			service_id VARCHAR(10) '$.service_id',
			alert_value_vday DECIMAL(14, 8) '$.max_value_vday',
			alert_value_month DECIMAL(14, 8) '$.max_value_month'
			)
		) AS alert ON max_ppu.service_id = alert.service_id

	IF NOT EXISTS (SELECT * FROM @t_max)
	BEGIN
		INSERT @t_max (service_id
					 , max_value_vday
					 , max_value_month
					 , alert_value_vday
					 , alert_value_month)
		VALUES('хвод'
			 , 5
			 , 100
			 , 5
			 , 50)
			, ('гвод'
			 , 5
			 , 100
			 , 5
			 , 30)
			, ('элек'
			 , 200
			 , 5000
			 , 180
			 , 2000)
	END

	RETURN
END
go

