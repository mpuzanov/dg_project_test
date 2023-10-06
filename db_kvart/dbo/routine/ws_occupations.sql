-- =============================================
-- Author:		Пузанов
-- Create date: 29.12.07
-- Description:	для веб-сервисов
-- =============================================
CREATE     PROCEDURE [dbo].[ws_occupations]
	(
	@occ INT = NULL,
	@bldn_id INT = NULL,
    @flat_id INT = NULL
	)

AS
	SET NOCOUNT ON;

	IF @occ = 0 SET @occ = NULL
	IF @bldn_id = 0 SET @bldn_id = NULL
	IF @flat_id = 0 SET @flat_id = NULL

    IF (@occ IS NULL) AND (@flat_id IS NULL) AND (@bldn_id IS NULL) RETURN

	SELECT  
	ROW_NUMBER() OVER (ORDER BY f.nom_kvr_sort) AS RowNumber,
	occ, 
	        jeu, 
	        schtl, 
	        flat_id, 
	        ot.name AS tip_name, 
	        roomtype_id,
			proptype_id, 
			status_id, 
			living_sq, 
			total_sq, 
			[address],
			f.telephon,
			dolg=(saldo-paid_old)
	FROM dbo.OCCUPATIONS AS o 
	     JOIN dbo.FLATS AS f ON o.flat_id=f.id
	     JOIN dbo.OCCUPATION_TYPES AS ot  ON o.tip_id=ot.id
	WHERE occ=CASE
		WHEN @occ IS NULL THEN occ
        ELSE @occ
	END
	AND f.bldn_id=CASE
		WHEN @bldn_id IS NULL THEN bldn_id
        ELSE @bldn_id
	END 
    AND flat_id=CASE
		WHEN @flat_id IS NULL THEN flat_id
        ELSE @flat_id
	END
	ORDER BY f.nom_kvr_sort

	RETURN
go

