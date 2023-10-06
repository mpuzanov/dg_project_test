CREATE   FUNCTION [dbo].[Fun_Initials_All]
(
	@occ1 INT
)
RETURNS VARCHAR(50)

AS
/*

Инициалы квартиросьемщика

Дата изменения: 10.06.08
Автор изменения: Пузанов М.А.

*/

BEGIN

	DECLARE @Initials VARCHAR(50)

	SELECT
		@Initials = CONCAT(RTRIM(p.[Last_name]),' ',LEFT(p.[First_name],1),'.',LEFT(p.Second_name,1),'.')
	FROM People AS p
	WHERE 
		p.occ = @occ1
		AND Fam_id = 'отвл'
		AND Del = 0;

	RETURN CASE
               WHEN COALESCE(@Initials, '') = '' THEN '-'
               ELSE @Initials
        END;

END
go

