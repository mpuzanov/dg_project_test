-- =============================================
-- Author:		Пузанов
-- Create date: 31.03.2016
-- Description:	Перевод числа в строку с разделителем "запятая"
-- =============================================
CREATE   FUNCTION [dbo].[nstr]
(
	@Number FLOAT
)
RETURNS VARCHAR(20)
WITH SCHEMABINDING
AS
/*
	Функция форматирования числел (без незначащих нулей)
	
	PRINT STR(0456.7834,15,6)
	PRINT dbo.nstr(0456.7834)	
	PRINT dbo.nstr(0456)
	PRINT dbo.nstr(null)

	SELECT 01456.7834, STR(01456.7834,15,6) as DEF_STR,  dbo.nstr(01456.7834) as nstr
	SELECT 01456, STR(01456,9,2) as DEF_STR,  dbo.nstr(01456) as nstr
*/
BEGIN
	RETURN replace(replace(convert(varchar(20), coalesce(@Number,0)),'.',','), char(160),'')
END
go

