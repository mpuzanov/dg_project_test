CREATE   PROCEDURE [dbo].[k_GetVersionCard]
-- Проверяем версию картотечника
(
	@major1			INT
	,@minor1		INT
	,@release1		INT
	,@build1		INT
	,@oldversion	SMALLINT	OUTPUT
-- 0 - текущая версия картотечника
-- 1 - старая версия картотечника
-- 0 - новая версия картотечника
)
AS
	SET NOCOUNT ON

	DECLARE	@major		INT
			,@minor		INT
			,@release	INT
			,@build		INT

	SELECT
		@major = major
		,@minor = minor
		,@release = release
		,@build = build
	FROM VERSION

	SELECT
		@oldversion = 1 -- по умолчанию старая версия

	IF @major > @major1
		RETURN 0
	IF @minor > @minor1
		RETURN 0
	IF @release > @release1
		RETURN 0
	IF @build > @build1
		RETURN 0

	IF @major > @major1
		AND @minor = @minor1
		AND @release = @release1
		AND @build = @build1
	BEGIN
		SELECT
			@oldversion = 0   -- текущая версия
		RETURN 0
	END

	-- Обновляем версию
	UPDATE VERSION
	SET	major		= @major1
		,minor		= @minor1
		,release	= @release1
		,build		= @build1

	SELECT
		@oldversion = 2
go

