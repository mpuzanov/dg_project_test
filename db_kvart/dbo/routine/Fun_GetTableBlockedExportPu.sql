-- =============================================
-- Author:		Name
-- Create date: 
-- Description:	Список заблокированных услуг приборов учёта по домам
-- =============================================
CREATE      FUNCTION [dbo].[Fun_GetTableBlockedExportPu]
(
	  @tip_id SMALLINT = NULL
	, @build_id INT = NULL
	, @service_id VARCHAR(10) = NULL
)
RETURNS TABLE

AS
	/*
	select * from [dbo].[Fun_GetTableBlockedExportPu](null,null,null)
	select * from [dbo].[Fun_GetTableBlockedExportPu](60,null,'хвод')
	select * from [dbo].[Fun_GetTableBlockedExportPu](60,3810,null)
	select * from [dbo].[Fun_GetTableBlockedExportPu](60,3810,'хвод')
	*/

RETURN (
	SELECT b.tip_id
		 , b.id     AS build_id
		 , s.id     AS service_id
		 , CAST(CASE
                    WHEN stc.no_export = 1 THEN 1
                    ELSE 0
        END AS BIT) AS tip_blocked
		 , CAST(CASE
                    WHEN b.blocked_counter_out = 1 THEN 1
                    ELSE 0
        END AS BIT) AS build_blocked
		 , CAST(CASE
                    WHEN sb.is_export_pu = 0 THEN 1
                    ELSE 0
        END AS BIT) AS build_serv_blocked
	FROM dbo.Buildings AS b 
		CROSS JOIN dbo.Services s 
		LEFT JOIN dbo.Services_type_counters stc  ON b.tip_id = stc.tip_id
			AND stc.service_id = s.id
		LEFT JOIN dbo.Services_build sb ON b.id = sb.build_id
			AND sb.service_id = s.id
	WHERE s.is_counter = CAST(1 AS BIT) -- id IN ('хвод', 'гвод', 'элек', 'тепл', 'пгаз', 'отоп')
		AND (@tip_id IS NULL OR b.tip_id = @tip_id)
		AND (@build_id IS NULL OR b.id = @build_id)
		AND (@service_id IS NULL OR s.id = @service_id)
		AND (
		(COALESCE(stc.no_export, 0) = 1 AND COALESCE(sb.is_export_pu, 1) = 1) -- блокировка экспорта по типу фонда (по услуге запрета нет)
		OR
		(COALESCE(sb.is_export_pu, 1) = 0 AND b.blocked_counter_out = 0) -- блокировка экспорта в доме по услуге
		OR
		(b.blocked_counter_out = 1)-- блокировка экспорта по всему дому
		)
)
go

