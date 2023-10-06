CREATE   PROCEDURE [dbo].[rep_olap_sup]
(
	@fin_id1		SMALLINT    = NULL
	,@tip_id		SMALLINT
	,@div_id		SMALLINT	= NULL
	,@build_id		INT			= NULL
	,@sup_id		SMALLINT	= NULL
	,@PrintGroup	SMALLINT	= NULL
	,@town_id		SMALLINT	= NULL
	,@fin_id2		SMALLINT	= NULL
)
AS
	/*
	
	WEB
	
	ОБОРОТНАЯ ВЕДОМОСТЬ по лицевым счетам поставщиков
	
	rep_olap_sup 170,28

	*/

	SET NOCOUNT ON


	DECLARE @Fin_current SMALLINT

	-- находим значение текущего фин периода
	SELECT
		@Fin_current = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, NULL)

	IF @fin_id1 IS NULL
		SET @fin_id1 = @Fin_current - 1

	IF @fin_id2 IS NULL
		SET @fin_id2 = @fin_id1

	SELECT		
		oh.start_date AS 'Период'
		,b.town_Name AS 'Населенный пункт'
		,b.adres AS 'Адрес дома'
		,b.street_name AS 'Улица'
		,b.nom_dom AS 'Номер дома'
		,oh.nom_kvr AS 'Квартира'
		,oh.kol_people AS 'Кол-во граждан'
		,oh.PROPTYPE_ID AS 'Тип собств.'
		,CAST(oh.TOTAL_SQ AS DECIMAL(9,2)) AS 'Площадь'
		,os.occ  AS 'Лицевой'
		,os.occ_sup AS 'Лицевой поставщика'
		,dbo.Fun_Initials(oh.occ) AS 'ФИО'
		,oh.bldn_id AS 'Код дома'
		,os.saldo AS 'Вх.сальдо'
		,os.value AS 'Начислено'
		,os.added AS 'Разовые'
		,os.paymaccount AS 'Оплачено'
		,os.paid AS 'Пост. начисление'
		,os.Whole_payment AS 'К оплате'
		,os.penalty_value AS 'Пени нов.'
		,(os.Penalty_old_new + os.penalty_value)  AS 'Пени итог' 
		,os.PaymAccount_peny AS 'Оплачено пени'
		,(os.paymaccount - os.paymaccount_peny) AS 'Оплата по услугам'
		,os.debt AS 'Кон.сальдо'
		,(os.saldo - (os.paymaccount-os.Penalty_value)) AS 'Задолженность'
		,b.sector_name AS 'Участок'
		,b.div_Name AS 'Район'
		,b.tip_name AS 'Тип фонда'
		,SA.Name AS 'Поставщик'
		,os.rasschet AS 'Расчётный счёт'
		,CONCAT(b.street_name, b.nom_dom_sort) AS sort_dom
		,oh.nom_kvr_sort
	FROM dbo.VOCC_SUPPLIERS AS os 
	JOIN dbo.View_OCC_ALL AS oh 
		ON os.occ = oh.occ AND os.fin_id = oh.fin_id
	JOIN dbo.View_BUILD_ALL AS b
		ON oh.bldn_id = b.bldn_id AND oh.fin_id = b.fin_id
	JOIN dbo.SUPPLIERS_ALL AS SA 
		ON os.SUP_ID = SA.id
	WHERE 
		(os.SUP_ID = @sup_id OR @sup_id IS NULL)
		AND oh.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND oh.status_id <> 'закр'
		AND (b.tip_id = @tip_id OR @tip_id IS NULL)
		AND (b.div_id = @div_id OR @div_id IS NULL)
		AND (oh.bldn_id = @build_id OR @build_id IS NULL)
		AND (b.town_id = @town_id OR @town_id IS NULL)
		AND (@PrintGroup IS NULL
		OR EXISTS (SELECT
				1
			FROM dbo.PRINT_OCC AS po 
			WHERE po.occ = oh.occ
			AND po.group_id = @PrintGroup)
		)
go

