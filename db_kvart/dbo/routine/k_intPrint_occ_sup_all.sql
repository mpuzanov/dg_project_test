CREATE   PROCEDURE [dbo].[k_intPrint_occ_sup_all]
(
	  @fin_id1 SMALLINT
	, @occ1 INT = 0
	, @sup_id INT = NULL
	, @tip_id SMALLINT = NULL
	, @sum_dolg DECIMAL(9, 2) = 0 -- если не равно 0 вывод только с долгом более этой суммы 
	, @current_dolg BIT = 0 -- использовать текущий долг для выборки
	, @debug BIT = 0
	, @SetLastDayMonthPrint BIT = NULL -- устанавливать последний день месяца печати
)
AS
	/*
по поставщикам по лицевому счёту
exec [k_intPrint_occ_sup_all] @fin_id1=195,@occ1=318105,@sup_id=365,@debug = 1 

*/
	SET NOCOUNT ON

	DECLARE @sal INT
		  , @db_name VARCHAR(20)
		  , @dog_int INT
		  , @fin_current SMALLINT
		  , @SumPaymUks DECIMAL(9, 2) = 0
		  , @StrSub3 VARCHAR(100) = ''

	SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip_id, NULL, NULL, @occ1)

	IF @sum_dolg = 0
		OR @sum_dolg IS NULL
		SET @sal = -999999999
	ELSE
		SET @sal = @sum_dolg

	IF @current_dolg IS NULL
		SET @current_dolg = 0

	SELECT @occ1 = dbo.Fun_GetFalseOccIn(@occ1)

	DECLARE @t myTypeTableOcc

	DECLARE @t_schet TABLE (
		  occ INT
		, sup_id INT
		, NameFirma VARCHAR(100) COLLATE Cyrillic_General_CI_AS DEFAULT NULL
		, BANK VARCHAR(100) COLLATE Cyrillic_General_CI_AS DEFAULT NULL
		, rasscht VARCHAR(30) DEFAULT NULL
		, korscht VARCHAR(30) DEFAULT NULL
		, bik VARCHAR(20) DEFAULT NULL
		, inn VARCHAR(20) DEFAULT NULL
		, kpp VARCHAR(9) DEFAULT NULL
		, tip_id SMALLINT DEFAULT 1
		, id_barcode VARCHAR(50) DEFAULT ''
		, licbank BIGINT DEFAULT 0
		, adres VARCHAR(60) COLLATE Cyrillic_General_CI_AS DEFAULT ''
		, Initials VARCHAR(120) COLLATE Cyrillic_General_CI_AS DEFAULT ''
		, total_sq DECIMAL(10, 4) DEFAULT 0
		, total_people SMALLINT DEFAULT 0
		, PersonStatus VARCHAR(80) DEFAULT ''
		, NameFirma_str2 VARCHAR(100) COLLATE Cyrillic_General_CI_AS DEFAULT NULL
		, LastDayPaym SMALLDATETIME DEFAULT NULL
		, tip_account_org SMALLINT-- признак откуда взяли банковский счет
		, proptype_id VARCHAR(10) DEFAULT NULL
		, index_postal INT DEFAULT NULL
		, Visible BIT DEFAULT 1
		, tip_name_dog VARCHAR(50) DEFAULT NULL
		, LastName VARCHAR(25) DEFAULT ''
		, FirstName VARCHAR(25) DEFAULT ''
		, Second_name VARCHAR(25) DEFAULT ''
		, cbc VARCHAR(20) DEFAULT NULL
		, oktmo VARCHAR(11) DEFAULT NULL
		, kol_people_reg SMALLINT DEFAULT 0
	)
	--WHEN tip_account_org=1 THEN 'Тип фонда'
	--WHEN tip_account_org=2 THEN 'Участок'
	--WHEN tip_account_org=3 THEN 'Поставщик'
	--WHEN tip_account_org=4 THEN 'Район'
	--WHEN tip_account_org=5 THEN 'Дом'
	--WHEN tip_account_org=6 THEN 'Договор'

	IF @occ1 > 0
	BEGIN
		INSERT INTO @t (occ
					  , proptype_id
					  , roomtype_id
					  , fin_id
					  , tip_id
					  , flat_id
					  , build_id
					  , total_sq
					  , sup_id
					  , occ_sup
					  , kol_people_reg)
		SELECT --DISTINCT
			o.occ
		  , o.proptype_id
		  , o.roomtype_id
		  , o.fin_id
		  , o.tip_id
		  , o.flat_id
		  , o.bldn_id
		  , o.total_sq
		  , bs.sup_id
		  , bs.occ_sup
		  , o.kol_people_reg
		FROM dbo.View_occ_all_lite AS o 
			JOIN dbo.Occ_Suppliers AS bs 
				ON o.occ = bs.occ
				AND o.fin_id = bs.fin_id
		WHERE o.occ = @occ1
			AND o.fin_id = @fin_id1
			AND o.status_id <> 'закр'
			AND (bs.sup_id = @sup_id OR @sup_id IS NULL)
			AND bs.fin_id = @fin_id1
	END

