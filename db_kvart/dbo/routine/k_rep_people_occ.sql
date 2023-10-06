CREATE   PROCEDURE [dbo].[k_rep_people_occ]
(
	  @occ1 INT
	, @sup_id INT = NULL  -- null -все 0-ед.лицевой, больше 0 - по поставщику
	, @id1 INT = NULL
)
AS
	/*
	Для справок
	exec k_rep_people_occ 680000603, null, 13403
	exec k_rep_people_occ 680000603, 345, 13403
	exec k_rep_people_occ 248019, 0, NULL
		
	*/
	SET NOCOUNT ON

	IF @id1 = 0
		SET @id1 = NULL

	SELECT TOP(1) t.*
		 , CASE
			   WHEN (t.SALDO + t.Penalty_old - t.Paymaccount_Serv) <= 0 THEN 0
			   ELSE (t.SALDO + t.Penalty_old - t.Paymaccount_Serv)
		   END AS Dolg
		 , CASE
			   WHEN (t.SALDO + t.Penalty_old - t.Paymaccount_Serv) < 0 THEN '0 руб.'
			   ELSE dbo.Fun_RubPhrase(t.SALDO + t.Penalty_old - t.Paymaccount_Serv)
		   END AS SumStr
	FROM (
		SELECT o.address AS adres
			 , CASE
				   WHEN t.region_short IS NOT NULL THEN CONCAT(t.region_short , ',' , o.address)
				   ELSE o.address
			   END AS Adres_full
			 , CASE
				   WHEN ot.synonym_name <> '' THEN RTRIM(ot.synonym_name)
				   ELSE ot.name
			   END AS UKName
			 , CASE
				   WHEN o.proptype_id = N'прив' THEN 'приватизированное'
				   WHEN o.proptype_id = N'купл' THEN 'купленное'
				   WHEN o.proptype_id = N'непр' THEN 'не приватизированное'
			   END AS PROPTYPE
			 , ot.[start_date] as [start_date]
			 , CASE
				   WHEN @sup_id = 0 THEN o.saldo
				   WHEN @sup_id > 0 THEN os1.saldo
				   ELSE o.SaldoAll
			   END AS saldo
			 , CASE
				   WHEN @sup_id = 0 THEN o.Paymaccount
				   WHEN @sup_id > 0 THEN os1.PaymAccount
				   ELSE o.Paymaccount+COALESCE(os1.Paymaccount,0)
			   END AS Paymaccount
			 , CASE
				   WHEN @sup_id = 0 THEN o.PaymAccount_peny
				   WHEN @sup_id > 0 THEN os1.PaymAccount_peny
				   ELSE o.PaymAccount_peny+COALESCE(os1.PaymAccount_peny,0)
			   END AS PaymAccount_peny
			 , CASE
				   WHEN @sup_id = 0 THEN (o.paymaccount-o.paymaccount_peny)
				   WHEN @sup_id > 0 THEN os1.Paymaccount_Serv
				   ELSE o.Paymaccount_ServAll
			   END AS Paymaccount_Serv		     
			 , CASE
				   WHEN @sup_id = 0 THEN o.Penalty_old
				   WHEN @sup_id > 0 THEN os1.Penalty_old
				   ELSE o.Penalty_old + COALESCE(os1.Penalty_old, 0)
			   END AS Penalty_old
			 , CASE
				   WHEN @sup_id = 0 THEN o.Penalty_old_new
				   WHEN @sup_id > 0 THEN os1.Penalty_old_new
				   ELSE o.Penalty_old_new + COALESCE(os1.Penalty_old_new, 0)
			   END AS Penalty_old_new
			 , CASE
                   WHEN @sup_id > 0 THEN os1.occ_sup
                   ELSE dbo.Fun_GetFalseOccOut(o.OCC, o.tip_id)
            END AS OCC
			 , p.id
			 , p.Del
			 , p.Last_name
			 , p.First_name
			 , p.Second_name
			 , p.Lgota_id
			 , p.status_id
			 , p.Status2_id
			 , p.Fam_id
			 , p.Doxod
			 , p.KolMesDoxoda
			 , p.dop_norma
			 , p.Reason_extract
			 , p.Birthdate
			 , p.DateReg
			 , p.DateDel
			 , p.DateEnd
			 , p.DateDeath
			 , p.sex
			 , p.Military
			 , p.Criminal
			 , p.comments
			 , p.Dola_priv
			 , p.kol_day_add
			 , p.kol_day_lgota
			 , p.lgota_kod
			 , p.Citizen
			 , p.OwnerParent
			 , p.Nationality
			 , p.Dola_priv1
			 , p.Dola_priv2
			 , p.dateoznac
			 , p.datesoglacie
			 , p.DateRegBegin
			 , p.doc_privat
			 , p.AutoDelPeople
			 , p.DateBeginPrivat
			 , p.Contact_info
			 , p.DateEdit
			 , p.snils
			 , p.id as owner_id
			 , p2.KraiOld
			 , p2.RaionOld
			 , p2.TownOld
			 , p2.VillageOld
			 , p2.StreetOld
			 , p2.Nom_domOld
			 , p2.Nom_kvrOld
			 , p2.KraiNew
			 , p2.RaionNew
			 , p2.TownNew
			 , p2.VillageNew
			 , p2.StreetNew
			 , p2.Nom_domNew
			 , p2.Nom_kvrNew
			 , p2.KraiBirth
			 , p2.RaionBirth
			 , p2.TownBirth
			 , p2.VillageBirth
			 , p3.DOCTYPE_ID
			 , DOC.short_name AS DOCTYPE_short_name
			 ,CASE
				WHEN p3.DOCTYPE_ID='пасп' THEN 'по паспорту'
				WHEN p3.DOCTYPE_ID IS NOT NULL THEN 'по '+LOWER(CASE
                                                                    WHEN COALESCE(name_dat, '') <> '' THEN name_dat
                                                                    ELSE doc.[name]
                    END)
				ELSE ''
			 END AS DOCTYPE_STR
			 , p3.doc_no
			 , p3.PASSSER_NO
			 , p3.ISSUED
			 , p3.DOCORG
			 , p3.user_edit
			 , p3.date_edit
			 , p3.kod_pvs
		FROM dbo.Occupations AS o 
			JOIN dbo.Occupation_Types AS ot ON 
				o.tip_id = ot.id			
			JOIN dbo.Flats f ON 
				o.flat_id = f.id
			JOIN dbo.Buildings b ON 
				f.bldn_id = b.id
			JOIN dbo.Global_values AS gb ON 
				b.fin_current = gb.fin_id
			JOIN dbo.Towns t ON 
				b.town_id = t.id
			LEFT JOIN dbo.People AS p ON 
				o.OCC = p.OCC
				AND (p.id = @id1) 
			LEFT OUTER JOIN dbo.People_2 AS p2 ON 
				p.id = p2.owner_id
			LEFT OUTER JOIN dbo.Iddoc AS p3 ON 
				p.id = p3.owner_id
				AND p3.active = 1
			LEFT JOIN dbo.Iddoc_types AS DOC ON 
				p3.DOCTYPE_ID = DOC.id
			OUTER APPLY (
				SELECT os.occ_sup AS occ_sup
					 , SUM(os.saldo) AS saldo
					 , SUM(os.PaymAccount) AS PaymAccount
					 , SUM(os.PaymAccount_peny) AS PaymAccount_peny
				     , SUM(os.PaymAccount_serv) AS PaymAccount_serv
					 , SUM(os.Penalty_old) AS Penalty_old
					 , SUM(os.Penalty_old_new) AS Penalty_old_new
				FROM dbo.VOcc_Suppliers AS os
				WHERE os.OCC = o.OCC
					AND os.fin_id = o.fin_id
					AND (@sup_id IS NULL OR os.sup_id = @sup_id)
				GROUP BY os.occ_sup
			) AS os1
		WHERE o.OCC = @occ1
	) AS t
go

