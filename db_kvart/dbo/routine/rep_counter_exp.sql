-- =============================================
-- Author:		Пузанов
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE                 PROCEDURE [dbo].[rep_counter_exp]
	  @tip_str VARCHAR(2000) = ''
	, @fin_id1 SMALLINT = NULL
	, @build_id1 INT = NULL
	, @service_id1 VARCHAR(10) = NULL
	, @date1 SMALLDATETIME = NULL
	, @date2 SMALLDATETIME = NULL
	, @div_id SMALLINT = NULL
	, @is_del BIT = 0
	, @town_id SMALLINT = NULL
	, @is_exp BIT = 0
	, @PrintGroup SMALLINT = NULL
	, @debug BIT = 0
	, @serv_str VARCHAR(1000) = NULL   -- список кодов услуг через ","
	, @is_unique_sernum BIT = NULL
AS
/*
DECLARE	@return_value int
EXEC	@return_value = [dbo].[rep_counter_exp]
		@tip_str = N'6',
		@fin_id1 = 240,
		@service_id1 = N'хвод',
		@is_del = 0,
		@debug = 1,
		@is_unique_sernum = 0
SELECT	'Return Value' = @return_value

exec [dbo].[rep_counter_exp] @tip_str='28',@fin_id1=178, @is_del=0, @build_id1=1081
exec [dbo].[rep_counter_exp] @tip_str='2',@fin_id1=233, @is_del=1
exec [dbo].[rep_counter_exp] @tip_str='6',@fin_id1=241, @debug=1
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @DB_NAME VARCHAR(20) = UPPER(DB_NAME())
		  , @user_id INT
		  , @DB_NAME_ID INT

	--IF @debug=1 print dbo.fn_app_name()
	--IF @debug=1 PRINT '@is_exp '+STR(@is_exp)

	IF dbo.fn_app_name() = N'Экспорт.exe'
		SET @is_exp = 1

	SELECT @user_id = [dbo].[Fun_GetCurrentUserId]()
		 , @DB_NAME_ID =
						CASE
							WHEN @DB_NAME = 'KOMP' THEN 1000000
							WHEN @DB_NAME = 'KVART' THEN 2000000
							WHEN @DB_NAME = 'KR1' THEN 3000000
							ELSE 4000000
						END

	IF @is_exp is NULL
		SET @is_exp = 0
	IF @date2 IS NULL
		AND @date1 IS NOT NULL
		SET @date2 = current_timestamp
	IF @is_del IS NULL
		SET @is_del = 0
	IF @is_unique_sernum IS NULL
		SET @is_unique_sernum = 0

	DECLARE @tip TABLE (
		  tip_id INT PRIMARY KEY
		, fin_id SMALLINT DEFAULT NULL
	)
	IF @tip_str = ''
		OR @tip_str IS NULL
		INSERT INTO @tip (tip_id)
		SELECT id
		FROM dbo.VOcc_types VT
		WHERE VT.payms_value = 1
	ELSE
		INSERT INTO @tip (tip_id)
		SELECT Value
		FROM STRING_SPLIT(@tip_str, ',')
		WHERE RTRIM(Value) <> ''

	UPDATE t
	SET fin_id = CASE
                     WHEN @fin_id1 IS NULL THEN ot.fin_id
                     ELSE @fin_id1
        END
	FROM @tip AS t
		JOIN dbo.Occupation_Types AS ot ON t.tip_id = ot.id

	IF @fin_id1 IS NULL
		AND COALESCE(@tip_str, '') = ''
		AND @build_id1 IS NULL
		AND @div_id IS NULL
		AND @is_exp = 0
			UPDATE t
			SET fin_id = 0
			FROM @tip AS t

	-- для ограничения доступа услуг
	CREATE TABLE #serv (
		  id VARCHAR(10) COLLATE database_default PRIMARY KEY
		, name VARCHAR(100) COLLATE database_default
		, is_build BIT
	)
	INSERT INTO #serv (id, name, is_build)
	SELECT id
		 , name
		 , is_build
	FROM dbo.View_services
	WHERE is_counter = 1

	IF COALESCE(@serv_str, '') <> ''
		DELETE FROM #serv
		WHERE id NOT IN (
				SELECT Value
				FROM STRING_SPLIT(@serv_str, ',')
				WHERE RTRIM(Value) <> ''
			)

		--IF @debug=1 PRINT @is_exp
		--IF @debug=1 SELECT * FROM @tip
		--IF @debug=1 SELECT * FROM #serv
		;
	WITH cte AS
	(
		SELECT ROW_NUMBER() OVER (PARTITION BY c.serial_number ORDER BY (SELECT NULL)) AS row_sernum
			 , gv.start_date
			 , dbo.Fun_GetFalseOccOut(o.occ, t.tip_id) AS occ
			 , o.kol_people
			 , c.service_id
			 , s.name AS street
			 , s.short_name AS short_street
			 , b.nom_dom
			 , b.nom_dom_sort
			 , f.nom_kvr
			 , f.nom_kvr_sort
			 , c.type
			 , c.serial_number AS serial_number
			 , ci_pred.inspector_date AS date_pred
			 , ci_pred.inspector_value AS value_pred
			 , ci.inspector_date
			 , ci.inspector_value
			 , (ci.inspector_value - COALESCE(ci_pred.inspector_value, 0)) AS actual_value  --ci.actual_value
			 , c.build_id
			 , c.date_create
			 , c.count_value
			 , c.PeriodCheck
			 , c.date_edit
			 , S1.name AS serv_name
			 , c.date_del
			 , b.tip_id
			 , t.fin_id
			 , c.id AS counter_id
			 , (@DB_NAME_ID + c.id) AS counter_id_exp
			 , cl.lic_source as lic_source
			 , o.total_sq
			 , c.external_id AS external_counter_id
			 , b.town_name AS town_name
			 , b.nom_dom_without_korp
			 , b.korp
		FROM dbo.Counters AS c 
			JOIN dbo.View_Buildings AS b ON 
				c.build_id = b.id
			JOIN dbo.Flats AS f ON 
				c.flat_id = f.id
			JOIN @tip AS t ON 
				b.tip_id = t.tip_id
			JOIN dbo.Occupations AS o ON 
				f.id = o.flat_id
			JOIN dbo.VStreets AS s ON 
				b.street_id = s.id
			JOIN #serv AS S1 ON 
				c.service_id = S1.id
			JOIN dbo.Global_values AS gv ON 
				t.fin_id = gv.fin_id
			LEFT JOIN dbo.Counter_list_all AS cla ON 
				c.id = cla.counter_id
				AND t.fin_id = cla.fin_id
				AND cla.occ = o.occ
			LEFT JOIN dbo.Consmodes_list as cl ON cl.occ=o.occ and cl.service_id=c.service_id
			OUTER APPLY [dbo].Fun_GetCounterTableValue_Current(c.id, t.fin_id) AS ci
			OUTER APPLY [dbo].Fun_GetCounterTableValue_Pred(c.id, t.fin_id) AS ci_pred
		WHERE (@build_id1 IS NULL OR b.id = @build_id1)
			AND (@service_id1 IS NULL OR c.service_id = @service_id1)
			AND (@div_id IS NULL OR b.div_id = @div_id)
			AND (@town_id IS NULL OR b.town_id = @town_id)
			AND c.date_edit BETWEEN COALESCE(@date1, c.date_edit) AND COALESCE(@date2, c.date_edit)
			AND (
			(@is_del = 0 AND cla.occ IS NOT NULL --AND c.date_del IS NULL
			) 
			OR 
			(@is_del = 1 AND c.date_del IS NOT NULL)
			)
			AND b.is_paym_build = 1
			AND o.total_sq > 0
			AND (@PrintGroup IS NULL OR EXISTS (
				SELECT 1
				FROM dbo.Print_occ AS po 
				WHERE po.occ = o.occ
					AND po.group_id = @PrintGroup
			))
			AND (@is_exp = 0 OR (@is_exp = 1 AND NOT EXISTS (
				SELECT *
				FROM [dbo].[Fun_GetTableBlockedExportPu](o.tip_id, b.id, c.service_id)
			)))
	)
	SELECT ROW_NUMBER() OVER (ORDER BY street, nom_dom_sort, nom_kvr_sort, Occ, service_id) AS row_num
		 , *
	FROM cte
	WHERE (@is_unique_sernum = 0)		
		OR (@is_unique_sernum = 1 AND row_sernum = 1)
	ORDER BY street
		   , nom_dom_sort
		   , nom_kvr_sort
		   , Occ
		   , service_id
	--OPTION (RECOMPILE)
	OPTION (MAXDOP 1, FAST 10)

END
go

