CREATE   PROCEDURE [dbo].[adm_showbuild_lic]
(
	@bldn_id1 INT
   ,@fin_id1  SMALLINT = NULL
)
AS
	/*
	Список лицевых по дому
	
	*/
	SET NOCOUNT ON

	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, @bldn_id1, NULL, NULL)

	IF @fin_id1 IS NULL
		SELECT
			@fin_id1 = @fin_current

	IF @fin_id1 = @fin_current

		SELECT
			o.occ
		   ,o.address as [address]
		   ,o.TOTAL_SQ
		   ,o.LIVING_SQ
		   ,o.status_id
		   ,ROOMTYPE_ID
		   ,PROPTYPE_ID
		   ,f.floor
		   ,f.rooms
		   ,f.nom_kvr
		   ,dbo.Fun_Initials(o.occ) AS Initials
		   ,kol_people AS KolPeople
		   ,@fin_id1 as fin_id
		FROM dbo.Occupations AS o                     -- Чтобы можно было редактировать (напр. площадь)
		JOIN dbo.Flats AS f
			ON o.flat_id = f.id
		WHERE 
			f.bldn_id = @bldn_id1
		ORDER BY f.nom_kvr_sort

	ELSE

		SELECT
			o.occ
		   ,dbo.Fun_GetAdres(o.bldn_id, f.id, o.occ) AS [address]
		   ,o.TOTAL_SQ
		   ,o.LIVING_SQ
		   ,o.status_id
		   ,ROOMTYPE_ID
		   ,PROPTYPE_ID
		   ,f.floor
		   ,f.rooms
		   ,f.nom_kvr
		   ,dbo.Fun_Initials(o.occ) AS Initials
		   ,kol_people AS KolPeople
		   ,o.fin_id
		FROM dbo.View_occ_all AS o
		JOIN dbo.Flats AS f
			ON o.flat_id = f.id
		WHERE 
			o.bldn_id = @bldn_id1
			AND o.fin_id = @fin_id1
			AND o.bldn_id = @bldn_id1
		ORDER BY f.nom_kvr_sort
go

