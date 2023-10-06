-- =============================================
-- Author:		Пузанов
-- Create date: 24.10.2008
-- Description:	
-- =============================================
CREATE                 PROCEDURE [dbo].[rep_value_fin]
(
	  @fin_id1 SMALLINT = NULL
	, @tip_id1 SMALLINT = NULL
	, @build_id1 INT = NULL
	, @div_id1 SMALLINT = NULL
	, @max_rows INT = NULL -- убрал использование
	, @service_id VARCHAR(10) = NULL
	, @sup_id INT = NULL
	, @town_id SMALLINT = NULL
	, @PrintGroup SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
)
AS
/*
SET STATISTICS IO ON
exec rep_value_fin @tip_id1=1, @fin_id1=239, @fin_id2=240, @PrintGroup=null
exec rep_value_fin @fin_id1=-1,@tip_id1=2
exec rep_value_fin @fin_id1=NULL,@tip_id1=2

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
	CREATE TABLE #s (
		  id VARCHAR(10) COLLATE database_default PRIMARY KEY
		, [name] VARCHAR(100) COLLATE database_default
	)
	INSERT INTO #s (id
				  , name)
	SELECT id
		 , name
	FROM dbo.View_services
	WHERE id = COALESCE(@service_id, id)

	SELECT 
		ROW_NUMBER() OVER (ORDER BY pl.fin_id, b.street_name, b.nom_dom_sort, o.nom_kvr_sort) AS row_num
	  , pl.[start_date]
		--,pl.occ -- лицевой счет
	  , CASE
            WHEN @sup_id > 0 THEN pl.occ_sup_paym
            ELSE pl.occ
        END AS occ
	  , o.tip_name
	  , b.street_name                            AS street
	  , b.nom_dom
	  , o.nom_kvr
	  , PT.name                                  AS prop_type --'Тип собственности'
	  , RT.name                                  AS room_type --'Тип помещения'
	  , pl.service_id                                         -- код услуги
		--,serv.name AS serv_name
	  , CASE
            WHEN COALESCE(servt.service_name_full, '') = '' THEN serv.name
            ELSE servt.service_name_full
        END                                      AS serv_name -- заменяем наименования услуг по типам фонда
	  , s_kvit.service_name_kvit                 AS serv_name_kvit
	  , pl.sup_id                                AS sup_id
	  , sup.name                                 AS sup_name
	  , pl.tarif
	  , ROUND(pl.SALDO, 2)                       AS SALDO
	  , ROUND(pl.value, 2)                       AS value
	  , pl.Discount                              AS Discount
	  , t_sub.value                              AS compens
	  , (pl.Added -	COALESCE(t_sub.value, 0)) AS Added
	  , ROUND(pl.paid, 2)                        AS paid      -- пост.начисления (value-discount+added)
	  , ROUND(pl.PaymAccount, 2) AS PaymAccount
	  , ROUND(pl.PaymAccount_peny, 2) AS PaymAccount_peny
	  , ROUND(pl.paymaccount_serv, 2) AS paymaccount_serv     -- Оплачено по услуге (без пени)
	  , ROUND(pl.Debt, 2) AS Debt
	  , b.bldn_id                                             -- код дома
	  , o.flat_id                                             -- код помещения можно использовать для подсчета кол-ва помещений
	  , pl.occ_sup_paym AS occ_serv
	  , o.kol_people
	  --, dbo.Fun_GetKolPeopleOccServ(pl.fin_id, pl.occ, pl.service_id) AS kol_people_serv
	  , 0 AS kol_people_serv
	  , pl.kol
	  , (pl.kol_added -	COALESCE(t_sub.kol, 0)) AS kol_added
	  , pl.unit_id
	  , u.name AS unit_name
	  , CASE
			WHEN pl.metod = 0 THEN 'не начислять'
			WHEN pl.metod = 2 THEN 'по среднему'
			WHEN pl.metod = 3 THEN 'по счетчику'
			WHEN pl.metod = 4 THEN 'по домовому'
			WHEN pl.is_counter > 0 THEN 'по норме'
			ELSE NULL
		END AS metod
	  , CASE
            WHEN COALESCE(pl.metod, 1) NOT IN (3, 4) THEN pl.kol
            ELSE 0
        END AS kol_norma
	  , CASE
            WHEN pl.metod = 3 THEN pl.kol
            ELSE 0
        END AS kol_ipu
	  , CASE
            WHEN pl.metod = 4 THEN pl.kol
            ELSE 0
        END AS kol_opu
	  , pl.penalty_prev
	  , pl.penalty_old AS penalty_old
	  , pl.penalty_serv
	  , (pl.penalty_old + pl.penalty_serv) AS penalty_itog
	  , (ROUND(pl.SALDO, 2) + pl.penalty_old + pl.PaymAccount_peny) AS saldo_with_peny
	  , (ROUND(pl.Debt, 2) + pl.penalty_old + pl.penalty_serv) AS debt_with_peny
	FROM dbo.View_paym AS pl 
		JOIN dbo.View_occ_all_lite AS o ON o.occ = pl.occ
			AND o.fin_id = pl.fin_id			
		JOIN dbo.View_build_all AS b ON o.bldn_id = b.bldn_id
			AND pl.fin_id = b.fin_id
		JOIN #s AS serv ON pl.service_id = serv.id
		LEFT JOIN dbo.View_services_kvit AS s_kvit ON o.tip_id = s_kvit.tip_id
			AND o.build_id = s_kvit.build_id
			AND pl.service_id = s_kvit.service_id
		LEFT JOIN dbo.Services_types AS servt ON servt.service_id = serv.id
			AND servt.tip_id = o.tip_id
		LEFT JOIN dbo.Property_types AS PT ON o.proptype_id = PT.id
		LEFT JOIN dbo.Room_types AS RT ON o.roomtype_id = RT.id
		LEFT JOIN dbo.Units AS u ON u.id = pl.unit_id
		LEFT JOIN dbo.Suppliers_all AS sup ON pl.sup_id = sup.id
		CROSS APPLY (
			SELECT SUM(va.Value) AS Value
				,SUM(va.kol) AS kol
			FROM dbo.View_added_lite va 
			WHERE va.fin_id = pl.fin_id
				AND va.occ = pl.occ
				AND va.service_id = pl.service_id
				AND va.sup_id = pl.sup_id
				AND va.add_type = 15
		) AS t_sub

	WHERE pl.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND (@tip_id1 IS NULL OR b.tip_id = @tip_id1)
		AND (@build_id1 IS NULL OR b.build_id = @build_id1)
		AND (@div_id1 IS NULL OR b.div_id = @div_id1)
		AND (@sup_id IS NULL OR pl.sup_id = @sup_id)
		AND (@town_id IS NULL OR b.town_id = @town_id)
		AND (@PrintGroup IS NULL OR EXISTS (
			SELECT 1
			FROM dbo.Print_occ AS po 
			WHERE po.occ = o.occ
				AND po.group_id = @PrintGroup
		))
		AND (pl.SALDO <> 0 OR pl.value <> 0 OR pl.Debt <> 0 OR pl.Added <> 0 OR pl.kol <> 0 OR pl.PaymAccount <> 0 OR pl.penalty_old <> 0 OR pl.penalty_serv <> 0)
	ORDER BY pl.fin_id
		   , b.street_name
		   , b.nom_dom_sort
		   , o.nom_kvr_sort
	OPTION (RECOMPILE)

END
go

