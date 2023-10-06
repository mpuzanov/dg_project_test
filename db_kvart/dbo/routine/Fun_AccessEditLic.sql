CREATE   FUNCTION [dbo].[Fun_AccessEditLic]
(
	@occ1 INT
)
RETURNS TINYINT
AS
BEGIN
/*
	 Проверка можно ли редактировать лицевой счет
	
	 0 - Редактирование  запрещено;   1 - Разрешено
	
*/
	DECLARE @result1 TINYINT
	SET @result1 = 0

	DECLARE	@Rejim		VARCHAR(10)
			,@Status_id	VARCHAR(10)

	SELECT
		@Rejim = dbo.Fun_GetRejimOcc(@occ1)

	SELECT
		@Status_id = status_id
	FROM dbo.VOCC 
	WHERE occ = @occ1

	IF (@Rejim = 'норм')
		AND (@Status_id <> 'закр')
		SET @result1 = 1

	RETURN @result1

END
go

