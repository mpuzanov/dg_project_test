CREATE   PROCEDURE [dbo].[k_adres_people]
(
	@code1	 BIGINT -- код улицы по налоговому классификатору
   ,@Nom_dom VARCHAR(12)
   ,@Nom_kvr VARCHAR(20) = NULL
)
AS
	--
	--  Список Людей в квартире
	--
	SET NOCOUNT ON

	SELECT
		o.occ
	   ,f.nom_kvr
	   ,p.Last_name
	   ,p.First_name
	   ,p.Second_name
	   ,p.Birthdate
	   ,p.Fam_id
	   ,DOCTYPE_ID
	   ,DOC_NO
	   ,PASSSER_NO
	   ,ISSUED
	   ,DOCORG
	   ,p.sex
	   ,p.DateReg
	   ,p.Status2_id
	   ,p.Status_id
	   ,ps.is_subs
	   ,ps.is_lgota
	FROM dbo.Occupations AS o 
	JOIN dbo.Flats AS f 
		ON o.flat_id = f.id
	JOIN dbo.Buildings AS b
		ON f.bldn_id = b.id
	JOIN dbo.VStreets AS s 
		ON b.street_id = s.id
	JOIN dbo.People AS p 
		ON o.occ = p.occ
	JOIN dbo.Person_statuses AS ps 
		ON ps.id = p.Status2_id
	LEFT JOIN Iddoc AS doc -- выдаем паспорт если есть
		ON p.id = doc.owner_id
		AND doc.active = 1
	WHERE s.code = @code1
	AND b.nom_dom = @Nom_dom
	AND (f.nom_kvr = @Nom_kvr
	OR @Nom_kvr IS NULL)
	AND p.Del = 0
	ORDER BY f.nom_kvr_sort
go

