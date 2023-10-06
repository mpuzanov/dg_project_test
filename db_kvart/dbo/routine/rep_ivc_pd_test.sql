-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE           PROCEDURE [dbo].[rep_ivc_pd_test]
(
	@fin_id		SMALLINT
   ,@tip_id		SMALLINT
   ,@build_id	INT = NULL
   ,@sup_id		INT = NULL
   ,@occ		INT = NULL
   ,@format		VARCHAR(10) = NULL
)
AS
/*
rep_ivc_pd @fin_id=178, @tip_id=28,@build_id=1031, @sup_id=323, @occ=680003552, @format='xml'	
rep_ivc_pd @fin_id=178, @tip_id=28,@build_id=1031, @sup_id=323
rep_ivc_pd @fin_id=222, @tip_id=169,@build_id=5871, @format='xml'
rep_ivc_pd @fin_id=222, @tip_id=169,@build_id=null, @sup_id=null, @occ=330001, @format='xml'	
*/
BEGIN
	SET NOCOUNT ON;

	IF @build_id IS NULL
		AND @sup_id IS NULL
		AND @tip_id is NULL
		SELECT
			@build_id = 0
		   ,@sup_id = 0
		   ,@fin_id = 0
		   ,@tip_id = 0

	-- 1. Создать основную таблицу
	IF COALESCE(@sup_id, 0) = 0
	BEGIN
		DROP TABLE IF EXISTS #t_pd
		CREATE TABLE #t_pd
		(
		sort_no INT
	   ,fin_id  SMALLINT
	   ,occ		INT
	   ,SumPaym DECIMAL(9,2)
	   ,SumPaymNoPeny  DECIMAL(9,2)
	   ,SumPaymDebt    DECIMAL(9,2)
	   ,Paid	DECIMAL(9,2)
	   ,occ_pd  INT
	   ,num_pd  VARCHAR(16) COLLATE database_default
	   ,id_els_gis  VARCHAR(10) COLLATE database_default
	   ,id_jku_gis  VARCHAR(13) COLLATE database_default
	   ,id_jku_pd_gis	VARCHAR(20) COLLATE database_default
	   ,Penalty_itog	DECIMAL(9,2)
	   ,jeu			SMALLINT
	   ,jeu_name	VARCHAR(30) COLLATE database_default
	   ,Initials	VARCHAR(120) COLLATE database_default
	   ,adres		VARCHAR(100) COLLATE database_default
	   ,Lgota		VARCHAR(20) COLLATE database_default
	   ,total_people	SMALLINT
	   ,TOTAL_SQ		DECIMAL(9,2)
	   ,LIVING_SQ		DECIMAL(9,2)
	   ,FinPeriod		SMALLDATETIME
	   ,StrFinPeriod    VARCHAR(30) COLLATE database_default
	   ,SALDO			DECIMAL(9,2)
	   ,paymaccount		DECIMAL(9,2)
	   ,paymaccount_peny  DECIMAL(9,2)
	   ,Debt			DECIMAL(9,2)
	   ,LastDayPaym		SMALLDATETIME
	   ,LastDayPaym2	SMALLDATETIME
	   ,PersonStatus	VARCHAR(50) COLLATE database_default
	   ,Month3			VARCHAR(20) COLLATE database_default
	   ,penalty_value	DECIMAL(9,2)
	   ,StrSubsidia1	VARCHAR(100) COLLATE database_default
	   ,StrSubsidia2	VARCHAR(100) COLLATE database_default
	   ,StrSubsidia3	VARCHAR(100) COLLATE database_default
	   ,Div_id			SMALLINT
	   ,KolMesDolg		DECIMAL(5,1)
	   ,DateCreate		SMALLDATETIME
	   ,NameFirma		VARCHAR(100) COLLATE database_default
	   ,NameFirma_str2	VARCHAR(100) COLLATE database_default
	   ,[EAN]			VARCHAR(50)	COLLATE database_default	 
	   ,[EAN_2D]		NVARCHAR(2000) COLLATE database_default
	   ,[EAN_2D_NoPeny] VARCHAR(50) COLLATE database_default
	   ,[EAN_2D_Peny]	VARCHAR(50) COLLATE database_default
	   ,[EAN_SBER]		VARCHAR(50) COLLATE database_default
	   ,bank			VARCHAR(100) COLLATE database_default
	   ,rasscht			VARCHAR(30) COLLATE database_default
	   ,korscht			VARCHAR(30) COLLATE database_default
	   ,bik				VARCHAR(20) COLLATE database_default
	   ,inn				VARCHAR(20) COLLATE database_default
	   ,kpp				VARCHAR(20) COLLATE database_default
	   ,cbc				VARCHAR(20) COLLATE database_default
	   ,oktmo			VARCHAR(20) COLLATE database_default
	   ,[INDEX]			INT
	   ,index_postal	INT
	   ,tip_id			SMALLINT
	   ,[tip_name]		VARCHAR(150) COLLATE database_default
	   ,adres_tip		VARCHAR(100) COLLATE database_default
	   ,telefon_tip		VARCHAR(100) COLLATE database_default
	   ,inn_tip			VARCHAR(20) COLLATE database_default
	   ,kpp_tip			VARCHAR(20) COLLATE database_default
	   ,ogrn_tip		VARCHAR(20) COLLATE database_default
	   ,email_tip		VARCHAR(50) COLLATE database_default
	   ,details_tip		VARCHAR(250) COLLATE database_default
	   ,StrAdd			VARCHAR(800) COLLATE database_default
	   ,LastStr1		VARCHAR(100) COLLATE database_default
	   ,LastStr2		VARCHAR(1000) COLLATE database_default
	   ,logo			VARBINARY(MAX)
	   ,adres_sec		VARCHAR(100) COLLATE database_default
	   ,fio_sec			VARCHAR(50) COLLATE database_default
	   ,telefon_sec		VARCHAR(100) COLLATE database_default
	   ,tip_org_for_account VARCHAR(100) COLLATE database_default
	   ,bldn_id				INT
	   ,LastDayPaymAccount  VARCHAR(10) COLLATE database_default
	   ,build_norma_gkal	DECIMAL(9,6)
	   ,build_opu_sq		DECIMAL(10, 4)
	   ,build_opu_sq_elek	DECIMAL(10, 4)
	   ,build_total_sq		DECIMAL(10, 4)
	   ,build_arenda_sq	DECIMAL(10, 4)
	   ,build_comments  VARCHAR(4000) COLLATE database_default
	   ,adres_build		VARCHAR(100) COLLATE database_default
	   ,account_rich	VARCHAR(MAX) COLLATE database_default
	   ,nom_kvr			VARCHAR(20) COLLATE database_default
	   ,StrLast			VARCHAR(1000) COLLATE database_default
	   ,DatePrint		SMALLDATETIME
	   ,kol_jeu			SMALLINT
	   ,row_num_jeu		SMALLINT
	   ,kol_occ_jeu		SMALLINT
	   ,kol_occ_build	INT
	   ,[start_date]	SMALLDATETIME
	   ,tip_occ			SMALLINT
	   ,marketing_str   VARCHAR(1000) COLLATE database_default
	   ,watermark		BIT
	   ,watermark_text	VARCHAR(50) COLLATE database_default
	   ,Square_str		VARCHAR(1000) COLLATE database_default
	   ,PROPTYPE_ID		VARCHAR(10) COLLATE database_default
	   ,Penalty_period	DECIMAL(9,2)
	   ,Penalty_old_new	DECIMAL(9,2)
	   ,comments_print	VARCHAR(50) COLLATE database_default
	)

	IF @occ is not NULL
		SET @build_id = NULL

		INSERT INTO #t_pd
		EXEC k_intPrint_occ @fin_id1 = @fin_id
						   ,@tip_id = @tip_id
						   ,@build = @build_id
						   ,@occ1 =	@occ
							--,@debug=1

	END
	ELSE
	BEGIN
		DROP TABLE IF EXISTS #t_pd_sup
		CREATE TABLE #t_pd_sup
		(
			sort_no		INT
		   ,fin_id		SMALLINT
		   ,occ			INT
		   ,sup_id		INT
		   ,occ_sup		INT
		   ,occ_pd		INT
		   ,num_pd		VARCHAR(20) COLLATE database_default
		   ,id_els_gis  VARCHAR(20) COLLATE database_default
		   ,id_jku_gis	VARCHAR(20) COLLATE database_default
		   ,id_jku_pd_gis	VARCHAR(20) COLLATE database_default
		   ,saldo			DECIMAL(9,2)
		   ,value			DECIMAL(9,2)
		   ,added			DECIMAL(9,2)
		   ,paid			DECIMAL(9,2)
		   ,PaymAccount		DECIMAL(9,2)
		   ,PaymAccount_peny	DECIMAL(9,2)
		   ,debt				DECIMAL(9,2)
		   ,Penalty_value		DECIMAL(9,2)
		   ,Penalty_old_new		DECIMAL(9,2)
		   ,Penalty_old			DECIMAL(9,2)
		   ,Penalty_itog		DECIMAL(9,2)
		   ,Whole_payment		DECIMAL(9,2)
		   ,SumPaym				DECIMAL(9,2)
		   ,SumPaymNoPeny		DECIMAL(9,2)
		   ,SumPaymDebt			DECIMAL(9,2)
		   ,KolMesDolg			DECIMAL(5,1)
		   ,Penalty_old_edit	SMALLINT
		   ,Paid_old			DECIMAL(9,2)
		   ,dog_int				INT
		   ,cessia_dolg_mes_old	SMALLINT
		   ,cessia_dolg_mes_new	SMALLINT
		   ,NameFirma			VARCHAR(100) COLLATE database_default
		   ,NameFirma_str2		VARCHAR(100) COLLATE database_default
		   ,[EAN]				VARCHAR(25) COLLATE database_default
		   ,[EAN_2D]			NVARCHAR(2000) COLLATE database_default
		   ,BANK				VARCHAR(100) COLLATE database_default
		   ,rasscht				VARCHAR(30) COLLATE database_default
		   ,korscht				VARCHAR(30) COLLATE database_default
		   ,bik					VARCHAR(20) COLLATE database_default
		   ,inn					VARCHAR(20) COLLATE database_default
		   ,kpp					VARCHAR(20) COLLATE database_default
		   ,cbc					VARCHAR(20) COLLATE database_default
		   ,oktmo				VARCHAR(20) COLLATE database_default
		   ,[index]				INT
		   ,index_postal		INT
		   ,tip_id				SMALLINT
		   ,[tip_name]			VARCHAR(150) COLLATE database_default
		   ,StrAdd				VARCHAR(800) COLLATE database_default
		   ,adres				VARCHAR(100) COLLATE database_default
		   ,adres_build			VARCHAR(100) COLLATE database_default
		   ,nom_kvr				VARCHAR(20) COLLATE database_default
		   ,Initials			VARCHAR(120) COLLATE database_default
		   ,FinPeriod			SMALLDATETIME
		   ,StrFinPeriod	    VARCHAR(15) COLLATE database_default
		   ,total_sq			DECIMAL(10, 4)
		   ,living_sq			DECIMAL(10, 4)
		   ,total_people		SMALLINT
		   ,PersonStatus		VARCHAR(80) COLLATE database_default
		   ,sup_name			VARCHAR(50) COLLATE database_default
		   ,adres_tip			VARCHAR(100) COLLATE database_default
		   ,telefon_tip			VARCHAR(70) COLLATE database_default
		   ,inn_tip				VARCHAR(15) COLLATE database_default
		   ,kpp_tip				VARCHAR(15) COLLATE database_default
		   ,ogrn_tip			VARCHAR(15) COLLATE database_default
		   ,email_tip			VARCHAR(50) COLLATE database_default
		   ,laststr1			VARCHAR(70) COLLATE database_default
		   ,laststr2			VARCHAR(1000) COLLATE database_default
		   ,logo				VARBINARY(MAX)
		   ,tip_org_for_account VARCHAR(50) COLLATE database_default
		   ,strPaymDiscount		VARCHAR(100) COLLATE database_default
		   ,LastDayPaym			SMALLDATETIME
		   ,LastDayPaym2		SMALLDATETIME
		   ,LastDayPaymAccount	VARCHAR(10) COLLATE database_default
		   ,StrSubsidia3		VARCHAR(100) COLLATE database_default
		   ,visible				SMALLINT
		   ,str_account1		VARCHAR(100) COLLATE database_default
		   ,DatePrint			SMALLDATETIME
		   ,LastStrAccountSup	VARCHAR(15) COLLATE database_default
		   ,sup_adres			VARCHAR(100) COLLATE database_default
		   ,sup_inn				VARCHAR(15) COLLATE database_default
		   ,sup_kpp				VARCHAR(15) COLLATE database_default
		   ,sup_ogrn			VARCHAR(15) COLLATE database_default
		   ,sup_telefon			VARCHAR(70) COLLATE database_default
		   ,sup_email			VARCHAR(50) COLLATE database_default
		   ,sup_web_site		VARCHAR(50) COLLATE database_default
		   ,sup_rezhim_work		VARCHAR(50) COLLATE database_default
		   ,[start_date]		SMALLDATETIME
		   ,tip_occ				SMALLINT
		   ,account_rich		VARCHAR(4000) COLLATE database_default
		   ,Penalty_period		DECIMAL(9,2)
		   ,comments_print		VARCHAR(50) COLLATE database_default
		)

		INSERT INTO #t_pd_sup
			EXEC k_intPrint_occ_sup @fin_id1 = @fin_id
								   ,@tip_id = @tip_id
								   ,@build = @build_id
								   ,@sup_id = @sup_id
								   ,@occ1=	@occ
									--,@debug=1
	END
	DROP TABLE IF EXISTS #t_main
	CREATE TABLE #t_main (
		[period] VARCHAR(15) COLLATE database_default
		,poluchatel NVARCHAR(1000) COLLATE database_default
		,rekvizity VARCHAR(1000) COLLATE database_default
		,platelshik VARCHAR(200) COLLATE database_default
		,nomerls VARCHAR(20) COLLATE database_default
		,pomeshenie VARCHAR(100) COLLATE database_default
		,uk  VARCHAR(1000) COLLATE database_default
		,uk_rekvizity VARCHAR(1000) COLLATE database_default
		,ki_passport	VARCHAR(1000) COLLATE database_default
		,ki_buhgalteria	VARCHAR(1000) COLLATE database_default
		,ki_dispetcher	VARCHAR(1000) COLLATE database_default
		,ki_avaria	VARCHAR(1000) COLLATE database_default
		,ki_uchastor	VARCHAR(1000) COLLATE database_default
		,obshaya_ploshad DECIMAL(9,2)
		,zaregistrirovano INT 
		,prozhivaet		VARCHAR(1000) COLLATE database_default
		,floor	SMALLINT
		,nachisleno	DECIMAL(9,2)
		,nachalniy_ostatok	DECIMAL(9,2)
		,oplacheno	DECIMAL(9,2)
		,koplate	DECIMAL(9,2)
	)

	IF dbo.Fun_ExistsTable('#t_pd_sup')=1
		INSERT into #t_main
		SELECT 
			REPLACE(CONVERT(VARCHAR(7), FinPeriod, 23),'-','.') AS [period] --yyyy.MM
			,NameFirma as poluchatel
			,NameFirma_str2 as rekvizity -- NameFirma_str2" ИНН: inn
			,Initials as platelshik
			,occ_pd as nomerls
			,Adres as pomeshenie
			,tip_name as uk  -- tip_name telefon_tip email_tip ИНН: inn_tip КПП: kpp_tip ОГРН: ogrn_tip
			,CONCAT(adres_tip,' ИНН: ',inn_tip,' КПП: ', kpp_tip) as uk_rekvizity
			,'' as ki_passport
			,'' as ki_buhgalteria
			,'' as ki_dispetcher
			,'' as ki_avaria
			,'' as ki_uchastor
			,total_sq as obshaya_ploshad
			,total_people as zaregistrirovano
			,PersonStatus as prozhivaet
			,Null as floor
			,paid as nachisleno
			,saldo as nachalniy_ostatok
			,PaymAccount as oplacheno
			,SumPaym as koplate
		FROM #t_pd_sup
	ELSE
		INSERT into #t_main
		SELECT 
			REPLACE(CONVERT(VARCHAR(7), FinPeriod, 23),'-','.') as FinPeriod --yyyy.MM
			,NameFirma as poluchatel
			,NameFirma_str2 as rekvizity -- NameFirma_str2" ИНН: inn
			,Initials as platelshik
			,occ_pd as nomerls
			,Adres as pomeshenie
			,tip_name as uk  -- tip_name telefon_tip email_tip ИНН: inn_tip КПП: kpp_tip ОГРН: ogrn_tip
			,CONCAT(adres_tip,', ИНН: ',inn_tip,' КПП: ',kpp_tip) as uk_rekvizity
			,'' as ki_passport
			,'' as ki_buhgalteria
			,'' as ki_dispetcher
			,'' as ki_avaria
			,'' as ki_uchastor
			,total_sq as obshaya_ploshad
			,total_people as zaregistrirovano
			,PersonStatus as prozhivaet
			,Null as floor
			,paid as nachisleno
			,saldo as nachalniy_ostatok
			,PaymAccount as oplacheno
			,SumPaym as koplate
		FROM #t_pd

