CREATE   PROCEDURE [dbo].[rep_svod]
(
	@tip_id SMALLINT = NULL
)
AS
	/* 
		Подготовка данных для сводных отчетов
		exec rep_svod 137
		exec rep_svod 28
	*/
	--*************************************************************
	SET NOCOUNT ON

	DECLARE @msg		 NVARCHAR(200)
		   ,@fin_current SMALLINT
		   ,@tip_name	 VARCHAR(50)
		   ,@kol_build	 INT

	CREATE TABLE #t_build(id INT PRIMARY KEY)

	DECLARE @i INT = 0
	DECLARE curs CURSOR LOCAL FOR
		SELECT
			id
		   ,Fin_id
		   ,name
		FROM dbo.Occupation_Types
		WHERE 
			id = COALESCE(@tip_id, id)
			AND (payms_value = 1 OR only_pasport = 1)
		ORDER BY id
	OPEN curs
	FETCH NEXT FROM curs INTO @tip_id, @fin_current, @tip_name

	WHILE (@@fetch_status = 0)
	BEGIN
		SET @i = @i + 1
		SET @msg = CONCAT(@i,') код: ', @tip_id,' ', @tip_name)
		--LTRIM(STR(@i, 3)) + ' код:' + STR(@tip_id, 4) + ' ' + @tip_name
		RAISERROR (@msg, 10, 1) WITH NOWAIT;

		-- Обновляем общую информацию по базе для "Администратора"
		--EXEC adm_info_basa @tip_id		
		--EXEC adm_info_basa_history	@fin_current,@tip_id
		EXEC adm_info_basa @tip_id1 = @tip_id
						  ,@fin_id1 = @fin_current
						  ,@debug = 0
		RAISERROR ('обновили общую инфу по фонду', 10, 1) WITH NOWAIT;

		TRUNCATE TABLE #t_build
		INSERT INTO #t_build(id)
		SELECT id
		FROM dbo.Buildings 
		WHERE 
			tip_id = @tip_id
			AND is_paym_build = 1
		SET @kol_build = @@rowcount

		--select @fin_current, ID FROM #t_build

		DELETE ds 
			FROM dbo.DOM_SVOD AS ds
			JOIN #t_build AS b
				ON ds.build_id = b.id
		WHERE Fin_id = @fin_current

		RAISERROR ('загружаем dom_svod (Домов: %i)', 10, 1, @kol_build) WITH NOWAIT;
		INSERT INTO dbo.Dom_svod ([fin_id], [build_id], [CountLic], [CountFlats], [Square], [SquareLive], [CurrentDate], [CountPeople], 
			[CountPeopleLgot], [CountLicLgot], [CountLicSubsid], [CountIPU], [CountOPU], 
			[CountFlatsIPU], [CountPeopleIPU], [CountFlatsNoIPU], [CountPeopleNoIPU])
			SELECT
				@fin_current
			   ,b1.id
			   ,COUNT(COALESCE(occ, 0)) AS CountLic
			   ,COALESCE((SELECT
						COUNT(DISTINCT F.id)
					FROM dbo.FLATS F
					JOIN dbo.OCCUPATIONS t 
						ON t.flat_id = F.id
					WHERE F.bldn_id = b1.id
					AND t.Status_id <> 'закр')
				, 0) AS CountFlats
			   ,SUM(COALESCE(TOTAL_SQ, 0)) AS [SQUARE]
			   ,SUM(COALESCE(LIVING_SQ, 0)) AS SquareLive
			   ,current_timestamp AS CurrentDate
			   ,COALESCE((SELECT
						COUNT(p.id)
					FROM dbo.PEOPLE AS p 
					JOIN dbo.OCCUPATIONS AS o2 
						ON p.occ = o2.occ
					JOIN dbo.FLATS AS f2 
						ON o2.flat_id = f2.id
					JOIN dbo.PERSON_STATUSES AS ps 
						ON p.Status2_id = ps.id
					WHERE f2.bldn_id = b1.id
					AND ps.is_paym = 1
					AND ps.is_kolpeople = 1
					AND p.Del = 0)
				, 0) AS CountPeople
			   ,0 AS CountPeopleLgot
			   ,0 AS CountLicLgot
			   ,0 AS CountLicSubsid
			   ,COALESCE((SELECT
						COUNT(c1.id)
					FROM dbo.COUNTERS AS c1 
					WHERE c1.build_id = b1.id
					AND c1.is_build = 0
					AND c1.date_del IS NULL)
				, 0) AS CountIPU
			   ,COALESCE((SELECT
						COUNT(c1.id)
					FROM dbo.COUNTERS AS c1 
					WHERE c1.build_id = b1.id
					AND c1.is_build = 1
					AND c1.date_del IS NULL)
				, 0) AS CountOPU
			   ,COALESCE((SELECT
						COUNT(DISTINCT c1.flat_id)
					FROM dbo.COUNTERS AS c1 
					WHERE c1.build_id = b1.id
					AND c1.is_build = 0
					AND c1.date_del IS NULL)
				, 0) AS CountFlatsIPU
			   ,COALESCE((SELECT
						SUM(o.kol_people)
					FROM dbo.Occupations o 
					JOIN dbo.Flats f ON 
						o.flat_id = f.id
					WHERE o.Status_id <> 'закр'
					AND f.bldn_id = b1.id
					AND EXISTS (SELECT
							1
						FROM dbo.View_counter_all_lite vca 
						WHERE vca.bldn_id = b1.id
						AND vca.Fin_id = @fin_current
						AND vca.occ = o.occ))
				, 0) AS CountPeopleIPU
				, 0 AS [CountFlatsNoIPU]
				, 0 AS [CountPeopleNoIPU]
			FROM dbo.Occupations AS o1 
			JOIN dbo.FLATS AS f1 ON 
				o1.flat_id = f1.id
			JOIN #t_build AS b1	ON 
				f1.bldn_id = b1.id
			WHERE 
				o1.Status_id <> 'закр'
			GROUP BY b1.id
			OPTION (RECOMPILE)

		RAISERROR ('записали dom_svod', 10, 1) WITH NOWAIT;

		DELETE ds
			FROM dbo.DOM_SVOD_ALL AS ds
			JOIN #t_build AS b
				ON ds.build_id = b.id
		WHERE Fin_id = @fin_current;

		RAISERROR ('загружаем dom_svod_all', 10, 1) WITH NOWAIT;
		INSERT INTO dbo.DOM_SVOD_ALL
			SELECT
				@fin_current AS fin_id
			   ,b1.id
			   ,cl.mode_id
			   ,cl.source_id
			   ,cl.is_counter
			   ,CountLic = COUNT(o1.occ)
			   ,CountFlats = COUNT(DISTINCT f1.id)
			   ,SquareLic = SUM(o1.TOTAL_SQ)
			   ,SquareLicLive = SUM(o1.LIVING_SQ)
			   ,CurrentDate = current_timestamp
			   ,CountPeople = 0
			   ,CountPeopleLgot = 0
			   ,CountLicLgot = 0
			   ,CountLicSubsid = 0
			   ,CountPeople_no = 0
			FROM dbo.OCCUPATIONS AS o1 
			JOIN dbo.FLATS AS f1 
				ON o1.flat_id = f1.id
			JOIN #t_build AS b1
				ON f1.bldn_id = b1.id
			JOIN dbo.CONSMODES_LIST AS cl 
				ON cl.occ = o1.occ
			WHERE o1.Status_id <> 'закр'
			GROUP BY b1.id
					,cl.service_id
					,cl.mode_id
					,cl.source_id
					,cl.is_counter
			OPTION (RECOMPILE)

		-- обновляем инфу по людям
		RAISERROR ('обновляем dom_svod_all по людям', 10, 1) WITH NOWAIT;
		UPDATE dsa
		SET CountPeople	   = COALESCE(p.have_paym_yes, 0)
		   ,countpeople_no = COALESCE(p.have_paym_no, 0)
		FROM dbo.DOM_SVOD_ALL AS dsa
		JOIN (SELECT
				f2.bldn_id
			   ,cl2.mode_id
			   ,cl2.source_id
			   ,cl2.is_counter
			   ,have_paym_no = SUM(
				CASE
					WHEN pc.have_paym = 0 THEN 1
					ELSE 0
				END
				)
			   ,have_paym_yes = SUM(
				CASE
					WHEN pc.have_paym = 1 THEN 1
					ELSE 0
				END
				)
			FROM dbo.PEOPLE AS p 
			JOIN dbo.OCCUPATIONS AS o2 
				ON p.occ = o2.occ
			JOIN dbo.FLATS AS f2 
				ON o2.flat_id = f2.id
			LEFT JOIN dbo.PERSON_STATUSES AS ps 
				ON p.Status2_id = ps.id
			LEFT JOIN dbo.CONSMODES_LIST AS cl2 
				ON cl2.occ = o2.occ
			LEFT JOIN dbo.PERSON_CALC AS pc
				ON p.Status2_id = pc.Status_id
				AND pc.service_id = cl2.service_id
			WHERE 
				o2.tip_id = @tip_id
				AND p.Del = 0
				AND ps.is_paym = 1
				AND o2.Status_id <> 'закр'
			GROUP BY f2.bldn_id
					,cl2.mode_id
					,cl2.source_id
					,cl2.is_counter) AS p
			ON p.bldn_id = dsa.build_id
			AND p.mode_id = dsa.mode_id
			AND p.source_id = dsa.source_id
			AND p.is_counter = dsa.is_counter
		OPTION (RECOMPILE)

		RAISERROR ('записали dom_svod_all', 10, 1) WITH NOWAIT;

		FETCH NEXT FROM curs INTO @tip_id, @fin_current, @tip_name
	END

	CLOSE curs
	DEALLOCATE curs
go

