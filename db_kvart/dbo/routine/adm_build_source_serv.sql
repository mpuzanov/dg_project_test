CREATE   PROCEDURE [dbo].[adm_build_source_serv]
(
	@build_id1	 INT
   ,@service_id1 VARCHAR(10)
)
AS
	/*
		--  Вывести всех поставщиков дому по заданной услуге
	*/
	SET NOCOUNT ON

	DECLARE @t TABLE
		(
			service_id VARCHAR(10)
		   ,id2		   INT		   DEFAULT NULL
		   ,name2	   VARCHAR(100) DEFAULT NULL
		   ,source_id  INT
		   ,Name	   VARCHAR(100)
		   ,id		   INT
		   ,kol		   INT
		)

	INSERT INTO @t
	(service_id
	,id2
	,name2
	,source_id
	,Name
	,id
	,kol)
		SELECT
			cl.service_id
		   ,cl.mode_id
		   ,cm1.Name
		   ,cl.source_id
		   ,cm.Name
		   ,cl.source_id AS id
		   ,COUNT(*) AS kol
		FROM dbo.Consmodes_list AS cl
		JOIN dbo.Occupations AS o 
			ON cl.occ = o.occ
		JOIN dbo.FLATS AS f 
			ON o.flat_id = f.id
		LEFT JOIN dbo.Build_source AS b 
			ON cl.source_id = b.source_id
			AND cl.service_id = b.service_id
			AND f.bldn_id = b.build_id
		LEFT JOIN dbo.View_suppliers AS cm 
			ON b.service_id = cm.service_id
			AND b.source_id = cm.id
		JOIN dbo.Cons_modes cm1 
			ON cl.mode_id = cm1.id
			AND cl.service_id = cm1.service_id
		WHERE f.bldn_id = @build_id1
		AND cl.service_id = @service_id1
		GROUP BY cl.service_id
				,cl.mode_id
				,cm1.Name
				,cl.source_id
				,cm.Name;


	INSERT INTO @t
		SELECT
			b.service_id
		   ,0
		   ,'Нет'
		   ,b.source_id
		   ,cm.Name
		   ,b.source_id AS id
		   ,0
		FROM dbo.Build_source AS b 
		JOIN dbo.View_suppliers AS cm 
			ON b.source_id = cm.id
			AND b.service_id = cm.service_id
		LEFT JOIN @t AS t
			ON b.source_id = t.source_id
			AND b.service_id = t.service_id
		WHERE b.build_id = @build_id1
		AND b.service_id = @service_id1
		AND t.source_id IS NULL;


	SELECT
		*
	FROM @t
	ORDER BY source_id
go

