CREATE   PROCEDURE [dbo].[adm_activity_user]
(
	@DB_NAME VARCHAR(20) = NULL
)
/*
adm_activity_user @DB_NAME='komp'
adm_activity_user @DB_NAME=''
adm_activity_user @DB_NAME=NULL
*/
AS
	SET NOCOUNT ON

	IF @DB_NAME IS NULL
		SET @DB_NAME = UPPER(DB_NAME())

	DECLARE @t TABLE(
		loginame VARCHAR(30) --COLLATE database_default
		,[program_name] VARCHAR(50)
		,client_net_address VARCHAR(30) 
		,hostname VARCHAR(30)
		,dbname VARCHAR(30)
	)
	INSERT INTO @t(loginame, [program_name],client_net_address, hostname, dbname)
	SELECT substring(p.loginame,1,30), 
		substring(p.[program_name],1,50),
		substring(c.client_net_address,1,30), 
		substring(rtrim(p.hostname),1,30), 
		substring(DB_NAME(p.dbid),1,30)
	FROM master.sys.sysprocesses p
	JOIN master.sys.dm_exec_connections c
		ON c.session_id = p.spid

	SELECT DISTINCT
		u.id AS users_id
	   ,t.[program_name] AS program
	   ,Initials AS FIO
	   ,CAST(u.[login] AS VARCHAR(30)) AS [login]
	   ,u.comments
	   ,t.hostname AS comp
	   ,t.dbname AS dbname
	   ,a.dir_program
	   ,a.StrVer
	   ,CASE
			WHEN PATINDEX('<%', t.client_net_address) = 0 THEN t.client_net_address
			ELSE a.IPaddress
		END AS IPaddress
	   ,u.last_connect
	FROM @t as t
	JOIN dbo.USERS AS u 
		ON (t.loginame = CASE
                             WHEN u.login = 'dbo' THEN 'sa'
                             ELSE u.login
            END) 
		AND (t.[program_name] <> '')
	JOIN dbo.PROGRAMS pr
		ON pr.[name] = t.[program_name]
	LEFT JOIN dbo.ACTIVITY AS a 
		ON a.sysuser = u.login
		AND UPPER(t.[program_name]) = UPPER(a.program)
		AND a.is_work = 1
		AND t.[hostname] = a.comp
		AND t.dbname = CASE
                           WHEN @DB_NAME = '' THEN t.dbname
                           ELSE @DB_NAME
                END

	--WHERE PATINDEX('<%', c.client_net_address) = 0  -- закомментировал 19.10.18

	ORDER BY IPaddress

--USE [master]  
--GO
--GRANT VIEW SERVER STATE TO [public]   -- для запуска sysprocesses пользователями
--GO

    grant execute on adm_activity_user to admin
go