/*
poluchatel="ООО ИВЦ-Ижевск, УР, г.Ижевск, ул.Кирова, д.108А, каб.4, ИНН 1841008627, КПП 183101001" 
rekvizity="ОТДЕЛЕНИЕ СБЕРБАНКА РОССИИ №8618 БИК:049401601, р/с: 40702810968000010038, к/с: 30101810400000000601 при оплате через ФГПУ ПОЧТА РОССИИ - р/с 40821810968000093538, УДМУРТСКОЕ ОТДЕЛЕНИЕ №8618 ПАО СБЕРБАНК Г.ИЖЕВСК, БИК 049401601, к/с 30101810400000000601" 
platelshik="Ардашева Нина Кузьмовна" 
nomerls="330248548" 
pomeshenie="40 лет Победы, 50 кв.1" 
uk="ООО 'Аргон 19', 426072, УР, Ижевск, Молодежная, дом № 6, ИНН 1832096465" 
uk_rekvizity="ОТДЕЛЕНИЕ СБЕРБАНКА РОССИИ №8618 БИК:049401601, р/с: 40702810968000099680, к/с: 30101810400000000601" 
ki_passport="Пн,чт 8.00-12.00, вт 8.00-19.00,  ср 8.00-17.00) тел.31-31-86 (доб. 210), обед с 12.00 до 13.00. Пятница - неприемный день" 
ki_buhgalteria="пн,ср 8.00-17.00, вт,чт 8.00-18.00) тел.31-31-86 (доб. 210), обед с 12.00 до 13.00. Пятница - неприемный день" 
ki_dispetcher="тел.31-31-86 (доб. 221, 222) (с 8.00 до 17.00)" 
ki_avaria="тел.723-901 (с 17.00 до 08.00 в рабочие дни, круглосуточно в выходные и праздничные дни)." 
ki_uchastor="" 
obshaya_ploshad="36" 
zaregistrirovano="0" 
prozhivaet="0" 
floor="1" 
nachisleno="1569.29" 
nachalniy_ostatok="3350.03" 
oplacheno="3350.03" 
koplate="1569.29">
*/

	-- 2. Создать таблицу с услугами
	-- rep_gis_pd_serv
			CREATE TABLE #pdserv
		(
			num_pd				 VARCHAR(20) COLLATE database_default
		   ,build_id			 INT
		   ,occ					 INT
		   ,short_name			 VARCHAR(30) COLLATE database_default
		   ,short_id			 VARCHAR(6) COLLATE database_default
		   ,service_id			 VARCHAR(10) COLLATE database_default
		   ,tarif				 DECIMAL(10, 4)		DEFAULT 0
		   ,kol					 DECIMAL(12, 6) DEFAULT 0
		   ,kol_dom				 DECIMAL(12, 6) DEFAULT 0
		   ,koef				 DECIMAL(10, 4)		DEFAULT NULL
		   ,saldo				 DECIMAL(9, 2)  DEFAULT 0 NOT NULL
		   ,value				 DECIMAL(9, 2)  DEFAULT 0 NOT NULL
		   ,value_dom			 DECIMAL(9, 2)  DEFAULT 0 NOT NULL
		   ,value_itog			 DECIMAL(9, 2)  DEFAULT 0 NOT NULL
		   ,added1				 DECIMAL(9, 2)  DEFAULT 0 NOT NULL
		   ,added12				 DECIMAL(9, 2)  DEFAULT 0 NOT NULL
		   ,added				 DECIMAL(9, 2)  DEFAULT 0 NOT NULL
		   ,paid				 DECIMAL(9, 2)  DEFAULT 0 NOT NULL
		   ,paid_dom			 DECIMAL(9, 2)  DEFAULT 0 NOT NULL
		   ,paid_koef_up		 DECIMAL(9, 2)  DEFAULT 0 NOT NULL
		   ,paid_itog			 DECIMAL(9, 2)  DEFAULT 0 NOT NULL
		   ,debt				 DECIMAL(9, 2)  DEFAULT 0 NOT NULL
		   ,sort_no				 INT			DEFAULT 0
		   ,mode_id				 INT			DEFAULT NULL
		   ,unit_id				 VARCHAR(10)	COLLATE database_default DEFAULT NULL
		   ,is_build			 BIT			DEFAULT 0
		   ,service_id_from		 VARCHAR(10)	COLLATE database_default DEFAULT NULL
		   ,sup_id				 INT			DEFAULT 0
		   ,account_one			 BIT			DEFAULT 0
		   ,is_sum				 BIT			DEFAULT 1
		   ,subsid_only			 BIT			DEFAULT 0
		   ,tip_id				 SMALLINT		DEFAULT 0
		   ,VSODER				 BIT			DEFAULT 0
		   ,VYDEL				 BIT			DEFAULT 0
		   ,OWNER_ID			 INT			DEFAULT 0
		   ,[service_name]		 VARCHAR(30)	COLLATE database_default DEFAULT ''
		   ,OWNER_ID_BUILD		 INT			DEFAULT 0
		   ,metod				 SMALLINT		DEFAULT 0
		   ,service_name_gis	 NVARCHAR(100)  COLLATE database_default DEFAULT NULL
		   ,service_type		 SMALLINT		DEFAULT 1
		   ,is_counter			 SMALLINT		DEFAULT 0
		   ,reason_added		 VARCHAR(800)   COLLATE database_default DEFAULT NULL
		   ,is_koef_up			 BIT			DEFAULT 0
		   ,no_export_volume_gis BIT			DEFAULT 0
		   ,koef_up				 DECIMAL(9, 4)  DEFAULT NULL
		   ,total_sq			 DECIMAL(9, 2)  DEFAULT 0
		)

		INSERT INTO #pdserv
			EXEC k_intPrintDetail_occ_build @fin_id1 = @fin_id -- Фин.период
										   ,@build_id = @build_id-- дом
										   ,@occ1 = @occ -- лицевой
										   ,@tip_id = @tip_id --жилой фонд
										   ,@sup_id = @sup_id
										   ,@debug = 0 

	-- nachislenie ROOT
	CREATE TABLE #t_detail (
		nomerls VARCHAR(20) COLLATE database_default
		,vid VARCHAR(50) COLLATE database_default
		,tarif DECIMAL(9,2)
		,ed VARCHAR(20) COLLATE database_default
		,normativ DECIMAL(9,2)
		,potrebleno DECIMAL(9,2)
		,nachisleno DECIMAL(9,2)
		,pereraschet DECIMAL(9,2)
		,koplate DECIMAL(9,2)
	)
	INSERT into #t_detail
	SELECT 
		num_pd as nomerls
		,short_name as vid
		,tarif as tarif
		,short_id as ed
		,0 as normativ
		,kol as potrebleno
		,value as nachisleno
		,added as pereraschet
		,paid_itog as koplate
	FROM #pdserv
	
	--SELECT 
	--	nomerls as '@nomerls'
	--	,vid as '@vid'
	--	,tarif as '@tarif'
	--	,ed as '@ed'
	--	,0 as '@normativ'
	--	,potrebleno as '@potrebleno'
	--	,nachisleno as '@nachisleno'
	--	,pereraschet as '@pereraschet'
	--	,koplate as '@koplate'
	--FROM #t_detail as det FOR XML PATH('nachislenie')

	-- 3. Объеденить 2 таблицы для вывода результатов в XML && JSON
	-- 
	DECLARE @period VARCHAR(15)
	SELECT top 1 @period=period FROM #t_main

	if @format is null
		select * from #t_main

	--	select 'Person' as "@tableName",
	 --(select * from deleted for xml path('DataItem'), type)
	 --for xml path('Root')

	if @format='xml'
		select (
			SELECT @period as '@period',
				(SELECT 
					t.poluchatel as '@poluchatel'
					,t.rekvizity as '@rekvizity'
					,t.platelshik as '@platelshik'
					,t.nomerls as '@nomerls'
					,t.pomeshenie as '@pomeshenie'
					,t.uk as '@uk'
					,t.uk_rekvizity as '@uk_rekvizity'
					,t.ki_passport as '@ki_passport'
					,t.ki_buhgalteria as '@ki_buhgalteria'
					,t.ki_dispetcher as '@ki_dispetcher'
					,t.ki_avaria as '@ki_avaria'
					,t.ki_uchastor as '@ki_uchastor'
					,t.obshaya_ploshad as '@obshaya_ploshad'
					,t.zaregistrirovano as '@zaregistrirovano'
					,t.prozhivaet as '@prozhivaet'
					,t.[floor] as '@floor'
					,t.nachisleno as '@nachisleno'
					,t.nachalniy_ostatok as '@nachalniy_ostatok'
					,t.oplacheno as '@oplacheno'
					,t.koplate as '@koplate'							
					,(SELECT 
						nomerls as '@nomerls'
						,vid as '@vid'
						,tarif as '@tarif'
						,ed as '@ed'
						,0 as '@normativ'
						,potrebleno as '@potrebleno'
						,nachisleno as '@nachisleno'
						,pereraschet as '@pereraschet'
						,koplate as '@koplate'
					FROM #t_detail as det FOR XML PATH('nachislenie'), TYPE)

				FROM #t_main AS T FOR XML PATH('item'), TYPE) 			
			FOR XML PATH('platezhki')
		) as result

	if @format='json'
		select (select * from #t_main FOR JSON PATH, ROOT('platezhki')) as result

END
go

