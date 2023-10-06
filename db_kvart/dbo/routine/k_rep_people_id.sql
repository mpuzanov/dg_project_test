CREATE   PROCEDURE [dbo].[k_rep_people_id]
(
	@id1 INT
   ,@sup_id INT = NULL  -- null -все 0-ед.лицевой, больше 0 - по поставщику
)
AS
/*
	Для отчета "Справкав ПВС"
	k_rep_people_id 149805
	k_rep_people_id 132412
		
*/
	SET NOCOUNT ON

	SELECT
		t.*
		,CASE
			WHEN (t.Saldo + t.Penalty_old_new) <= 0 THEN 0
			ELSE (t.Saldo + t.Penalty_old_new)
		END AS Dolg
		,CASE
			WHEN (t.Saldo + t.Penalty_old_new) < 0 THEN '0 руб.'
			ELSE dbo.Fun_RubPhrase(Saldo + Penalty_old_new)
		END AS SumStr
	FROM (SELECT
			p.id
			,p.occ
			,p.Del
			,p.last_name
			,p.first_name
			,p.second_name
			,p.lgota_id
			,p.status_id
			,p.status2_id
			,p.Fam_id
			,p.Doxod
			,p.KolMesDoxoda
			,p.dop_norma
			,p.REASON_EXTRACT
			,p.birthdate
			,p.DateReg
			,p.DateDel
			,p.DateEnd
			,p.DateDeath
			,p.sex
			,p.Military
			,p.Criminal
			,p.comments
			,p.Dola_priv
			,p.kol_day_add
			,p.kol_day_lgota
			,p.lgota_kod
			,p.CITIZEN
			,p.OwnerParent
			,p.Nationality
			,p.Dola_priv1
			,p.Dola_priv2
			,p.dateoznac
			,p.datesoglacie
			,p.DateRegBegin
			,p.doc_privat
			,p.AutoDelPeople
			,p.DateBeginPrivat
			,p.Contact_info
			,p.DateEdit
			,p.snils
			,o.address AS Adres
			,p.id as owner_id
			,p2.KraiOld
			,p2.RaionOld
			,p2.TownOld
			,p2.VillageOld
			,p2.StreetOld
			,p2.Nom_domOld
			,p2.Nom_kvrOld
			,p2.KraiNew
			,p2.RaionNew
			,p2.TownNew
			,p2.VillageNew
			,p2.StreetNew
			,p2.Nom_domNew
			,p2.Nom_kvrNew
			,p2.KraiBirth
			,p2.RaionBirth
			,p2.TownBirth
			,p2.VillageBirth
			,p3.DOCTYPE_ID
			,DOC.short_name as DOCTYPE_short_name
			,CASE
				WHEN p3.DOCTYPE_ID='пасп' THEN 'по паспорту'
				WHEN p3.DOCTYPE_ID IS NOT NULL THEN 'по '+LOWER(CASE
                                                                    WHEN COALESCE(name_dat, '') <> '' THEN name_dat
                                                                    ELSE doc.[name]
                    END)
				ELSE ''
			END AS DOCTYPE_STR
			,p3.DOC_NO
			,p3.PASSSER_NO
			,p3.ISSUED
			,p3.DOCORG
			,p3.user_edit
			,p3.date_edit
			,p3.kod_pvs
			,CASE
				WHEN t.region_short IS NOT NULL THEN t.region_short + ',' + o.address
				ELSE o.address
			END AS Adres_full
			,CASE
				WHEN ot.synonym_name <> '' THEN RTRIM(ot.synonym_name)
				ELSE ot.NAME
			END AS UKName
			,CASE
				WHEN o.PROPTYPE_ID = 'прив' THEN 'приватизированное'
				WHEN o.PROPTYPE_ID = 'купл' THEN 'купленное'
				WHEN o.PROPTYPE_ID = 'непр' THEN 'не приватизированное'
			END AS PROPTYPE
			,gb.start_date
			,CASE
				WHEN @sup_id = 0 THEN o.saldo
				WHEN @sup_id > 0 THEN os1.saldo
				ELSE o.SaldoAll
			END AS saldo
			,CASE
				WHEN @sup_id = 0 THEN o.Penalty_old_new
				WHEN @sup_id > 0 THEN os1.Penalty_old_new
				ELSE o.Penalty_old_new + COALESCE(os1.Penalty_old_new, 0)
			END AS Penalty_old_new
		FROM dbo.PEOPLE AS p
		LEFT OUTER JOIN dbo.PEOPLE_2 AS p2 
			ON p.id = p2.owner_id
		LEFT OUTER JOIN dbo.IDDOC AS p3 
			ON p.id = p3.owner_id
			AND p3.active = 1
		LEFT JOIN dbo.IDDOC_TYPES AS DOC 
			ON p3.DOCTYPE_ID = doc.id
		JOIN dbo.OCCUPATIONS AS o 
			ON p.occ = o.occ
		JOIN dbo.OCCUPATION_TYPES AS ot 
			ON o.tip_id = ot.id
		JOIN dbo.FLATS f
			ON o.flat_id = f.id
		JOIN dbo.BUILDINGS b 
			ON f.bldn_id = b.id
		JOIN dbo.GLOBAL_VALUES AS gb
			ON b.fin_current = gb.fin_id
		JOIN TOWNS t
			ON b.town_id = t.id
		OUTER APPLY (SELECT
				SUM(os.saldo) AS saldo
			   ,SUM(os.Penalty_old_new) AS Penalty_old_new
			FROM dbo.OCC_SUPPLIERS AS os 
			WHERE os.Occ = o.Occ
			AND os.fin_id = ot.fin_id
			AND (@sup_id IS NULL OR os.sup_id = @sup_id)) AS os1
		WHERE p.id = @id1) AS t
go

