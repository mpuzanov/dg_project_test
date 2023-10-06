CREATE   PROCEDURE [dbo].[ka_show_services2]
(
	  @str1 VARCHAR(4000) = '' -- строка формата: код дома;код дома
	, @param_in SMALLINT = 1 -- 1- на входе дома, 2- лиц.счета
	, @is_counter BIT = 0
	, @fin_id SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
	, @is_plus BIT = 0  -- 1 - берём текущий фин.период
	, @serv_filter VARCHAR(100) = NULL
)
AS
	/*
	Выдаем список услуг с поставщиками для разовых
				
	exec ka_show_services2 @str1='1031;1081',@param_in=1,@is_counter=0, @fin_id=170,@fin_id2=177
	exec ka_show_services2 '33100;33101',2		
	exec ka_show_services2 '1050;1059;1064;1079',1		
	exec ka_show_services2 @str1='910003474',@param_in=2,@fin_id=235, @is_plus = 1
	*/

	SET NOCOUNT ON

	IF @str1 IS NULL
		SET @str1 = ''
	IF @param_in IS NULL
		SET @param_in = 1
	IF @is_counter = 0
		SET @is_counter = NULL
	IF @is_plus IS NULL
		SET @is_plus = 0
	IF @serv_filter=''
		SET @serv_filter = NULL

	-- Таблица с домами или лицевыми
	DECLARE @t_in TABLE (
		  id INT
	)
	INSERT INTO @t_in (id)
	SELECT value
	FROM STRING_SPLIT(@str1, ';')
	WHERE RTRIM(value) <> '';

	-- для ограничения доступа услуг
	CREATE TABLE #s (
		  id VARCHAR(10) COLLATE database_default PRIMARY KEY
		, name VARCHAR(100) COLLATE database_default
		, is_build BIT
		, is_counter BIT
	)
	INSERT INTO #s (id
				  , name
				  , is_build
				  , is_counter)
	SELECT id
		 , name
		 , is_build
		 , is_counter
	FROM dbo.view_services vs
	OUTER APPLY STRING_SPLIT(@serv_filter, ',') AS t	
	WHERE (is_counter = @is_counter OR @is_counter IS NULL)
		and @serv_filter IS NULL OR t.value=vs.id;

	IF @fin_id IS NULL
		SET @fin_id = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)

	IF @fin_id IS NOT NULL
		AND @fin_id2 IS NULL
		SET @fin_id2 = @fin_id

	IF @param_in = 1 -- на входе дома
	BEGIN
		SELECT ROW_NUMBER() OVER (ORDER BY serv_name) AS ROW_NUM
			 , *
		FROM (
			SELECT DISTINCT s.id
				 , s.name AS serv_name
				 , cl.source_id
				 , cl.sup_id
				 , sa.name AS sup_name
				 , CONCAT(s.name , ' (' , RTRIM(sa.name) , ')') AS name2
				 , u.short_id
				 , coalesce(sb.is_direct_contract, CAST(0 AS BIT)) AS is_direct_contract  -- прямые расчеты по дому
			FROM dbo.Occupations AS o
				JOIN Flats f ON 
					o.flat_id = f.id
				JOIN @t_in t ON 
					f.bldn_id = t.id
				JOIN dbo.View_consmodes_lite AS cl ON 
					o.occ = cl.occ
				JOIN #s AS s ON 
					cl.service_id = s.id
				JOIN dbo.Suppliers sa ON 
					cl.source_id = sa.id
				LEFT JOIN dbo.Service_units AS su ON 
					s.id = su.service_id
					AND su.fin_id = cl.fin_id
					AND su.tip_id = o.tip_id
					AND su.ROOMTYPE_ID = o.ROOMTYPE_ID
				LEFT JOIN dbo.Units AS u ON 
					su.unit_id = u.id
				LEFT JOIN dbo.Services_build AS sb ON 
					sb.build_id=f.bldn_id 
					AND sb.service_id=s.id
			WHERE cl.fin_id BETWEEN @fin_id AND @fin_id2
				AND (
				(cl.mode_id % 1000) != 0 OR (cl.source_id % 1000) != 0
				)
				AND o.STATUS_ID <> 'закр'
				AND o.TOTAL_SQ > 0
			GROUP BY s.id
				   , s.name
				   , cl.source_id
				   , cl.sup_id
				   , sa.name
				   , u.short_id
				   , sb.is_direct_contract
		) AS t
		ORDER BY serv_name
	--OPTION (MAXDOP 1, FAST 10)
	END
	IF @param_in = 2  -- входе лиц.счета
	BEGIN
		SELECT ROW_NUMBER() OVER (ORDER BY serv_name) AS ROW_NUM
			 , *
		FROM (
			SELECT DISTINCT s.id
				 , s.name AS serv_name
				 , cl.source_id
				 , cl.sup_id
				 , sa.name AS sup_name
				 , CONCAT(s.name , ' (' , RTRIM(sa.name) , ')') AS name2
				 , u.short_id
				 , coalesce(sb.is_direct_contract, CAST(0 AS BIT)) AS is_direct_contract  -- прямые расчеты по дому
			FROM @t_in t
				JOIN dbo.VOcc AS o ON 
					o.occ = t.id
				JOIN dbo.Occupation_Types ot ON 
					o.tip_id = ot.id
				JOIN dbo.View_consmodes_lite AS cl ON 
					o.occ = cl.occ
				JOIN #s AS s ON 
					cl.service_id = s.id
				JOIN dbo.Suppliers sa ON 
					cl.source_id = sa.id
				LEFT JOIN dbo.Service_units AS su ON 
					s.id = su.service_id
					AND su.fin_id = cl.fin_id
					AND su.tip_id = o.tip_id
					AND su.ROOMTYPE_ID = o.ROOMTYPE_ID
				LEFT JOIN dbo.Units AS u ON su.unit_id = u.id
				LEFT JOIN dbo.Services_build AS sb ON 
					sb.build_id=o.bldn_id AND sb.service_id=s.id
			WHERE (@is_plus = 0 AND cl.fin_id BETWEEN @fin_id AND @fin_id2)
				OR (@is_plus = 1 AND cl.fin_id = o.fin_id)
			GROUP BY s.id
				   , s.name
				   , cl.source_id
				   , cl.sup_id
				   , sa.name
				   , u.short_id
				   , sb.is_direct_contract
		) AS t
		ORDER BY serv_name
	--OPTION (MAXDOP 1, FAST 10)
	END
go

