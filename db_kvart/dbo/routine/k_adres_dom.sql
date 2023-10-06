CREATE   PROCEDURE [dbo].[k_adres_dom]
(
	@Street_id1 INT
   ,@Nom_dom	VARCHAR(12)
)
AS
	--
	--  Список лицевых по дому
	--
	SET NOCOUNT ON

	SELECT
		o.OCC
	   ,o.address
	   ,ROOMTYPE_ID
	   ,proptype_id
	   ,Total_sq
	   ,[floor]
	   ,o.ROOMS
	   ,b.id AS build_id
	FROM dbo.Occupations AS o
		JOIN dbo.Flats AS f
			ON f.id = o.flat_id
		JOIN dbo.Buildings AS b
			ON b.id = f.bldn_id
	WHERE 1=1
		AND b.street_id = @Street_id1
		AND b.nom_dom = @Nom_dom
go

