CREATE   PROCEDURE [dbo].[adm_ulica]
(
	@tip_id		SMALLINT	= NULL
	,@town_id	SMALLINT	= NULL
)
AS
	SET NOCOUNT ON
	IF @tip_id = 0
		SET @tip_id = NULL
	IF @town_id IS NULL
		SET @town_id = NULL

	SELECT
		s.id
		,s.name AS name
		,s.code
		,s.town_id
		,s.prefix
		,s.full_name
		,s.full_name2
		,s.kod_fias		
		,t_build.cnt as count_build
	FROM dbo.Streets AS s 
		CROSS APPLY (SELECT COUNT(Id) as cnt FROM dbo.Buildings b  WHERE b.street_id=s.id) as t_build
	WHERE (@town_id IS NULL OR s.town_id = @town_id)
	ORDER BY name
go

