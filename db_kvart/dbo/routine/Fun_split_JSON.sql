CREATE   FUNCTION [dbo].[Fun_split_JSON]
(
  @List       varchar(8000),
  @Delimiter  char(1) -- ignored but made automated testing easier
)
/*
select * from dbo.Fun_split_JSON('1,2,3,4',',')
select * from dbo.Fun_split_JSON('123,22,AAA,777',',')  -- буквы не может
*/
RETURNS TABLE WITH SCHEMABINDING
AS
    RETURN (SELECT value FROM OPENJSON( CHAR(91) + @List + CHAR(93) ));
go

