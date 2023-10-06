-- =============================================
-- Author:		Пузанов
-- Create date: 23.01.2022
-- Description:	Оборотка по услугам по домам
-- =============================================
CREATE         PROCEDURE [dbo].[rep_olap1_build]
(
	  @fin_id1 SMALLINT = NULL
	, @tip_id1 SMALLINT = NULL
	, @build_id1 INT = NULL
	, @div_id1 SMALLINT = NULL
	, @service_id VARCHAR(10) = NULL
	, @sup_id INT = NULL
	, @town_id SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
	, @serv_str1 VARCHAR(2000) = NULL -- список услуг через запятую
)
AS
/*
exec rep_olap1_build @fin_id1=239,@tip_id1=1, @fin_id2=239, @serv_str1='площ,БлТр'
exec rep_olap1_build @fin_id1=239,@tip_id1=1, @fin_id2=239
*/
BEGIN
	SET NOCOUNT ON;


	DECLARE @fin_current SMALLINT
	SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip_id1, NULL, NULL, NULL)

	IF @fin_id1 < 0
		SELECT @fin_id1 = @fin_current
			 , @fin_id2 = @fin_current
	ELSE
	IF @fin_id1 IS NULL
		AND @tip_id1 IS NOT NULL
		SET @fin_id1 = @fin_current - 1

	IF @fin_id2 IS NULL
		OR @fin_id2 < @fin_id1
		SET @fin_id2 = @fin_id1

	IF @tip_id1 IS NULL
		AND @build_id1 IS NULL
		AND @div_id1 IS NULL
		AND @town_id IS NULL
		SET @tip_id1 = 0

	IF @service_id = ''
		SET @service_id = NULL

	-- для ограничения доступа услуг
	CREATE TABLE #services (
		  id VARCHAR(10) COLLATE database_default --PRIMARY KEY
		, [name] VARCHAR(100) COLLATE database_default
	)
	INSERT INTO #services (id
						 , name)
	SELECT vs.id
		 , vs.name
	FROM dbo.View_services AS vs
		OUTER APPLY STRING_SPLIT(@serv_str1, ',') AS t
	WHERE (vs.id = t.value)
		OR @serv_str1 IS NULL
	CREATE UNIQUE INDEX SERV ON #services (id)

	SELECT o.[start_date] AS 'Период'
		 , o.tip_name AS 'Тип фонда'
		 , b.street_name AS 'Улица'
		 , b.nom_dom AS 'Номер дома'
		 , (b.street_name + ' д.' + b.nom_dom) AS 'Адрес дома'
		 , b.bldn_id AS 'КодДома'
		 , MIN(pl.service_id) AS 'Код услуги'
		   --, CASE WHEN(COALESCE(servt.service_name_full, '') <> '') THEN servt.service_name_full ELSE serv.name END AS 'Услуга' -- заменяем наименования услуг по типам фонда
		 , CASE
			   WHEN COALESCE(servt.service_name_full, '') <> '' THEN servt.service_name_full -- заменяем наименования услуг по типам фонда
			   ELSE serv.name
		   END AS 'Услуга'
		 , MIN(s_kvit.service_name_kvit) AS 'Услуга в квитанции'
		 , SUM(pl.SALDO) AS 'Сальдо'
		 , SUM(pl.value) AS 'Начислено'
		 , SUM(pl.Added - COALESCE(ap_sub.val, 0)) AS 'Разовые'
		 , SUM(COALESCE(ap_sub.val, 0)) AS 'Субсидия'
		 , SUM(pl.Paid) AS 'Пост_Начисление' -- пост.начисления (value-discount+added)
		 , SUM(pl.PaymAccount) AS 'Оплачено'
		 , SUM(pl.PaymAccount_peny) AS 'из_них_пени'
		 , SUM(pl.Paymaccount_Serv) AS 'Оплата по услугам' -- (без пени)
		 , SUM(pl.Debt) AS 'Кон_Сальдо'
		 , SUM(o.kol_people) AS 'Кол граждан'
		   --,kol_people_serv = dbo.Fun_GetKolPeopleOccServ(pl.fin_id, pl.occ, pl.service_id)
		 , SUM(pl.kol) AS 'Количество'
		 , SUM(pl.kol_added) AS 'Кол_Разовых'
		 , CASE WHEN(COALESCE(pl.metod, 1) NOT IN (3, 4)) THEN SUM(pl.kol) ELSE 0 END AS 'Объём по норме'
		 , CASE WHEN(pl.metod = 3) THEN SUM(pl.kol) ELSE 0 END AS 'Объём по ИПУ'
		 , CASE WHEN(pl.metod = 4) THEN SUM(pl.kol) ELSE 0 END AS 'Объём по ОПУ'
		 , SUM(pl.penalty_prev) AS 'Пени старое'
		 , SUM(pl.Penalty_old) AS 'Пени старое изм'
		 , SUM(pl.penalty_serv) AS 'Пени новое'
		 , SUM(pl.Penalty_old + pl.penalty_serv) AS 'Пени итог'
		 , SUM(ROUND(pl.SALDO, 2) + pl.Penalty_old + pl.PaymAccount_peny) AS 'Нач_сальдо с пени'
		 , SUM(ROUND(pl.Debt, 2) + pl.Penalty_old + pl.penalty_serv) AS 'Кон_Сальдо с пени'
	FROM dbo.View_paym AS pl 
		JOIN dbo.View_occ_all_lite AS o 
			ON o.occ = pl.occ
			AND o.fin_id = pl.fin_id
			AND (pl.sup_id = @sup_id OR @sup_id IS NULL)
		--AND COALESCE(pl.sup_id, 0) = COALESCE(@sup_id, COALESCE(pl.sup_id, 0))
		JOIN dbo.View_build_all AS b 
			ON o.bldn_id = b.bldn_id
			AND o.fin_id = b.fin_id
		JOIN #services AS serv ON pl.service_id = serv.id
		LEFT JOIN dbo.View_services_kvit AS s_kvit 
			ON o.tip_id = s_kvit.tip_id
			AND o.build_id = s_kvit.build_id
			AND pl.service_id = s_kvit.service_id
		LEFT JOIN dbo.Services_types AS servt 
			ON servt.service_id = serv.id
			AND servt.tip_id = o.tip_id
		LEFT JOIN dbo.Consmodes_list AS cl 
			ON pl.occ = cl.occ
			AND pl.service_id = cl.service_id
		CROSS APPLY (
			SELECT SUM(va.value) AS val
			FROM dbo.View_added va
			WHERE va.fin_id = pl.fin_id
				AND va.occ = pl.occ
				AND va.service_id=pl.service_id
				AND va.add_type = 15
		) AS ap_sub
	WHERE pl.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND (@tip_id1 IS NULL OR b.tip_id = @tip_id1)
		AND (@build_id1 IS NULL OR b.bldn_id = @build_id1)
		AND (@div_id1 IS NULL OR b.div_id=@div_id1)
		--AND vs.sup_id = coalesce(@sup_id, vs.sup_id)
		AND (@town_id IS NULL OR b.town_id = @town_id)
		AND (pl.SALDO <> 0 OR pl.value <> 0 OR pl.Debt <> 0 OR pl.Added <> 0 OR pl.kol <> 0 OR pl.PaymAccount <> 0 OR pl.penalty_prev<>0 OR pl.penalty_serv<>0)
	GROUP BY o.[start_date]
		   , o.tip_name
		   , b.street_name
		   , b.nom_dom
		   , b.bldn_id -- код дома		
		   , b.nom_dom_sort
		   , serv.name
		   , servt.service_name_full
		   , pl.metod
	OPTION (RECOMPILE)
END
go

