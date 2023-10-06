/*
-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	для веб-сервисов
-- =============================================
*/
CREATE       PROCEDURE [dbo].[ws_builds] 
(
	@street_name1	VARCHAR(50)	= ''
	,@is_json		BIT			= 0
)
/*
exec ws_builds '',0
exec ws_builds '30 лет Победы ул.'
exec ws_builds 'Барышникова'
*/
AS
BEGIN
	SET NOCOUNT ON;

	IF @is_json IS NULL
		SET @is_json = 0

	IF @is_json = 0
		SELECT 
			b.nom_dom
		FROM dbo.Buildings b
		JOIN dbo.VStreets s ON 
			b.street_id=s.id
		WHERE (s.name LIKE @street_name1 + '%')
		ORDER BY b.nom_dom_sort
	ELSE
		SELECT 
			b.nom_dom
		FROM dbo.Buildings b
		JOIN dbo.VStreets s ON 
			b.street_id=s.id
		WHERE (s.name LIKE @street_name1 + '%')
		ORDER BY b.nom_dom_sort
		FOR JSON PATH, ROOT ('Buildings')
END
go

