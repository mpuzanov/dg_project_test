CREATE   PROCEDURE [dbo].[adm_info_sysbasa]
AS
/*
	Процедура получения общей информации по физической базе

	exec adm_info_sysbasa
*/
	SET NOCOUNT ON

	DECLARE @name SYSNAME = DB_NAME()

	SELECT
		@name AS Basaname
	   ,CONVERT(SYSNAME, DATABASEPROPERTYEX(@name, 'Updateability')) AS Updateability
	   ,CONVERT(SYSNAME, DATABASEPROPERTYEX(@name, 'UserAccess')) AS UserAccess
	   ,(SELECT
				STR(CONVERT(DEC(15), SUM(f.SIZE)) * 8192 / 1048576, 9, 2) + ' Мб'
			FROM sys.sysfiles AS f
			)
		AS dbsize
go

