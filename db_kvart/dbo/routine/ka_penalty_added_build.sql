CREATE   PROCEDURE [dbo].[ka_penalty_added_build]
(
	  @build_id1 INT
	  ,@fin_id1 SMALLINT = NULL
	  ,@fin_id2 SMALLINT = NULL
)
AS
	/*
	Показываем Разовые по пени по дому

	exec ka_penalty_added_build @build_id1=6840, @fin_id1=232, @fin_id2=233
	exec ka_penalty_added_build @build_id1=6788, @fin_id1=232

	SELECT * FROM dbo.Peny_added pa ORDER BY pa.fin_id DESC

	*/

	SET NOCOUNT ON


	DECLARE @fin_current SMALLINT = dbo.Fun_GetFinCurrent(NULL, @build_id1, NULL, NULL)
	
	IF @fin_id1 = 0
		OR @fin_id1 IS NULL
		SET @fin_id1 = @fin_current
	IF @fin_id2 = 0
		OR @fin_id2 IS NULL
		SET @fin_id2 = @fin_current


	SELECT cp.StrFinPeriod
		 , pa.occ AS occ
		 , pa.value_added
		 , pa.doc AS doc
		 , u.Initials AS Initials
		 , pa.date_edit
		 , pa.fin_id AS fin_id
		 , pa.finPeriods
		 , f.nom_kvr
	FROM dbo.Peny_added pa
		JOIN dbo.Users AS u ON 
			pa.user_edit = u.login
		JOIN dbo.Calendar_period cp ON 
			cp.fin_id = pa.fin_id
		JOIN dbo.Peny_all AS pal ON 
			pal.occ=pa.occ 
			AND pal.fin_id=pa.fin_id
		JOIN dbo.Occupations AS o ON 
			o.occ=pal.occ1
		JOIN dbo.Flats AS f ON 
			f.id=o.flat_id
	WHERE 
		f.bldn_id = @build_id1
		AND (pa.fin_id BETWEEN @fin_id1 AND @fin_id2)
	ORDER BY pa.fin_id DESC
		, f.nom_kvr_sort
go

