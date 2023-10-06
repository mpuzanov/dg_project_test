CREATE   FUNCTION [dbo].[Fun_GetKolPeopleOccAll]
(
	@fin_id SMALLINT
   ,@occ1   INT
)
RETURNS SMALLINT
AS
BEGIN
	/*
	select [dbo].[Fun_GetKolPeopleOccAll](141,390027001)
	select [dbo].[Fun_GetKolPeopleOccAll](180,680004137)
	select [dbo].[Fun_GetKolPeopleOccAll](182,680004831)	
			
	 Возврашаем количество человек прописанных по лицевому 	 

	*/
	RETURN COALESCE(

	(SELECT
		COUNT(owner_id)
	FROM (SELECT
			p1.id AS owner_id
		FROM dbo.People AS p1 
		JOIN dbo.Occupations o 
			ON p1.occ = o.occ
		WHERE p1.occ = @occ1
			AND p1.Del = cast(0 as bit)
			AND o.fin_id = @fin_id
		UNION
		SELECT
			p2.owner_id
		FROM dbo.People_history AS p2 
		WHERE p2.fin_id = @fin_id
		AND p2.occ = @occ1
		) AS t
	), 0);

END
go

