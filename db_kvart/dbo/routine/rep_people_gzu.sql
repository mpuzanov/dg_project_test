CREATE   PROCEDURE [dbo].[rep_people_gzu]
(
	@tip_id SMALLINT   = NULL
   ,@div_id SMALLINT   = NULL
   ,@dom1   INT		   = NULL
   ,@kv1	VARCHAR(7) = NULL
)
/*
--
-- Выдаем список прописаных людей по улице или дому или квартире
--
exec rep_people_gzu 28
exec rep_people_gzu 179
*/
AS
	SET NOCOUNT ON


	IF @tip_id IS NULL
		AND @dom1 IS NULL
		SET @tip_id = 0

	IF @kv1 = ''
		SET @kv1 = NULL

	SELECT
		b.street_name
	   ,b.nom_dom
	   ,f.nom_kvr
	   ,p.occ
	   ,p.Last_name
	   ,p.First_name
	   ,p.Second_name
	   ,p.DateReg
	   ,fam.name AS fam_name
	   ,p.Birthdate
	   ,p.status2_id
	   ,status_reg = ps.name
	   ,o.living_sq
	   ,o.Total_sq
	   ,b.id AS build_id
	   ,p.id
	FROM dbo.[View_BUILDINGS] AS b 
	JOIN dbo.FLATS AS f 
		ON f.bldn_id = b.id
	JOIN dbo.VOCC AS o 
		ON o.flat_id = f.id
	JOIN dbo.PEOPLE AS p 
		ON p.occ = o.occ
	LEFT JOIN dbo.FAM_RELATIONS AS fam 
		ON fam.id = p.Fam_id
	LEFT JOIN dbo.PERSON_STATUSES AS ps 
		ON p.status2_id = ps.id
	WHERE (b.tip_id = @tip_id
	OR @tip_id IS NULL)
	AND (b.div_id = @div_id
	OR @div_id IS NULL)
	AND (b.id = @dom1
	OR @dom1 IS NULL)
	AND (f.nom_kvr = @kv1
	OR @kv1 IS NULL)
	AND o.status_id <> 'закр'
	AND p.Del = 0
	ORDER BY b.street_name
	, b.nom_dom_sort
	, f.nom_kvr_sort
go

