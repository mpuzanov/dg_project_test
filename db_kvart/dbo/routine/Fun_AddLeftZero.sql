CREATE   FUNCTION [dbo].[Fun_AddLeftZero]
(
	@val_in	BIGINT
	,@n		TINYINT
)
RETURNS VARCHAR(50)
WITH SCHEMABINDING
AS
BEGIN
	/*
	  Функция добавляет 0 слева до числа @n
	  
	  select [dbo].[Fun_AddLeftZero](26, 6)
	  select [dbo].[Fun_AddLeftZero](100, 4)
	  select [dbo].[Fun_AddLeftZero](-100, 6)
	  select [dbo].[Fun_AddLeftZero](100, 1)
	*/

	RETURN CASE 
			WHEN @val_in>0 THEN RIGHT(REPLICATE('0', @n) + CAST(@val_in AS VARCHAR), @n)
			ELSE CAST(@val_in AS VARCHAR)
		END
END
go

exec sp_addextendedproperty 'MS_Description', N'Функция добавляет 0 слева до числа @n', 'SCHEMA', 'dbo', 'FUNCTION',
     'Fun_AddLeftZero'
go

