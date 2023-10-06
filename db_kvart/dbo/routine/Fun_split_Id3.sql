CREATE   FUNCTION [dbo].[Fun_split_Id3]
(
	@List			NVARCHAR(MAX)
	,@delimiter1	NCHAR(1)	= N';' -- разделитель1
	,@delimiter2	NCHAR(1)	= N',' -- разделитель2
)
RETURNS @returntable TABLE
(
	id1		NVARCHAR(500)
	,id2	NVARCHAR(500)
	,id3	NVARCHAR(500)
)
AS
/*
Вход: строка формата
значение1,значение2,значение3;значение1,значение2,значение3

Выход:  Таблица
значение1,значение2,значение3
значение1,значение2,значение3
значение1,значение2,значение3

Пример использования:
select * from dbo.Fun_split_Id3 ('площ,0,345.34;хвод,313,678.89;хвc2,313,-100',';',',')
select * from dbo.Fun_split_Id3 ('',';',',')

DECLARE @temp TABLE
(
	service_id VARCHAR(10)
	,sup_id INT
	,summa DECIMAL(9,2)
	,PRIMARY KEY(service_id,sup_id)
)
INSERT INTO @temp
select * from dbo.Fun_split_Id3 ('площ,0,345.34;хвод,313,678.89;хвc2,313,-100;',';',',')
select * FROM @temp

*/
BEGIN

	INSERT INTO @returntable
	SELECT
		t2.*
	FROM STRING_SPLIT(@List, @delimiter1) as t1
		CROSS APPLY (
			SELECT 
				 MAX(CAST(case when RowNumber = 1 then value else '' end AS NVARCHAR(500))) AS id1
				,MAX(CAST(case when RowNumber = 2 then value else '' end AS NVARCHAR(500))) AS id2
				,MAX(CAST(case when RowNumber = 3 then value else '' end AS NVARCHAR(500))) AS id3			
			FROM (
				SELECT 
					ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS RowNumber
					,value 
				FROM STRING_SPLIT(t1.value, @delimiter2)
				WHERE RTRIM(value) <> ''
			) as tmp
		) as t2
	WHERE RTRIM(t1.value) <> ''

	RETURN
END
go

