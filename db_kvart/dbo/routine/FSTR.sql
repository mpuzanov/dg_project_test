-- =============================================
-- Author:		Пузанов
-- Create date: 31.03.2016
-- Description:	Перевод числа в строку с разделителем "запятая"
-- =============================================
CREATE   FUNCTION [dbo].[FSTR]
(
	@Number FLOAT,
	@length SMALLINT = 15,	
	@decimal SMALLINT = 0
)
RETURNS VARCHAR(20)
WITH SCHEMABINDING
AS
/*
	Функция форматирования числел (без незначащих нулей)

	PRINT STR(456.7834,15,6)
	PRINT dbo.FSTR(456.7834,15,6)	
	PRINT dbo.FSTR(456,15,6)

	SELECT 1456.7834, STR(1456.7834,15,6) as DEF_STR,  dbo.FSTR(1456.7834,15,6) as FSTR
	SELECT 1456, STR(1456,9,2) as DEF_STR,  dbo.FSTR(1456,9,2) as FSTR

	на функцию влияет SET LANGUAGE будет точка или запятая на выходе

	убираем неразрывный пробел (группировки) CHAR(160)
*/
BEGIN		
	RETURN replace(replace(convert(varchar(20), coalesce(@Number,0)),'.',','), char(160),'')
	--RETURN REPLACE(FORMAT(@Number,'G'), CHAR(160),'') 
END
go

exec sp_addextendedproperty 'MS_Description', N'Перевод числа в строку с разделителем "запятая"', 'SCHEMA', 'dbo',
     'FUNCTION', 'FSTR'
go