LABEL1:

	-- убираем лицевые которые не должны печатать
	IF @occ1 = 0
		DELETE t
		FROM @t AS t
			JOIN dbo.Occ_not_print AS onp
				ON t.occ = onp.occ
				AND onp.flag = 1

	IF @debug = 1
		SELECT '@t'
			 , *
		FROM @t

	-- Записываем банковские реквизиты у поставщика
	INSERT INTO @t_schet (occ
						, sup_id
						, NameFirma
						, BANK
						, rasscht
						, korscht
						, bik
						, inn
						, kpp
						, tip_id
						, id_barcode
						, licbank
						, adres
						, Initials
						, total_sq
						, total_people
						, PersonStatus
						, NameFirma_str2
						, tip_account_org
						, LastDayPaym
						, proptype_id
						, index_postal
						, tip_name_dog
						, LastName
						, FirstName
						, Second_name
						, cbc
						, oktmo
						, kol_people_reg)
	SELECT --DISTINCT
		t.occ
	  , t.sup_id
	  , ao.name_str1 COLLATE Cyrillic_General_CI_AS
	  , ao.BANK COLLATE Cyrillic_General_CI_AS
	  , ao.rasschet
	  , ao.korschet
	  , ao.bik
	  , ao.inn
	  , ao.kpp
	  , o.tip_id
	  , ao.id_barcode
	  , ao.licbank
	  , o.address COLLATE Cyrillic_General_CI_AS
	  , I.Initials COLLATE Cyrillic_General_CI_AS
	  , I.total_sq
	  , I.total_people
	  , I.PersonStatus --  dbo.Fun_PersonStatusStr(o.occ)
	  , ao.name_str2
	  , ao.tip
	  , CASE
			WHEN vst.LastPaymDay IS NULL THEN I.LastDayPaym2
			ELSE vst.LastPaymDay
		END AS LastDayPaym
	  , t.proptype_id
	  , b.index_postal
	  , ds.tip_name_dog
	  , p.last_name
	  , p.first_name
	  , p.Second_name
	  , ao.cbc
	  , ao.oktmo
	  , t.kol_people_reg
	FROM @t AS t
		JOIN dbo.Occupations AS o 
			ON t.occ = o.occ
		JOIN dbo.Flats f 
			ON o.flat_id = f.Id
		JOIN dbo.Buildings b 
			ON f.bldn_id = b.Id
		JOIN dbo.Intprint AS I 
			ON t.occ = I.occ
			AND I.fin_id = @fin_id1
		LEFT JOIN dbo.People AS p 
			ON I.Initials_owner_id = p.Id
		JOIN dbo.Dog_build AS db 
			ON t.fin_id = db.fin_id
			AND t.build_id = db.build_id
		JOIN dbo.Dog_sup AS ds 
			ON db.dog_int = ds.Id
			AND t.sup_id = ds.sup_id
		JOIN dbo.Account_org AS ao 
			ON ds.bank_account = ao.Id
		LEFT JOIN [dbo].[View_suppliers_types] AS vst 
			ON t.fin_id = vst.fin_id
			AND o.tip_id = vst.tip_id
			AND t.sup_id = vst.sup_id
			AND vst.service_id = ''

	IF @debug = 1
		SELECT '@t_schet'
			 , *
		FROM @t_schet

	IF EXISTS (
			SELECT 1
			FROM @t_schet AS t
			WHERE rasscht IS NULL
				OR rasscht = ''
		)
	BEGIN
		RAISERROR ('Нет банковских реквизитов!', 16, 1)
		RETURN
	END

	UPDATE @t_schet
	SET Visible = 0
	WHERE sup_id = (
			SELECT s.sup_id
			FROM dbo.Suppliers AS s
			WHERE s.account_one = 1
				AND s.service_id IN ('капр')
		)
		AND proptype_id = 'непр'

	UPDATE ts
	SET Visible = 0
	FROM @t_schet ts
		JOIN @t t ON ts.occ = t.occ
			AND ts.sup_id = t.sup_id
	WHERE EXISTS (
			SELECT 1
			FROM dbo.Suppliers_build sb 
			WHERE sb.build_id = t.build_id
				AND sb.sup_id = t.sup_id
				AND sb.print_blocked = 1
		)
		OR EXISTS (
			SELECT 1
			FROM dbo.Suppliers_types sb 
			WHERE sb.tip_id = t.tip_id
				AND sb.sup_id = t.sup_id
				AND sb.print_blocked = 1
		)
	IF EXISTS (
			SELECT 1
			FROM dbo.Global_values 
			WHERE fin_id = @fin_id1
				AND BlokedPrintAccount = 1
		)
	BEGIN -- Блокируем печать квитанций
		DELETE FROM @t_schet
	END

	DELETE FROM @t_schet
	WHERE Visible = 0

	IF @debug = 1
		SELECT *
		FROM @t_schet
		ORDER BY occ

	IF @db_name IN ('KR1', 'ARX_KR1')
	BEGIN
		IF EXISTS (
				SELECT 1
				FROM dbo.View_payings 
				WHERE fin_id = @fin_id1
					AND occ = @occ1
					AND sup_id IS NOT NULL
					AND (
					tip_paym_id IN ('1013') --'Уступка долга'				
					)
			)
			EXEC dbo.k_StrsumPaymUks @occ1
								   , @fin_id1
								   , '1013'
								   , 'переданного в'
								   , @StrSub3 OUT
								   , @SumPaymUks OUT

	END

	DECLARE @DatePrint SMALLDATETIME
		  , @start_date SMALLDATETIME
	SELECT @DatePrint = dbo.Fun_GetOnlyDate(
		   CASE
			   WHEN @SetLastDayMonthPrint = 1 THEN end_date
			   ELSE current_timestamp
		   END)
		 , @start_date = gb.start_date
	FROM dbo.Global_values AS gb 
	WHERE fin_id = @fin_id1


	SELECT os.fin_id
		 , os.occ
		 , os.sup_id
		 , os.occ_sup
		 , os.id_jku_gis
		 , dbo.Fun_GetNumPdGis2(os.id_jku_gis, os.fin_id) AS id_jku_pd_gis
		 , os.saldo
		 , os.Value
		 , os.Added
		 , os.Paid
		 , os.PaymAccount - @SumPaymUks AS PaymAccount
		 , os.PaymAccount_peny
		 , os.Debt
		 , os.PaymAccount_storno
		 , os.Penalty_value
		 , os.Penalty_added				-- DECIMAL(9,2)
		 , os.Penalty_old_new
		 , os.Penalty_old
		 , (os.Penalty_value + os.Penalty_added) AS Penalty_period		-- DECIMAL(9,2)	
		 , (os.Penalty_value + os.Penalty_added + os.Penalty_old_new) AS Penalty_itog	-- DECIMAL(9,2)
		 , os.Whole_payment
		 , os.Whole_payment - (os.Penalty_value + os.Penalty_added + os.Penalty_old_new) AS SumPaymNoPeny
		 , COALESCE(os.Debt, 0) + (os.Penalty_value + os.Penalty_added + os.Penalty_old_new) AS SumPaymDebt -- может быть отрицательным
		 , os.KolMesDolg
		 , os.Penalty_old_edit
		 , os.Paid_old
		 , os.dog_int
		 , os.cessia_dolg_mes_old
		 , os.cessia_dolg_mes_new
		 , t.NameFirma
		 , t.NameFirma_str2
		 , dbo.Fun_GetScaner_Kod_SUP_EAN(t.occ, sup.Id, @fin_id1, os.Whole_payment, t.id_barcode) AS [EAN]
		   --, [EAN_2D] = dbo.Fun_GetScaner_Kod_PDF417(t.occ, NULL, @fin_id1, i.Whole_payment, t.adres, t.Initials, t.NameFirma, t.bik, t.rasscht, t.licbank)
		   --,[EAN_2D] =
		   --	CASE
		   --		WHEN ot.is_2D_Code = 1 THEN [dbo].[Fun_GetScaner_2D_SBER](t.occ_false, @fin_id1, NULL, i.SumPaym, t.adres, i.Initials, t.bank, t.bik, t.korscht, t.NameFirma, t.rasscht, t.inn, t.kpp, t.licbank)
		   --		--[dbo].[Fun_GetScaner_PDF417](t.occ_false, @fin_id1, NULL, i.SumPaym, t.adres, i.Initials, t.bank, t.bik, t.korscht, t.NameFirma, t.rasscht, t.inn, t.kpp, t.licbank)
		   --		ELSE CASE
		   --			WHEN @tip_id IN (60, 57, 59) THEN dbo.Fun_GetScaner_Kod_SUP_EAN(t.occ_false, 0, @fin_id1, o.Summa1, t.id_barcode) --o.Whole_payment
		   --			ELSE dbo.Fun_GetScaner_Kod_EAN(t.occ_false, NULL, @fin_id1, i.SumPaym, t.id_barcode, barcode_type, t.inn)
		   --		END
		   --	END
		 , CASE
			   --WHEN ot.is_2D_Code = 1 THEN [dbo].[Fun_GetScaner_PDF417](t.occ, @fin_id1, sup.id, i.Whole_payment, t.adres, t.Initials, t.BANK, t.bik, t.korscht, t.NameFirma, t.rasscht, t.inn, t.kpp, t.licbank)
			   WHEN ot.is_2D_Code = 1 THEN [dbo].[Fun_GetScaner_2D_SBER](t.occ, @fin_id1, sup.Id, os.Whole_payment, t.adres, t.Initials, t.BANK, t.bik, t.korscht, t.NameFirma, t.rasscht, t.inn, t.kpp, t.licbank, t.LastName, t.FirstName, t.Second_name, t.cbc, t.oktmo, dbo.Fun_GetNumPdGis2(os.id_jku_gis, os.fin_id), '')
			   ELSE dbo.Fun_GetScaner_Kod_SUP_EAN(t.occ, sup.Id, @fin_id1, os.Whole_payment, t.id_barcode)
		   END AS [EAN_2D]
		   --,[EAN_2D_B] =
		   --	CASE
		   --		WHEN ot.is_2D_Code = 1 THEN CAST([dbo].[Fun_GetScaner_PDF417](t.occ, @fin_id1, sup.id, i.Whole_payment, t.adres, t.Initials, t.BANK, t.bik, t.korscht, t.NameFirma, t.rasscht, t.inn, t.kpp, t.licbank) AS VARBINARY(700))
		   --		ELSE CAST(0 AS VARBINARY(700))
		   --	END
		 , t.BANK
		 , t.rasscht
		 , t.korscht
		 , t.bik
		 , t.inn
		 , t.kpp
		 , t.cbc
		 , t.oktmo
		 , t.index_postal AS index_postal
		 , t.tip_id
		 , CASE
			   WHEN t.tip_name_dog IS NOT NULL AND
				   t.tip_name_dog <> '' THEN t.tip_name_dog
			   WHEN ot.synonym_name IS NULL OR
				   ot.synonym_name = '' THEN ot.name
			   ELSE ot.synonym_name
		   END AS [tip_name]
		 , [dbo].[Fun_GetAddStr](t.occ, @fin_id1, sup.Id, NULL) AS StrAdd
		 , CASE
			   WHEN t.index_postal > 1 THEN LTRIM(STR(t.index_postal, 6)) + ','
			   ELSE ''
		   END + t.adres AS adres
		 , Initials
		 , dbo.Fun_NameFinPeriod(@fin_id1) AS StrFinPeriod
		 , t.total_sq
		   --, total_people
		   --,[dbo].[Fun_GetKolPeopleOccReg](@fin_id1, t.occ) AS total_people
		 , t.kol_people_reg AS total_people
		 , t.PersonStatus
		 , COALESCE(sup.synonym_name, sup.name) AS sup_name
		 , ot.adres AS adres_tip
		 , ot.telefon AS telefon_tip
		 , ot.inn AS inn_tip
		 , ot.kpp AS kpp_tip
		 , ot.ogrn AS ogrn_tip
		 , ot.email AS email_tip
		 , ot.laststr1 AS laststr1
		 , ot.laststr2 AS laststr2
		 , ot.logo
		 , CASE
			   WHEN (sup.Id > 0) AND
				   (COALESCE(sup.tip_org_for_account, '') <> '') THEN sup.tip_org_for_account
			   WHEN ot.tip_org_for_account IS NULL OR
				   LTRIM(ot.tip_org_for_account) = '' THEN 'Управляющая организация'
			   ELSE ot.tip_org_for_account
		   END AS tip_org_for_account
		 , [dbo].[Fun_GetPrintStrPaymDiscount](t.occ, os.fin_id, os.sup_id) AS strPaymDiscount
		 , t.LastDayPaym
		 , CASE
			   WHEN os.PaymAccount = 0 THEN ''
			   ELSE (
					   SELECT TOP 1 CONVERT(VARCHAR(10), p2.day, 104) -- дата последней оплаты
					   FROM dbo.Payings AS p1 
						   JOIN dbo.Paydoc_packs AS p2 
							ON p1.pack_id = p2.Id
					   WHERE p1.occ = t.occ
						   AND p2.fin_id = @fin_id1
						   AND p1.sup_id = os.sup_id
					   ORDER BY p2.day DESC
				   )
		   END AS LastDayPaymAccount
		 , @StrSub3 AS StrSubsidia3
		 , CASE
			   WHEN t.visible = 0 AND
				   t.proptype_id = 'непр' THEN 0
			   ELSE t.visible
		   END AS visible -- печатать или нет квитанцию поставщика	
		 , sup.str_account1
		 , @DatePrint AS DatePrint
		 , COALESCE(sup.LastStrAccount, '') AS LastStrAccountSup		 
	FROM @t_schet AS t
		JOIN dbo.VOcc_Suppliers AS os 
			ON t.occ = os.occ
			AND os.fin_id = @fin_id1
			AND t.sup_id = os.sup_id
		JOIN dbo.Occupation_Types AS ot
			ON t.tip_id = ot.Id
		JOIN dbo.Suppliers_all AS sup 
			ON os.sup_id = sup.Id
		LEFT JOIN dbo.VOcc_Suppliers AS i2 
			ON t.occ = i2.occ
			AND i2.fin_id = @fin_current
			AND t.sup_id = i2.sup_id
	WHERE @sal <=
				 CASE
					 WHEN @current_dolg = 1 THEN i2.Whole_payment
					 ELSE os.Whole_payment
				 END
--ORDER BY ts.sort_no
go

