CREATE   FUNCTION [dbo].[Fun_Capitalize]
	(@s NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
	/*
	Для функции СуммаПрописью (Первую букву в верхний регистр)
	*/
	RETURN UPPER(LEFT(@s,1))+RIGHT(@s,LEN(@s)-1)
END
go

exec sp_addextendedproperty 'MS_Description', N'Для функции СуммаПрописью (Первую букву в верхний регистр)', 'SCHEMA',
     'dbo', 'FUNCTION', 'Fun_Capitalize'
go

