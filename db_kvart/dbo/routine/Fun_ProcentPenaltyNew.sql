CREATE   FUNCTION [dbo].[Fun_ProcentPenaltyNew]
(
	@fin_id1 SMALLINT
)
RETURNS DECIMAL(10, 4)
AS
BEGIN
	/*
	select dbo.Fun_ProcentPenaltyNew(180)
	select dbo.Fun_ProcentPenaltyNew(null)
	*/

	DECLARE @Proc1 DECIMAL(10, 4)

	SELECT
		@Proc1 = PenyProc
	FROM dbo.Global_values
	WHERE fin_id = @fin_id1

	IF @Proc1 IS NULL
	BEGIN
		SELECT
			@fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)
		SELECT
			@Proc1 = PenyProc
		FROM dbo.GLOBAL_VALUES
		WHERE fin_id = @fin_id1
	END

	RETURN @Proc1

END
go

