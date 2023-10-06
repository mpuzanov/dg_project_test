CREATE   PROCEDURE [dbo].[rep_people_id]
(
	@id1 INT
)
AS
	/*

	exec rep_people_id 13404
				
	*/
	SET NOCOUNT ON

	SELECT
		p.*
		, CASE
              WHEN t.region_short IS NOT NULL THEN CONCAT(t.region_short , ',' , o.address)
              ELSE o.address
        END  AS Adres
		,dbo.Fun_padeg_fio(Last_name, First_name, Second_name, 'Д', CASE
                                                                        WHEN p.sex = 1 THEN 'МУЖ'
                                                                        ELSE CASE
                                                                                 WHEN p.sex = 0 THEN 'ЖЕН'
                                                                                 ELSE NULL
                                                                            END
        END) AS FIOdat
	FROM dbo.PEOPLE AS p 
	JOIN dbo.OCCUPATIONS AS o 
		ON p.occ = o.occ
	JOIN dbo.FLATS f 
		ON o.flat_id = f.Id
	JOIN dbo.BUILDINGS b 
		ON f.bldn_id = b.Id
	JOIN TOWNS t 
		ON b.town_id = t.Id
	WHERE p.Id = @id1
go

