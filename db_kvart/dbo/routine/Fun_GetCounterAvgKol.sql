-- =============================================
-- Author:		Пузанов
-- Create date: 28.12.2010
-- Description:	Получаем среднее показание в день
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetCounterAvgKol]
(
	@occ1			INT
	,@service_id1	VARCHAR(10)
)
RETURNS DECIMAL(14, 6)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @kol DECIMAL(14, 6) = 0

	-- вычисляем сумму средних значений счётчиков
	SELECT
		@kol = COALESCE(SUM(value_vday), 0)
	FROM (SELECT
			counter_id
			,COALESCE(AVG(value_vday), 0) AS value_vday
		FROM dbo.View_counter_inspector
		WHERE occ = @occ1
			AND service_id = @service_id1
			AND tip_value = 1
		GROUP BY counter_id) AS t

	-- Return the result of the function
	RETURN @kol

END
go

