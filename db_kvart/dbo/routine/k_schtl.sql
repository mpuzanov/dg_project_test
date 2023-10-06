CREATE   PROCEDURE [dbo].[k_schtl]
(
	  @occ1 INT
)
AS
	/*
	
    Открытие лицевого счета

	EXEC k_schtl 700009021
	EXEC k_schtl 680002159
	*/

	SET NOCOUNT ON

	SELECT o.occ
		 , o.jeu
		 , o.schtl
		 , o.schtl_old
		 , o.flat_id
		 , o.tip_id
		 , o.roomtype_id
		 , o.proptype_id
		 , o.status_id
		 , o.living_sq
		 , o.total_sq
		 , o.teplo_sq
		 , o.norma_sq
		 , o.socnaim
		 , o.saldo
		 , o.saldo_serv
		 , o.saldo_edit
		 , o.value
		 , o.discount
		 , o.compens
		 , compens_ext = 0 --o.compens_ext
		 , o.added
		 , o.added_ext
		 , o.paymaccount		 
		 , o.paymaccount_peny
		 , (o.paymaccount-o.paymaccount_peny) as paymaccount_serv
		 , o.paid
		 , o.paid_minus
		 , o.paid_old
		 , o.debt
		 , o.penalty_calc
		 , o.penalty_value
		 , o.penalty_added
		 , (o.penalty_value + o.penalty_added) as penalty_period
		 , o.penalty_old_new
		 , o.penalty_old
		 , o.penalty_old_edit

		, case when ((((o.saldo+o.paid)+o.paid_minus)-(o.paymaccount-o.paymaccount_peny))+((o.penalty_value+o.penalty_added)+o.penalty_old_new))<0 
			then 0 
			else (((o.saldo+o.paid)+o.paid_minus)-(o.paymaccount-o.paymaccount_peny))+((o.penalty_value+o.penalty_added)+o.penalty_old_new) 
		  end as whole_payment

		 , o.address
		 , o.data_rascheta
		 , o.comments
		 , o.comments2
		 , o.comments_print
		 , o.rooms
		 , o.kol_people
		 , o.peny_calc_date_begin
		 , o.peny_calc_date_end
		 , o.peny_nocalc_date_begin
		 , o.peny_nocalc_date_end
		 , o.doc_order_kvr
		 , o.telephon as telephon
		 , o.telephon as telefon_big
		 , o.date_create
		 , o.date_start
		 , o.date_end
		 , CASE
			   WHEN b.index_postal > 1 THEN LTRIM(STR(b.index_postal, 6)) + ','
			   ELSE ''
		   END + o.address AS fulladres
		 , f.nom_kvr
		 , f.[floor]
		 , f.approach
		 , f.bldn_id
		 , b.street_id
		 , b.nom_dom
		 , b.ID AS build_id
		 , CONCAT(LTRIM(STR(j.ID, 3)) , ', ' , j.name) AS jeu_name -- название участка
		 , CONCAT(j.name , ' (' , ot.name , ')') AS jeuname -- название участка c типом фонда
		 , ot.name AS typename -- наименование типа фонда
		 , CONCAT(ot.name, ', ', LTRIM(STR(ot.ID, 3))) AS tip_name
		 , '' AS Standart
		 , d.name AS divname -- название района 
		 , b.div_id -- код района
		 , b.dog_bit -- заключен договор управления на доме
		   --,Account_name=ra.FileName -- название файла квитанции для этого типа фонда
		 , CASE
			   WHEN b.id_accounts IS NOT NULL THEN (
					   SELECT ra2.FileName
					   FROM dbo.Buildings AS b2 
						   JOIN dbo.Reports_account AS ra2 ON b2.ID = b.ID
							   AND b2.id_accounts = ra2.ID
				   )
			   ELSE ra.FileName -- название файла квитанции для этого типа фонда
		   END AS Account_name
		 , b.fin_current AS fin_current
		 , dbo.Fun_NameFinPeriod(b.fin_current) AS StrMes  -- наименование текущего фин.периода
		 , b.penalty_calc_build
		 , ((o.penalty_old_new+o.penalty_added)+o.penalty_value) AS peny_itog
		 , dbo.Fun_GetRejimOcc(o.Occ) AS state_id_tip
		 , COALESCE(b.town_id, 1) AS town_id
		 , b.date_start AS build_date_start
		 , b.date_end AS build_date_end
		 , b.opu_sq AS build_opu_sq
		 , b.opu_sq_elek AS build_opu_sq_elek
		 , b.opu_sq_otop AS build_opu_sq_otop
		 , b.arenda_sq AS build_arenda_sq
		 , b.build_total_sq AS build_total_sq
		 , b.build_total_area AS build_total_area
		 , CASE
			   WHEN (b.opu_sq > 0 AND b.build_total_sq > 0) THEN CAST(b.opu_sq AS MONEY) * o.total_sq / (b.build_total_sq + COALESCE(b.arenda_sq, 0))
			   ELSE 0
		   END          AS                                                              occ_opu_sq
		 , o.prefix
		 , ot.is_2D_Code
		 , o.email
		 , s.name       AS                                                              street_name
		 , s.short_name AS                                                              street_short_name
		 , t.name       AS                                                              town_name
		 , o.auto_email
		 , o.occ_sync
		 , CAST(CASE
                    WHEN onp.Occ IS NULL THEN 0
                    ELSE 1
        END AS BIT)     AS                                                              block_print_account
		 , c.name       AS                                                              court_name -- наименование судебного участка
		 , b.court_id -- код судебного участка
		 , bt.name      AS                                                              build_type
		 , vb.name      AS                                                              build_vid_blag
		 , ot.start_date
		 , CONCAT('Метод расчета: ' , COALESCE((
			   SELECT TOP 1 name
			   FROM Peny_metod pm
			   WHERE pm.ID = ot.penalty_metod
		   ), ''),  '. Последний день оплаты: ' , LTRIM(STR(COALESCE(ot.lastpaym, 0)))) penalty_str
		 , CAST(CASE
			   WHEN ot.paym_order_metod = 'пени1' THEN 'Погашение пени, затем услуг'
			   WHEN ot.paym_order_metod = 'пени2' THEN 'Первоочередная оплата услуг, затем пени'
			   ELSE ''
		   END AS NVARCHAR(50))                                     AS          paym_order
		   --,COALESCE(ot.paym_order, 'Начисление;Долг;Пени') AS 
		 , CASE
               WHEN b.only_pasport = 1 THEN b.only_pasport
               ELSE ot.only_pasport
           END AS only_pasport
		 , ot.only_value
		 , o.id_jku_gis
		 , o.id_els_gis
		 , f.CadastralNumber
		 , f.id_nom_gis
		 , CAST(CASE
                    WHEN b.is_paym_build = 0 THEN 0
                    ELSE ot.payms_value
			END AS BIT) AS payms_value
		 , o.dogovor_num
		 , o.dogovor_date
		 , b.levels          AS build_levels
		 , b.opu_tepl_kol    AS build_opu_tepl_kol
		 , o.room_id
		 , r.id_room_gis
		 , r.CadastralNumber AS room_CadastralNumber
		 , f.area
	     , b.is_commission_uk
		 , o.bank_account
	FROM dbo.Occupations AS o 
		JOIN dbo.Flats AS f 
			ON o.flat_id = f.ID
		JOIN dbo.Buildings AS b 
			ON f.bldn_id = b.ID
		JOIN dbo.Divisions AS d 
			ON b.div_id = d.ID
		JOIN dbo.VOcc_types AS ot 
			ON b.tip_id = ot.ID
		LEFT JOIN dbo.Reports_account AS ra 
			ON ot.id_accounts = ra.ID
		JOIN dbo.VStreets s 
			ON b.street_id = s.ID
		JOIN dbo.Towns AS t
			ON b.town_id = t.ID
		LEFT JOIN dbo.Sector AS j 
			ON b.sector_id = j.ID
		LEFT JOIN [dbo].[Occ_not_print] AS onp 
			ON o.Occ = onp.Occ
		LEFT JOIN dbo.Courts c 
			ON b.court_id = c.ID
		LEFT JOIN dbo.Build_types AS bt 
			ON b.build_type = bt.ID
		LEFT JOIN dbo.Vid_blag vb 
			ON b.Vid_blag = vb.ID
		LEFT JOIN dbo.Rooms r 
			ON o.room_id = r.ID
	WHERE 
		o.Occ = @occ1
go

