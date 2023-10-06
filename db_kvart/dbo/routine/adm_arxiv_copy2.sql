CREATE    PROCEDURE [dbo].[adm_arxiv_copy2] 
( @DirBasa varchar(50) = null,
  @DirLog  varchar(50) = null
)
AS
--
--  Востановление базы KOMP под именем KOMP2
--
--  Копия базы на сервере 
--
ALTER DATABASE komp2 set SINGLE_USER with rollback AFTER 5 SECONDS

if @DirBasa is Null
  set @DirBasa='r:\data\komp2_data.mdf'
else
  set @DirBasa=@DirBasa+'\komp2_data.mdf'

if @DirLog is Null
  set @DirLog='e:\log\komp2_log.ldf'
else
  set @DirLog=@DirLog+'\komp2_log.ldf'

RESTORE FILELISTONLY 
FROM DISK = 'e:\komp_bak\komp_backup.BAK' 
RESTORE DATABASE KOMP2 
FROM disk = 'e:\komp_bak\komp_backup.BAK' 
with REPLACE,
MOVE 'komp_data' TO @DirBasa, 
MOVE 'komp_log' TO @DirLog

ALTER DATABASE komp2 set MULTI_USER with rollback AFTER 5 SECONDS
go

