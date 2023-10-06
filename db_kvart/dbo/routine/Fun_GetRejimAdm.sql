CREATE   FUNCTION [dbo].[Fun_GetRejimAdm] ()
RETURNS VARCHAR(10)
AS
BEGIN
	--
	--  Функция возвращает текущий режим базы  (норм, стоп, чтен, адмч)
	--
	DECLARE	@Rejim	VARCHAR(10)

	SELECT
		@Rejim = COALESCE(dbstate_id, 'стоп')
	FROM dbo.DB_STATES
	WHERE is_current = cast(1 as bit);

	IF @Rejim IS NULL SET @Rejim='????'

	RETURN @Rejim;

END
go

