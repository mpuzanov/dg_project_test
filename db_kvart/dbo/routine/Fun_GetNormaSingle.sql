-- =============================================
-- Author:		Пузанов
-- Create date: 11.11.11
-- Description:	Получить норму по режиму
-- =============================================
CREATE         FUNCTION [dbo].[Fun_GetNormaSingle]
(
	@unit_id1		VARCHAR(10)
	,@mode_id1		INT
	,@is_counter1	TINYINT
	,@tip_id		SMALLINT
	,@fin_id		SMALLINT
)
RETURNS DECIMAL(12, 6)
/*
select [dbo].[Fun_GetNormaSingle](@unit_id1,@mode_id1,@is_counter1,@tip_id,@fin_id)
*/
AS
BEGIN
	DECLARE @NormaSingle DECIMAL(12, 6) = NULL

	SELECT @is_counter1 = CASE
                              WHEN @is_counter1 > 0 THEN 1
                              ELSE 0
        END

	SELECT
		@NormaSingle = q_single
	FROM dbo.MEASUREMENT_UNITS 
	WHERE unit_id = @unit_id1
		AND mode_id = @mode_id1
		AND is_counter = CONVERT(INT, @is_counter1)
		AND tip_id = @tip_id
		AND fin_id = @fin_id

	RETURN COALESCE(@NormaSingle,0)
END
go

