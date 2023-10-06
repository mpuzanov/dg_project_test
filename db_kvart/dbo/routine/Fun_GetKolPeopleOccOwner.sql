CREATE   FUNCTION [dbo].[Fun_GetKolPeopleOccOwner]
(
   @occ1   INT
)
RETURNS SMALLINT
AS
BEGIN
	/*
	select [dbo].[Fun_GetKolPeopleOccOwner](680003665)
			
	 Возврашаем количество собственников по лицевому счёту

	*/
	
	RETURN COALESCE(
		(SELECT
			COUNT(p.id)
		FROM dbo.People AS p 
		WHERE p.occ = @occ1
		AND p.Del = cast(0 as bit)
		AND p.Dola_priv1 IS NOT NULL)
	, 0)

END
go

