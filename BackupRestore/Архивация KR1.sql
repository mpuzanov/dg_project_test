-- Архивация kr1 на G
use kr1
CHECKPOINT
use master
BACKUP DATABASE [kr1] TO  DISK = N'G:\kr1.bak' WITH NOFORMAT, INIT,  NAME = N'kr1-Полная База данных Резервное копирование', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'kr1' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'kr1' )
if @backupSetId is null begin raiserror(N'Ошибка верификации. Сведения о резервном копировании для базы данных "kr1" не найдены.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'G:\kr1.bak' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO


-- Архивация kr1 на H
use kr1
CHECKPOINT
use master
BACKUP DATABASE [kr1] TO  DISK = N'H:\kr1.bak' WITH NOFORMAT, INIT,  NAME = N'kr1-Полная База данных Резервное копирование', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'kr1' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'kr1' )
if @backupSetId is null begin raiserror(N'Ошибка верификации. Сведения о резервном копировании для базы данных "kr1" не найдены.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'H:\kr1.bak' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO

-- Архивация kr1 на F
BACKUP DATABASE [kr1] TO  DISK = N'F:\kr1.bak' WITH NOFORMAT, INIT,  NAME = N'kr1-Полная База данных Резервное копирование', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'kr1' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'kr1' )
if @backupSetId is null begin raiserror(N'Ошибка верификации. Сведения о резервном копировании для базы данных "kr1" не найдены.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'F:\kr1.bak' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO


-- *********************************************************************
-- Архивация kv_empty на H
BACKUP DATABASE [kv_empty] TO  DISK = N'H:\kv_empty.bak' WITH NOFORMAT, INIT,  NAME = N'kv_empty-Полная База данных Резервное копирование', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO

-- *********************************************************************

-- Архивация KV_ALL на H
BACKUP DATABASE [KV_ALL] TO  DISK = N'H:\KV_ALL.bak' WITH NOFORMAT, INIT,  NAME = N'KV_ALL-Полная База данных Резервное копирование', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO

