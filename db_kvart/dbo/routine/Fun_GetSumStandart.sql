CREATE   FUNCTION [dbo].[Fun_GetSumStandart] (@occ1 INT, @kol_people1 TINYINT)  
RETURNS DECIMAL(15,2) AS  
BEGIN 
/*
Возращаем величину стандарта стоимости жилья на определеннную дату

дата: 23.07.06
*/

DECLARE @res DECIMAL(15,2)


SELECT TOP 1 @res=st.tarif
FROM dbo.OCCUPATIONS AS o
    JOIN dbo.FLATS AS f ON o.flat_id=f.id
    JOIN dbo.BUILDINGS AS b ON f.bldn_id=b.id		 	
	JOIN dbo.STANDART_TARIF AS st ON b.standart_id=st.standart_id
WHERE o.occ=@occ1
	AND st.Kol_people<=@kol_people1
ORDER BY st.Kol_people DESC


IF @res IS NULL  SET  @res=0
 
RETURN @res
END
go

