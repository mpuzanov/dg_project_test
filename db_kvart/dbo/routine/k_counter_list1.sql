CREATE   PROCEDURE [dbo].[k_counter_list1]
(
	@counter_id1	INT -- код счетчика
	,@build_id1		INT
	,@flat_id1		INT			= NULL
	,@fin_id1		SMALLINT	= NULL
)
AS
/*
	Список лицевых в доме у кого нет данного счетчика

*/
	SET NOCOUNT ON;

	IF @fin_id1 IS NULL
		SELECT
			@fin_id1 = dbo.Fun_GetFinCurrent(NULL, @build_id1, @flat_id1, NULL);

	IF (@flat_id1 = 0)
		SET @flat_id1 = NULL;

	SELECT
		o.occ
		,CONCAT(RTRIM(O1.address),' (',dbo.Fun_Initials(O.occ), ')') AS decription
	FROM dbo.View_occ_all_lite AS o 
	JOIN dbo.Occupations O1 
		ON o.occ = O1.occ
	WHERE 
		o.bldn_id = @build_id1
		AND NOT EXISTS (SELECT	1
			FROM dbo.View_counter_all
			WHERE counter_id = @counter_id1
			AND fin_id = @fin_id1
			AND occ = o.occ
			)
		AND (@flat_id1 IS NULL OR o.flat_id = @flat_id1)
		AND o.fin_id = @fin_id1
		AND (o.status_id <> 'закр' AND o.total_sq<>0)
	ORDER BY o.nom_kvr_sort;
go

