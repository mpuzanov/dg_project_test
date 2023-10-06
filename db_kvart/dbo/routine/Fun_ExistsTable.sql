CREATE   FUNCTION [dbo].[Fun_ExistsTable]
(
    @table1 VARCHAR(30)
)
RETURNS BIT
AS
--
--  Функция проверки существования временной таблицы
--
/*
  if dbo.FUN_EXISTSTABLE ('#t')=1
  select 'есть'
  else select 'нет'
*/

BEGIN
	IF object_id('tempdb..' + @table1) IS NOT NULL
	BEGIN
	    RETURN CAST(1 AS BIT)
	END
	RETURN CAST(0 AS BIT)
END
go

