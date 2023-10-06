CREATE   PROCEDURE [dbo].[adm_activity_Process]
(
	@filter1	SMALLINT	= 0    -- 0 -все, 1 - только блокированные строки, 2- выполняемые, 3-только текущая база, 4-suspended
	,@sys1		BIT			= NULL-- показать так же системные процессы   сейчас не используется
)
AS
	/*
	  Показаваем выполняющиеся процессы в базе
	  adm_activity_Process 0
	  adm_activity_Process 1
	  adm_activity_Process 2
	  adm_activity_Process 3
	  adm_activity_Process 4
	 */
	SET NOCOUNT ON

	DECLARE @i INT = 50  -- до 50 системные процессы

	SELECT 
		P.spid
		,COALESCE(P.blocked, 0) AS blocked
		,CONVERT(VARCHAR(20), UPPER(P.loginame)) AS loginame
		,CONVERT(VARCHAR(20), DB_NAME(P.dbid)) AS dbname
		,SUBSTRING(P.status, 1, 15) AS status
		,NULLIF(P.open_tran, 0) AS open_tran
		,CONVERT(VARCHAR(100), RTRIM(UPPER(P.program_name)) COLLATE database_default) AS APPLICATION
		,u.Initials AS fio
		,CONVERT(VARCHAR(25), P.cmd) AS command
		,NULLIF(P.waittime, 0) AS waittime
		,CONVERT(VARCHAR(10), P.hostname) AS hostname
		,P.last_batch
		,P.login_time
		,P.net_library
		,c.net_transport
		,c.encrypt_option
		,c.client_net_address
		,s.client_interface_name
		,c.auth_scheme
		,s.original_login_name
		--,st.text COLLATE database_default AS sql_text
		,(select [text] from  ::fn_get_sql(p.sql_handle)) AS sql_text
	FROM master.sys.sysprocesses P
	JOIN master.sys.dm_exec_connections c
		ON c.session_id = P.spid
	JOIN master.sys.dm_exec_sessions AS s
		ON c.session_id = s.session_id
	OUTER APPLY master.sys.dm_exec_sql_text(P.sql_handle) AS st
	LEFT JOIN dbo.USERS AS u 
		ON (P.loginame COLLATE database_default = CASE
                                                      WHEN u.[login] = 'dbo' THEN 'sa'
                                                      ELSE u.[login]
            END
		)
		AND (P.program_name <> '')
	WHERE P.spid >= @i
	AND COALESCE(P.blocked, 0) > (CASE
		WHEN @filter1 = 1 THEN 0
		ELSE -1
	END)
	AND P.status = CASE
                       WHEN @filter1 = 2 THEN 'runnable'
                       ELSE P.status
        END
	AND DB_NAME(P.dbid) = CASE
                              WHEN @filter1 = 3 THEN DB_NAME()
                              ELSE DB_NAME(P.dbid)
        END
	AND P.status = CASE
                       WHEN @filter1 = 4 THEN 'suspended'
                       ELSE P.status
        END
	AND c.parent_connection_id is null
	ORDER BY P.open_tran DESC, P.last_batch DESC, u.Initials
go

