-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	Показывает услугу у которой нет действующего ИПУ
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetCounterBlockedServ]
(
	@flat_id1 INT
)
RETURNS VARCHAR(10)
AS
BEGIN
	/*
	SELECT dbo.Fun_GetCounterBlockedServ(12859)
	SELECT dbo.Fun_GetCounterBlockedServ(240626)	
	SELECT dbo.Fun_GetCounterBlockedServ(300757)
	
	*/
	DECLARE @ResultVar VARCHAR(10) = ''


	SELECT
		@ResultVar = COALESCE(service_id, '')
	FROM (SELECT
			c1.service_id
			,(SELECT
					COUNT(*)
				FROM [dbo].[COUNTERS] AS c3
				WHERE c3.flat_id = c1.flat_id
				AND c3.date_del IS NULL) AS countIPU
			,COUNT(*) AS kolIPU
			,(SELECT
					COUNT(*)
				FROM [dbo].[COUNTERS] AS c2 
				WHERE c2.flat_id = c1.flat_id
				AND c2.service_id = c1.service_id
				AND c2.date_del IS NOT NULL) AS kolIPU_del
		FROM [dbo].[COUNTERS] AS c1 
		WHERE c1.flat_id = @flat_id1 --12859 --8447 --12560
		AND c1.service_id IN ('гвод', 'хвод')
		GROUP BY	c1.flat_id
					,c1.service_id) AS t
	WHERE (t.kolIPU - t.kolIPU_del) = 0
	AND countIPU > 0

	-- Проверяем режим потребления по услуге
	IF @ResultVar <> ''
	BEGIN
		-- если нет то очищаем услугу
		IF EXISTS (SELECT
					1
				FROM CONSMODES_LIST AS cl 
				JOIN OCCUPATIONS AS o 
					ON cl.occ = o.occ
				WHERE o.flat_id = @flat_id1
				AND cl.service_id = @ResultVar
				AND (cl.mode_id % 1000) = 0)
			SELECT
				@ResultVar = ''
	END

	RETURN COALESCE(@ResultVar, '')

END
go

