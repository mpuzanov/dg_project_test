CREATE   FUNCTION [dbo].[Fun_split_IdValue]
(
	@List		NVARCHAR(MAX)
	,@delimiter	NCHAR(1) = N',' -- разделитель 
) 
RETURNS @returntable TABLE
(
	id		NVARCHAR(50)
	,val	NVARCHAR(500)
)
AS
/*
Вход: строка формата
значение1:значение2,значение1:значение2,значение1:значение2

Выход:  Таблица
значение1:значение2
значение1:значение2
значение1:значение2

Пример использования:
select * from dbo.Fun_split_IdValue ('площ:9882.45; пгаз:0; лифт:678.78',';')
select * from dbo.Fun_split_IdValue ('площ:9882.45; пгаз:0; лифт:678.78;',';')
select * from dbo.Fun_split_IdValue ('',';')

дата создания: 23.03.17
автор: Пузанов М.А.

дата последней модификации:  
автор изменений:  

*/
BEGIN

	INSERT
	INTO @returntable
	(	id
		,val)
			SELECT
				LTRIM(SUBSTRING(value, 1, dbo.strpos(':', value) - 1))
				,LTRIM(SUBSTRING(value, dbo.strpos(':', value) + 1, LEN(value)))
			FROM STRING_SPLIT(@List, @delimiter) WHERE RTRIM(value) <> ''

	RETURN
END
go

