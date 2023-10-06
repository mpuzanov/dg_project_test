-- =============================================
-- Author:		Пузанов
-- Create date: 24.07.2019
-- Description:	Аналитика по тарифам
-- =============================================

CREATE   PROCEDURE [dbo].[rep_olap_rates]
(
	@tip_id		SMALLINT	= NULL
	,@fin_id1	SMALLINT	= NULL
	,@fin_id2	SMALLINT	= NULL
	,@build		INT			= NULL
)
AS
/*
rep_olap_rates @tip_id=28, @fin_id1=210, @fin_id2=210
rep_olap_rates @tip_id=28, @fin_id1=210, @fin_id2=210, @build=1031
*/
BEGIN
	SET NOCOUNT ON;


	IF @tip_id IS NULL
		SET @tip_id = 0
	--print @fin_start

	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(@tip_id, NULL, NULL, NULL)

	IF @fin_id1 = 0
		OR @fin_id1 IS NULL
		SET @fin_id1 = @fin_current

	IF @fin_id2 = 0
		OR @fin_id2 IS NULL
		SET @fin_id2 = @fin_current

	SELECT
	   gb.start_date AS 'Период'
	   ,ot.Name AS 'Тип фонда'
	   ,b.adres AS 'Дом'
	   ,s.Name AS 'Услуга'
	   ,r.status_id AS 'Статус'
	   ,r.proptype_id AS 'Тип собственности'
	   ,r.mode_id AS 'Код режима'
	   ,cm.Name AS 'Режим'
	   ,r.source_id AS 'Код поставщика'
	   ,su.Name AS 'Поставщик'
	   ,r.value AS 'Тариф'
	   ,r.extr_value AS 'Сверх.норм.тариф'
	   ,r.full_value AS 'Полный тариф'
	FROM dbo.RATES AS r 
	JOIN dbo.VOCC_TYPES AS ot 
		ON r.tipe_id = ot.id
	JOIN dbo.GLOBAL_VALUES AS gb 
		ON r.finperiod = gb.fin_id
	JOIN dbo.View_SERVICES AS s 
		ON r.service_id = s.id
	JOIN dbo.View_BUILDINGS AS b 
		ON r.tipe_id = b.tip_id
	JOIN dbo.BUILD_MODE bm 
		ON bm.build_id=b.id AND bm.service_id=s.id AND bm.mode_id=r.mode_id
	JOIN dbo.BUILD_SOURCE bs 
		ON bs.build_id=b.id AND bs.service_id=s.id AND bs.source_id=r.source_id
	JOIN dbo.CONS_MODES AS cm 
		ON bm.mode_id = cm.id AND cm.service_id = s.id
	JOIN dbo.View_SUPPLIERS AS su 
		ON bs.source_id = su.id

	WHERE r.finperiod BETWEEN @fin_id1 AND @fin_id2
	AND (r.tipe_id = @tip_id OR @tip_id IS NULL)
	AND (r.value<> 0
	OR r.full_value <> 0
	OR r.extr_value <> 0)
	AND (b.id = @build OR @build IS NULL)

	OPTION (MAXDOP 1, FAST 10)


END
go

