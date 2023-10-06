CREATE   PROCEDURE [dbo].[k_find_occ_address]
(
	@Street_name VARCHAR(50)
   ,@Nom_dom VARCHAR(12)
   ,@Nom_kvr VARCHAR(20) = NULL
   ,@town_name VARCHAR(30) = NULL
)
AS
/*
Поиск лицевого по адресу

EXEC k_find_occ_address @Street_name='Л.Толстого', @Nom_dom='3' ,@Nom_kvr='18'

*/
	SET NOCOUNT ON

	SELECT
		o.occ
	   ,f.nom_kvr
	   ,o.[address]
	   ,o.total_sq
	   ,o.status_id
	   ,o.flat_id
	FROM dbo.Occupations AS o
	JOIN dbo.Flats AS f
		ON o.flat_id = f.id
	JOIN dbo.Buildings AS b 
		ON f.bldn_id = b.id
	JOIN dbo.VStreets AS s
		ON b.street_id = s.id
	JOIN dbo.Towns as t ON t.ID=b.town_id
	WHERE (s.name=@Street_name or s.short_name=@Street_name or s.name_socr=@Street_name)
		AND b.nom_dom = @Nom_dom 
		AND (@Nom_kvr IS NULL OR f.nom_kvr = @Nom_kvr)
		AND (@town_name is null OR t.NAME=@town_name)
	ORDER BY f.nom_kvr_sort
go

