CREATE   FUNCTION [dbo].[Fun_GetPosStringSplit]
(
	@val_in	NVARCHAR(2000)
	,@delimiter nchar(1) = N',' -- разделитель
	,@get_pos tinyint = 1
)
RETURNS NVARCHAR(50)
AS
BEGIN
	/*
	  Функция берёт элемент в заданной позиции

	  select [dbo].[Fun_GetPosStringSplit]('04,02', ',', 2)
	  -- 02
	  select [dbo].[Fun_GetPosStringSplit]('04,02', ',', 1)
	  -- 04
	  select [dbo].[Fun_GetPosStringSplit]('', ',', 2)
	  -- ''
	*/

	DECLARE @str_out VARCHAR(50)

    select top (1) @str_out = value
            from (select row_number() over (ORDER BY (SELECT NULL)) as row_num
                       , value
                  from string_split(@val_in, @delimiter)
                 ) as t
            where row_num = @get_pos

    return coalesce(@str_out,'')
END
go

