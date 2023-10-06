CREATE   FUNCTION [dbo].[Fun_AccessPayLic] ()
RETURNS TINYINT
AS
BEGIN
	/* Проверка доступа к  для работы с Платежами
	   
	   0 - Доступ запрещен;   1 - Разрешен
	*/
	RETURN CAST(CASE
                    WHEN EXISTS(SELECT 1 FROM dbo.AccessPayOper) THEN 1
                    ELSE 0
        END AS TINYINT)

END
go

