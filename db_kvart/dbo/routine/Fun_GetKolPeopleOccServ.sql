CREATE   FUNCTION [dbo].[Fun_GetKolPeopleOccServ]
(
	@fin_id			SMALLINT
	,@occ1			INT
	,@service_id	VARCHAR(10)
)
RETURNS SMALLINT
AS
BEGIN
	/*
	Возврашаем количество человек проживающих по лицевому 
	в зависимости от статуса регистрации и начисления на услугу
	*/
	RETURN COALESCE(

	(SELECT
		COUNT(p.id)
	FROM dbo.View_people_all AS p 
	JOIN dbo.Person_statuses AS ps 
		ON p.status2_id = ps.id
	JOIN dbo.Person_calc AS PC 
		ON p.status2_id = PC.status_id
	WHERE 1=1
		AND p.fin_id = @fin_id
		AND p.occ = @occ1
		AND ps.is_kolpeople = cast(1 as bit)
		AND PC.service_id = @service_id
		AND PC.have_paym = cast(1 as bit)
	), 0);

END
go

