CREATE   FUNCTION [dbo].[Fun_GetDiscountType1]
(
	  @fin_id1 SMALLINT
	, @occ1 INT
	, @tip_serv TINYINT
)
RETURNS DECIMAL(10, 2)
AS
BEGIN
	--
	--   Возврашаем льготу по жилищным услугам или коммунальным услугам
	--
	DECLARE @Sum1 DECIMAL(10, 2)

	IF @tip_serv IS NULL
		SET @tip_serv = 1  -- по жилищным услугам

	IF @fin_id1 IS NULL
		SELECT @fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	SELECT @Sum1 = COALESCE(SUM(discount), 0)
	FROM dbo.View_paym AS pl 
		JOIN dbo.View_services AS s 
			ON pl.service_id = s.id
	WHERE fin_id = @fin_id1
		AND occ = @occ1
		AND s.service_type = @tip_serv


	RETURN (@Sum1)

END
go

