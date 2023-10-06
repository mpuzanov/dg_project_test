CREATE   PROCEDURE [dbo].[adm_kill_process]
(
	@spid1 INT
)
AS
	--
	--  Удаление процесса
	--
	SET NOCOUNT ON

	DECLARE @str1 VARCHAR(80)
	SET @str1 = 'KILL ' + CONVERT(VARCHAR(7), @spid1)

	--set @str1='master.dbo.xp_terminate_process ' +CONVERT(VARCHAR(7), @spid1)

	EXEC (@str1)
go

