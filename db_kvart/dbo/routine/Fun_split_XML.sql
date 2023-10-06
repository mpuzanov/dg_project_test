CREATE FUNCTION [dbo].[Fun_split_XML]
(
   @List       varchar(8000),
   @Delimiter  char(1)
)
/*
select * from dbo.Fun_split_XML('1,2,3,4',',')
*/
RETURNS TABLE WITH SCHEMABINDING
AS
   RETURN (SELECT [value] = y.i.value('(./text())[1]', 'varchar(8000)')
      FROM (SELECT x = CONVERT(XML, '<i>' 
          + REPLACE(@List, @Delimiter, '</i><i>') 
          + '</i>').query('.')
      ) AS a CROSS APPLY x.nodes('i') AS y(i));
go

