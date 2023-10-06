CREATE   FUNCTION [dbo].[Fun_GetSummaType]
(
	  @fin_id1 SMALLINT
	, @occ1 INT
	, @tip_serv SMALLINT
)
RETURNS DECIMAL(10, 2)
AS
BEGIN
	--
	--   Возврашаем начисления по коммунальным  услугам
	--
	DECLARE @Sum1 DECIMAL(10, 2)

	IF @fin_id1 IS NULL
		SELECT @fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	SELECT @Sum1 = COALESCE(SUM(Paid), 0)
	FROM dbo.View_paym AS pl
		JOIN dbo.View_services AS s 
			ON pl.service_id = s.id
	WHERE fin_id = @fin_id1
		AND Occ = @occ1
		AND s.service_type =
							CASE
								WHEN @tip_serv = 1 THEN 1  -- жилищные услуги
								WHEN @tip_serv = 2 THEN 2  -- коммун. услуги
								ELSE s.service_type      -- все
							END


	RETURN (@Sum1)

END
go

