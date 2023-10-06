CREATE   PROCEDURE [dbo].[rep_svod1]
(
	@tip	SMALLINT	= NULL
	,@jeu	SMALLINT	= NULL
)
AS
	/*
	Сводный отчет о числе человек в семье и среднем размере площади

	avg_total_sq.frf

	rep_svod1 28
	*/
	SET NOCOUNT ON

	SELECT
		*
		,CAST(100. * count_occ / SUM(count_occ) OVER () AS NUMERIC(5, 2)) AS proc_count_occ
	FROM (SELECT
			COALESCE(STR(o.kol_people, 3), '-') AS kol_people
			,AVG(o.TOTAL_SQ) AS avg_total_sq
			,COUNT(DISTINCT o.Occ) AS count_occ
		FROM dbo.VOcc AS o
		WHERE o.tip_id = COALESCE(@tip, o.tip_id)
		AND o.JEU = COALESCE(@jeu, o.JEU)
		AND o.STATUS_ID <> 'закр'
		GROUP BY o.kol_people
		) AS t
	ORDER BY kol_people
go

