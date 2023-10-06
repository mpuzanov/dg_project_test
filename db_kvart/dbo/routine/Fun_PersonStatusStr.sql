CREATE   FUNCTION [dbo].[Fun_PersonStatusStr]
(
	@occ1 INT
)
RETURNS VARCHAR(80)
AS
BEGIN
	/*
		Выдаем строку кол.людей по статусам прописок
		типа:  постоянно:2, временно:1
		по людям прописанным на данный момент
		
		select [dbo].[Fun_PersonStatusStr](680000005)
	*/
	DECLARE @StrStatus VARCHAR(80)
	SELECT
		@StrStatus = STUFF((SELECT
				'; ' + LTRIM(ps.short_name) + ':' + LTRIM(STR(COUNT(p.id)))
			FROM dbo.People AS p 
			JOIN dbo.Person_statuses AS ps 
				ON p.Status2_id = ps.id
			WHERE p.occ = @occ1
				AND p.Del = cast(0 as bit)
				AND ps.is_paym = cast(1 as bit)  -- добавил 22.04.2021
			GROUP BY ps.id_no
					,ps.short_name
			ORDER BY ps.id_no
			FOR XML PATH (''))
		, 1, 2, '')

	RETURN @StrStatus

END
go

