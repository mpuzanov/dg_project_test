CREATE   PROCEDURE [dbo].[rep_pay_4]
(
	  @date1 DATETIME
	, @date2 DATETIME
	, @tip SMALLINT
	, @div_id SMALLINT = NULL
	, @build INT = NULL
	, @sup_id INT = NULL
)
AS
	/*
		Ежедневный отчет по поступлениям за ЖКУ по участкам
	*/

	SET NOCOUNT ON


	SELECT d.name AS div
		 , b.sector_id
		 , s.name AS name_jeu
		 , COUNT(p.id) AS kol
		 , SUM(p.value) AS sum_value
	FROM dbo.Buildings AS b
		JOIN dbo.Flats AS f 
			ON b.id = f.bldn_id
		JOIN dbo.VOcc AS o 
			ON f.id = o.flat_id
		JOIN dbo.View_payings AS p 
			ON o.occ = p.occ
		JOIN dbo.VPaycol_user AS vp 
			ON p.ext = vp.ext
		LEFT JOIN dbo.Sector AS s 
			ON b.sector_id = s.id
		LEFT JOIN dbo.Divisions AS d 
			ON b.div_id = d.id
	WHERE 
		p.checked = 1
		AND p.forwarded = 1
		AND b.tip_id = @tip
		AND b.div_id = COALESCE(@div_id, b.div_id)
		AND b.id = COALESCE(@build, b.id)
		AND p.day BETWEEN @date1 AND @date2
		AND (p.sup_id = @sup_id OR @sup_id IS NULL)
	GROUP BY d.name
		   , b.sector_id
		   , s.name
	ORDER BY d.name
		   , b.sector_id
go

