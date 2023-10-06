CREATE   PROCEDURE [dbo].[k_address_OPS]
(
	@index_id  INT		= NULL
   ,@street_id INT		= NULL
   ,@dom_id	   INT		= NULL
   ,@town_id   SMALLINT = NULL
)
/*

используется в:	dprint

*/
AS
	SET NOCOUNT ON

	SELECT
		b.ID
	   ,concat(b.town_name , ',' , s.name , ' д. ' , b.nom_dom , ', ' , b.tip_name) AS dom
	   ,s.name AS street
	   ,b.nom_dom AS nom_dom
	   ,b.index_id
	   ,OPS.name AS OPS
	   ,b.town_name AS town_name
	FROM dbo.VSTREETS AS s
		JOIN dbo.View_BUILDINGS AS b
			ON s.ID = b.street_id
		JOIN dbo.OPS
			ON OPS.ID = b.index_id
	WHERE 1=1
		AND (@index_id IS NULL OR b.index_id = @index_id)
		AND (@street_id IS NULL OR b.street_id = @street_id)
		AND (@dom_id IS NULL OR b.ID = @dom_id)
		AND (@town_id IS NULL OR b.town_id = @town_id)
	ORDER BY s.name
	, b.nom_dom_sort
go

