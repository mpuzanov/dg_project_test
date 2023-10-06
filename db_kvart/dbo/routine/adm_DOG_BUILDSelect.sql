CREATE   PROC [dbo].[adm_DOG_BUILDSelect]
	@dog_int	INT
	,@fin_id	SMALLINT
	,@build_id	INT	= NULL
AS
	SET NOCOUNT ON

	SELECT
		[dog_int]
		,[fin_id]
		,[build_id]
		,b.is_paym_build
	FROM [dbo].[Dog_build] AS db 
	JOIN dbo.Buildings AS b 
		ON db.build_id = b.id
	JOIN dbo.Streets AS s 
		ON b.street_id = s.id
	WHERE ([dog_int] = @dog_int)
		AND ([fin_id] = @fin_id)
		AND ([build_id] = @build_id
		OR @build_id IS NULL)
	ORDER BY s.name, b.nom_dom_sort
go

