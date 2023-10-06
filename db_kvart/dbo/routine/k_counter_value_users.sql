CREATE   PROCEDURE [dbo].[k_counter_value_users]
(
	@date1	SMALLDATETIME	= NULL
	,@date2	SMALLDATETIME	= NULL
	,@login	VARCHAR(20)		= NULL
)
AS
	/*
	  Показываем паказатели по счетчику инспектора или квартиросъемщика
	*/
	SET NOCOUNT ON
	SET DATEFORMAT ymd;

	IF @date1 IS NULL
		SET @date1 = dbo.Fun_GetOnlyDate(current_timestamp)
	IF @date2 IS NULL
		SET @date2 = dbo.Fun_GetOnlyDate(current_timestamp) + 1

	SELECT
		c.[address] AS 'Адрес'
		,S.name AS 'Услуга'
		,c.inspector_value AS 'Значение'
		,c.inspector_date AS 'Дата показания'
		,c.date_edit AS 'Дата редакт'
		,c.kol_day AS 'Дней'
		,c.actual_value AS 'Факт'
		,c.value_vday AS 'В день'
		,c.comments AS 'Комментарий'
		,c.tarif AS 'Тариф'
		,c.value_paym AS 'Начисленно'
		,c.Initials AS 'Ф.И.О.'
		,cp.StrFinPeriod AS 'Период'
		,c.tip_name as 'Тип фонда'
		,b.adres as 'Адрес дома'
		,CASE
			WHEN COALESCE(c.mode_id, 0) = 0 THEN 'Текущий'
			ELSE (SELECT
					cm.name
				FROM dbo.CONS_MODES AS cm 
				WHERE cm.id = c.mode_id)
		END AS 'Режим'
		,c.id
	FROM dbo.View_counter_inspector AS c 
	JOIN dbo.Services S 
		ON c.service_id = S.id
	JOIN dbo.Calendar_period cp
		ON cp.fin_id = c.fin_id
	JOIN dbo.View_buildings_lite b ON c.bldn_id=b.id
	WHERE c.date_edit BETWEEN @date1 AND @date2
	ORDER BY inspector_date DESC
go

