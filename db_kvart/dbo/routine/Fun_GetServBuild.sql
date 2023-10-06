-- =============================================
-- Author:		Пузанов
-- Create date: 01.04.2023
-- Description: Список услуг в доме
-- Использовать: select * from dbo.Fun_GetServBuild(6820)
-- =============================================
CREATE   FUNCTION [dbo].[Fun_GetServBuild]
(
	@build_id INT
)
RETURNS TABLE
AS
RETURN (
	with cte AS (
	SELECT DISTINCT 
		s.id, s.name as name, short_name, s.sort_no
	FROM dbo.BUILD_MODE AS bm
		JOIN dbo.BUILD_SOURCE AS bs ON bm.build_id=bs.build_id AND bm.service_id=bs.service_id
		JOIN dbo.View_SERVICES AS s ON bm.service_id=s.id
		JOIN dbo.CONS_MODES AS cm ON bm.mode_id=cm.id
		JOIN dbo.SUPPLIERS AS sup ON bs.source_id=sup.id
	WHERE (mode_id%1000)<>0
		AND (source_id%1000)<>0  
		AND bm.build_id=@build_id
	)
	SELECT TOP(200) * from cte ORDER BY sort_no
)
go

