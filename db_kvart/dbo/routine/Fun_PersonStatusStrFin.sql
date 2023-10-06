CREATE   FUNCTION [dbo].[Fun_PersonStatusStrFin]
(
	  @occ1 INT
	, @fin_id SMALLINT = NULL
)
RETURNS VARCHAR(80)
AS
BEGIN
	/*
		Выдаем строку кол.людей по статусам прописок
		типа:  постоянно:2, временно:1
		по людям прописанным на данный момент
			
		select [dbo].[Fun_PersonStatusStrFin](680000005, NULL)
		select [dbo].[Fun_PersonStatusStrFin](680000005, 175)
	*/
	DECLARE @StrStatus VARCHAR(80) = ''

	IF @fin_id IS NULL
		SELECT @StrStatus = STUFF((
				SELECT '; ' + LTRIM(ps.short_name) + ':' + LTRIM(STR(COUNT(p.id)))
				FROM dbo.People AS p 
					JOIN dbo.Person_statuses AS ps
						ON p.status2_id = ps.id
				WHERE p.Occ = @occ1
					AND p.Del = cast(0 as bit)
				GROUP BY ps.id_no
					   , ps.short_name
				ORDER BY ps.id_no
				FOR XML PATH ('')
			), 1, 2, '')
	ELSE
		SELECT @StrStatus = STUFF((
				SELECT '; ' + LTRIM(ps.short_name) + ':' + LTRIM(STR(COUNT(p.id)))
				FROM dbo.People AS p 
					JOIN dbo.Person_statuses AS ps
						ON p.status2_id = ps.id
					JOIN dbo.People_history ph 
						ON ph.Occ = p.Occ
						AND ph.owner_id = p.id
				WHERE p.Occ = @occ1
					AND ph.fin_id = @fin_id
				GROUP BY ps.id_no
					   , ps.short_name
				ORDER BY ps.id_no
				FOR XML PATH ('')
			), 1, 2, '')

	RETURN @StrStatus

END
go

