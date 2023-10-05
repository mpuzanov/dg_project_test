-- 	поиск по тексту процедур и триггеров
DECLARE @SubStr VARCHAR(8000), @SubStr2 VARCHAR(8000)=''
--SET @SubStr = 'STRING_SPLIT' -- нужная фраза в кавычках
SET @SubStr = 'ric\' -- нужная фраза в кавычках
--SET @SubStr2 = 'Occ_Suppliers' -- нужная вторая фраза в кавычках
SELECT
 o.name, o.type_desc, o.[type] --, c.text
FROM
 [sys].[objects] AS o
 INNER JOIN syscomments AS c
 ON o.object_id = c.id
WHERE
 c.text LIKE '%' + @SubStr + '%'
 --AND c.text LIKE '%' + @SubStr2 + '%'
 --AND o.[TYPE] IN ('P','FN','TF')
ORDER BY o.name
