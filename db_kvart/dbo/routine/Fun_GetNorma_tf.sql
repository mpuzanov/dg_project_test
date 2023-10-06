-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       FUNCTION [dbo].[Fun_GetNorma_tf]
(
	@unit_id1		VARCHAR(10)
	,@mode_id1		INT
	,@is_counter1	SMALLINT
	,@tip_id		SMALLINT
	,@fin_id		SMALLINT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		q_single as NormaSingle
		, norma_extr_tarif
		, norma_full_tarif
	FROM dbo.Measurement_units
	WHERE unit_id = @unit_id1
		AND mode_id = @mode_id1
		AND is_counter = CASE WHEN @is_counter1 > 0 THEN 1 ELSE 0 END
		AND tip_id = @tip_id
		AND fin_id = @fin_id		
)
go

