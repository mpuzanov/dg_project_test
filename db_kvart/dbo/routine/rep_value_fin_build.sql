-- =============================================
-- Author:		Пузанов
-- Create date: 19.09.2014
-- Description:	Оборотка по услугам по домам
-- =============================================
CREATE           PROCEDURE [dbo].[rep_value_fin_build]
(
	  @fin_id1 SMALLINT = NULL
	, @tip_id1 SMALLINT = NULL
	, @build_id1 INT = NULL
	, @div_id1 SMALLINT = NULL
	, @service_id VARCHAR(10) = NULL
	, @sup_id INT = NULL
	, @town_id SMALLINT = NULL
	, @PrintGroup SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
	, @serv_str1 VARCHAR(2000) = NULL -- список услуг через запятую
)
AS
/*
exec rep_value_fin_build @fin_id1=250, @tip_id1=131, @fin_id2=251, @serv_str1='площ,БлТр',@PrintGroup=null
exec rep_value_fin_build @fin_id1=239,@tip_id1=1,@sup_id=345
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
		AND @PrintGroup IS NULL
		SET @tip_id1 = 0

	IF @service_id = ''
		SET @service_id = NULL

	-- для ограничения доступа услуг
	CREATE TABLE #services (
		  id VARCHAR(10) COLLATE database_default PRIMARY KEY
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

	SELECT pl.fin_id
	  , MIN(o.[start_date]) AS [start_date]
	  , o.tip_name
	  , b.street_name AS street
	  , MIN(b.nom_dom) AS nom_dom
	  , b.bldn_id                                         -- код дома
	  , pl.service_id                                     -- код услуги
	  , PT.name                       AS prop_type        --'Тип собственности'
	  , RT.name                       AS room_type        --'Тип помещения'
	  , pl.sup_id                     AS sup_id
	  , MIN(sup.name)                 AS sup_name
	  --, MIN(pl.occ_sup_paym) AS occ_sup_paym
	  , CASE
            WHEN COALESCE(MIN(servt.service_name_full), '') = '' THEN MIN(serv.name)
            ELSE MIN(servt.service_name_full)
        END                           AS serv_name        -- заменяем наименования услуг по типам фонда
	  , MIN(s_kvit.service_name_kvit) AS serv_name_kvit
	  --, MIN(pl.occ_sup_paym) AS occ_serv
	  --, MIN(o.flat_id) AS flat_id
	  , SUM(pl.saldo)                 AS saldo
	  , SUM(pl.value)                 AS value
	  , SUM(pl.added)                 AS added
	  , SUM(pl.paid)                  AS paid             -- пост.начисления (value-discount+added)
	  , SUM(pl.paymaccount)           AS paymaccount
	  , SUM(pl.paymaccount_peny)      AS paymaccount_peny
	  , SUM(pl.paymaccount_serv)      AS paymaccount_serv -- Оплачено по услуге (без пени)
	  , SUM(pl.debt) AS debt
	  , SUM(o.kol_people) AS kol_people
		--,kol_people_serv = dbo.Fun_GetKolPeopleOccServ(pl.fin_id, pl.occ, pl.service_id)
	  , SUM(pl.kol) AS kol
	  , SUM(pl.kol_added) AS kol_added
	  , CASE
            WHEN COALESCE(MAX(pl.metod), 1) NOT IN (3, 4) THEN SUM(pl.kol)
            ELSE 0
        END AS kol_norma
	  , CASE
            WHEN MAX(pl.metod) = 3 THEN SUM(pl.kol)
            ELSE 0
        END AS kol_ipu
	  , CASE
            WHEN MAX(pl.metod) = 4 THEN SUM(pl.kol)
            ELSE 0
        END AS kol_opu
	  , SUM(pl.penalty_prev) AS penalty_prev
	  , SUM(pl.penalty_old) AS penalty_old
	  , SUM(pl.penalty_serv) AS penalty_serv
	  , SUM(pl.penalty_old + pl.penalty_serv) AS penalty_itog
	  , SUM(ROUND(pl.SALDO, 2) + pl.penalty_old + pl.PaymAccount_peny) AS saldo_with_peny
	  , SUM(ROUND(pl.Debt, 2) + pl.penalty_old + pl.penalty_serv) AS debt_with_peny	  	  
	FROM dbo.View_paym AS pl 
		JOIN dbo.View_occ_all_lite AS o ON o.occ = pl.occ
			AND o.fin_id = pl.fin_id
			AND (pl.sup_id = @sup_id OR @sup_id IS NULL)
		--AND COALESCE(pl.sup_id, 0) = COALESCE(@sup_id, COALESCE(pl.sup_id, 0))
		JOIN dbo.View_build_all AS b ON pl.build_id = b.bldn_id
			AND pl.fin_id = b.fin_id
		JOIN #services AS serv ON pl.service_id = serv.id
		LEFT JOIN dbo.View_services_kvit AS s_kvit ON o.tip_id = s_kvit.tip_id
			AND o.build_id = s_kvit.build_id
			AND pl.service_id = s_kvit.service_id
		LEFT JOIN dbo.Services_types AS servt ON servt.service_id = serv.id
			AND servt.tip_id = o.tip_id
		LEFT JOIN dbo.Suppliers_all AS sup ON pl.sup_id = sup.id
		LEFT JOIN dbo.Property_types AS PT ON o.proptype_id = PT.id
		LEFT JOIN dbo.Room_types AS RT ON o.roomtype_id = RT.id
	WHERE pl.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND (b.tip_id = @tip_id1 OR @tip_id1 IS NULL)
		AND (b.bldn_id = @build_id1 OR @build_id1 IS NULL)
		AND (b.div_id = @div_id1 OR @div_id1 IS NULL)
		--AND vs.sup_id = coalesce(@sup_id, vs.sup_id)
		AND (b.town_id = @town_id OR @town_id IS NULL)
		AND (@PrintGroup IS NULL OR EXISTS (
			SELECT 1
			FROM dbo.Print_occ AS po 
			WHERE po.occ = o.occ
				AND po.group_id = @PrintGroup
		))
		AND (pl.saldo <> 0 OR pl.value <> 0 OR pl.debt <> 0 OR pl.added <> 0 OR pl.kol <> 0 OR pl.paymaccount <> 0)
	GROUP BY pl.fin_id
		   , o.tip_name
		   , b.street_name
		   , b.bldn_id -- код дома		
		   , b.nom_dom_sort
		   , pl.service_id -- код услуги
		   , PT.name
		   , RT.name
		   --, serv.name
		   --, servt.service_name_full
		   , pl.sup_id
	ORDER BY pl.fin_id
		   , b.street_name
		   , b.nom_dom_sort		   
		   , pl.service_id
		   --, PT.name
		   --, RT.name
	OPTION (RECOMPILE)
END
go

