CREATE   FUNCTION [dbo].[Fun_InitialsFull]
(
	@occ1 INT
)
RETURNS VARCHAR(50)
AS
BEGIN
	/*
select [dbo].[Fun_InitialsFull](680000798)

инициалы квартиросьемщика  Полные Имя и Отчество

Дата изменения: 19.05.08
Автор изменения: Пузанов М.А.

  У неприватизированной квартиры если не стоит
  ответственный квартиросьемщик
  следующего человека не ставим !!!

*/

	DECLARE @Initials	  VARCHAR(50)
		   ,@proptype_id1 VARCHAR(10) -- тип квартиры 

	SELECT
		@proptype_id1 = o.PROPTYPE_ID
	   ,@Initials = CONCAT(RTRIM([Last_name]), ' ', RTRIM([First_name]), ' ', RTRIM([Second_name]))
	FROM dbo.Occupations AS o
	LEFT JOIN dbo.People AS p ON 
		p.occ = o.occ
		AND p.Fam_id = 'отвл'
		AND p.Del = CAST(0 AS BIT)
	WHERE o.occ = @occ1


	IF (@Initials IS NULL)
		AND (@proptype_id1 <> 'непр')
	BEGIN
		SELECT TOP 1
			@Initials = CONCAT(RTRIM([Last_name]), ' ', RTRIM([First_name]), ' ', RTRIM([Second_name]))
		FROM dbo.People 
		WHERE 
			occ = @occ1
			AND Del = CAST(0 AS BIT)
			AND Dola_priv1 > 0
		ORDER BY Dola_priv1 DESC
	END

	RETURN CASE
               WHEN COALESCE(@Initials, '') = '' THEN '-'
               ELSE @Initials
        END;

END
go

