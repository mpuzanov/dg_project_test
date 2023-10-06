CREATE   PROCEDURE [dbo].[rep_svod_mode_all]
(
	@fin_id1		SMALLINT
	, @tip_id			SMALLINT	= NULL
	, @build			INT			= NULL
	, @service_id1	VARCHAR(10)	= NULL
	, @mode_id1		INT			= NULL
	, @source_id1		INT			= NULL
	, @fin_id2		SMALLINT	= NULL
)
AS
	/*
Пузанов
11.11.12

Отчет: аналитика

-- тестирование
DECLARE	@return_value int
EXEC	@return_value = [dbo].[rep_svod_mode_all]
		@fin_id1 = 244,
		@fin_id2 = 244
SELECT	'Return Value' = @return_value

GO

*/

	SET NOCOUNT ON

	IF @fin_id2 IS NULL
		SET @fin_id2 = @fin_id1

	SELECT
		GV.[start_date]
		,b.town_name AS 'Населённый пункт'
		,b.tip_name AS 'Тип фонда'
		,b.div_name AS 'Район'
		,b.sector_name AS 'Участок'
		,b.adres AS 'Адрес дома'
		,s.name AS 'Услуга'
		,cm.name AS 'Режим'
		,sup.name AS 'Поставщик'
		,CASE ds.is_counter
			WHEN 2 THEN 'Есть'
			ELSE 'Нет'
		END AS 'Счетчик'
		,CASE s.is_build
			WHEN 1 THEN 'Общедомовая'
			ELSE 'Квартирная'
		END AS 'Тип услуги'
		,countlic AS 'Кол-во лицевых'
		,countflats AS 'Кол-во квартир'
		,countpeople AS 'Кол-во граждан'
		,ds.[square] AS 'Общая площадь'
		,squarelive AS 'Жилая площадь'
		,(b.street_name + b.nom_dom_sort) AS sort_dom
	FROM dbo.DOM_SVOD_ALL AS ds 
	JOIN dbo.View_BUILD_ALL AS b 
		ON ds.build_id = b.bldn_id
		AND ds.fin_id = b.fin_id
	JOIN dbo.CONS_MODES AS cm 
		ON ds.mode_id = cm.id
	JOIN dbo.View_SUPPLIERS AS sup 
		ON ds.source_id = sup.id
	JOIN dbo.View_services AS s 
		ON cm.service_id = s.id
		AND sup.service_id = s.id
	JOIN dbo.GLOBAL_VALUES AS GV 
		ON GV.fin_id = b.fin_id
	WHERE 
		ds.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND (b.tip_id = @tip_id OR @tip_id IS NULL)
		AND (b.bldn_id = @build OR @build IS NULL)
		AND ds.mode_id = COALESCE(@mode_id1, ds.mode_id)
		AND ds.source_id = COALESCE(@source_id1, ds.source_id)
		AND (s.id = @service_id1 OR @service_id1 IS NULL)
	OPTION (RECOMPILE);
go

