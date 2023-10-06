CREATE   FUNCTION [dbo].[Fun_AccessRaschetLic] ()
RETURNS TINYINT
AS
BEGIN
	--
	-- Проверка доступа для перерасчетов лицевых
	--
	-- 0 - Доступ запрещен;   1 - Разрешен
	--
	RETURN CAST(CASE
                    WHEN EXISTS(SELECT 1 FROM dbo.AccessRaschetOper) THEN 1
                    ELSE 0
        END AS TINYINT)

END
go

