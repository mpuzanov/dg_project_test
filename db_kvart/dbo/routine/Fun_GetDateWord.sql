-- Функция дата прописью
-- Тестируем:  SELECT dbo.FUN_GetDateWord(current_timestamp)
CREATE   FUNCTION [dbo].[Fun_GetDateWord] 
(
@dt DATETIME
)
RETURNS NVARCHAR(100)
AS
BEGIN
DECLARE @str NVARCHAR(100)

SELECT 
@str=CASE DATEPART(dd, @dt)
WHEN 1 THEN 'Первого '
WHEN 2 THEN 'Второго '
WHEN 3 THEN 'Третьего '
WHEN 4 THEN 'Четвертого '
WHEN 5 THEN 'Пятого '
WHEN 6 THEN 'Шестого '
WHEN 7 THEN 'Седьмого '
WHEN 8 THEN 'Восьмого '
WHEN 9 THEN 'Девятого '
WHEN 10 THEN 'Десятого '
WHEN 11 THEN 'Одиннадцатого '
WHEN 12 THEN 'Двенадцатого '
WHEN 13 THEN 'Тринадцатого '
WHEN 14 THEN 'Четырнадцатого '
WHEN 15 THEN 'Пятнадцатого '
WHEN 16 THEN 'Шестнадцатого '
WHEN 17 THEN 'Семнадцатого '
WHEN 18 THEN 'Восемнадцатого '
WHEN 19 THEN 'Девятнадцатого '
WHEN 20 THEN 'Двадцатого '
WHEN 21 THEN 'Двадцать первого '
WHEN 22 THEN 'Двадцать второго '
WHEN 23 THEN 'Двадцать третьего '
WHEN 24 THEN 'Двадцать четвертого '
WHEN 25 THEN 'Двадцать пятого '
WHEN 26 THEN 'Двадцать шестого '
WHEN 27 THEN 'Двадцать седьмого '
WHEN 28 THEN 'Двадцать восьмого '
WHEN 29 THEN 'Двадцать девятого '
WHEN 30 THEN 'Тридцатого '
WHEN 31 THEN 'Тридцать первого '
END
+
CASE DATEPART(mm, @dt)
WHEN 1 THEN 'января'
WHEN 2 THEN 'февраля'
WHEN 3 THEN 'марта'
WHEN 4 THEN 'апреля'
WHEN 5 THEN 'мая'
WHEN 6 THEN 'июня'
WHEN 7 THEN 'июля'
WHEN 8 THEN 'августа'
WHEN 9 THEN 'сентября'
WHEN 10 THEN 'октября'
WHEN 11 THEN 'ноября'
WHEN 12 THEN 'декабря'
END
+' '+
CASE LEFT(DATEPART(yy, @dt),2)
WHEN 19 THEN 'одна тысяча девятьсот '
WHEN 20 THEN 'две тысячи '
WHEN 21 THEN 'две тысячи сто '
END
+
CASE WHEN RIGHT(DATEPART(yy, @dt), 2) IN 
(10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 30, 40, 50, 60, 70, 80, 90)
THEN 
CASE RIGHT(DATEPART(yy, @dt), 2)
WHEN 10 THEN 'десятого'
WHEN 11 THEN 'одиннадцатого'
WHEN 12 THEN 'двенадцатого'
WHEN 13 THEN 'тринадцатого'
WHEN 14 THEN 'четырнадцатого'
WHEN 15 THEN 'пятнадцатого'
WHEN 16 THEN 'шестнадцатого'
WHEN 17 THEN 'семнадцатого'
WHEN 18 THEN 'восемнадцатого'
WHEN 19 THEN 'девятнадцатого'
WHEN 20 THEN 'двадцатого'
WHEN 30 THEN 'трицатого'
WHEN 40 THEN 'сорокового'
WHEN 50 THEN 'пятидесятого'
WHEN 60 THEN 'шестидесятого'
WHEN 70 THEN 'семидесятого'
WHEN 80 THEN 'восьмидесятого'
WHEN 90 THEN 'девяностого'
END

ELSE 

CASE RIGHT (DATEPART(yy, @dt),2)/10
WHEN 2 THEN 'двадцать'
WHEN 3 THEN 'тридцать'
WHEN 4 THEN 'сорок'
WHEN 5 THEN 'пятьдесят'
WHEN 6 THEN 'шестьдесят'
WHEN 7 THEN 'семьдесят'
WHEN 8 THEN 'восемьдесят'
WHEN 9 THEN 'девяносто'
END
+
CASE RIGHT (DATEPART(yy, @dt),1)
WHEN 1 THEN 'первого'
WHEN 2 THEN 'второго'
WHEN 3 THEN 'третьего'
WHEN 4 THEN 'четвертого'
WHEN 5 THEN 'пятого'
WHEN 6 THEN 'шестого'
WHEN 7 THEN 'седьмого'
WHEN 8 THEN 'восьмого'
WHEN 9 THEN 'девятого'
END

END 
+' года'


RETURN @str

END
go

