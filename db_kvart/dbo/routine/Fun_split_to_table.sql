CREATE   FUNCTION [dbo].[Fun_split_to_table]
(
	@List		NVARCHAR(MAX)
	,@Delimiter	NCHAR(1)
)
RETURNS @returntable TABLE
(
	id		NVARCHAR(50)
	,val	NVARCHAR(500)
)
AS
/*
select * from dbo.Fun_split_to_table('площ:9882.45; пгаз:0; лифт:678.78',';')
*/
BEGIN
	DECLARE @List2 NVARCHAR(MAX)
	WHILE dbo.strpos(@Delimiter, @List) > 0
	BEGIN
		SET @List2 = SUBSTRING(@List, 1, dbo.strpos(@Delimiter, @List) - 1)

		INSERT
		INTO @returntable
				SELECT
					LTRIM(SUBSTRING(@List2, 1, dbo.strpos(':', @List2) - 1))
					,LTRIM(SUBSTRING(@List2, dbo.strpos(':', @List2) + 1, LEN(@List2)))

		SET @List = LTRIM(SUBSTRING(@List, dbo.strpos(@Delimiter, @List) + 1, LEN(@List)))
	END
	IF @List <> ''
		INSERT
		INTO @returntable
				SELECT
					LTRIM(SUBSTRING(@List, 1, dbo.strpos(':', @List) - 1))
					,LTRIM(SUBSTRING(@List, dbo.strpos(':', @List) + 1, LEN(@List)))

	RETURN
END
go

