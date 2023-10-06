CREATE PROCEDURE [dbo].[adm_show_command]
(
	@spid INT
)
AS
	--
	--  Текущие процессы в базе 
	--  показываем команду
	--
	--
	SET NOCOUNT ON


	DECLARE @str VARCHAR(200)
	SET @str = 'DBCC INPUTBUFFER(' + LTRIM(STR(@spid)) + ')'

	IF EXISTS (SELECT
				1
			FROM master..sysprocesses
			WHERE spid = @spid)
		EXEC (@str)
go

