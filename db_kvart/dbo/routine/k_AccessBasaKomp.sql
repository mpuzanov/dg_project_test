CREATE   PROCEDURE [dbo].[k_AccessBasaKomp]
AS
	/*
	Процедура входа в базу для каждого модуля 
	*/

	SET NOCOUNT ON;


	-- 5 сек ждем блокировку  в этой сесии пользователя
	SET LOCK_TIMEOUT 5000;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @StrFinPeriod VARCHAR(15)
		  , @start_date SMALLDATETIME
		  , @Fin_id1 SMALLINT = NULL
		  , @User_FIO VARCHAR(25)
		  , @SuperAdmin BIT = 0
		  , @IsDeveloper BIT = 0
		  , @Rejim VARCHAR(10)
		  , @RejimAdm VARCHAR(10) -- действительный режим базы для Администратора
		  , @AccessProgram BIT
		  , @user_id1 SMALLINT
		  , @Msg_TimeOut SMALLINT = 5
		  , @blocked_personal BIT
		  , @dir_new_version NVARCHAR(100)
		  , @Only_Sup INT -- доступ только к этому поставщику
		  , @AccessSubsidia BIT = 0
		  , @ProgramName VARCHAR(50) = '"Биллинг-РЦ"'
		  , @Web_site VARCHAR(100) = '' --'Группа в контакте: https://vk.com/billing_rc' --'http://www.kvartplata1.narod.ru' --'Группа в контакте: https://vk.com/billing_rc' 
		  , @Author_txt VARCHAR(200) = 'Пузанов Михаил, г.Ижевск ' + CHAR(13) + 'kvartplata1@narod.ru'
		  , @FTPServer VARCHAR(30)
		  , @FTPPort INT
		  , @FTPuser VARCHAR(30)
		  , @FTPpswd VARCHAR(30)
		  , @blocked_export BIT = 0
		  , @blocked_print BIT = 0
		  , @use_koef_build BIT = 0	-- Использовать коэффициенты для расчётов с домов
		  , @db_name VARCHAR(20) = DB_NAME()
		  , @servername NVARCHAR(20) = @@servername
		  , @POPserver VARCHAR(39)
		  , @name_org VARCHAR(50) = ''
		  , @FromMail VARCHAR(50) = 'zzz@izhmfc.ru'
		  , @FromUserMail VARCHAR(50) = ''
		  , @Yandex_dir VARCHAR(50) = '/Kavrt' -- каталог для скачивания клиентов на webdav.yandex.ru
		  , @APP_NAME NVARCHAR(128) = '' -- Программа клиент			
		  , @DLL_dir VARCHAR(100) = 'http://www.kvartplata1.narod.ru/download'
		  , @Path_download VARCHAR(100) = 'http://www.kvartplata1.narod.ru/download/kvart'
		  , @video_link VARCHAR(100) = 'https://disk.yandex.ru/d/Pt9CM0KikQD3cg'
		  , @app_folder VARCHAR(50) = '' -- наименование папки программы на англ. (имя программы на английском)
		  , @App_name_download VARCHAR(50) = ''
		  , @settings_developer NVARCHAR(MAX)
		  , @settings NVARCHAR(MAX)


	--SELECT @autor_txt='Пузанов Михаил, г.Ижевск '+CHAR(13)+'kvartplata1@narod.ru'

	-- находим последний используемый фин. период в базе
	SELECT TOP (1) @Fin_id1 = fin_id
	FROM dbo.Occupation_Types OT 
	ORDER BY fin_id DESC;

	SELECT TOP (1) @start_date = start_date
				 , @StrFinPeriod = StrMes
				 , @Msg_TimeOut = msg_timeout
				 , @dir_new_version = dir_new_version
				 , @ProgramName =
								 CASE
									 WHEN @servername IN ('WIN-D7BPOBPSCD0') OR
										 (system_user = 'kpspdu') THEN '"Биллинг-СпДУ"'
									 WHEN @servername IN ('S2011') THEN '"Биллинг-РЦ"'
									 WHEN @servername IN ('SRV2012R2') THEN '"РИЦ 018"'
									 ELSE COALESCE(ProgramName, @ProgramName)
								 END
				 , @FTPServer = FTPServer
				 , @FTPPort = FTPPort
				 , @FTPuser = FTPUser
				 , @FTPpswd = FTPPswd
				 , @blocked_export = blocked_export
				 , @POPserver = POPserver
				 , @name_org = name_org
				 , @APP_NAME = dbo.fn_app_name()
				 , @use_koef_build = use_koef_build
				 , @Path_download = COALESCE(Path_download, @Path_download)
				 , @settings_developer = settings_developer
				 , @settings = settings_json
	FROM dbo.Global_values 
	WHERE (fin_id = @Fin_id1 OR @Fin_id1 IS NULL)
	ORDER BY fin_id DESC;

	SELECT @User_FIO = RTRIM(u.Initials)
		 , @user_id1 = u.id
		 , @blocked_personal = blocked_personal
		 , @SuperAdmin = SuperAdmin
		 , @Only_Sup = COALESCE(Only_sup, 0)
		 , @blocked_export =
							CASE
								WHEN @blocked_export = 1 THEN 1 -- блокировка по базе приоритет
								ELSE blocked_export
							END
		 , @blocked_print = blocked_print
		 , @FromUserMail = u.email
		 , @IsDeveloper = u.is_developer
	FROM dbo.Users AS u
	WHERE login = system_user;

	SELECT @App_name_download = app_name_download
		 , @app_folder = p.app_folder
	FROM dbo.Programs AS p
	WHERE (p.name = @APP_NAME);

	IF EXISTS (
			SELECT 1
			FROM dbo.Program_access AS pa 
				JOIN dbo.Programs AS p ON pa.program_id = p.id
			WHERE pa.[user_id] = @user_id1
				AND p.name = @APP_NAME
		)
		SET @AccessProgram = 1;
	ELSE
		SET @AccessProgram = 0;

	IF system_user = 'sa'
		SELECT @AccessProgram = 1
			 , @SuperAdmin = 1;

	SELECT @Rejim = dbo.Fun_GetRejim()
		 , @RejimAdm = dbo.Fun_GetRejimAdm();

	--OPEN MASTER KEY DECRYPTION BY PASSWORD = '23987hxJKL969#ghf0%94467GRkjg5k3fd117r$$#1946kcj$n44nhdlj'
	--PRINT @settings_developer

	-- разбор настроек разработчика в БД
	SELECT @ProgramName = CASE
                              WHEN COALESCE(t.ProgramName, '') <> '' THEN t.ProgramName
                              ELSE @ProgramName
        END
		 , @Author_txt = CASE
                             WHEN COALESCE(t.Author_txt, '') <> '' THEN t.Author_txt
                             ELSE @Author_txt
        END
		 , @Web_site = CASE
                           WHEN COALESCE(t.web_site, '') <> '' THEN t.web_site
                           ELSE @Web_site
        END
		 , @Path_download = CASE
                                WHEN COALESCE(t.Path_download, '') <> '' THEN t.Path_download
                                ELSE @Path_download
        END
	FROM OPENJSON(@settings_developer)
	WITH (
	ProgramName VARCHAR(50) '$.app.program_name',
	Author_txt VARCHAR(200) '$.app.author_txt',
	web_site VARCHAR(100) '$.app.web_site',
	Path_download VARCHAR(100) '$.app.path_download'
	) AS t


	SELECT @Yandex_dir =
						CASE
							WHEN @APP_NAME IN ('Картотека.exe', 'Счетчики.exe', 'Перерасчеты.exe', 'Отчёты.exe') THEN '/Kvart'
							ELSE '/Kvart_admin'
						END;

	SELECT HOST_NAME() AS [HOST_NAME]
		 , SYSTEM_USER AS [SYSTEM_USER]
		 , USER_NAME() AS [USER_NAME]
		 , @APP_NAME AS [APP_NAME]
		 , @servername AS SERVERNAME  --SUBSTRING(RTRIM(@@servername), 1, 10) 
		 , @User_FIO AS User_FIO
		 , @Fin_id1 AS fin_id
		 , @StrFinPeriod AS StrFinPeriod
		 , @Rejim AS Rejim
		 , @RejimAdm AS RejimAdm
		 , @AccessProgram AS AccessProgram
		 , @db_name AS [DB_NAME]
		 , dbo.Fun_User_readonly()                                                           AS UserReadOnly
		 , @user_id1                                                                         AS [USER_ID]
		 , @start_date                                                                       AS [start_date]
		 , @Msg_TimeOut                                                                      AS Msg_TimeOut
		 , @blocked_personal                                                                 AS blocked_personal
		 , @SuperAdmin                                                                       AS SuperAdmin
		 , @IsDeveloper                                                                      AS IsDeveloper
		 , @dir_new_version                                                                  AS dir_new_version
		 , @Only_Sup                                                                         AS Only_Sup

		 , CAST(CASE
                    WHEN EXISTS(SELECT 1 FROM dbo.AccessCessia) THEN 1
                    ELSE 0
        END AS BIT)                                                                          AS AccessCessia
		 , CAST(CASE
                    WHEN EXISTS(SELECT 1 FROM dbo.AccessIski) THEN 1
                    ELSE 0
        END AS BIT)                                                                          AS AccessIski
		 , CAST(CASE
                    WHEN EXISTS(SELECT 1 FROM dbo.AccessAgri) THEN 1
                    ELSE 0
        END AS BIT)                                                                       AS AccessAgri
		 , @AccessSubsidia                                                                AS AccessSubsidia
		 , CAST(CASE
                    WHEN EXISTS(SELECT 1 FROM dbo.AccessPenaltyOper) THEN 1
                    ELSE 0
        END AS BIT)                                                                       AS AccessPeny
		 , CAST(CASE
                    WHEN EXISTS(SELECT 1 FROM dbo.AccessCounterOper) THEN 1
                    ELSE 0
        END AS BIT)                                                                       AS AccessCounter
		 , CAST(CASE
                    WHEN EXISTS(SELECT 1 FROM dbo.AccessPeopleAddOper) THEN 1
                    ELSE 0
        END AS BIT)                                                                       AS AccessPeopleAdd
		 , CAST(CASE
                    WHEN EXISTS(SELECT 1 FROM dbo.AccessSaldoOper) THEN 1
                    ELSE 0
        END AS BIT)                                                                    AS AccessSaldoEdit
		 , CAST(CASE
                    WHEN EXISTS(SELECT 1 FROM dbo.AccessGMPOper) THEN 1
                    ELSE 0
        END AS BIT)                                                                    AS AccessGMP
		 , CAST(CASE
                    WHEN EXISTS(SELECT 1 FROM dbo.AccessUJF) THEN 1
                    ELSE 0
        END AS BIT)        AS AccessUJF
		 , CAST(CASE
                    WHEN EXISTS(SELECT 1 FROM dbo.AccessBufferOper) THEN 1
                    ELSE 0
        END AS BIT)        AS AccessBuffer
		 , CAST(CASE
                    WHEN EXISTS(SELECT 1 FROM dbo.AccessGisOper) THEN 1
                    ELSE 0
        END AS BIT)        AS AccessGis
		 , CAST(CASE
                    WHEN EXISTS(SELECT 1 FROM dbo.AccessPayOper) THEN 1
                    ELSE 0
        END AS BIT)        AS AccessPay

		 , @ProgramName    AS ProgramName
		 , @FTPServer      AS FTPServer
		 , @FTPPort        AS FTPPort
		 , @FTPuser        AS FTPuser
		 , @FTPpswd        AS FTPpswd
		 , @blocked_export AS blocked_export
		 , @blocked_print AS blocked_print
		 , @Web_site AS Web_site
		 , @Author_txt AS Author_txt
		 , @POPserver AS POPserver
		 , 8025 AS POPport
		 , @name_org AS name_org
		 , @FromMail AS FromMail
		 , COALESCE(@FromUserMail, '') AS FromUserMail
		 , '2c09552dfbc24e9ca67cada01348e064' AS Yandex_Token
		 , @Yandex_dir AS Yandex_dir
		 , @DLL_dir AS DLL_dir
		 , @Path_download AS Path_download
		 , @video_link AS video_link
		 , @App_name_download AS App_name_download
		 , @app_folder AS app_folder
		 , @use_koef_build AS use_koef_build
		 , (
			   SELECT TOP (1) client_net_address
			   FROM master.sys.dm_exec_connections
			   WHERE session_id = @@spid
		   ) AS client_net_address
		 , @settings AS settings
		 , @settings_developer AS settings_developer


	EXEC sys.sp_set_session_context @key = N'User_ID'
								  , @value = @user_id1
	EXEC sys.sp_set_session_context @key = N'User_FIO'
								  , @value = @User_FIO
go

