CREATE   FUNCTION [dbo].[fun_charlist_to_table]
                    (@list      nvarchar(max),
                     @delimiter nchar(1) = N',') -- разделитель 
         RETURNS @tbl TABLE (pole1 varchar(250),
                             pole2 varchar(250)) AS
/*
Вход: строка формата
значение1:значение2,значение1:значение2,значение1:значение2

Выход:  Таблица
значение1:значение2
значение1:значение2
значение1:значение2

Пример использования:
select * from dbo.Fun_charlist_to_table ('площ:9882.45; пгаз:0; лифт:678.78',';')

дата создания: 24.04.04
автор: Пузанов М.А.

дата последней модификации:  
автор изменений:  

*/ 
   BEGIN
      DECLARE @pos      int,
              @pos2      int,
              @textpos  int,
              @chunklen smallint,
              @tmpstr   nvarchar(4000),
              @leftover nvarchar(4000),
              @tmpval   nvarchar(4000),
              @tmpval1   nvarchar(4000),
              @tmpval2   nvarchar(4000)

      SET @textpos = 1
      SET @leftover = ''
      WHILE @textpos <= datalength(@list)
      BEGIN
         SET @chunklen = 4000 - datalength(@leftover)
         SET @tmpstr = @leftover + substring(@list, @textpos, @chunklen)
         SET @textpos = @textpos + @chunklen

         SET @pos = dbo.strpos(@delimiter, @tmpstr)

         WHILE @pos > 0
         BEGIN
            SET @tmpval = ltrim(rtrim(left(@tmpstr, dbo.strpos(@delimiter, @tmpstr) - 1)))
            SET @pos2=dbo.strpos(':', @tmpval)

            SET @tmpval1 = ltrim(rtrim(substring(@tmpval, 1, @pos2-1) ))
            SET @tmpval2 =  ltrim(rtrim(substring(@tmpval, @pos2+1, len(@tmpval)-@pos2) ))

            INSERT @tbl (pole1, pole2) VALUES(@tmpval1, @tmpval2)

            SET @tmpstr = substring(@tmpstr, @pos + 1, len(@tmpstr))
            SET @pos = dbo.strpos(@delimiter, @tmpstr)
         END

         SET @leftover = @tmpstr
         SET @tmpval = @tmpstr  
         if datalength(@tmpval)>1 -- если строка не завершается разделителем
         BEGIN
           SET @pos2=dbo.strpos(':', @tmpval)   
           SET @tmpval1 = ltrim(rtrim(substring(@tmpval, 1, @pos2-1) ))
           SET @tmpval2 =  ltrim(rtrim(substring(@tmpval, @pos2+1, len(@tmpval)-@pos2) ))
           INSERT @tbl (pole1, pole2) VALUES(@tmpval1, @tmpval2)
         END

      END
 
   RETURN
   END
go

