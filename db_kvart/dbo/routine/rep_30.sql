CREATE   PROCEDURE [dbo].[rep_30]
--WEB-- Ведомость "Информация по лицевым счетам"
(
	@fin_id	 SMALLINT = NULL
   ,@tip	 SMALLINT = NULL
   ,@jeu	 SMALLINT = NULL
   ,@bldn_id INT	  = NULL
)
AS
	/*
	используется в отчете  rep30.fr3
	
	*/
	SET NOCOUNT ON


	IF @fin_id IS NULL
		SELECT
			@fin_id = dbo.Fun_GetFinCurrent(@tip, @bldn_id, NULL, NULL)

	IF @tip IS NULL
		AND @jeu IS NULL
		AND @bldn_id IS NULL
		SET @tip = 0

	SELECT
		o.occ
	   ,o1.address
	   ,o.roomtype_id
	   ,o.proptype_id
	   ,o.living_sq
	   ,o.total_sq
	   ,o.floor
	   ,o1.Rooms
	   ,o.kol_people AS Kolpeople
	   ,o1.telephon
	   ,NULL AS Kollgota
	FROM dbo.View_occ_all AS o 
	JOIN dbo.Buildings AS b 
		ON o.bldn_id = b.id
	JOIN dbo.VStreets AS s 
		ON b.street_id = s.id
	JOIN dbo.Occupations AS o1 
		ON o.occ = o1.occ
	WHERE (b.sector_id = @jeu
	OR @jeu IS NULL)
	AND (o.fin_id = @fin_id
	OR @fin_id IS NULL)
	AND o.status_id <> 'закр'
	AND (b.id = @bldn_id
	OR @bldn_id IS NULL)
	AND (b.tip_id = @tip
	OR @tip IS NULL)
	ORDER BY s.Name, b.nom_dom_sort, o.nom_kvr_sort
go

