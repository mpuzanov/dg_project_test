-- =============================================
-- Author:		Пузанов
-- Create date: 20.02.2011
-- Description:	Получаем текущий фин.период для заданного типа жилого фонда

/* 
  Пример:
  SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)
  SELECT dbo.Fun_GetFinCurrent(NULL, NULL, NULL, NULL)
*/
-- =============================================
CREATE       FUNCTION [dbo].[Fun_GetFinCurrent]
(
	@tip_id		SMALLINT	= NULL
	,@buil_id	INT			= NULL
	,@flat_id	INT			= NULL
	,@occ		INT			= NULL
)
RETURNS SMALLINT
AS
BEGIN

	DECLARE @finCurrent SMALLINT = NULL

	IF @tip_id IS NOT NULL
		AND @buil_id IS NULL
		AND @flat_id IS NULL
		AND @occ IS NULL
	BEGIN
		SELECT
			@finCurrent = fin_id
		FROM dbo.OCCUPATION_TYPES 
		WHERE id = @tip_id;

		RETURN @finCurrent
	END

	IF @flat_id IS NOT NULL
		AND @buil_id IS NULL
		AND @occ IS NULL
		SELECT
			@buil_id = f.bldn_id
		FROM dbo.FLATS AS f  
		WHERE f.id = @flat_id;

	IF @occ IS NOT NULL
		AND @buil_id IS NULL
	BEGIN
		SELECT
			@finCurrent = b.fin_current
		FROM dbo.OCCUPATIONS AS o 
			JOIN dbo.Flats AS f 
				ON o.flat_id = f.id
			JOIN dbo.Buildings AS b 
				ON f.bldn_id = b.id
		WHERE o.occ = @occ;

		IF @finCurrent IS NOT NULL
			RETURN @finCurrent;
	END

	IF @buil_id IS NOT NULL
		SELECT
			@finCurrent = fin_current
		FROM dbo.BUILDINGS 
		WHERE id = @buil_id;

	IF @finCurrent IS NULL
		SELECT TOP 1
			@finCurrent = fin_id
		FROM dbo.OCCUPATION_TYPES
		ORDER BY fin_id DESC;

	RETURN @finCurrent;

END
go

exec sp_addextendedproperty 'MS_Description', N'Получаем текущий фин.период для заданных параметров', 'SCHEMA', 'dbo',
     'FUNCTION', 'Fun_GetFinCurrent'
go

