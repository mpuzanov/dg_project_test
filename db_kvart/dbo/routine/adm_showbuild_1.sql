CREATE   PROCEDURE [dbo].[adm_showbuild_1]
(
	  @tip_id1 SMALLINT = NULL
	, @street_id1 SMALLINT = NULL
	, @sector_id1 SMALLINT = NULL
	, @div_id1 SMALLINT = NULL
	, @dop_info1 BIT = 0
	, @town_id SMALLINT = NULL
	, @build_id INT = NULL
	, @choice_all BIT = NULL
)
/*
 Список домов по условию
 SET STATISTICS IO ON
 exec [dbo].[adm_showbuild_1] 28
 exec [dbo].[adm_showbuild_1] @tip_id1=27, @build_id=715
 exec [dbo].[adm_showbuild_1] @build_id=6795
*/
AS

	SET NOCOUNT ON

	IF @street_id1 = 0
		SET @street_id1 = NULL

	IF @sector_id1 = 0
		SET @sector_id1 = NULL

	IF @town_id = 0
		SET @town_id = NULL

	IF COALESCE(@choice_all, 0) <> 1
		AND @tip_id1 IS NULL
		AND @street_id1 IS NULL
		AND @sector_id1 IS NULL
		AND @div_id1 IS NULL
		AND @town_id IS NULL
		AND @build_id IS NULL
		SELECT @build_id = 0

		--PRINT @build_id

		;
	WITH cte AS
	(
		SELECT b.ID                                                                         AS bldn_id
			 , COUNT(DISTINCT o.flat_id)                                                     AS KolFlats
			 , COALESCE(SUM(o.Rooms), 0)                                                     AS Kolrooms
			 , COALESCE(SUM(CASE
                                WHEN o.proptype_id = N'непр' THEN 1
                                ELSE 0
            END), 0)                                                                         AS Lic_nopriv
			 , COALESCE(SUM(CASE
                                WHEN o.proptype_id <> N'непр' THEN 1
                                ELSE 0
            END), 0)                                                                                       AS Lic_priv
			 , COALESCE(SUM(CASE
                                WHEN o.proptype_id = N'непр' THEN o.Total_sq
                                ELSE 0
            END), 0)                                                                                       AS Total_sq_nopriv
			 , COALESCE(SUM(CASE
                                WHEN o.proptype_id <> N'непр' THEN o.Total_sq
                                ELSE 0
            END), 0)                                                                                       AS Total_sq_priv
			 , COALESCE(SUM(CASE
                                WHEN o.proptype_id = N'арен' THEN o.Total_sq
                                ELSE 0
            END), 0)                                                                                       AS Total_sq_arenda
			 , COALESCE(SUM(o.Total_sq), 0)                                                                AS Total_sq
			 , COALESCE(COUNT(o.occ), 0)                                                                   AS KolLic
			 , COALESCE(SUM(CASE
                                WHEN o.Total_sq > 0 THEN 1
                                ELSE 0
            END), 0)                                                         AS KolLic_Total_sq
			 , COALESCE(SUM(CASE
                                WHEN o.proptype_id = N'непр' THEN COALESCE(o.kol_people, 0)
                                ELSE 0
            END), 0)                                                         AS KolPeople_nopriv
			 , COALESCE(SUM(CASE
                                WHEN o.proptype_id <> N'непр' THEN COALESCE(o.kol_people, 0)
                                ELSE 0
            END), 0)                                                         AS KolPeople_priv
			 , COALESCE(SUM(COALESCE(o.kol_people, 0)), 0)                   AS KolPeople
			 , COALESCE(SUM(CASE
                                WHEN o.roomtype_id IN (N'комм', N'об06', N'об10', N'отдк') THEN o.Total_sq
                                ELSE 0
            END), 0)                                                         AS [Жилая площадь]
			 , COALESCE(SUM(CASE
                                WHEN o.roomtype_id = N'парк' THEN o.Total_sq
                                ELSE 0
            END), 0)                                                         AS [Паркинг]
			 , COALESCE(SUM(CASE
                                WHEN o.roomtype_id = N'офис' THEN o.Total_sq
                                ELSE 0
            END), 0)                                           AS [Офис]
			 , COALESCE(SUM(CASE
                                WHEN o.roomtype_id = N'бокс' THEN o.Total_sq
                                ELSE 0
            END), 0) AS [Гаражный бокс]
			 , COALESCE(SUM(CASE
                                WHEN o.roomtype_id = N'клад' THEN o.Total_sq
                                ELSE 0
            END), 0) AS [Кладовая]
			 , COALESCE(SUM(CASE
                                WHEN o.roomtype_id = N'коля' THEN o.Total_sq
                                ELSE 0
            END), 0) AS [Колясочная]
			 , COALESCE(SUM(CASE
                                WHEN o.roomtype_id NOT IN (N'комм', N'об06', N'об10', N'отдк')
                                    OR o.proptype_id = 'арен' THEN o.Total_sq
                                ELSE 0
            END), 0) AS [Total_sq_noliving]
		FROM dbo.Buildings AS b 
			LEFT JOIN dbo.Flats AS f ON b.ID = f.bldn_id
			LEFT JOIN dbo.Occupations AS o ON f.ID = o.flat_id
				AND o.Status_id <> 'закр'
		WHERE (@build_id IS NULL OR b.ID = @build_id)
			AND (@street_id1 IS NULL OR b.street_id = @street_id1)
			AND (@sector_id1 IS NULL OR b.sector_id = @sector_id1)
			AND (@div_id1 IS NULL OR b.div_id = @div_id1)
			AND (@tip_id1 IS NULL OR b.tip_id = @tip_id1)
			AND (@town_id IS NULL OR b.town_id = @town_id)
		GROUP BY b.ID
	)

	SELECT b.ID
		 , b.street_id
		 , b.nom_dom
		 , b.sector_id
		 , b.div_id
		 , b.tip_id
		 , b.levels
		 , b.balans_cost
		 , b.material_wall
		 , b.comments
		 , b.standart_id
		 , s.name  AS street_name
		 , CONCAT(s.name, ' д.' , b.nom_dom) AS adres
		 , CONCAT(s.prefix, '. ', s.short_name, ' д.', b.nom_dom) AS adres2
		 , old
		 , b.kolpodezd
		 , dog_bit

		 , t1.*

		 , sec.name  AS sector_name
		 , t.name AS tip_name
		 , d.name AS div_name
		 , b.seria
		 , b.godp
		 , b.index_id
		 , b.index_postal
		 , b.tip_name_out
		 , b.date_out
		 , b.penalty_calc_build
		 , b.blocked_house
		 , b.id_accounts                          AS id_account_build
		 , COALESCE(b.id_accounts, t.id_accounts) AS id_accounts
		 , CASE
               WHEN b.id_accounts IS NOT NULL THEN (SELECT TOP 1 ra.FileName
                                                    FROM dbo.Reports_account AS ra 
                                                    WHERE ra.ID = b.id_accounts)
               ELSE (SELECT TOP 1 ra.FileName
                     FROM dbo.Reports_account AS ra 
                     WHERE ra.ID = t.id_accounts)
        END AS fileName_accounts
		 , b.bank_account
		 , b.norma_gkal
		 , b.norma_gkal_gvs
		 , b.norma_gaz_gvs
		 , b.norma_gaz_otop
		 , b.fin_current
		 , cp.StrFinPeriod AS fin_name
		 , b.arenda_sq
		 , b.lastpaym
		 , b.town_id
		 , tw.name AS town_name
		 , b.court_id
		 , b.collector_id
		 , b.dog_num
		 , b.dog_date
		 , b.dog_date_sobr
		 , b.dog_date_protocol
		 , b.dog_num_protocol
		 , b.dog_id_gis
		 , b.date_start
		 , b.date_end
		 , b.is_paym_build
		 , b.is_boiler
		 , b.opu_sq
		 , b.opu_sq_elek
		 , b.opu_sq_otop
		 , b.build_total_area
		 , b.is_lift
		 , b.Vid_blag
		 , b.odn_big_norma
		 , b.penalty_paym_no
		 , b.info_account_no
		 , b.build_type
		 , b.blocked_counter_add
		 , b.comments_add_fin
		 , b.kol_lift
		 , b.levels_min
		 , b.kol_sekcia
		 , b.iznos
		 , b.srok_sluzhba
		 , b.kol_musor
		 , b.people_reg_blocked
		 , b.ras_no_counter_poverka
		 , b.kod_fias
		 , b.kod_gis
		 , b.is_counter_add_balance
		 , b.only_pasport
		 , b.CadastralNumber
		 , b.kultura
		 , b.levels_underground
		 , b.id_nom_dom_gis
		 , t_start.StrFinPeriod             AS fin_name_start
		 , b.blocked_counter_out
		 , b.opu_tepl_kol
		 , CAST(b.build_uid AS VARCHAR(36)) AS build_uid
		 , b.soi_votv_fact
		 , b.account_rich
	     , b.is_commission_uk
	     , b.is_value_build_minus
	     , b.is_not_allocate_economy
		 , b.oktmo
		 , b.soi_metod_calc
		 , b.decimal_round
		 , b.peny_service_id
		 , b.counter_votv_norma
		 , b.soi_is_transfer_economy
		 , t.soi_is_transfer_economy as tip_soi_is_transfer_economy
		 , b.is_finperiod_owner
		 , b.latitude
		 , b.longitude
	FROM dbo.Buildings AS b 
		JOIN cte AS t1 ON b.ID = t1.bldn_id
		JOIN dbo.VStreets AS s ON b.street_id = s.ID
		LEFT JOIN dbo.Sector AS sec ON b.sector_id = sec.ID
		JOIN dbo.VOcc_types AS t ON b.tip_id = t.ID
		LEFT JOIN dbo.Divisions AS d ON b.div_id = d.ID
		JOIN dbo.Towns AS tw ON b.town_id = tw.ID
		JOIN dbo.Calendar_period cp ON b.fin_current = cp.fin_id
		OUTER APPLY (
			SELECT TOP (1) cp2.StrFinPeriod
			FROM dbo.Buildings_history bh
				JOIN dbo.Calendar_period cp2 ON bh.fin_id = cp2.fin_id
			WHERE bh.bldn_id = b.ID
			ORDER BY bh.fin_id
		) AS t_start
	ORDER BY s.name
		   , b.nom_dom_sort
go

