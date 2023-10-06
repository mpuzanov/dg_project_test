-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	для веб-сервисов
-- =============================================
CREATE     PROCEDURE [dbo].[ws_flats] 
(
	@street_name1	VARCHAR(50)	= ''
	,@nom_dom1		VARCHAR(12)	= ''
	,@is_json		BIT			= 0
)
/*
exec ws_flats '30 лет Победы ул.',33,0
exec ws_flats 'Барышникова ул.',3,0
*/
AS
BEGIN
	SET NOCOUNT ON;

	IF @is_json IS NULL
		SET @is_json = 0

	IF @is_json = 0
		SELECT 
			f.nom_kvr
		FROM dbo.Buildings b
		JOIN dbo.VStreets s ON b.street_id=s.id
		JOIN dbo.Flats as f ON f.bldn_id=b.id
		WHERE (s.name LIKE @street_name1 + '%')
			AND b.nom_dom=@nom_dom1
		ORDER BY f.nom_kvr_sort

		--WHERE o.street_name=@street_name1 AND o.nom_dom=@nom_dom1
		--AND o.kol_counters>0
		--ORDER BY o.nom_kvr_sort
	ELSE
		SELECT 
			f.nom_kvr
		FROM dbo.Buildings b
		JOIN dbo.VStreets s ON b.street_id=s.id
		JOIN dbo.Flats as f ON f.bldn_id=b.id
		WHERE (s.name LIKE @street_name1 + '%')
			AND b.nom_dom=@nom_dom1
		ORDER BY f.nom_kvr_sort
		FOR JSON PATH, ROOT('flats')
END
go

