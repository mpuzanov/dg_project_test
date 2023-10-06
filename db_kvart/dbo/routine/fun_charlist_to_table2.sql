CREATE   FUNCTION [dbo].[fun_charlist_to_table2]
                    (@list      nvarchar(max),
                     @delimiter nchar(1) = N',') -- разделитель 
         RETURNS @tbl TABLE (pole1 varchar(250)) AS

/*
Вход: строка формата
значение1,значение1,значение

Выход:  Таблица
значение1
значение1
значение1

Пример использования:
select * from dbo.Fun_charlist_to_table ('площ;пгаз;лифт',';')

дата создания: 21.03.05
автор: Пузанов М.А.

дата последней модификации:  
автор изменений:  

*/ 
   BEGIN
      DECLARE @pos      int,
              @textpos  int,
              @chunklen smallint,
              @tmpstr   nvarchar(4000),
              @leftover nvarchar(4000),
              @tmpval   nvarchar(4000)


      SET @textpos = 1
      SET @leftover = ''
      WHILE @textpos <= datalength(@list)
      BEGIN
         SET @chunklen = 4000 - datalength(@leftover)
         SET @tmpstr = @leftover + substring(@list, @textpos, @chunklen)
         SET @textpos = @textpos + @chunklen

         SET @pos = dbo.strpos(@delimiter, @tmpstr)
         --print @pos

         WHILE @pos > 0
         BEGIN
            SET @tmpval = ltrim(substring(@tmpstr, 1, @pos-1))
            --print @tmpstr

            INSERT @tbl (pole1) VALUES(@tmpval)

            SET @tmpstr = substring(@tmpstr, @pos + 1, len(@tmpstr))
            SET @pos = dbo.strpos(@delimiter, @tmpstr)
         END

         SET @leftover = @tmpstr
         SET @tmpval = @tmpstr 
         --print @tmpstr
         set @pos=datalength(@tmpval)

         if @pos>1 -- если строка не завершается разделителем
         BEGIN  
           SET @tmpval = ltrim(rtrim(substring(@tmpval, 1, @pos-1) ))
           INSERT @tbl (pole1) VALUES(@tmpval)
         END

      END
   RETURN
   END
go

