CREATE   PROCEDURE [dbo].[adm_permission](
    @del_permission BIT = 0 -- перед установкой прав убираем все права
, @debug BIT = 0
)
AS
/*
	 Процедура определяет права доступа к хранимым процедурам и таблицам
	 для групп admin, superoper, oper
	 Согласно состоянию базы установленному в DB_STATES
	 
	 adm_permission 1, 1
	--**************************************************************************************
*/
BEGIN
    SET NOCOUNT ON

    IF @del_permission IS NULL
        SET @del_permission = 1

    DECLARE @dbstate_id1 VARCHAR(10)
    SELECT @dbstate_id1 = dbstate_id
    FROM DB_STATES
    WHERE is_current = 1 -- Определяем состояние базы

    IF @debug = 1 PRINT N'Текущий режим: ' + @dbstate_id1

    DECLARE @tableName VARCHAR(100)
        ,@output_msg VARCHAR(80)
        ,@type CHAR(2)
        ,@ProcName VARCHAR(50)
        ,@FirstChar VARCHAR(10) --, @output_msg varchar(80)
        ,@err INT

    DECLARE @str_exec VARCHAR(1000)

BEGIN TRY

    DROP TABLE IF EXISTS #systable;
    CREATE TABLE #systable
    (
        name_obj VARCHAR(100) COLLATE database_default,
        TYPE     CHAR(2) COLLATE database_default,
        uid      INT default NULL
    )

    ;
    with cte as (SELECT SCHEMA_NAME(SCHEMA_ID) + '.' + LEFT(o.name, 128) as name, o.type, o.principal_id
                 FROM sys.objects AS o
                 where SCHEMA_NAME(SCHEMA_ID) = 'dbo'
    )
    INSERT
    INTO #systable(name_obj, TYPE, uid)
    select name, type, principal_id as length
    from cte

    if @debug=1 select count(name_obj) as [count objects] from #systable

    --*** Устанавливаем владельца DBO ***********************************
    IF @debug = 1 PRINT N'Устанавливаем владельца DBO'
    DECLARE table_curs CURSOR FOR
        SELECT name_obj
        FROM #systable
        WHERE ((TYPE = 'P')
            OR (TYPE = 'FN'))
          AND (uid is not null)
    OPEN table_curs
    FETCH NEXT FROM table_curs INTO @tableName
    WHILE (@@fetch_status = 0)
        BEGIN
            SET @str_exec = 'sp_changeobjectowner ''' + @tableName + ''', dbo'
            IF @debug = 1 PRINT @str_exec
            --   EXEC sp_changeobjectowner @tablename, 'dbo'
            EXEC (@str_exec)
            FETCH NEXT FROM table_curs INTO @tableName
        END
    CLOSE table_curs
    DEALLOCATE table_curs

    --region *** Убираем все права *****************************************************************
    IF @del_permission = 1
        BEGIN
            IF @debug = 1 PRINT N'Убераем все права на таблицы и хр. процедуры'
            DECLARE table_curs CURSOR FOR
                SELECT name_obj
                FROM #systable
                WHERE TYPE IN ('V', 'U')
                ORDER BY name_obj
            OPEN table_curs
            FETCH NEXT FROM table_curs INTO @tableName
            WHILE (@@fetch_status = 0)
                BEGIN
                    SET @str_exec = CONCAT(
                            'REVOKE  SELECT, UPDATE, DELETE, INSERT  ON ', @tableName,'  FROM ADMIN, OPER, SUPEROPER,OPER_READ ')
                    IF @debug = 1
                        PRINT @str_exec
                    EXEC (@str_exec)
                    FETCH NEXT FROM table_curs INTO @tableName
                END
            CLOSE table_curs
            DEALLOCATE table_curs

            -- хр.процедуры
            DECLARE proc_curs CURSOR FOR
                SELECT name_obj
                FROM #systable
                WHERE TYPE = 'P'
                ORDER BY name_obj
            OPEN proc_curs
            FETCH NEXT FROM proc_curs INTO @ProcName
            WHILE (@@fetch_status = 0)
                BEGIN
                    SET @str_exec = CONCAT('REVOKE EXECUTE ON ', @ProcName,' FROM ADMIN, OPER, SUPEROPER')
                    IF @debug = 1 PRINT @str_exec
                    EXEC (@str_exec)
                    FETCH NEXT FROM proc_curs INTO @ProcName
                END
            CLOSE proc_curs
            DEALLOCATE proc_curs
        END
    --endregion *** Убераем все права *************************************************************************

    --region *** стоп ******************************************************************************
    IF (@dbstate_id1 = N'стоп')
        OR (@dbstate_id1 IS NULL)
        BEGIN
            IF @debug = 1 PRINT N'Установка прав доступа на таблицы. Режим: стоп'
            -- хр.процедуры
            IF @debug = 1 PRINT N'Установка прав доступа на хранимые процедуры Режим: стоп'
            --DECLARE proc_curs CURSOR FOR
            --	SELECT
            --		name_obj
            --	FROM #systable
            --	WHERE TYPE = 'P'
            --	ORDER BY name_obj
            --OPEN proc_curs
            --FETCH NEXT FROM proc_curs INTO @ProcName
            --WHILE (@@fetch_status = 0)
            --BEGIN
            --	IF @ProcName IN ('dbo.k_activity_2')
            --		EXEC ('GRANT  EXECUTE  ON ' + @ProcName + '  TO ADMIN, SUPEROPER ')
            --	PRINT @output_msg
            --	FETCH NEXT FROM proc_curs INTO @ProcName
            --END
            --CLOSE proc_curs
            --DEALLOCATE proc_curs

            -- нужна для проверки режима базы
            GRANT EXECUTE ON k_AccessBasaKomp TO admin, oper, superoper, oper_read

        END
    --endregion *** стоп ******************************************************************************

    --region *** чтен ******************************************************************************
    IF (@dbstate_id1 = N'чтен')
        BEGIN
            IF @debug = 1 PRINT N'Установка прав доступа на таблицы. Режим: чтен'
            DECLARE table_curs CURSOR FOR
                SELECT name_obj
                FROM #systable
                WHERE TYPE IN ('V', 'U', 'IF')
                ORDER BY name_obj
            OPEN table_curs
            FETCH NEXT FROM table_curs INTO @tableName
            WHILE (@@fetch_status = 0)
                BEGIN
                    SET @str_exec =
                            CONCAT('GRANT SELECT ON ', @tableName,' TO ADMIN, OPER, SUPEROPER, OPER_READ')
                    IF @debug = 1 PRINT @str_exec                    
                    EXECUTE(@str_exec)
                    FETCH NEXT FROM table_curs INTO @tableName
                END
            CLOSE table_curs
            DEALLOCATE table_curs

            -- хр.процедуры
            PRINT ' '
            IF @debug = 1 PRINT N'Установка прав доступа на хранимые процедуры Режим: ' + @dbstate_id1
            DECLARE proc_curs CURSOR FOR
                SELECT name_obj
                FROM #systable
                WHERE TYPE = 'P'
                ORDER BY name_obj
            OPEN proc_curs
            FETCH NEXT FROM proc_curs INTO @ProcName
            WHILE (@@fetch_status = 0)
                BEGIN
                    SELECT @FirstChar = SUBSTRING(@ProcName, 1, dbo.strpos('_', @ProcName))
                    IF (@FirstChar = 'dbo.adm_')
                        SET @str_exec = CONCAT('GRANT  EXECUTE  ON  ', @ProcName,' TO ADMIN, SUPEROPER')
                    IF (@FirstChar IN ('dbo.k_', 'dbo.rep_', 'dbo.ka_', 'dbo.b_', 'dbo.ws_', 'dbo.usp_'))
                        SET @str_exec =
                                CONCAT('GRANT  EXECUTE  ON  ', @ProcName,' TO ADMIN, OPER, SUPEROPER, OPER_READ')
                    IF @debug = 1 PRINT @str_exec
                    EXEC (@str_exec)
                    FETCH NEXT FROM proc_curs INTO @ProcName
                END
            CLOSE proc_curs
            DEALLOCATE proc_curs

            GRANT UPDATE, DELETE, INSERT ON PEOPLE TO admin, superoper
            GRANT UPDATE, DELETE, INSERT ON PEOPLE_2 TO admin, superoper
            GRANT UPDATE, DELETE, INSERT ON BANK TO admin, superoper
            GRANT UPDATE, DELETE, INSERT ON BANK_DBF_TMP TO admin, oper, superoper, oper_read
            GRANT UPDATE, DELETE, INSERT ON BANK_DBF2_TMP TO admin, oper, superoper, oper_read
        END
    --endregion *** чтен ******************************************************************************

    --region *** норм ******************************************************************************
    IF (@dbstate_id1 = N'норм')
        BEGIN
            IF @debug = 1 PRINT N'Установка прав доступа на таблицы. Режим: норм'
            DECLARE table_curs CURSOR FOR
                SELECT name_obj
                FROM #systable
                WHERE TYPE IN ('V', 'U', 'IF')
                ORDER BY name_obj
            OPEN table_curs
            FETCH NEXT FROM table_curs INTO @tableName
            WHILE (@@fetch_status = 0)
                BEGIN
                    SET @str_exec =
                            CONCAT('GRANT SELECT  ON  ', @tableName,' TO ADMIN, OPER, SUPEROPER, OPER_READ')
                    EXEC (@str_exec)

                    -- добавляем права администратору
                    SET @str_exec = CONCAT('GRANT SELECT,UPDATE,DELETE,INSERT ON  ', @tableName,' TO ADMIN')
                    EXEC (@str_exec)
                    FETCH NEXT FROM table_curs INTO @tableName
                END
            CLOSE table_curs
            DEALLOCATE table_curs

            GRANT ALTER ON Occ_suppliers TO admin;
            GRANT ALTER ON Counter_list_all TO admin;
            GRANT ALTER ON Comp_serv_all TO admin;
            GRANT ALTER ON Suppliers TO admin;

            -- только группе  OPER_READ не даем право изменять таблицы
            GRANT UPDATE, DELETE, INSERT ON CONSMODES_LIST TO admin, oper, superoper
            GRANT UPDATE, DELETE, INSERT ON PEOPLE TO admin, oper, superoper
            GRANT UPDATE, DELETE, INSERT ON PEOPLE_2 TO admin, oper, superoper
            GRANT UPDATE, DELETE, INSERT ON PEOPLE_IMAGE TO admin, oper, superoper
            GRANT UPDATE, DELETE, INSERT ON PEOPLE_LISTOK TO admin, oper, superoper
            GRANT UPDATE, DELETE, INSERT ON OCCUPATIONS TO admin, oper, superoper
            GRANT UPDATE, DELETE, INSERT ON Occ_Suppliers TO admin, oper, superoper
            GRANT UPDATE, DELETE, INSERT ON FLATS TO admin, oper, superoper
            GRANT UPDATE, DELETE, INSERT ON KOEF_OCC TO admin, oper, superoper
            GRANT UPDATE, DELETE, INSERT ON BUILDINGS TO admin, superoper
            GRANT UPDATE, DELETE, INSERT ON DOG_SUP TO admin, superoper
            GRANT UPDATE, DELETE, INSERT ON OCCUPATION_TYPES TO admin, superoper
            GRANT UPDATE, DELETE, INSERT ON COMPENSAC_TMP TO admin, oper, superoper
            GRANT UPDATE, DELETE, INSERT ON BANK_DBF_TMP TO admin, oper, superoper, oper_read
            GRANT UPDATE, DELETE, INSERT ON BANK_DBF2_TMP TO admin, oper, superoper, oper_read
            GRANT UPDATE, DELETE, INSERT ON BANKDBF_COMMENTS TO admin, superoper
            GRANT UPDATE, DELETE, INSERT ON PRINT_GROUP TO admin, oper, superoper, oper_read
            GRANT UPDATE, DELETE, INSERT ON PRINT_OCC TO admin, oper, superoper, oper_read
            GRANT UPDATE, DELETE, INSERT ON OPS TO admin, oper, superoper, oper_read
            GRANT UPDATE, DELETE, INSERT ON OCC_NOT_print TO admin, oper, superoper, oper_read
            GRANT UPDATE, DELETE, INSERT ON AGRICULTURE_OCC TO admin, oper, superoper
            GRANT UPDATE, DELETE, INSERT ON COUNTER_LIST_ALL TO admin, oper, superoper
			GRANT UPDATE, DELETE, INSERT ON Counter_inspector TO admin, oper, superoper
            GRANT UPDATE, DELETE, INSERT ON ROOMS TO admin, oper, superoper
            GRANT UPDATE, DELETE, INSERT ON SECTOR TO admin
            GRANT UPDATE, DELETE, INSERT ON CONS_MODES TO admin
            GRANT UPDATE, DELETE, INSERT ON SERVICE_UNITS TO admin
            GRANT UPDATE, DELETE, INSERT ON GLOBAL_VALUES TO admin
            GRANT UPDATE, DELETE, INSERT ON BANK TO admin, superoper
            GRANT UPDATE, DELETE, INSERT ON PAYCOLL_ORGS TO admin, superoper
            GRANT UPDATE, DELETE, INSERT ON PERSON_STATUSES TO admin
            GRANT UPDATE, DELETE, INSERT ON PERSON_CALC TO admin
            GRANT UPDATE, DELETE, INSERT ON [STATUS] TO admin
            GRANT UPDATE, DELETE, INSERT ON IDDOC_TYPES TO admin
            GRANT UPDATE, DELETE, INSERT ON SUPPLIERS TO admin
            GRANT UPDATE, DELETE, INSERT ON FAM_RELATIONS TO admin
            GRANT SELECT, UPDATE, DELETE, INSERT ON PID TO admin, oper, superoper, oper_read

            DENY UPDATE, DELETE, INSERT ON CONSMODES_LIST TO oper_read
            DENY UPDATE, DELETE, INSERT ON PEOPLE TO oper_read
            DENY UPDATE, DELETE, INSERT ON PEOPLE_2 TO oper_read
            DENY UPDATE, DELETE, INSERT ON IDDOC_TYPES TO oper_read
            DENY UPDATE, DELETE, INSERT ON OCCUPATIONS TO oper_read
            DENY UPDATE, DELETE, INSERT ON FLATS TO oper_read
            DENY UPDATE, DELETE, INSERT ON KOEF_OCC TO oper_read
            DENY UPDATE, DELETE, INSERT ON BUILDINGS TO oper_read

            -- Даем права на изменяемые Представления
            GRANT UPDATE, DELETE, INSERT ON dbo.VOCC_TYPES TO [admin]
            GRANT UPDATE, DELETE, INSERT ON dbo.VOCC TO admin, superoper, oper

            --*** норм ******************************************************************************
            -- хр.процедуры
            IF @debug = 1 PRINT N'Установка прав доступа на хранимые процедуры. Режим: норм'
            DECLARE proc_curs CURSOR FOR
                SELECT name_obj
                FROM #systable
                WHERE TYPE = 'P'
                ORDER BY name_obj
            OPEN proc_curs
            FETCH NEXT FROM proc_curs INTO @ProcName
            WHILE (@@fetch_status = 0)
                BEGIN
                    SET @str_exec =
                            CONCAT('GRANT  EXECUTE  ON  ', @ProcName,'  TO ADMIN, OPER, SUPEROPER, OPER_READ')
                    IF @debug = 1 PRINT @str_exec
                    EXEC (@str_exec)
                    FETCH NEXT FROM proc_curs INTO @ProcName
                END
            CLOSE proc_curs
            DEALLOCATE proc_curs

            --*** норм ******************************************************************************
            --  ФУНКЦИИ
            IF @debug = 1 PRINT N'Установка прав доступа на функции. Режим: норм'
            DECLARE proc_curs CURSOR FOR
                SELECT name_obj
                     , TYPE
                FROM #systable
                WHERE TYPE IN ('FN', 'FS') --, 'TF'
                ORDER BY name_obj
            OPEN proc_curs
            FETCH NEXT FROM proc_curs INTO @ProcName, @type
            WHILE (@@fetch_status = 0)
                BEGIN
                    EXEC ('GRANT  EXECUTE  ON ' + @ProcName + '  TO ADMIN, OPER, SUPEROPER, OPER_READ')
                    FETCH NEXT FROM proc_curs INTO @ProcName, @type
                END
            CLOSE proc_curs
            DEALLOCATE proc_curs

        END
    --endregion *** норм *************************************************************

    --region *** адмн ******************************************************************************
    IF (@dbstate_id1 = N'адмн')
        BEGIN
            IF @debug = 1 PRINT N'Установка прав доступа на таблицы. Режим: адмн'
            DECLARE table_curs CURSOR FOR
                SELECT name_obj
             FROM #systable
                WHERE TYPE IN ('V', 'U', 'IF')
                ORDER BY name_obj
            OPEN table_curs
            FETCH NEXT FROM table_curs INTO @tableName
            WHILE (@@fetch_status = 0)
                BEGIN
                    EXEC ('GRANT SELECT  ON ' + @tableName + '  TO ADMIN')
                    -- добавляем права администратору
                    EXEC ('GRANT SELECT,UPDATE,DELETE,INSERT  ON ' + @tableName + '  TO ADMIN')

                    FETCH NEXT FROM table_curs INTO @tableName
                END
            CLOSE table_curs
            DEALLOCATE table_curs

            --*** адмн ******************************************************************************
            -- хр.процедуры
            IF @debug = 1 PRINT N'Установка прав доступа на хранимые процедуры. Режим: адмн'
            DECLARE proc_curs CURSOR FOR
                SELECT name_obj
                FROM #systable
                WHERE TYPE = 'P'
                ORDER BY name_obj
            OPEN proc_curs
            FETCH NEXT FROM proc_curs INTO @ProcName
            WHILE (@@fetch_status = 0)
                BEGIN
                    SET @str_exec = CONCAT('GRANT  EXECUTE  ON ', @ProcName,' TO ADMIN')
                    IF @debug = 1 PRINT @str_exec
                    EXEC (@str_exec)
                    FETCH NEXT FROM proc_curs INTO @ProcName
                END
            CLOSE proc_curs
            DEALLOCATE proc_curs

            --*** адмн ******************************************************************************
            --  ФУНКЦИИ
            IF @debug = 1 PRINT N'Установка прав доступа на функции. Режим: адмн'
            DECLARE proc_curs CURSOR FOR
                SELECT name_obj
                FROM #systable
                WHERE TYPE IN ('FN', 'FS')
                ORDER BY name_obj
            OPEN proc_curs
            FETCH NEXT FROM proc_curs INTO @ProcName
            WHILE (@@fetch_status = 0)
                BEGIN
                    SET @str_exec = CONCAT('GRANT  EXECUTE  ON ', @ProcName,' TO ADMIN')
                    IF @debug = 1 PRINT @str_exec
                    EXEC (@str_exec)
                    FETCH NEXT FROM proc_curs INTO @ProcName
                END
            CLOSE proc_curs
            DEALLOCATE proc_curs

        END
    --endregion *** адмн *************************************************************

    --region *** адмч ******************************************************************************
    IF (@dbstate_id1 = N'адмч')
        BEGIN
            IF @debug = 1 PRINT N'Установка прав доступа на таблицы. Режим: адмч'
            DECLARE table_curs CURSOR FOR
                SELECT name_obj
                FROM #systable
                WHERE TYPE IN ('V', 'U', 'IF')
                ORDER BY name_obj
            OPEN table_curs
            FETCH NEXT FROM table_curs INTO @tableName
            WHILE (@@fetch_status = 0)
                BEGIN
                    EXEC ('GRANT SELECT  ON ' + @tableName + '  TO ADMIN, OPER, SUPEROPER, OPER_READ')

                    -- добавляем права администратору
                    EXEC ('GRANT SELECT,UPDATE,DELETE,INSERT ON ' + @tableName + ' TO ADMIN')

                    -- закрываем изменения у других
                    EXEC ('DENY UPDATE,DELETE,INSERT  ON ' + @tableName + '  TO OPER, SUPEROPER, OPER_READ')

                    FETCH NEXT FROM table_curs INTO @tableName
                END
            CLOSE table_curs
            DEALLOCATE table_curs

            --*** адмч ******************************************************************************
            -- хр.процедуры
            IF @debug = 1 PRINT N'Установка прав доступа на хранимые процедуры. Режим: адмч'
            DECLARE proc_curs CURSOR FOR
                SELECT name_obj
                FROM #systable
                WHERE TYPE = 'P'
                ORDER BY name_obj
            OPEN proc_curs
            FETCH NEXT FROM proc_curs INTO @ProcName
            WHILE (@@fetch_status = 0)
                BEGIN
                    SELECT @FirstChar = SUBSTRING(@ProcName, 1, dbo.strpos('_', @ProcName))
                    IF (@FirstChar = 'dbo.adm_')
                        SET @str_exec = CONCAT('GRANT  EXECUTE  ON  ', @ProcName,' TO ADMIN, SUPEROPER')
                    IF (@FirstChar IN ('dbo.k_', 'dbo.rep_', 'dbo.ka_', 'dbo.b_', 'dbo.ws_', 'dbo.usp_'))
                        SET @str_exec =
                                CONCAT('GRANT  EXECUTE  ON  ', @ProcName,' TO ADMIN, SUPEROPER, SUPEROPER, OPER_READ')
                    IF @debug = 1 PRINT @str_exec
                    EXEC (@str_exec)

                    FETCH NEXT FROM proc_curs INTO @ProcName
                END
            CLOSE proc_curs
            DEALLOCATE proc_curs

            --*** адмч ******************************************************************************
            --  ФУНКЦИИ
            IF @debug = 1 PRINT N'Установка прав доступа на функции. Режим: адмч'
            DECLARE proc_curs CURSOR FOR
                SELECT name_obj
                FROM #systable
                WHERE TYPE IN ('FN', 'FS')
                ORDER BY name_obj
            OPEN proc_curs
            FETCH NEXT FROM proc_curs INTO @ProcName
            WHILE (@@fetch_status = 0)
                BEGIN
                    EXEC ('GRANT EXECUTE ON ' + @ProcName + ' TO ADMIN, OPER, SUPEROPER, OPER_READ');

                    FETCH NEXT FROM proc_curs INTO @ProcName
                END
            CLOSE proc_curs
            DEALLOCATE proc_curs

        END
    --endregion *** адмч *************************************************************


    GRANT SELECT, UPDATE, DELETE, INSERT ON TYPE_GIS_FILE TO admin, oper, superoper
    GRANT SELECT, UPDATE, DELETE, INSERT ON SERVICES_TYPE_GIS TO admin, oper, superoper
    GRANT SELECT, UPDATE, DELETE, INSERT ON ACCOUNT_EMAIL TO admin, oper, superoper
	GRANT SELECT, UPDATE ON Reports_favorites TO admin, oper, superoper
    GRANT SELECT, UPDATE ON SERVICES_TYPES (service_name_gis) TO admin, oper, superoper
	
    GRANT SELECT, UPDATE, DELETE, INSERT ON ACTIVITY TO admin, oper, superoper, oper_read
    GRANT UPDATE, DELETE, INSERT ON BANKDBF_COMMENTS TO admin, superoper
    GRANT UPDATE, DELETE, INSERT ON BANK_FORMAT TO admin, superoper
    GRANT UPDATE, DELETE, INSERT ON BANK_TBL_SPISOK TO admin, superoper
    GRANT UPDATE, DELETE, INSERT ON BANK_DBF_LOG TO admin, superoper
    GRANT UPDATE, DELETE, INSERT ON Errors_occ TO admin, superoper

    -- Даем права на изменяемые Представления
    GRANT UPDATE, DELETE, INSERT ON dbo.VOCC_TYPES TO [admin]
    GRANT UPDATE, DELETE, INSERT ON dbo.VOCC TO [admin]

    -- для всех режимов
    GRANT EXECUTE ON adm_dsc_groups TO admin, oper, superoper
    GRANT EXECUTE ON adm_occup_types TO admin, oper, superoper
    GRANT EXECUTE ON adm_readsector TO admin, oper, superoper

    GRANT EXECUTE ON adm_create_dolg2 TO admin, superoper
    GRANT EXECUTE ON adm_bank_add TO admin, superoper
    GRANT EXECUTE ON adm_bank_del TO admin, superoper
    GRANT EXECUTE ON adm_bank_show TO admin, superoper
    GRANT EXECUTE ON adm_bank_account_show TO admin, superoper
    GRANT EXECUTE ON adm_info_sysbasa TO admin, superoper

    GRANT EXECUTE ON dbo.adm_CloseDay TO admin, superoper
    GRANT EXECUTE ON dbo.adm_create_pack TO admin, superoper
    GRANT EXECUTE ON dbo.adm_packs_show TO admin, superoper
    GRANT EXECUTE ON dbo.adm_packs_show_fin TO admin, superoper
    GRANT EXECUTE ON dbo.adm_packs_out TO admin, superoper

    GRANT EXECUTE ON adm_change_schtl TO admin, oper, superoper
    GRANT EXECUTE ON adm_showbuild_1 TO admin, oper, superoper
    GRANT EXECUTE ON adm_info_show TO admin, oper, superoper
    GRANT EXECUTE ON adm_show_banks TO admin, oper, superoper

    GRANT EXECUTE ON k_adderrors_card TO admin, oper, superoper, oper_read
    GRANT EXECUTE ON dbo.k_msg_read TO admin, oper, superoper, oper_read
    GRANT EXECUTE ON dbo.k_activity_1 TO admin, oper, superoper, oper_read
    GRANT EXECUTE ON dbo.k_activity_2 TO admin, oper, superoper, oper_read
    GRANT EXECUTE ON dbo.k_activity_3 TO admin, oper, superoper, oper_read

    GRANT EXECUTE ON dbo.k_AccessBasaKomp TO admin, oper, superoper, oper_read
    GRANT EXECUTE ON dbo.k_ulica TO admin, oper, superoper, oper_read
    GRANT EXECUTE ON dbo.k_dom TO admin, oper, superoper, oper_read
    GRANT EXECUTE ON dbo.k_kvartira_1 TO admin, oper, superoper, oper_read
    GRANT EXECUTE ON dbo.k_monthYear2 TO admin, oper, superoper, oper_read

    GRANT ALTER ON OBJECT::dbo.GeneratePeolpleSequence TO admin, oper, superoper
    GRANT UPDATE ON OBJECT::dbo.GeneratePeolpleSequence TO admin, oper, superoper

    /*
USE [master]  
GO
GRANT VIEW SERVER STATE TO [public]   -- для запуска sysprocesses пользователями
GO

USE [msdb]  
GO
grant execute on sp_send_dbmail to public
GO
*/

END TRY
BEGIN CATCH
	EXEC dbo.k_err_messages
END CATCH

END
go

