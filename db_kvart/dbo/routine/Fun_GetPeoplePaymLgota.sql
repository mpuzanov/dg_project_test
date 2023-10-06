CREATE   FUNCTION [dbo].[Fun_GetPeoplePaymLgota]
(
	  @fin_id1 SMALLINT
	, @occ1 INT
)
RETURNS INT
AS
--
--  Кол. людей на которые участвуют в расчете льготы (по статусу прописки)
--
BEGIN

	DECLARE @result INT

	DECLARE @fin_current SMALLINT
	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	IF @fin_current <= @fin_id1
	BEGIN
		SELECT @result = COUNT(p.id)
		FROM dbo.People AS p 
		   , dbo.Person_statuses AS ps 
		WHERE p.Occ = @occ1
			AND p.Del = 0
			AND p.Status2_id = ps.id
			AND ps.is_paym = 1
			AND ps.is_lgota = 1
	END
	ELSE
	BEGIN
		SELECT @result = COUNT(p.owner_id)
		FROM dbo.People_history AS p 
		   , dbo.Person_statuses AS ps 
		WHERE p.Occ = @occ1
			AND p.fin_id = @fin_id1
			AND p.Status2_id = ps.id
			AND ps.is_paym = 1
			AND ps.is_lgota = 1
	END

	RETURN COALESCE(@result, 0)

END
go

