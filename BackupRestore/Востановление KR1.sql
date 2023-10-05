-- Восстановление с G
Use master
ALTER DATABASE [kr1] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [kr1] FROM  DISK = N'G:\kr1.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
ALTER DATABASE [kr1] SET MULTI_USER
GO

-- Восстановление с IVC
Use master
ALTER DATABASE [kr1] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [kr1] FROM  DISK = N'E:\sql_backup\ivc\kr1_backup_2021_09_21_041033_5913505.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
ALTER DATABASE [kr1] SET MULTI_USER
GO

-- Восстановление с I
RESTORE DATABASE [kr1] FROM  DISK = N'I:\kr1.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO
-- Восстановление с G
RESTORE DATABASE [kr1] FROM  DISK = N'G:\kr1.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO

USE [master]
ALTER DATABASE [kr1] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [kr1] FROM  DISK = N'E:\sql_backup\ivc\kr1_backup_2021_07_21_040648_2616957.bak' WITH  FILE = 1,  
MOVE N'kr1' TO N'D:\sql_data\kr1.mdf',  
MOVE N'kr1_log' TO N'D:\sql_data\kr1_log.ldf',  
MOVE N'kr1_in_memory_file' TO N'D:\sql_data\kr1_in_memory_file',  
NOUNLOAD,  REPLACE,  STATS = 10
ALTER DATABASE [kr1] SET MULTI_USER
GO

-- Восстановление с E
RESTORE DATABASE [kr1] FROM  DISK = N'E:\kr1.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO

ALTER DATABASE [kr1] SET MULTI_USER
GO

--************************************************************************
-- восстановление архивной базы
USE [master]
RESTORE DATABASE [arx_kr1] FROM  DISK = N'E:\sql_backup\ivc\kr1_archive_20210406.bak' WITH  FILE = 1,  
MOVE N'kr1' TO N'D:\sql_data\kr1_1.mdf',  
MOVE N'kr1_log' TO N'D:\sql_data\kr1_log_1.ldf',  
MOVE N'kr1_in_memory_file' TO N'D:\sql_data\arx_kr1_in_memory_file',  
NOUNLOAD,  REPLACE,  STATS = 5

GO

--************************************************************************
USE [master]
RESTORE DATABASE [kv_empty] FROM  DISK = N'H:\kv_empty.bak' WITH  FILE = 1,  
MOVE N'kv_empty' TO N'G:\sql_data\kv_empty.mdf',  
MOVE N'kv_empty_log' TO N'G:\sql_data\kv_empty_log.ldf',  
NOUNLOAD,  REPLACE,  STATS = 5
GO

USE [master]
RESTORE DATABASE [kv_empty] FROM  DISK = N'H:\kv_empty.bak' WITH  FILE = 1,  
MOVE N'kv_empty' TO N'D:\sql_data\kv_empty.mdf',  
MOVE N'kv_empty_log' TO N'D:\sql_data\kv_empty_log.ldf',  
NOUNLOAD,  REPLACE,  STATS = 5
GO

-- Восстановление KV_ALL с I
RESTORE DATABASE [KV_ALL] FROM  DISK = N'I:\KV_ALL.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO
-- Восстановление KV_ALL с F
RESTORE DATABASE [KV_ALL] FROM  DISK = N'F:\KV_ALL.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO
-- Восстановление KV_ALL с H
RESTORE DATABASE [KV_ALL] FROM  DISK = N'H:\KV_ALL.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO
-- Восстановление KV_ALL с G
RESTORE DATABASE [KV_ALL] FROM  DISK = N'G:\KV_ALL.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO

/*
RESTORE DATABASE arx_kr2
FROM  DISK = N'c:\sql_backup\kr1_archive_20220304.bak' WITH  FILE = 1, 
MOVE N'kr1' TO N'C:\sql_data\kr1_2.mdf', MOVE N'kr1_log' TO N'C:\sql_data\kr1_log_2.ldf',  MOVE N'kr1_in_memory_file' TO N'C:\sql_data\arx_kr2_in_memory_file', 
NOUNLOAD,  REPLACE,  STATS = 10


USE [master]
RESTORE DATABASE [kr1] FROM  DISK = N'H:\kr1.bak' WITH  FILE = 1,  
MOVE N'kr1' TO N'G\sql_data\kr1.mdf',  
MOVE N'kr1_log' TO N'G:\sql_data\kr1_log.ldf',  
--MOVE N'memory_optimized_file_0' TO N'G:\sql_data\memory_optimized_file_0',  
MOVE N'kr1_in_memory_file' TO N'G:\sql_data\kr1_in_memory_file',
NOUNLOAD,  REPLACE,  STATS = 5
GO

USE [master]
RESTORE DATABASE [arx_naim] FROM  DISK = N'R:\sql_backup\naim_archive_20170426.bak' WITH  FILE = 1,  
MOVE N'naim_in_memory_file' TO N'R:\sql_data\arx_naim_in_memory_file',  
NOUNLOAD,  REPLACE,  STATS = 5
GO

RESTORE FILELISTONLY FROM DISK = 'E:\sql_backup\komp_backup.BAK'
RESTORE FILELISTONLY FROM DISK = 'E:\sql_backup\kr1_archive_20170426.bak'

После этой команды файл журнала потихоньку уменьшается
запись транзакций на диск
CHECKPOINT
GO

use kr1
CHECKPOINT
GO
dbcc shrinkfile(kr1,2000)
dbcc shrinkfile(kr1_Log,1000)

dbcc shrinkfile(komp_Data,15000)
dbcc shrinkfile(komp_Log,1000)

dbcc shrinkfile(kvart_Data,8000)
dbcc shrinkfile(kvart_Log,500)

DBCC CHECKDB

alter database [kr1] set single_user with rollback immediate
dbcc checkdb(kr1,repair_allow_data_loss)
alter database [kr1] set multi_user
dbcc checkconstraints with all_constraints
*/
