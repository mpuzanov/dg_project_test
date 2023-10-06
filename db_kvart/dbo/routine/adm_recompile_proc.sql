CREATE PROCEDURE  [dbo].[adm_recompile_proc] AS
--
--  Перекомпиляция процедур и функций
--
declare @table_name sysname
declare mycurs cursor for select table_name from information_schema.tables where table_type = 'VIEW'
open mycurs
fetch next from mycurs into @table_name
while @@fetch_status = 0
begin
	print 'sp_refreshview '+@table_name
	EXEC('sp_refreshview '+@table_name)
	fetch next from mycurs into @table_name
end
close mycurs
deallocate mycurs
 
 
declare @proc_name nvarchar(128)
 
declare mycurs cursor for select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES
open mycurs
fetch next from mycurs into @proc_name
while @@fetch_status = 0
begin
	print 'sp_recompile '+@proc_name
	EXEC('sp_recompile '+@proc_name)
	fetch next from mycurs into @proc_name
end
close mycurs
deallocate mycurs
DBCC FREEPROCCACHE
go

