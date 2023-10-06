CREATE   FUNCTION [dbo].[Fun_GetCountPeopleOcc]
(
	@fin_id1 smallint,
	@occ1 int
)
RETURNS TABLE
AS
/*
select * from [dbo].[Fun_GetCountPeopleOcc](200,680002938)
*/
RETURN
	SELECT
		p.fin_id
	   ,p.occ
	   ,CAST(COALESCE(SUM(CASE
                              WHEN ps.is_kolpeople = 1 THEN 1
                              ELSE 0
        END), 0) AS SMALLINT)         AS kol_live
	   ,CAST(COALESCE(SUM(CASE
                              WHEN ps.is_registration = 1 THEN 1
                              ELSE 0
        END), 0) AS SMALLINT)         AS kol_registration
	   ,CAST(COUNT(p.id) AS SMALLINT) AS kol_itogo
	   ,CAST(COALESCE(SUM(CASE
                              WHEN p.dola_priv1 IS NOT NULL OR p.is_owner_flat = 1 THEN 1
                              ELSE 0
        END), 0) AS SMALLINT)         AS kol_owner
	FROM dbo.View_PEOPLE_ALL AS p
		JOIN dbo.PERSON_STATUSES AS ps ON p.Status2_id = ps.id
	WHERE p.fin_id = @fin_id1
	AND p.occ = @occ1
	GROUP BY p.fin_id
			,p.occ
go

