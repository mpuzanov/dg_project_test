CREATE   FUNCTION [dbo].[Fun_Initials]
(
	  @occ1 INT
)
RETURNS VARCHAR(50)
AS
BEGIN
	/*
	инициалы квартиросьемщика

	Дата изменения: 04.04.04
	Автор изменения: Пузанов М.А.
	
	--  У неприватизированной квартиры если не стоит
	--  ответственный квартиросьемщик
	--  следующего человека не ставим !!!
	
	*/
	DECLARE @Initials VARCHAR(50)
		  , @proptype_id1 VARCHAR(10) -- тип квартиры 

	SELECT @proptype_id1 = o.proptype_id
		 , @Initials = CONCAT(RTRIM(p.[Last_name]),' ',LEFT(p.[First_name],1),'.',LEFT(p.Second_name,1),'.')
	FROM dbo.People AS p 
		JOIN dbo.Occupations AS o 
			ON p.Occ = o.Occ
	WHERE o.Occ = @occ1
		AND Fam_id = 'отвл'
		AND Del = 0

	IF (@Initials IS NULL)
		AND (@proptype_id1 <> 'непр')
	BEGIN
		SELECT TOP (1) @Initials = CONCAT(RTRIM([Last_name]),' ',LEFT([First_name],1),'.',LEFT(Second_name,1),'.')
		FROM dbo.People
		WHERE Occ = @occ1
			AND Del = 0
	END

	RETURN COALESCE(@Initials, '-')

END
go

