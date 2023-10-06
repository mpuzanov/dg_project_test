CREATE   FUNCTION [dbo].[Fun_PersonStatusStrAll]
(
	@tip_id		SMALLINT	= NULL
	,@build_id	INT			= NULL
	,@occ1		INT			= NULL
)
RETURNS VARCHAR(100)
AS
BEGIN
	/*
		
		Выдаем строку кол.людей по статусам прописок
		типа:  постоянно:2, временно:1
		по людям прописанным на данный момент в доме
		
		select [dbo].[Fun_PersonStatusStrAll](28,null,null)
	*/

	DECLARE @StrStatus VARCHAR(100) = ''

	IF @tip_id IS NULL
		AND @build_id IS NULL
		AND @occ1 IS NULL
		RETURN @StrStatus


	SET @StrStatus = STUFF((SELECT
			'; ' + LTRIM(ps.short_name) + ':' + LTRIM(STR(COUNT(p.id)))
		FROM dbo.PEOPLE AS p 
		JOIN dbo.PERSON_STATUSES AS ps 
			ON p.Status2_id = ps.id
		JOIN dbo.OCCUPATIONS AS o 
			ON p.occ = o.occ
		JOIN dbo.FLATS AS f 
			ON o.flat_id = f.id
		WHERE 1=1
			AND (@occ1 IS NULL OR p.occ = @occ1)
			AND p.Del = cast(0 as bit)
			AND (@tip_id IS NULL OR o.tip_id = @tip_id)
			AND (@build_id IS NULL OR f.bldn_id = @build_id)
		GROUP BY	ps.id_no
					,ps.short_name
		ORDER BY ps.id_no
		FOR XML PATH (''))
	, 1, 2, '')

	RETURN @StrStatus

END
go

