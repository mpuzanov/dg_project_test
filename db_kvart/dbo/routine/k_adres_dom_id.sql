CREATE   PROCEDURE [dbo].[k_adres_dom_id]
(
	@tip_id	   SMALLINT = NULL
   ,@build_id1 INT		= NULL
)
AS
	/*
	  Список лицевых по дому
	*/
	SET NOCOUNT ON

	IF @tip_id IS NULL
		AND @build_id1 IS NULL
		SELECT
			@tip_id = 0
		   ,@build_id1 = 0

	SELECT
		o.OCC
	   ,o.address
	   ,ROOMTYPE_ID
	   ,proptype_id
	   ,Total_sq
	   ,[floor]
	   ,o.ROOMS
	   ,b.id AS build_id
	   ,t.name AS tipname
	   ,approach
	FROM dbo.OCCUPATIONS AS o
	JOIN dbo.FLATS AS f 
		ON o.flat_id = f.id
	JOIN dbo.BUILDINGS AS b
		ON b.id = f.bldn_id
	JOIN dbo.VOCC_TYPES AS t
		ON b.tip_id = t.id
	WHERE 1=1
		AND (@tip_id IS NULL OR o.tip_id = @tip_id)
		AND (@build_id1 IS NULL OR b.id = @build_id1)
	ORDER BY f.nom_kvr_sort
go

