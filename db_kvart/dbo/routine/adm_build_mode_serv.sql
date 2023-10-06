CREATE   PROCEDURE [dbo].[adm_build_mode_serv]
(
	@build_id1	 INT
   ,@service_id1 VARCHAR(10)
)
AS
	/*	
		Вывести все режимы потребления по дому по заданной услуге
		adm_build_mode_serv 647, 'гвод'
		adm_build_mode_serv 1031, 'площ'
	*/
	SET NOCOUNT ON

	DECLARE @t TABLE
		(
			service_id VARCHAR(10)
		   ,id2		   INT
		   ,name2	   VARCHAR(100)
		   ,mode_id	   INT
		   ,name	   VARCHAR(100)
		   ,id		   INT
		   ,kol		   INT
		)

	INSERT INTO @t
		SELECT
			cl.service_id AS service_id
		   ,cl.source_id AS id2
		   ,sa.name AS name2
		   ,cl.mode_id AS mode_id
		   ,cm.name AS name
		   ,cl.mode_id AS id
		   ,COUNT(*) AS kol
		FROM dbo.Consmodes_list AS cl 
		JOIN dbo.Occupations AS o 
			ON cl.Occ = o.Occ
		JOIN dbo.Flats AS f
			ON o.flat_id = f.id
		LEFT JOIN dbo.Build_mode AS b 
			ON cl.mode_id = b.mode_id
			AND cl.service_id = b.service_id
			AND f.bldn_id = b.build_id
		LEFT JOIN dbo.Cons_modes AS cm 
			ON b.service_id = cm.service_id
			AND b.mode_id = cm.id
		LEFT JOIN dbo.Suppliers sa 
			ON cl.source_id = sa.id
		WHERE f.bldn_id = @build_id1
		AND cl.service_id = @service_id1
		GROUP BY cl.service_id
				,cl.source_id
				,sa.name
				,cl.mode_id
				,cm.name

	INSERT INTO @t
		SELECT
			b.service_id
		   ,0 AS id2
		   ,'Нет' AS name2
		   ,b.mode_id AS mode_id
		   ,cm.name AS name
		   ,b.mode_id AS id
		   ,0 AS kol
		FROM dbo.Build_mode AS b 
		JOIN dbo.Cons_modes AS cm 
			ON b.mode_id = cm.id
			AND b.service_id = cm.service_id
		LEFT JOIN @t AS t
			ON b.mode_id = t.mode_id
			AND b.service_id = t.service_id
		WHERE b.build_id = @build_id1
		AND b.service_id = @service_id1
		AND t.mode_id IS NULL

	SELECT
		*
	FROM @t
	ORDER BY mode_id
go

