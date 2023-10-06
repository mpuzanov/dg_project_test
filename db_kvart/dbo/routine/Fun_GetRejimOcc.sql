CREATE   FUNCTION [dbo].[Fun_GetRejimOcc]
(
	  @occ INT
)
RETURNS VARCHAR(10)
AS
BEGIN
	/*
		Функция возвращает текущий режим по лицевому счёту (норм, стоп, чтен, адмн, адмч)
	*/
	DECLARE @Rejim VARCHAR(10) = 'норм'

	IF NOT EXISTS (
			SELECT 1
			FROM dbo.Users u
			WHERE (u.login = system_user AND u.SuperAdmin = 1)
				OR system_user IN ('sa', 'NT SERVICE\SQLSERVERAGENT', 'UDMR\puzanov_ma', 'mfc-01-srv-10\manager', 'SRV2012R2\Михаил')
		)
	BEGIN
		-- Проверяем режим по типу фонда
		SELECT @Rejim = OT.state_id
		FROM dbo.Occupations AS O
			JOIN dbo.Occupation_Types AS OT 
				ON O.tip_id = OT.id
		WHERE O.occ = @occ;

		IF @Rejim = 'норм'  -- то берём режим базы
			SELECT @Rejim = dbo.Fun_GetRejim();
	END

	RETURN (@Rejim)

END
go

