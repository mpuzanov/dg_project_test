CREATE   FUNCTION [dbo].[Fun_GetKolPeopleOccStatus]
(
    @occ1 INT
)
RETURNS SMALLINT
AS
BEGIN
/*
select [dbo].[Fun_GetKolPeopleOccStatus](680003665)

Возврашаем количество человек проживающих по лицевому 
в зависимости от статуса прописки

*/
RETURN coalesce(
	(SELECT count(p.id)
	FROM
		dbo.people AS p 
		JOIN dbo.person_statuses AS ps
			ON p.status2_id = ps.id
	WHERE
		p.occ = @occ1
		AND del = CAST(0 AS BIT)
		AND ps.is_kolpeople = CAST(1 AS BIT)

	), 0)

END
go

