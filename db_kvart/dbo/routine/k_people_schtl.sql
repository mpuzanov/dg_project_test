CREATE   PROCEDURE [dbo].[k_people_schtl]
(
	  @occ1 INT
	, @peoplecount SMALLINT = 0 OUTPUT
)
AS
	/*

  Список зарегистрированных людей на лицевом

дата: 25.12.04
добавил: Initials

EXEC k_people_schtl @occ1=289015
*/
	SET NOCOUNT ON

	SELECT p.id
		 , p.Last_name
		 , p.First_name
		 , p.Second_name
		 , p.Doxod
		 , p.Status2_id
		 , p.Fam_id
		 , CASE
               WHEN p.lgota_id <> 0 THEN p.lgota_id
               ELSE NULL
           END AS lgota_id
		 , p.Birthdate
		 , p.Initials_people AS Initials
		 , dbo.Fun_GetBetweenDateYear(p.Birthdate, current_timestamp) AS Age -- кол-во лет человеку
		 , CASE
               WHEN Dola_priv1 > 0 THEN CONCAT(LTRIM(STR(Dola_priv1)), '/', LTRIM(STR(COALESCE(Dola_priv2, 1))))
               ELSE ''
           END AS Dola_priv_str
		 , p.is_owner_flat
		 , p.DateEnd
		 , p.sex
		 , p.DateReg
		 , P.Contact_info
	FROM dbo.VPeople AS p 
		LEFT OUTER JOIN dbo.Fam_relations AS fam ON p.Fam_id = fam.id
	WHERE p.occ = @occ1
		AND Del = CAST(0 AS BIT)
	ORDER BY fam.id_no
		   , p.id

	SELECT @peoplecount = @@rowcount
go

