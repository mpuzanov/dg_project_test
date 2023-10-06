CREATE   FUNCTION [dbo].[strpos]
(
@ToFind nvarchar(100)
,@ToSearch nvarchar(1000)
)
RETURNS INT
AS 
/*
 * SELECT dbo.strpos('world', 'hello world');
 */
BEGIN
	return charindex(@ToFind, @ToSearch)
	
	/* Postgresql
	 * strpos(<где_ищем>, <что_ищем>)
	 * strpos(substring(<где_ищем>, <с_какой_позиции_ищем_начиная_с_1>, length(<где_ищем>)- <с_какой_позиции_ищем_начиная_с_1>+1), <что_ищем>)
	 */
END
go

exec sp_addextendedproperty 'MS_Description', N'возвращает расположение подстроки в строке или 0 если не найдена.',
     'SCHEMA', 'dbo', 'FUNCTION', 'strpos'
go

