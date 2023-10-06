CREATE   PROCEDURE [dbo].[rep_modes_source]
(
	@service_id1	VARCHAR(10)
	,@mode_id1		INT			= NULL
	,@source_id1	INT			= NULL
	,@jeu_id1		SMALLINT	= NULL
	,@build1		INT			= NULL
	,@tip_id1		SMALLINT	= NULL
	,@div_id1		SMALLINT	= NULL
)
AS
/*
	-- Выдает список лицевых с заданными режимами потребления и поставщика
	-- modes_source.fr3
	--
	rep_modes_source 'площ', 1001
*/
	SET NOCOUNT ON


	IF @mode_id1 IS NULL
		AND @source_id1 IS NULL
	BEGIN
		RAISERROR ('Задайте режим или поставщика!', 16, 1)
		RETURN
	END


	SELECT
		c1.Occ
		,c1.mode_id
		,c1.service_id
		,c2.Name AS mode_name
		,c1.source_id
		,c3.Name AS source_name
		,o.address
		,b.sector_id
		,b.div_id
	FROM dbo.CONSMODES_LIST AS c1 
	JOIN dbo.CONS_MODES AS c2 
		ON c2.id = c1.mode_id
	JOIN dbo.View_SUPPLIERS AS c3 
		ON c3.id = c1.source_id
	JOIN dbo.VOCC AS o 
		ON c1.Occ = o.Occ
	JOIN dbo.BUILDINGS AS b 
		ON o.bldn_id = b.id
	JOIN dbo.VSTREETS AS s 
		ON b.street_id = s.id
	WHERE o.STATUS_ID <> 'закр'
	AND c1.service_id = @service_id1
	AND c1.mode_id = COALESCE(@mode_id1, c1.mode_id)
	AND c1.source_id = COALESCE(@source_id1, c1.source_id)
	AND b.sector_id = COALESCE(@jeu_id1, b.sector_id)
	AND b.id = COALESCE(@build1, b.id)
	AND b.tip_id = COALESCE(@tip_id1, b.tip_id)
	AND b.div_id = COALESCE(@div_id1, b.div_id)
	ORDER BY s.Name,
		b.nom_dom_sort,
		o.nom_kvr_sort
go

