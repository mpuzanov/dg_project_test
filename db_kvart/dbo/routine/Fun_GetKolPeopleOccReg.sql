CREATE   FUNCTION [dbo].[Fun_GetKolPeopleOccReg]
(
	@fin_id SMALLINT
   ,@occ1   INT
)
RETURNS SMALLINT
AS
BEGIN
	/*
	select [dbo].[Fun_GetKolPeopleOccReg](141,390027001)
	select [dbo].[Fun_GetKolPeopleOccReg](180,680004137)
	select [dbo].[Fun_GetKolPeopleOccReg](182,680004831)	
			
	 Возврашаем количество человек зарегестрированных по лицевому 
	 в зависимости от статуса регистрации

	*/
	RETURN COALESCE(

	(SELECT
		COUNT(p.owner_id)
	FROM (SELECT
			p1.id AS owner_id
		   ,p1.status2_id
		FROM dbo.People AS p1
		JOIN dbo.Occupations o
			ON p1.occ = o.occ
		WHERE p1.occ = @occ1
		AND p1.Del = cast(0 as bit)
		AND o.fin_id = @fin_id
		UNION
		SELECT
			p2.owner_id
		   ,p2.status2_id
		FROM dbo.People_history AS p2 
		WHERE p2.fin_id = @fin_id
		AND p2.occ = @occ1
		) AS p
	JOIN dbo.Person_statuses AS ps
		ON p.status2_id = ps.id
	WHERE ps.is_registration = cast(1 as bit)

	), 0)

END
go

