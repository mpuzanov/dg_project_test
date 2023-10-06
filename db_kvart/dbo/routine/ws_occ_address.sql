-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	для веб-сервисов
-- =============================================
CREATE       PROCEDURE [dbo].[ws_occ_address] 
(
	@street_name1	VARCHAR(50)	= ''
	,@nom_dom1		VARCHAR(12)	= ''
	,@nom_kvr1		VARCHAR(20)	= ''
	,@is_json		BIT			= 0
)
/*
exec ws_occ_address '30 лет Победы ул.',33,99
exec ws_occ_address 'Барышникова ул.',3,0
*/
AS
BEGIN
	SET NOCOUNT ON;

	IF @is_json IS NULL
		SET @is_json = 0

	IF @is_json = 0
		SELECT 
			dbo.Fun_GetFalseOccOut(o.occ, o.tip_id) AS occ
		FROM dbo.Buildings b 
			JOIN dbo.VStreets s ON b.street_id=s.id
			JOIN dbo.Flats as f ON f.bldn_id=b.id
			JOIN dbo.OCCUPATIONS o ON o.flat_id=f.id
		WHERE (s.name LIKE @street_name1 + '%')
			AND b.nom_dom=@nom_dom1
			AND f.nom_kvr=@nom_kvr1

		--WHERE o.street_name=@street_name1 AND o.nom_dom=@nom_dom1
		--AND o.kol_counters>0
		--ORDER BY o.nom_kvr_sort
	ELSE
		SELECT 
			dbo.Fun_GetFalseOccOut(o.occ, o.tip_id) AS occ
		FROM dbo.Buildings b 
			JOIN dbo.VStreets s ON b.street_id=s.id
			JOIN dbo.Flats as f ON f.bldn_id=b.id
			JOIN dbo.OCCUPATIONS o ON o.flat_id=f.id
		WHERE (s.name LIKE @street_name1 + '%')
			AND b.nom_dom=@nom_dom1
			AND f.nom_kvr=@nom_kvr1
		FOR JSON PATH, ROOT('lics')
END
go

