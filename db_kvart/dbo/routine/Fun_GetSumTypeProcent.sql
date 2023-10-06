CREATE   FUNCTION [dbo].[Fun_GetSumTypeProcent]
(
	  @occ1 INT
	, @fin_id1 SMALLINT
)
RETURNS DECIMAL(10, 4)
AS
BEGIN
	--
	--   Возврашаем процент от начислений за коммунальные услуги
	--
	DECLARE @Res1 DECIMAL(10, 4)
		  , @prop1 VARCHAR(10)
		  , @socnaim1 BIT
	DECLARE @Sum1 DECIMAL(9, 2)   -- все услуги
	DECLARE @Sum2 DECIMAL(9, 2)   -- коммунальные услуги



	IF @fin_id1 IS NULL
		SELECT @fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)


	SELECT @prop1 = proptype_id
		 , @socnaim1 = socnaim
	FROM dbo.View_occ_all
	WHERE fin_id = @fin_id1
		AND Occ = @occ1

	SELECT @Sum1 = COALESCE(SUM(Paid), 0)
	FROM dbo.View_paym AS pl 
	WHERE fin_id = @fin_id1
		AND Occ = @occ1

	SELECT @Sum2 = COALESCE(SUM(Paid), 0)
	FROM dbo.View_paym AS pl
		JOIN dbo.View_services AS s 
			ON pl.service_id = s.id
	WHERE fin_id = @fin_id1
		AND Occ = @occ1
		AND s.service_type = 2


	IF (@Sum1 <> 0)
		AND (@Sum1 <> @Sum2)
		SET @Res1 = @Sum2 / @Sum1
	ELSE
		SET @Res1 = 1

	IF @prop1 = 'непр'
		AND @socnaim1 = 1
		SET @Res1 = 1

	RETURN (@Res1)

END
go

