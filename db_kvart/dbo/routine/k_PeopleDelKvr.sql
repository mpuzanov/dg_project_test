CREATE   PROCEDURE [dbo].[k_PeopleDelKvr]
(
	@flat_id1  INT -- код квартиры
   ,@is_listok BIT = 0 -- из листков прибытия
)
AS
	/*
		Список людей выписанных из этой квартиры
	*/
	SET NOCOUNT ON

	IF @is_listok IS NULL
		SET @is_listok = 0

	IF @is_listok = 0
	BEGIN
		SELECT
			p.id
		   ,p.last_name
		   ,p.first_name
		   ,p.second_name
		   ,p.birthdate
		   ,p.DateDel
		   ,p.Lgota_id
		FROM dbo.OCCUPATIONS AS o 
		JOIN dbo.PEOPLE AS p 
			ON o.occ = p.occ
		WHERE o.flat_id = @flat_id1
		AND p.Del = 1
		ORDER BY p.DateDel DESC
	END

	IF @is_listok = 1
	BEGIN
		SELECT
			p.id
		   ,p.last_name
		   ,p.first_name
		   ,p.second_name
		   ,p.birthdate
		   ,p.occ
		   ,p.DateCreate
		FROM dbo.OCCUPATIONS AS o 
		JOIN dbo.PEOPLE_LISTOK AS p ON o.occ = p.occ
		WHERE o.flat_id = @flat_id1
		AND p.listok_id = 1
		ORDER BY p.DateDel DESC
	END
go

