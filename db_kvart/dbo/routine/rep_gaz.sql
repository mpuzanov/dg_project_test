CREATE   PROCEDURE [dbo].[rep_gaz]
(
	@service_id	VARCHAR(10)	= 'отоп'
	,@mode_id	INT			= 2003
	,@tip_str	VARCHAR(2000)
	,@fin_id	SMALLINT	= NULL
)
AS
	--
	--  
	--
	/*
	добавил выбор списка типов фонда Пузанов 25.05.11
	добавил тип фонда Пузанов 4.06.07
	добавил тип фин.период Пузанов 3.10.08
	
	*/

	SET NOCOUNT ON

	IF @fin_id IS NULL
		SET @fin_id = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

	DECLARE @tip TABLE(tip_id INT PRIMARY KEY)
	INSERT INTO @tip
	SELECT * FROM STRING_SPLIT(@tip_str, ',')  WHERE RTRIM(value) <> ''

	SELECT
		o.occ
		,b.street_name AS street
		,b.nom_dom
		,o.nom_kvr
		,dbo.Fun_Initials(o.occ) AS fio
		,COALESCE(t2.kol_people, 0) AS kol_people
		,CASE
			WHEN o.occ = cl.occ THEN o.total_sq
			ELSE 0
		END AS teplo_sq
	FROM dbo.View_BUILD_ALL AS b 
	JOIN dbo.View_OCC_ALL AS o 
		ON b.build_id = o.build_id
		AND b.fin_id = o.fin_id
	LEFT OUTER JOIN (SELECT
			p.occ
			,COUNT(p.owner_id) AS kol_people
		FROM dbo.View_OCC_ALL AS o 
		JOIN dbo.View_PEOPLE_ALL AS p 
			ON o.occ = p.occ
			AND o.fin_id = p.fin_id
		JOIN dbo.PERSON_CALC AS pc 
			ON p.status2_id = pc.status_id
		JOIN dbo.PERSON_STATUSES AS ps 
			ON p.status2_id = ps.id
		WHERE o.status_id <> 'закр'
		AND EXISTS (SELECT
				1
			FROM @tip
			WHERE tip_id = o.tip_id)
		AND o.fin_id = @fin_id
		AND ps.is_kolpeople = 1
		AND pc.have_paym = 1
		AND pc.service_id = 'пгаз'
		GROUP BY p.occ) AS t2
		ON o.occ = t2.occ
	LEFT OUTER JOIN dbo.View_PAYM AS cl 
		ON cl.service_id = @service_id
		AND cl.mode_id = @mode_id
		AND cl.occ = o.occ
		AND cl.fin_id = o.fin_id
	WHERE 
		b.fin_id = @fin_id
		AND o.status_id <> 'закр'
		AND b.is_paym_build = 1 -- только если начисляем по дому 29.10.2014
		AND EXISTS (SELECT
			1
		FROM @tip
		WHERE tip_id = o.tip_id)
	ORDER BY o.occ
go

