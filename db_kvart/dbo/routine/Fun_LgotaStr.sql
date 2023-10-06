CREATE   FUNCTION [dbo].[Fun_LgotaStr]
(
	@occ1 INT
)
RETURNS VARCHAR(50)
AS
BEGIN
	/*
	Функция выдает строку льгот на лицевом     типа:   22-1,1-2, 2-1
	по людям прописанным на данный момент

	select [dbo].[Fun_LgotaStr](230118)
	select [dbo].[Fun_LgotaStr](230119)
	
	*/
	DECLARE @strLgota VARCHAR(50) = '-'

	SELECT
		@strLgota = STUFF((SELECT
				',' + LTRIM(STR(Lgota_id)) + '-' + LTRIM(STR(COUNT(Lgota_id)))
			FROM dbo.PEOPLE
			WHERE occ = @occ1
			AND Lgota_id <> 0
			AND Del = 0
			GROUP BY Lgota_id
			FOR XML PATH (''))
		, 1, 1, '')

	RETURN COALESCE(@strLgota,'-')

END
go

