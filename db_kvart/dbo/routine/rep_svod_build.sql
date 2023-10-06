CREATE   PROCEDURE [dbo].[rep_svod_build]
(
	@fin_id1 SMALLINT -- фин период
   ,@tip_id	 SMALLINT = NULL -- тип жилого фонда
   ,@build	 INT	  = NULL -- дом
   ,@fin_id2 SMALLINT = NULL
)
AS
	/*
Пузанов
20.01.13
12.09.19 + Признак расчётов по организации

Отчет: аналитика

-- тестирование
DECLARE	@return_value int
EXEC	@return_value = [dbo].[rep_svod_build]
		@fin_id1 = 154,
		@fin_id2 = 154
SELECT	'Return Value' = @return_value

GO

*/

	SET NOCOUNT ON

	IF @fin_id2 IS NULL
		SET @fin_id2 = @fin_id1

	SELECT
		b.[start_date] AS 'Период'
	   ,ot.StrMes AS 'Фин.период'
	   ,b.town_name AS 'Населённый пункт'
	   ,b.div_name AS 'Район'
	   ,b.tip_name AS 'Тип фонда'
	   ,b.sector_name AS 'Участок'
	   ,b.adres AS 'Адрес дома'
	   ,bt.name AS 'Тип дома'
	   ,b.bldn_id AS 'Код дома'
	   ,ds.CountLic AS 'Кол-во лицевых'
	   ,ds.CountPeople AS 'Кол-во граждан'
	   ,ds.CountFlats AS 'Кол-во квартир'
	   ,ds.[Square] AS 'Общая площадь'
	   ,ds.SquareLive AS 'Жилая площадь'
	   ,ds.CountIPU AS 'Кол-во ИПУ'
	   ,ds.CountOPU AS 'Кол-во ОПУ'
	   ,ds.CountFlatsIPU AS 'Кол-во квартир с ИПУ'
	   ,ds.CountFlatsNoIPU AS 'Кол-во квартир без ИПУ'
	   ,ds.CountPeopleIPU AS 'Кол-во граждан с ИПУ'
	   ,ds.CountPeopleNoIPU                                            AS 'Кол-во граждан без ИПУ'
	   ,COALESCE(b.arenda_sq, 0)                                       AS 'Площадь нежилых'
	   ,COALESCE(b.opu_sq, 0)                                          AS 'Площадь МОП'
	   ,COALESCE(b.opu_sq_elek, 0)                                     AS 'Площадь МОП ЭлЭн'
	   ,ds.[Square] + COALESCE(b.arenda_sq, 0) + COALESCE(b.opu_sq, 0) AS 'Общая площадь дома'
	   ,vb.name                                                        AS 'Кат. благоустройства'
	   ,b1.kod_fias                                                    AS 'Код ФИАС'
	   ,b1.id_nom_dom_gis                                              AS 'Код в ГИС ЖКХ'
	   ,b1.CadastralNumber                                             AS 'Кадастровый №'
	   ,s.kod_fias                                                     AS 'Код Улицы ФИАС'
	   , CASE
             WHEN ot2.only_pasport = 1 THEN 'Только паспортный стол'
             ELSE CASE
                      WHEN ot2.only_value = 1 THEN 'Только расчёты'
                      ELSE CASE
                               WHEN ot2.payms_value = 0 THEN 'Не начисляем'
                               ELSE 'Комплекс'
                          END
                 END
        END                                                            AS 'Признак расчётов по организации'
	   ,CONCAT(b.street_name, b.nom_dom_sort) AS sort_dom
	FROM dbo.Dom_svod AS ds 
	JOIN dbo.View_build_all AS b 
		ON ds.build_id = b.bldn_id
		AND ds.fin_id = b.fin_id
	JOIN dbo.VOcc_types_all AS ot 
		ON b.tip_id = ot.id
		AND ot.fin_id = b.fin_id
	LEFT JOIN dbo.Build_types AS bt 
		ON b.build_type = bt.id
	JOIN dbo.Buildings b1 
		ON b.bldn_id = b1.id
	JOIN dbo.Streets s 
		ON b1.street_id = s.Id
	JOIN dbo.Occupation_Types ot2 
		ON b.tip_id = ot2.id
	LEFT JOIN dbo.VID_BLAG vb 
		ON b1.VID_BLAG = vb.id
	WHERE 
		ds.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND (b.tip_id = @tip_id	OR @tip_id IS NULL)
		AND (b.bldn_id = @build	OR @build IS NULL)
	OPTION (MAXDOP 1);
go

