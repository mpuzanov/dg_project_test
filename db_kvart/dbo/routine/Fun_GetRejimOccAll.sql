CREATE   FUNCTION [dbo].[Fun_GetRejimOccAll]
(
	@occ INT = NULL
)
RETURNS VARCHAR(10)
AS
BEGIN
	/*
		Функция возвращает текущий режим по лицевому счёту (норм, стоп, чтен, адмн, адмч)

		не взирая на пользователей суперадминов
	*/
	DECLARE @Rejim VARCHAR(10) = 'норм'

	IF @occ IS NOT NULL
	BEGIN
		-- Проверяем режим по типу фонда
		SELECT
			@Rejim = OT.state_id
		FROM dbo.Occupations AS O 
		JOIN dbo.Occupation_Types AS OT 
			ON O.tip_id = OT.id
		WHERE O.Occ = @occ
	END

	IF @Rejim = 'норм'  -- то проверяем режим базы
		SELECT
			@Rejim = COALESCE(dbstate_id, 'стоп')
		FROM dbo.Db_states
		WHERE is_current = 1;

	RETURN (@Rejim)

END
go

