-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE             PROCEDURE [dbo].[adm_query_exeсute]
(
	@param1 SMALLINT
	, @debug BIT = 0
)
AS
/*
adm_query_exeсute 1, 1
adm_query_exeсute 2
adm_query_exeсute 8
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @SQL NVARCHAR(4000)
		,@db_name varchar(30) = DB_NAME()

	IF @param1 = 1
	BEGIN  -- Статистика хранимых процедур в кэше		
		SET @SQL =
		'
		IF NOT EXISTS (SELECT
					*
				FROM tempdb.sys.objects
				WHERE name = ''Activproc'')
			CREATE TABLE tempdb.[dbo].[Activproc]
			(
				SP_Name					SYSNAME		 NOT NULL PRIMARY KEY
				,last_execution_time	DATETIME	 NOT NULL
				,execution_count		BIGINT		 NOT NULL
				,min_elapsed_time		DECIMAL(9,4) NOT NULL
				,max_elapsed_time		DECIMAL(9,4) NOT NULL
				,avg_total_rows			INT			 NOT NULL
				,avg_elapsed_time_sec	DECIMAL(9,4) NOT NULL
			)
		DECLARE	@SP_Name				SYSNAME
				,@last_execution_time	DATETIME
				,@avg_elapsed_time_sec	DECIMAL(9,4)
				,@execution_count		BIGINT
				,@min_elapsed_time		DECIMAL(9,4)
				,@max_elapsed_time		DECIMAL(9,4)
				,@avg_total_rows		INT

		DECLARE c_Activproc CURSOR GLOBAL FOR

			SELECT TOP 100 PERCENT
				OBJECT_NAME(s.objectid, s.dbid) AS SP_Name
				,MAX(st.last_execution_time) AS last_execution_time
				,MAX(st.execution_count) AS execution_count
				,SUM(CAST((st.min_elapsed_time * 1.0 / 100000) AS MONEY)) AS min_elapsed_time
				,SUM(CAST((st.max_elapsed_time * 1.0 / 100000) AS MONEY)) AS max_elapsed_time
				,MAX(CAST(st.total_rows / st.execution_count AS INT)) AS avg_total_rows
				,SUM(CAST((st.total_elapsed_time * 1.0 / 100000) / st.execution_count AS MONEY))
				AS avg_elapsed_time_sec
			FROM master.sys.dm_exec_cached_plans AS c
				CROSS APPLY master.sys.dm_exec_query_plan(c.plan_handle) AS q
				JOIN master.sys.dm_exec_query_stats AS st
					ON c.plan_handle = st.plan_handle
				CROSS APPLY master.sys.dm_exec_sql_text(sql_handle) AS s
			WHERE c.cacheobjtype = ''Compiled Plan''
				AND c.objtype = ''Proc''
				AND q.dbid = DB_ID()
			GROUP BY	DB_NAME(q.dbid)
						,OBJECT_NAME(s.objectid, s.dbid)
			ORDER BY avg_elapsed_time_sec DESC

		OPEN GLOBAL c_Activproc
		WHILE 1 = 1
		BEGIN
			FETCH c_Activproc INTO @SP_Name, @last_execution_time, @execution_count, @min_elapsed_time, @max_elapsed_time, @avg_total_rows, @avg_elapsed_time_sec
			IF @@fetch_status <> 0
				BREAK
			IF @SP_Name NOT IN (SELECT
						SP_Name
					FROM tempdb.dbo.Activproc
					WHERE SP_Name = @SP_Name)
			BEGIN
				INSERT
				INTO tempdb.dbo.Activproc
				(	SP_Name
					,last_execution_time
					,execution_count
					,min_elapsed_time
					,max_elapsed_time
					,avg_total_rows
					,avg_elapsed_time_sec)
				VALUES (@SP_Name, @last_execution_time, @execution_count, @min_elapsed_time, @max_elapsed_time, @avg_total_rows, @avg_elapsed_time_sec)
			END
			ELSE
			BEGIN
				UPDATE tempdb.dbo.Activproc
				SET	last_execution_time		= @last_execution_time
					,execution_count		= @execution_count
					,min_elapsed_time		= @min_elapsed_time
					,max_elapsed_time		= @max_elapsed_time
					,avg_total_rows			= @avg_total_rows
					,avg_elapsed_time_sec	= @avg_elapsed_time_sec
				WHERE SP_Name = @SP_Name
			END
		END
		CLOSE GLOBAL c_Activproc
		DEALLOCATE c_Activproc	
		
		IF EXISTS (SELECT
					*
				FROM tempdb.sys.objects
				WHERE name = ''Activproc'')
		SELECT * FROM tempdb.dbo.Activproc order by avg_elapsed_time_sec desc
		ELSE
		Select ''Обновите статистику''		
	'		
	END

	IF @param1 = 2
	BEGIN  -- Информация по базе		
		SET @SQL = 'use '+@db_name
		SET @SQL = @SQL + ';'+
		'
		select
			so.type_desc, 
			count(*) as [#objects],
			sum(len(definition)-len(replace(definition, char(10), '''')))  + 1 as [#lines]
		from sys.objects so
		left join sys.sql_modules sm 
			 on sm.[object_id] = so.object_id
		group by so.type_desc  
		order by type_desc 
		'
	END
	
	IF @param1 = 3
	BEGIN  -- SQL Server Agent Job Execution Information		
		SET @SQL =
		'
		SELECT 
			[sJOB].[name] AS [JobName]
			, CASE 
				WHEN [sJOBH].[run_date] IS NULL OR [sJOBH].[run_time] IS NULL THEN NULL
				ELSE CAST(
						CAST([sJOBH].[run_date] AS CHAR(8))
						+ '' '' 
						+ STUFF(
							STUFF(RIGHT(''000000'' + CAST([sJOBH].[run_time] AS VARCHAR(6)),  6)
								, 3, 0, '':'')
							, 6, 0, '':'')
						AS DATETIME)
				END AS [LastRunDateTime]
			, CASE [sJOBH].[run_status]
				WHEN 0 THEN ''Failed''
				WHEN 1 THEN ''Succeeded''
				WHEN 2 THEN ''Retry''
				WHEN 3 THEN ''Canceled''
				WHEN 4 THEN ''Running'' -- In Progress
				END AS [LastRunStatus]
			, STUFF(
					STUFF(RIGHT(''000000'' + CAST([sJOBH].[run_duration] AS VARCHAR(6)),  6)
						, 3, 0, '':'')
					, 6, 0, '':'') 
				AS [LastRunDuration (HH:MM:SS)]
			, [sJOBH].[message] AS [LastRunStatusMessage]
			, CASE [sJOBSCH].[NextRunDate]
				WHEN 0 THEN NULL
				ELSE CAST(
						CAST([sJOBSCH].[NextRunDate] AS CHAR(8))
						+ '' '' 
						+ STUFF(
							STUFF(RIGHT(''000000'' + CAST([sJOBSCH].[NextRunTime] AS VARCHAR(6)),  6)
								, 3, 0, '':'')
							, 6, 0, '':'')
						AS DATETIME)
				END AS [NextRunDateTime]
			, [sJOB].[job_id] AS [JobID]
		FROM 
			[msdb].[dbo].[sysjobs] AS [sJOB]
			LEFT JOIN (
						SELECT
							[job_id]
							, MIN([next_run_date]) AS [NextRunDate]
							, MIN([next_run_time]) AS [NextRunTime]
						FROM [msdb].[dbo].[sysjobschedules]
						GROUP BY [job_id]
					) AS [sJOBSCH]
				ON [sJOB].[job_id] = [sJOBSCH].[job_id]
			LEFT JOIN (
						SELECT 
							[job_id]
							, [run_date]
							, [run_time]
							, [run_status]
							, [run_duration]
							, [message]
							, ROW_NUMBER() OVER (
													PARTITION BY [job_id] 
													ORDER BY [run_date] DESC, [run_time] DESC
								) AS RowNumber
						FROM [msdb].[dbo].[sysjobhistory]
						WHERE [step_id] = 0
					) AS [sJOBH]
				ON [sJOB].[job_id] = [sJOBH].[job_id]
				AND [sJOBH].[RowNumber] = 1
		ORDER BY [JobName]
		'
	END
	
	IF @param1 = 4
	BEGIN -- SQL Server Agent Job Steps Execution Information		
		SET @SQL =
		'
			SELECT
			[sJOB].[name] AS [JobName]
			, [sJSTP].[step_id] AS [StepNo]
			, [sJSTP].[step_name] AS [StepName]
			, CASE [sJSTP].[last_run_outcome]
				WHEN 0 THEN ''Failed''
				WHEN 1 THEN ''Succeeded''
				WHEN 2 THEN ''Retry''
				WHEN 3 THEN ''Canceled''
				WHEN 5 THEN ''Unknown''
			  END AS [LastRunStatus]
			, STUFF(
					STUFF(RIGHT(''000000'' + CAST([sJSTP].[last_run_duration] AS VARCHAR(6)),  6)
						, 3, 0, '':'')
					, 6, 0, '':'')
			  AS [LastRunDuration (HH:MM:SS)]
			, [sJSTP].[last_run_retries] AS [LastRunRetryAttempts]
			, CASE [sJSTP].[last_run_date]
				WHEN 0 THEN NULL
				ELSE 
					CAST(
						CAST([sJSTP].[last_run_date] AS CHAR(8))
						+ '' '' 
						+ STUFF(
							STUFF(RIGHT(''000000'' + CAST([sJSTP].[last_run_time] AS VARCHAR(6)),  6)
								, 3, 0, '':'')
							, 6, 0, '':'')
						AS DATETIME)
			  END AS [LastRunDateTime]
			, [sJOB].[job_id] AS [JobID]
			, [sJSTP].[step_uid] AS [StepID]
		FROM
			[msdb].[dbo].[sysjobsteps] AS [sJSTP]
			INNER JOIN [msdb].[dbo].[sysjobs] AS [sJOB]
				ON [sJSTP].[job_id] = [sJOB].[job_id]
		ORDER BY [JobName], [StepNo] 
		'
	END

	IF @param1 = 5
	BEGIN -- SQL Server Agent Job Steps Execution Information		
		SET @SQL =
		'
		sp_who2
		'
	END

	IF @param1 = 6
	BEGIN  -- db_missing_index 1		
		SET @SQL =
		'
	SELECT
		DB_NAME(COALESCE(mid.database_id,1)) AS [Имя базы данных]
		,ROUND(user_seeks * avg_total_user_cost * (avg_user_impact * 0.01),2) AS [index_advantage]
		,migs.last_user_seek
		,mid.[statement] AS [Database.Schema.Table]
		,mid.equality_columns
		,mid.inequality_columns
		,mid.included_columns
		,migs.unique_compiles
		,migs.user_seeks
		,CAST(migs.avg_total_user_cost as decimal(9,4)) as avg_total_user_cost
		,migs.avg_user_impact		
	FROM sys.dm_db_missing_index_group_stats AS migs 
	INNER JOIN sys.dm_db_missing_index_groups AS mig 
		ON migs.group_handle = mig.index_group_handle
	INNER JOIN sys.dm_db_missing_index_details AS mid 
		ON mig.index_handle = mid.index_handle
	ORDER BY index_advantage DESC
	OPTION (RECOMPILE);
	'
	END

	IF @param1 = 7
	BEGIN  -- db_missing_index 2		
		SET @SQL =
		'
;WITH XMLNAMESPACES
(DEFAULT ''http://schemas.microsoft.com/sqlserver/2004/07/showplan'')
SELECT
    REPLACE(REPLACE(n.value(''(//MissingIndex/@Database)[1]'', ''VARCHAR(128)''), ''['', ''''), '']'', '''') AS Dbname
	,tab.usecounts
	,n.value(''(//MissingIndexGroup/@Impact)[1]'', ''FLOAT'') AS impact
	,objtype			
	,n.value(''(//MissingIndex/@Database)[1]'', ''VARCHAR(128)'') + ''.'' +
	n.value(''(//MissingIndex/@Schema)[1]'', ''VARCHAR(128)'') + ''.'' +
	n.value(''(//MissingIndex/@Table)[1]'', ''VARCHAR(128)'') AS statement
	,(SELECT DISTINCT
			c.value(''(@Name)[1]'', ''VARCHAR(128)'') + '', ''
		FROM n.nodes(''//ColumnGroup'') AS t (cg)
		CROSS APPLY cg.nodes(''Column'') AS r (c)
		WHERE cg.value(''(@Usage)[1]'', ''VARCHAR(128)'') = ''EQUALITY''
		FOR XML PATH (''''))
	AS equality_columns
	,(SELECT DISTINCT
			c.value(''(@Name)[1]'', ''VARCHAR(128)'') + '', ''
		FROM n.nodes(''//ColumnGroup'') AS t (cg)
		CROSS APPLY cg.nodes(''Column'') AS r (c)
		WHERE cg.value(''(@Usage)[1]'', ''VARCHAR(128)'') = ''INEQUALITY''
		FOR XML PATH (''''))
	AS inequality_columns
	,(SELECT DISTINCT
			c.value(''(@Name)[1]'', ''VARCHAR(128)'') + '', ''
		FROM n.nodes(''//ColumnGroup'') AS t (cg)
		CROSS APPLY cg.nodes(''Column'') AS r (c)
		WHERE cg.value(''(@Usage)[1]'', ''VARCHAR(128)'') = ''INCLUDE''
		FOR XML PATH (''''))
	AS include_columns
	,ObjectName
	,n.value(''(@StatementText)[1]'', ''VARCHAR(4000)'') AS sql_text
	,tab.text	
	,query_plan
FROM (SELECT
		usecounts
		,query_plan
		,text
		,ObjectName
		,objtype
	FROM (SELECT
			usecounts
			,cacheobjtype
			,objtype
			,query.text
			,OBJECT_NAME(query.objectid) ObjectName
			,executionplan.query_plan
		FROM sys.dm_exec_cached_plans
		OUTER APPLY sys.dm_exec_sql_text(plan_handle) AS query
		OUTER APPLY sys.dm_exec_query_plan(plan_handle) AS executionplan
		WHERE [text] NOT LIKE ''%sys%'') qs
	WHERE qs.query_plan.exist(''//MissingIndex'') = 1) AS tab (usecounts,query_plan, text, ObjectName, objtype)

CROSS APPLY query_plan.nodes(''//StmtSimple'') AS q (n)
WHERE n.exist(''QueryPlan/MissingIndexes'') = 1
ORDER BY tab.usecounts desc	'
	END

	IF @param1 = 8
	BEGIN  -- Показать неиспользуемые индексы SQL Server		
		SET @SQL =
		'
SELECT TOP (25)
 o.name AS ObjectName
 , i.name AS IndexName
 , i.index_id AS IndexID
 , dm_ius.user_seeks AS UserSeek
 , dm_ius.user_scans AS UserScans
 , dm_ius.user_lookups AS UserLookups
 , dm_ius.user_updates AS UserUpdates
 , p.TableRows
 ,DB_NAME(COALESCE(dm_ius.database_id,1)) AS dbName
 , ''DROP INDEX'' + QUOTENAME(i.name)
 + '' ON '' + QUOTENAME(s.name) + ''.'' + QUOTENAME(OBJECT_NAME(dm_ius.OBJECT_ID)) AS ''drop statement''
 FROM sys.dm_db_index_usage_stats dm_ius
 INNER JOIN sys.indexes i ON i.index_id = dm_ius.index_id AND dm_ius.OBJECT_ID = i.OBJECT_ID
 INNER JOIN sys.objects o ON dm_ius.OBJECT_ID = o.OBJECT_ID
 INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
 INNER JOIN (SELECT SUM(p.rows) TableRows, p.index_id, p.OBJECT_ID
 FROM sys.partitions p GROUP BY p.index_id, p.OBJECT_ID) p
 ON p.index_id = dm_ius.index_id AND dm_ius.OBJECT_ID = p.OBJECT_ID
 WHERE OBJECTPROPERTY(dm_ius.OBJECT_ID,''IsUserTable'') = 1
 AND i.type_desc = ''nonclustered''
 AND i.is_primary_key = 0
 AND i.is_unique_constraint = 0
 AND dm_ius.database_id = DB_ID()
 ORDER BY (dm_ius.user_seeks + dm_ius.user_scans + dm_ius.user_lookups) ASC
 '

	END

	IF @debug= 1
		PRINT @SQL

	EXECUTE sp_executesql @SQL

END
go

