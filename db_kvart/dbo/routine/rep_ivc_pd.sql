-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE               PROCEDURE [dbo].[rep_ivc_pd]
(
	  @fin_id SMALLINT = NULL
	, @tip_id SMALLINT
	, @build_id INT = NULL
	, @sup_id INT = NULL
	, @occ INT = NULL
	, @format VARCHAR(10) = NULL
	, @debug BIT = 0
)
AS
/*
rep_ivc_pd @fin_id=232, @tip_id=2,@build_id=6765, @sup_id=null, @occ=null	
rep_ivc_pd @fin_id=232, @tip_id=1,@build_id=null, @sup_id=345, @occ=30040

exec rep_ivc_pd @fin_id=212, @tip_id=28,@build_id=1026, @sup_id=323, @occ=680001639 --, @format='xml'	
exec rep_ivc_pd @fin_id=212, @tip_id=28,@build_id=1026, @sup_id=345, @occ=680001639

*/
BEGIN
	SET NOCOUNT ON;

	IF @build_id IS NULL
		AND @sup_id IS NULL
		AND @tip_id IS NULL
		SELECT @build_id = 0
			 , @sup_id = 0
			 , @fin_id = 0
			 , @tip_id = 0

	IF @fin_id IS NULL
		SELECT @fin_id = dbo.Fun_GetFinCurrent(@tip_id, @build_id, NULL, @occ)

	-- 1. Создать основную таблицу
	IF COALESCE(@sup_id, 0) = 0
	BEGIN
		DROP TABLE IF EXISTS #t_pd
		CREATE TABLE #t_pd (
			  sort_no INT
			, fin_id SMALLINT
			, occ INT
			, SumPaym DECIMAL(15, 4)
			, SumPaymNoPeny DECIMAL(15, 4)
			, SumPaymDebt DECIMAL(15, 4)
			, Paid DECIMAL(15, 4)
			, occ_pd INT
			, num_pd VARCHAR(16) COLLATE database_default
			, id_els_gis VARCHAR(10)  COLLATE database_default
			, id_jku_gis VARCHAR(13) COLLATE database_default
			, id_jku_pd_gis VARCHAR(20) COLLATE database_default
			, Penalty_itog DECIMAL(15, 4)
			, jeu SMALLINT
			, jeu_name VARCHAR(30) COLLATE database_default
			, Initials VARCHAR(120) COLLATE database_default
			, adres VARCHAR(100) COLLATE database_default
			, Lgota VARCHAR(20) COLLATE database_default
			, total_people SMALLINT
			, TOTAL_SQ DECIMAL(9, 2)
			, LIVING_SQ DECIMAL(9, 2)
			, FinPeriod SMALLDATETIME
			, StrFinPeriod VARCHAR(30) COLLATE database_default
			, SALDO DECIMAL(15, 4)
			, DolgWithPeny DECIMAL(15, 4)
			, paymaccount DECIMAL(15, 4)
			, paymaccount_peny DECIMAL(15, 4)
			, Debt DECIMAL(15, 4)
			, paymaccount_storno DECIMAL(15, 4)
			, LastDayPaym SMALLDATETIME
			, LastDayPaym2 SMALLDATETIME
			, PersonStatus VARCHAR(50) COLLATE database_default
			, Month3 VARCHAR(20) COLLATE database_default
			, penalty_value DECIMAL(15, 4)
			, StrSubsidia1 VARCHAR(100) COLLATE database_default
			, StrSubsidia2 VARCHAR(100) COLLATE database_default
			, StrSubsidia3 VARCHAR(100) COLLATE database_default
			, Div_id SMALLINT
			, KolMesDolg DECIMAL(5, 1)
			, DateCreate SMALLDATETIME
			, NameFirma VARCHAR(100) COLLATE database_default
			, NameFirma_str2 VARCHAR(100) COLLATE database_default
			, [ean] VARCHAR(50) COLLATE database_default
			, [ean_2d] NVARCHAR(2000) COLLATE database_default
			, [ean_2d_nopeny] VARCHAR(50) COLLATE database_default
			, [ean_2d_peny] VARCHAR(50) COLLATE database_default
			, [ean_sber] VARCHAR(50) COLLATE database_default
			, bank VARCHAR(100) COLLATE database_default
			, rasscht VARCHAR(30) COLLATE database_default
			, korscht VARCHAR(30) COLLATE database_default
			, bik VARCHAR(20) COLLATE database_default
			, inn VARCHAR(20) COLLATE database_default
			, kpp VARCHAR(20) COLLATE database_default
			, cbc VARCHAR(20) COLLATE database_default
			, oktmo VARCHAR(20) COLLATE database_default
			, [INDEX] INT
			, index_postal INT
			, tip_id SMALLINT
			, [tip_name] VARCHAR(150) COLLATE database_default
			, adres_tip VARCHAR(100) COLLATE database_default
			, telefon_tip VARCHAR(100) COLLATE database_default
			, inn_tip VARCHAR(20) COLLATE database_default
			, kpp_tip VARCHAR(20) COLLATE database_default
			, ogrn_tip VARCHAR(20) COLLATE database_default
			, email_tip VARCHAR(50) COLLATE database_default
			, details_tip VARCHAR(1000) COLLATE database_default
			, StrAdd VARCHAR(800) COLLATE database_default
			, LastStr1 VARCHAR(100) COLLATE database_default
			, LastStr2 VARCHAR(1000) COLLATE database_default
			, logo VARBINARY(MAX)
			, adres_sec VARCHAR(100) COLLATE database_default
			, fio_sec VARCHAR(50) COLLATE database_default
			, telefon_sec VARCHAR(100) COLLATE database_default
			, tip_org_for_account VARCHAR(100) COLLATE database_default
			, build_id INT
			, LastDayPaymAccount VARCHAR(10) COLLATE database_default
			, build_norma_gkal DECIMAL(9, 6)
			, build_opu_sq DECIMAL(9, 2)
			, build_opu_sq_elek DECIMAL(9, 2)
			, build_total_sq DECIMAL(9, 2)
			, build_arenda_sq DECIMAL(9, 2)
			, build_comments VARCHAR(4000) COLLATE database_default
			, adres_build VARCHAR(100) COLLATE database_default
			, account_rich VARCHAR(MAX)
			, nom_kvr VARCHAR(20) COLLATE database_default
			, StrLast VARCHAR(1000) COLLATE database_default
			, DatePrint SMALLDATETIME
			, kol_jeu SMALLINT
			, row_num_jeu SMALLINT
			, kol_occ_jeu SMALLINT
			, kol_occ_build INT
			, [start_date] SMALLDATETIME
			, tip_occ SMALLINT
			, soi_isTotalSq_Pasport BIT
			, build_total_area DECIMAL(9, 2)
			, marketing_str VARCHAR(1000) COLLATE database_default
			, watermark BIT
			, watermark_text VARCHAR(50) COLLATE database_default
			, Square_str VARCHAR(1000) COLLATE database_default
			, PROPTYPE_ID VARCHAR(10) COLLATE database_default
			, Penalty_old DECIMAL(15, 4)
			, Penalty_period DECIMAL(15, 4)
			, Penalty_old_new DECIMAL(15, 4)
			, comments_print VARCHAR(50) COLLATE database_default
			, web_site VARCHAR(50) COLLATE database_default
			, rezhim_work VARCHAR(100) COLLATE database_default
			, comments_tip VARCHAR(100) COLLATE database_default
			, telefon_pasp VARCHAR(100) COLLATE database_default
			, tip_occ_name VARCHAR(20) COLLATE database_default
			, roomtype_id VARCHAR(10) COLLATE database_default
		    , epd_dolg	DECIMAL(15,2) NOT NULL DEFAULT 0
			, epd_overpayment DECIMAL(15,2) NOT NULL DEFAULT 0
		    , epd_saldo_dolg	DECIMAL(15,2) NOT NULL DEFAULT 0
			, epd_saldo_overpayment DECIMAL(15,2) NOT NULL DEFAULT 0
			, tip_pd VARCHAR(10) COLLATE database_default NOT NULL DEFAULT 'Текущий'
			, qrData NVARCHAR(2000) COLLATE database_default
		)

		IF @occ IS NOT NULL
			SET @build_id = NULL

		INSERT INTO #t_pd
		EXEC k_intPrint_occ @fin_id1 = @fin_id
						  , @tip_id = @tip_id
						  , @build = @build_id
						  , @occ1 = @occ
						  , @notocc = 1  -- выдавать даже заблокированные
						--, @debug=1
	END
	ELSE
	BEGIN
		DROP TABLE IF EXISTS #t_pd_sup
		CREATE TABLE #t_pd_sup (
			  sort_no INT
			, fin_id SMALLINT
			, occ INT
			, sup_id INT
			, occ_sup INT
			, occ_pd INT
			, num_pd VARCHAR(20) COLLATE database_default
			, id_els_gis VARCHAR(20) COLLATE database_default
			, id_jku_gis VARCHAR(20) COLLATE database_default
			, id_jku_pd_gis VARCHAR(20) COLLATE database_default
			, SALDO DECIMAL(15, 4)
			, value DECIMAL(15, 4)
			, added DECIMAL(15, 4)
			, Paid DECIMAL(15, 4)
			, paymaccount DECIMAL(15, 4)
			, paymaccount_peny DECIMAL(15, 4)
			, Debt DECIMAL(15, 4)
			, paymaccount_storno DECIMAL(15, 4)
			, penalty_value DECIMAL(15, 4)
			, penalty_added DECIMAL(15, 4)
			, Penalty_old_new DECIMAL(15, 4)
			, Penalty_old DECIMAL(15, 4)
			, Penalty_itog DECIMAL(15, 4)
			, Whole_payment DECIMAL(15, 4)
			, SumPaym DECIMAL(15, 4)
			, SumPaymNoPeny DECIMAL(15, 4)
			, SumPaymDebt DECIMAL(15, 4)
			, KolMesDolg DECIMAL(5, 1)
			, Penalty_old_edit SMALLINT
			, Paid_old DECIMAL(15, 4)
			, dog_int INT
			, cessia_dolg_mes_old SMALLINT
			, cessia_dolg_mes_new SMALLINT
			, NameFirma VARCHAR(100) COLLATE database_default
			, NameFirma_str2 VARCHAR(100) COLLATE database_default
			, [ean] VARCHAR(25) COLLATE database_default
			, [ean_2d] NVARCHAR(2000) COLLATE database_default
			, bank VARCHAR(100) COLLATE database_default
			, rasscht VARCHAR(30) COLLATE database_default
			, korscht VARCHAR(30) COLLATE database_default
			, bik VARCHAR(20) COLLATE database_default
			, inn VARCHAR(20) COLLATE database_default
			, kpp VARCHAR(20) COLLATE database_default
			, cbc VARCHAR(20) COLLATE database_default
			, oktmo VARCHAR(20) COLLATE database_default
			, [INDEX] INT
			, index_postal INT
			, tip_id SMALLINT
			, [tip_name] VARCHAR(150) COLLATE database_default
			, StrAdd VARCHAR(800) COLLATE database_default
			, adres VARCHAR(100) COLLATE database_default
			, adres_build VARCHAR(100) COLLATE database_default
			, nom_kvr VARCHAR(20) COLLATE database_default
			, Initials VARCHAR(120) COLLATE database_default
			, FinPeriod SMALLDATETIME
			, StrFinPeriod VARCHAR(15) COLLATE database_default
			, TOTAL_SQ DECIMAL(9, 2)
			, LIVING_SQ DECIMAL(9, 2)
			, total_people SMALLINT
			, PersonStatus VARCHAR(80) COLLATE database_default
			, sup_name VARCHAR(50) COLLATE database_default
			, adres_tip VARCHAR(100) COLLATE database_default
			, telefon_tip VARCHAR(70) COLLATE database_default
			, inn_tip VARCHAR(15) COLLATE database_default
			, kpp_tip VARCHAR(15) COLLATE database_default
			, ogrn_tip VARCHAR(15) COLLATE database_default
			, email_tip VARCHAR(50) COLLATE database_default
			, LastStr1 VARCHAR(70) COLLATE database_default
			, LastStr2 VARCHAR(1000) COLLATE database_default
			, logo VARBINARY(MAX)
			, tip_org_for_account VARCHAR(50) COLLATE database_default
			, strPaymDiscount VARCHAR(100) COLLATE database_default
			, LastDayPaym SMALLDATETIME
			, LastDayPaym2 SMALLDATETIME
			, LastDayPaymAccount VARCHAR(10) COLLATE database_default
			, StrSubsidia3 VARCHAR(100) COLLATE database_default
			, visible SMALLINT
			, str_account1 VARCHAR(100) COLLATE database_default
			, DatePrint SMALLDATETIME
			, LastStrAccountSup VARCHAR(15) COLLATE database_default
			, sup_adres VARCHAR(100) COLLATE database_default
			, sup_inn VARCHAR(15) COLLATE database_default
			, sup_kpp VARCHAR(15) COLLATE database_default
			, sup_ogrn VARCHAR(15) COLLATE database_default
			, sup_telefon VARCHAR(70) COLLATE database_default
			, sup_email VARCHAR(50) COLLATE database_default
			, sup_web_site VARCHAR(50) COLLATE database_default
			, sup_rezhim_work VARCHAR(50) COLLATE database_default
			, [start_date] SMALLDATETIME
			, tip_occ SMALLINT
			, account_rich VARCHAR(4000) COLLATE database_default
			, Penalty_period DECIMAL(15, 4)
			, comments_print VARCHAR(50) COLLATE database_default
			, tip_occ_name VARCHAR(20) COLLATE database_default
			, roomtype_id VARCHAR(10) COLLATE database_default
			, build_id INT
			, tip_pd VARCHAR(10) COLLATE database_default NOT NULL DEFAULT 'Текущий'
			, qrData NVARCHAR(2000) COLLATE database_default
		)

		INSERT INTO #t_pd_sup
		EXEC k_intPrint_occ_sup @fin_id1 = @fin_id
							  , @tip_id = @tip_id
							  , @build = @build_id
							  , @sup_id = @sup_id
							  , @occ1 = @occ
	--,@debug=1
	END


	DROP TABLE IF EXISTS #t_main
	CREATE TABLE #t_main (
		  [period] VARCHAR(15)
		, num_pd VARCHAR(20)
		, poluchatel NVARCHAR(1000)
		, rekvizity VARCHAR(1000)
		, platelshik VARCHAR(200)
		, nomerls VARCHAR(20)
		, lc_numer VARCHAR(20)
		, pomeshenie VARCHAR(100)
		, uk VARCHAR(1000)
		, uk_rekvizity VARCHAR(1000)
		, ki_passport VARCHAR(1000)
		, ki_buhgalteria VARCHAR(1000)
		, ki_dispetcher VARCHAR(1000)
		, ki_avaria VARCHAR(1000)
		, ki_uchastor VARCHAR(1000)
		, obshaya_ploshad DECIMAL(9, 2)
		, zaregistrirovano INT
		, prozhivaet VARCHAR(1000)
		, floor SMALLINT
		, nachisleno DECIMAL(9, 2)
		, nachisleno_uslugi DECIMAL(9, 2)
		, nachisleno_peni DECIMAL(9, 2)
		, nachalniy_ostatok DECIMAL(9, 2)
		, oplacheno DECIMAL(9, 2)
		, koplate DECIMAL(9, 2)
		, ean_2d NVARCHAR(2000)
		, pay_rs VARCHAR(30) -- rasscht
		, pay_ks VARCHAR(30) -- korscht
		, pay_bik VARCHAR(20) -- bik
		, pay_inn VARCHAR(20) -- inn
		, pay_kpp VARCHAR(20) -- kpp
		, pay_bank VARCHAR(100)  -- bank
		, pay_dest VARCHAR(100)  -- NameFirma
		, typels VARCHAR(20)
		, ediny_ls VARCHAR(20)  -- Единый лицевой счет для ГИС ЖКХ
		, id_jku_gis VARCHAR(20)
		, size_live DECIMAL(9, 2) DEFAULT 0 --Общая площадь жилых помещений м2
		, size_other DECIMAL(9, 2) DEFAULT 0 --Общая площадь нежилых помещений м2
		, size_oi_hv_gv_vo DECIMAL(9, 2) DEFAULT 0 --Площадь о.и. (Для ХВ,ГВ,ВО) м2
		, size_oi_el DECIMAL(9, 2) DEFAULT 0 --Площадь для о.и. (для эл.) м2
		, overdue_start DECIMAL(9, 2) DEFAULT 0 --Долг на начало месяца (на 01 число)
		, build_id INT DEFAULT NULL
		, occ VARCHAR(20) DEFAULT NULL
		, sup_id INT DEFAULT NULL
		, fin_id INT DEFAULT NULL
		, adres_build VARCHAR(100)
	)

	IF dbo.Fun_ExistsTable('#t_pd_sup') = 1
	BEGIN  
		INSERT INTO #t_main (period
						   , num_pd
						   , poluchatel
						   , rekvizity
						   , platelshik
						   , nomerls
						   , lc_numer
						   , pomeshenie
						   , uk
						   , uk_rekvizity
						   , ki_passport
						   , ki_buhgalteria
						   , ki_dispetcher
						   , ki_avaria
						   , ki_uchastor
						   , obshaya_ploshad
						   , zaregistrirovano
						   , prozhivaet
						   , floor
						   , nachisleno
						   , nachisleno_uslugi
						   , nachisleno_peni
						   , nachalniy_ostatok
						   , oplacheno
						   , koplate
						   , ean_2d
						   , pay_rs -- rasscht
						   , pay_ks -- korscht
						   , pay_bik -- bik
						   , pay_inn -- inn
						   , pay_kpp -- kpp
						   , pay_bank -- bank
						   , pay_dest -- NameFirma
						   , typels
						   , ediny_ls
						   , id_jku_gis
						   , overdue_start
						   , build_id
						   , occ
						   , sup_id
						   , fin_id
						   , adres_build)
		-- квитанция по поставщику
		SELECT REPLACE(CONVERT(VARCHAR(7), FinPeriod, 23),'-','.') AS [period]  --yyyy.MM
			 , num_pd
			 , CONCAT(NameFirma,', ', NameFirma_str2,', ИНН: ',inn) AS poluchatel
			 , CONCAT(bank,' БИК: ', bik,', р/сч: ', rasscht,', к/сч: ', korscht) AS rekvizity
			 , Initials AS platelshik
			 , occ_pd AS nomerls  
			 , occ_pd AS lc_numer  -- occ 21.10.2021
			 , adres AS pomeshenie
			 , tip_name AS uk  -- tip_name telefon_tip email_tip ИНН: inn_tip КПП: kpp_tip ОГРН: ogrn_tip			
			 , CONCAT(adres_tip,', ИНН: ',  inn_tip, CASE WHEN kpp_tip IS NOT NULL THEN ', КПП:' + kpp_tip ELSE '' END)
			   AS uk_rekvizity
			 , '' AS ki_passport
			 , '' AS ki_buhgalteria
			 , '' AS ki_dispetcher
			 , '' AS ki_avaria
			 , '' AS ki_uchastor
			 , TOTAL_SQ AS obshaya_ploshad
			 , total_people AS zaregistrirovano
			 , COALESCE(PersonStatus,'') AS prozhivaet
			 , NULL AS floor
			 , Paid + COALESCE(Penalty_period, 0) AS nachisleno
			 , Paid AS nachisleno_uslugi
			 , Penalty_period AS nachisleno_peni
			 , SALDO AS nachalniy_ostatok
			 , paymaccount AS oplacheno
			 , SumPaym AS koplate
			 , EAN_2D AS EAN_2D
			 , rasscht
			 , korscht
			 , bik
			 , inn
			 , kpp
			 , bank
			 , NameFirma
			 , dbo.Fun_GetTipOccGisToNameKvit(tip_occ_name, roomtype_id) AS tip_occ_name
			 , id_els_gis
			 , id_jku_gis
			 , SALDO + Penalty_old
			 , build_id
			 , occ
			 , sup_id
			 , fin_id
			 , adres_build
		FROM #t_pd_sup
	END
	ELSE
	BEGIN -- квитанция единому лицевому счету
		INSERT INTO #t_main (period
						   , num_pd
						   , poluchatel
						   , rekvizity
						   , platelshik
						   , nomerls
						   , lc_numer
						   , pomeshenie
						   , uk
						   , uk_rekvizity
						   , ki_passport
						   , ki_buhgalteria
						   , ki_dispetcher
						   , ki_avaria
						   , ki_uchastor
						   , obshaya_ploshad
						   , zaregistrirovano
						   , prozhivaet
						   , floor
						   , nachisleno
						   , nachisleno_uslugi
						   , nachisleno_peni
						   , nachalniy_ostatok
						   , oplacheno
						   , koplate
						   , ean_2d
						   , pay_rs -- rasscht
						   , pay_ks -- korscht
						   , pay_bik -- bik
						   , pay_inn -- inn
						   , pay_kpp -- kpp
						   , pay_bank -- bank
						   , pay_dest -- NameFirma
						   , typels
						   , ediny_ls
						   , id_jku_gis
						   , overdue_start
						   , size_live
						   , size_other
						   , size_oi_hv_gv_vo
						   , size_oi_el
						   , build_id
						   , occ
						   , sup_id
						   , fin_id
						   , adres_build)
		SELECT REPLACE(CONVERT(VARCHAR(7), FinPeriod, 23),'-','.') AS [period]  --yyyy.MM
			 , num_pd
			 , CONCAT(NameFirma,', ', NameFirma_str2,', ИНН: ',inn) AS poluchatel
			 , CONCAT(bank,' БИК: ', bik,', р/сч: ', rasscht,', к/сч: ', korscht) AS rekvizity
			 , Initials AS platelshik
			 , occ AS nomerls  -- occ_pd 21.10.2021
			 , occ AS lc_numer
			 , adres AS pomeshenie
			 , tip_name AS uk  -- tip_name telefon_tip email_tip ИНН: inn_tip КПП: kpp_tip ОГРН: ogrn_tip
			 , CONCAT(adres_tip,', ИНН: ',  inn_tip, CASE WHEN kpp_tip IS NOT NULL THEN ', КПП:' + kpp_tip ELSE '' END)
			   AS uk_rekvizity
			 , '' AS ki_passport
			 , '' AS ki_buhgalteria
			 , '' AS ki_dispetcher
			 , '' AS ki_avaria
			 , '' AS ki_uchastor
			 , TOTAL_SQ AS obshaya_ploshad
			 , total_people AS zaregistrirovano
			 , COALESCE(PersonStatus,'') AS prozhivaet
			 , NULL AS floor
			 , Paid + COALESCE(Penalty_period, 0) AS nachisleno
			 , Paid AS nachisleno_uslugi
			 , COALESCE(Penalty_period, 0) AS nachisleno_peni
			 , SALDO AS nachalniy_ostatok
			 , paymaccount AS oplacheno
			 , SumPaym AS koplate
			 , EAN_2D AS EAN_2D
			 , rasscht
			 , korscht
			 , bik
			 , inn
			 , kpp
			 , bank
			 , NameFirma
			 , dbo.Fun_GetTipOccGisToNameKvit(tip_occ_name, roomtype_id) AS tip_occ_name
			 , id_els_gis
			 , id_jku_gis
			 , DolgWithPeny
			 , COALESCE(build_total_area, 0)
			 , COALESCE(build_arenda_sq, 0)
			 , COALESCE(build_opu_sq, 0)
			 , COALESCE(build_opu_sq_elek, 0)
			 , build_id
			 , occ_pd
			 , COALESCE(@sup_id, 0)
			 , fin_id
			 , adres_build
		FROM #t_pd
	END

	DECLARE @period VARCHAR(15)
	SELECT TOP (1) @period = period
	FROM #t_main

	IF @format IS NULL
		SELECT *
		FROM #t_main

	IF @format = 'xml'
		SELECT (
				SELECT @period AS '@period'
					 , (
						   SELECT T.poluchatel AS '@poluchatel'
								, T.rekvizity AS '@rekvizity'
								, T.platelshik AS '@platelshik'
								, T.nomerls AS '@nomerls'
								, T.lc_numer AS '@lc_numer'
								, T.occ AS '@occ'
								, T.pomeshenie AS '@pomeshenie'
								, T.uk AS '@uk'
								, T.uk_rekvizity AS '@uk_rekvizity'
								, T.ki_passport AS '@ki_passport'
								, T.ki_buhgalteria AS '@ki_buhgalteria'
								, T.ki_dispetcher AS '@ki_dispetcher'
								, T.ki_avaria AS '@ki_avaria'
								, T.ki_uchastor AS '@ki_uchastor'
								, T.obshaya_ploshad AS '@obshaya_ploshad'
								, T.zaregistrirovano AS '@zaregistrirovano'
								, T.prozhivaet AS '@prozhivaet'
								, T.[floor] AS '@floor'
								, T.nachisleno AS '@nachisleno'
								, T.nachalniy_ostatok AS '@nachalniy_ostatok'
								, T.oplacheno AS '@oplacheno'
								, T.koplate AS '@koplate'
								, T.ean_2d AS ',@ean_2d'

								, T.ediny_ls AS ',@ediny_ls'
								, T.id_jku_gis AS ',@id_jku_gis'
								, T.overdue_start AS ',@overdue_start'
								, T.size_live AS ',@size_live'
								, T.size_other AS ',@size_other'
								, T.size_oi_hv_gv_vo AS ',@size_oi_hv_gv_vo'
								, T.size_oi_el AS ',@size_oi_el'

						   FROM #t_main AS T
						   FOR XML PATH ('item'), TYPE
					   )
				FOR XML PATH ('platezhki')
			) AS result

	IF @format = 'json'
		SELECT (
				SELECT *
				FROM #t_main
				FOR JSON PATH, ROOT ('platezhki')
			) AS result

END
go

