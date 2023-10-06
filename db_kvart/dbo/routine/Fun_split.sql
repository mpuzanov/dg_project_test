CREATE   FUNCTION [dbo].[Fun_split]
(
	 @List	NVARCHAR(MAX)
	,@Delimiter	NCHAR(1)
)
RETURNS @returntable TABLE
(
	value NVARCHAR(4000)
)
AS
/*
select * from [dbo].[Fun_split]('1,2,3,4',',')
*/
BEGIN

	WHILE dbo.strpos(@Delimiter, @List) > 0
	BEGIN
		INSERT INTO @returntable
				SELECT
					SUBSTRING(@List, 1, dbo.strpos(@Delimiter, @List) - 1)
		SET @List = SUBSTRING(@List, dbo.strpos(@Delimiter, @List) + 1, LEN(@List))
	END
	IF @List <> ''
		INSERT INTO @returntable
		VALUES (@List)

	RETURN
END
go

