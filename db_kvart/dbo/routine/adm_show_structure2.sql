CREATE   PROCEDURE [dbo].[adm_show_structure2]
AS
	--
	--  Выдаем список таблиц в базе с описанием
	--
	SET NOCOUNT ON

	DECLARE @table VARCHAR(30)
		   ,@descr SQL_VARIANT

	CREATE TABLE #t
	(
		PriKey		 INT PRIMARY KEY IDENTITY (1, 1)
	   ,table_name	 SYSNAME
	   ,descriptions SQL_VARIANT
	)

	--set @table='STREETS'

	DECLARE curs1 CURSOR FOR
		SELECT
			s1.name
		FROM sysobjects AS s1
		WHERE type = 'U'
		ORDER BY 1
	OPEN curs1
	FETCH NEXT FROM curs1 INTO @table
	WHILE (@@fetch_status = 0)
	BEGIN

		SET @descr = ''

		SELECT
			@descr = value
		FROM ::fn_listextendedproperty
		(NULL, 'user', 'dbo', 'table', @table, NULL, NULL) --'column'

		INSERT INTO #t
		VALUES (@table
			   ,@descr)

		FETCH NEXT FROM curs1 INTO @table
	END
	CLOSE curs1
	DEALLOCATE curs1

	SELECT
		*
	FROM #t
go

