-- =============================================
-- Author:		Пузанов
-- Create date: 25.08.2008
-- Description:	Возвращает адрес дома по коду
-- =============================================
CREATE             FUNCTION [dbo].[Fun_GetAdres]
(
	  @build_id INT = NULL
	, @flat_id INT = NULL
	, @occ INT = NULL
)
RETURNS VARCHAR(60)
AS
/*
select dbo.Fun_GetAdres(6801,82164,910003055) as address
select dbo.Fun_GetAdres(6801,82402,910003288) as address
select dbo.Fun_GetAdres(6801,82402,NULL) as address
select dbo.Fun_GetAdres(1031,NULL,NULL) as address
*/
BEGIN
	DECLARE @StrAdres VARCHAR(60) = ''
		  , @nom_kvr VARCHAR(20) = ''
		  , @prefix VARCHAR(7) = ''
		  , @name_kvit VARCHAR(10) = 'кв.'

	SELECT TOP(1)
		@StrAdres= 
		CASE
			WHEN tw.prefix IS NOT NULL AND
				tw.NAME IS NOT NULL THEN CONCAT(tw.prefix , '' , tw.NAME , ', ' , s.socr_name , ', д.' , b.nom_dom)
			WHEN tw.NAME IS NOT NULL THEN CONCAT(tw.NAME , ', ' , s.socr_name , ', д.' , b.nom_dom)
			ELSE CONCAT(s.socr_name , ', д.' , b.nom_dom)
		END
		, @nom_kvr= CASE
                        WHEN @flat_id is NULL AND @occ IS NULL THEN ''
                        ELSE f.nom_kvr
        END
		,@prefix = COALESCE(LTRIM(O.prefix), '')
		,@name_kvit = rt.name_kvit
	FROM dbo.Buildings AS b 
		JOIN dbo.VStreets AS s 
			ON b.street_id = s.id
		LEFT JOIN dbo.Towns AS tw 
			ON s.town_id = tw.id
		LEFT JOIN dbo.Flats AS f 
			ON b.id = f.bldn_id
		LEFT JOIN dbo.Occupations O 
			ON o.flat_id=f.id
		LEFT JOIN dbo.Room_types AS rt 
			ON O.roomtype_id = rt.id
	WHERE (1=1)
		AND (@build_id IS NULL OR b.id = @build_id)
		AND (@flat_id IS NULL OR f.id=@flat_id)
		AND (@occ IS NULL OR o.occ=@occ)

	IF @prefix <> ''
	BEGIN
		IF LEFT(@prefix, 1) = '&'
		BEGIN
			SELECT @nom_kvr = REPLACE(@prefix, '&', '')
				 , @flat_id = NULL
				 , @occ = NULL
		END
	END

	IF @occ IS NOT NULL
	BEGIN
		SELECT @nom_kvr = CONCAT(@nom_kvr, @prefix)
	END

	IF @nom_kvr NOT IN ('', '-')
		SET @StrAdres = CONCAT(@StrAdres,', ', COALESCE(@name_kvit,''), @nom_kvr)

	RETURN @StrAdres

END
go

