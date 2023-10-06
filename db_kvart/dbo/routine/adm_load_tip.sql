-- =============================================
-- Author:		Пузанов
-- Create date: 09.09.2020
-- Description:	Добавляем новый тип фонда из файла JSON
-- =============================================
CREATE     PROCEDURE [dbo].[adm_load_tip]
(
	@FileJson NVARCHAR(MAX)
	,@id_new SMALLINT = NULL OUTPUT
   ,@debug	  BIT = 0
)
AS
/*
-- Тест процедуры импорта типов фонда в формате json
DECLARE @RC int
DECLARE @FileJson nvarchar(max)
DECLARE @debug bit

SET @FileJson =  
N'
{
	"Types": 
		{
			"id": 28,
			"name": "ООО УК \"Ареола\"",
			"payms_value": true,
			"id_accounts": 37,
			"adres": "426068,г. Ижевск, Автозаводская, 58",
			"telefon": "тел. 61-21-02",
			"id_barcode": 0,
			"bank_account": 18,
			"laststr1": "",
			"penalty_calc_tip": false,
			"counter_metod": 2,
			"counter_votv_ras": true,
			"laststr2": "",
			"penalty_metod": 2,
			"occ_min": 680000000,
			"occ_max": 689999999,
			"occ_prefix_tip": "",
			"paym_order": "Задолженность;Пред_Начисления;Тек_Начисления;История_Начислений;Пени",
			"paym_order_metod": "пени1",
			"lastpaym": 25,
			"namesoderhousing": "Содержание жилья",
			"fin_id": 212,
			"PaymClosed": false,
			"start_date": "2019-09-01T00:00:00",
			"LastPaymDay": "2019-08-31T00:00:00",
			"state_id": "норм",
			"SaldoEditTrue": true,
			"email": "e-mail: areola@bk.ru",
			"paymaccount_minus": true,
			"saldo_rascidka": false,
			"counter_add_ras_norma": true,
			"synonym_name": "ООО УК \"Ареола\"",
			"inn": "1834047449",
			"people0_counter_norma": false,
			"PaymRaskidkaAlways": false,
			"comments": "",
			"tip_org_for_account": "Исполнитель коммунальных услуг",
			"counter_votv_norma": true,
			"ras_paym_fin_new": true,
			"kpp": "183401001",
			"is_PrintFioPrivat": false,
			"is_ValueBuildMinus": false,
			"is_2D_Code": true,
			"raschet_no": false,
			"raschet_agri": false,
			"is_counter_cur_tarif": true,
			"is_paying_saldo_no_paid": false,
			"is_not_allocate_economy": false,
			"telefon_pasp": "тел. 64-66-89,61-21-02",
			"barcode_charset": "2",
			"ras_no_counter_poverka": true,
			"only_pasport": false,
			"only_value": false,
			"is_counter_add_balance": false,
			"PenyBeginDolg": 0.0,
			"tip_occ": 1,
			"export_gis": false,
			"bank_file_out": "z_%FNAME%",
			"is_calc_subs12": false,
			"is_cash_serv": true,
			"peny_paym_blocked": false
		}
	
}
'
EXECUTE @RC = dbo.adm_load_tip 
   @FileJson
  ,@debug=1

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @DB_NAME VARCHAR(20)  = UPPER(DB_NAME())
		   ,@msg_out VARCHAR(200) = ''

	-- проверяем файл 
	IF @FileJson IS NULL
		OR ISJSON(@FileJson) = 0
	BEGIN
		SET @msg_out = 'Входной файл не в JSON формате'
		IF @debug = 1
			PRINT @msg_out
		RAISERROR (@msg_out, 16, 1)
	END

	DROP TABLE IF EXISTS #t_type

	SELECT
		ot.id
	   ,ot.name
	   ,ot.payms_value
	   ,ot.id_accounts
	   ,ot.adres
	   ,ot.fio
	   ,ot.telefon
	   ,ot.id_barcode
	   ,ot.bank_account
	   ,ot.laststr1
	   ,ot.penalty_calc_tip
	   ,ot.counter_metod
	   ,ot.counter_votv_ras
	   ,ot.laststr2
	   ,ot.penalty_metod
	   ,ot.occ_min
	   ,ot.occ_max
	   ,ot.occ_prefix_tip
	   ,ot.paym_order
	   ,ot.paym_order_metod
	   ,ot.lastpaym
	   ,ot.namesoderhousing
	   ,ot.Fin_id
	   ,ot.fincloseddata
	   ,ot.PaymClosedData
	   ,ot.PaymClosed
	   ,ot.start_date
	   ,ot.LastPaymDay
	   ,ot.state_id
	   ,ot.logo
	   ,ot.SaldoEditTrue
	   ,ot.email
	   ,ot.paymaccount_minus
	   ,ot.saldo_rascidka
	   ,ot.counter_add_ras_norma
	   ,ot.synonym_name
	   ,ot.inn
	   ,ot.people0_counter_norma
	   ,ot.PaymRaskidkaAlways
	   ,ot.ogrn
	   ,ot.comments
	   ,ot.tip_org_for_account
	   ,ot.tip_paym_blocked
	   ,ot.tip_details
	   ,ot.counter_votv_norma
	   ,ot.ras_paym_fin_new
	   ,ot.people_reg_blocked
	   ,ot.kpp
	   ,ot.is_PrintFioPrivat
	   ,ot.is_ValueBuildMinus
	   ,ot.is_2D_Code
	   ,ot.raschet_no
	   ,ot.raschet_agri
	   ,ot.is_counter_cur_tarif
	   ,ot.is_paying_saldo_no_paid
	   ,ot.is_not_allocate_economy
	   ,ot.telefon_pasp
	   ,ot.barcode_charset
	   ,ot.ras_no_counter_poverka
	   ,ot.only_pasport
	   ,ot.only_value
	   ,ot.account_rich
	   ,ot.is_counter_add_balance
	   ,ot.web_site
	   ,ot.adres_fact
	   ,ot.rezhim_work
	   ,ot.email_subscribe
	   ,ot.PenyBeginDolg
	   ,ot.tip_occ
	   ,ot.blocked_counter_add_ras_norma
	   ,ot.export_gis
	   ,ot.Bank_format_out
	   ,ot.bank_file_out
	   ,ot.watermark_text
	   ,ot.watermark_dolg_mes
	   ,ot.is_only_quarter
	   ,ot.is_calc_subs12
	   ,ot.tip_nalog
	   ,ot.is_cash_serv
	   ,ot.peny_paym_blocked
	INTO #t_type
	FROM OPENJSON(@FileJson, '$.Types')
	WITH (
	id SMALLINT '$.id',
	name VARCHAR(50) '$.name',
	payms_value BIT '$.payms_value',
	id_accounts INT '$.id_accounts',
	adres VARCHAR(100) '$.adres',
	fio VARCHAR(50) '$.fio',
	telefon VARCHAR(70) '$.telefon',
	id_barcode SMALLINT '$.id_barcode',
	bank_account INT '$.bank_account',
	laststr1 VARCHAR(70) '$.laststr1',
	penalty_calc_tip BIT '$.penalty_calc_tip',
	counter_metod SMALLINT '$.counter_metod',
	counter_votv_ras BIT '$.counter_votv_ras',
	laststr2 VARCHAR(1000) '$.laststr2',
	penalty_metod SMALLINT '$.penalty_metod',
	occ_min INT '$.occ_min',
	occ_max INT '$.occ_max',
	occ_prefix_tip VARCHAR(3) '$.occ_prefix_tip',
	paym_order NVARCHAR(100) '$.paym_order',
	paym_order_metod VARCHAR(10) '$.paym_order_metod',
	lastpaym SMALLINT '$.lastpaym',
	namesoderhousing VARCHAR(30) '$.namesoderhousing',
	Fin_id SMALLINT '$.fin_id',
	fincloseddata SMALLDATETIME '$.fincloseddata',
	PaymClosedData SMALLDATETIME '$.PaymClosedData',
	PaymClosed BIT '$.PaymClosed',
	start_date SMALLDATETIME '$.start_date',
	LastPaymDay SMALLDATETIME '$.LastPaymDay',
	state_id VARCHAR(10) '$.state_id',
	logo VARBINARY(MAX) '$.logo',
	SaldoEditTrue BIT '$.SaldoEditTrue',
	email VARCHAR(50) '$.email',
	paymaccount_minus BIT '$.paymaccount_minus',
	saldo_rascidka BIT '$.saldo_rascidka',
	counter_add_ras_norma BIT '$.counter_add_ras_norma',
	synonym_name VARCHAR(150) '$.synonym_name',
	inn VARCHAR(10) '$.inn',
	people0_counter_norma BIT '$.people0_counter_norma',
	PaymRaskidkaAlways BIT '$.PaymRaskidkaAlways',
	ogrn VARCHAR(15) '$.ogrn',
	comments VARCHAR(50) '$.comments',
	tip_org_for_account VARCHAR(50) '$.tip_org_for_account',
	tip_paym_blocked BIT '$.tip_paym_blocked',
	tip_details VARCHAR(250) '$.tip_details',
	counter_votv_norma BIT '$.counter_votv_norma',
	ras_paym_fin_new BIT '$.ras_paym_fin_new',
	people_reg_blocked BIT '$.people_reg_blocked',
	kpp VARCHAR(9) '$.kpp',
	is_PrintFioPrivat BIT '$.is_PrintFioPrivat',
	is_ValueBuildMinus BIT '$.is_ValueBuildMinus',
	is_2D_Code BIT '$.is_2D_Code',
	raschet_no BIT '$.raschet_no',
	raschet_agri BIT '$.raschet_agri',
	is_counter_cur_tarif BIT '$.is_counter_cur_tarif',
	is_paying_saldo_no_paid BIT '$.is_paying_saldo_no_paid',
	is_not_allocate_economy BIT '$.is_not_allocate_economy',
	telefon_pasp VARCHAR(50) '$.telefon_pasp',
	barcode_charset CHAR(1) '$.barcode_charset',
	ras_no_counter_poverka BIT '$.ras_no_counter_poverka',
	only_pasport BIT '$.only_pasport',
	only_value BIT '$.only_value',
	account_rich VARCHAR(MAX) '$.account_rich',
	is_counter_add_balance BIT '$.is_counter_add_balance',
	web_site VARCHAR(50) '$.web_site',
	adres_fact VARCHAR(100) '$.adres_fact',
	rezhim_work VARCHAR(50) '$.rezhim_work',
	email_subscribe VARCHAR(100) '$.email_subscribe',
	PenyBeginDolg DECIMAL(9, 2) N'$.PenyBeginDolg',
	tip_occ SMALLINT '$.tip_occ',
	blocked_counter_add_ras_norma BIT '$.blocked_counter_add_ras_norma',
	export_gis BIT '$.export_gis',
	Bank_format_out SMALLINT '$.bank_format_out',
	bank_file_out VARCHAR(50) '$.bank_file_out',
	watermark_text VARCHAR(50) '$.watermark_text',
	watermark_dolg_mes SMALLINT '$.watermark_dolg_mes',
	is_only_quarter BIT '$.is_only_quarter',
	is_calc_subs12 BIT '$.is_calc_subs12',
	tip_nalog VARCHAR(50) '$.tip_nalog',
	is_cash_serv BIT '$.is_cash_serv',
	peny_paym_blocked BIT '$.peny_paym_blocked'
	) AS ot


	SELECT
		*
	FROM #t_type tt

	-- Проверяем есть ли такой тип фонда в базе
	DECLARE @tip_name_new VARCHAR(50)
	SELECT
		@tip_name_new = tt.[name]
	FROM #t_type tt

	IF EXISTS (SELECT
				1
			FROM Occupation_Types ot
			WHERE ot.name = @tip_name_new)
	BEGIN
		RAISERROR ('Тип фонда <%s> уже есть в базе!', 10, 1, @tip_name_new)
		RETURN -1
	END

	-- Тогда добавляем 
	BEGIN TRAN

	SELECT @id_new=COALESCE(MAX(id),0)+1 FROM Occupation_Types ot

	INSERT INTO Occupation_Types
	(id
	,name
	,payms_value
	,id_accounts
	,adres
	,fio
	,telefon
	,id_barcode
	,bank_account
	,laststr1
	,penalty_calc_tip
	,counter_metod
	,counter_votv_ras
	,laststr2
	,penalty_metod
	,occ_min
	,occ_max
	,occ_prefix_tip
	,paym_order
	,paym_order_metod
	,lastpaym
	,namesoderhousing
	,Fin_id
	,fincloseddata
	,PaymClosedData
	,PaymClosed
	,start_date
	,LastPaymDay
	,state_id
	,logo
	,SaldoEditTrue
	,email
	,paymaccount_minus
	,saldo_rascidka
	,counter_add_ras_norma
	,synonym_name
	,inn
	,people0_counter_norma
	,PaymRaskidkaAlways
	,ogrn
	,comments
	,tip_org_for_account
	,tip_paym_blocked
	,tip_details
	,counter_votv_norma
	,ras_paym_fin_new
	,people_reg_blocked
	,kpp
	,is_PrintFioPrivat
	,is_ValueBuildMinus
	,is_2D_Code
	,raschet_no
	,raschet_agri
	,is_counter_cur_tarif
	,is_paying_saldo_no_paid
	,is_not_allocate_economy
	,telefon_pasp
	,barcode_charset
	,ras_no_counter_poverka
	,only_pasport
	,only_value
	,account_rich
	,is_counter_add_balance
	,web_site
	,adres_fact
	,rezhim_work
	,email_subscribe
	,PenyBeginDolg
	,tip_occ
	,blocked_counter_add_ras_norma
	,export_gis
	,Bank_format_out
	,bank_file_out
	,watermark_text
	,watermark_dolg_mes
	,is_only_quarter
	,is_calc_subs12
	,tip_nalog
	,is_cash_serv
	,peny_paym_blocked)
		SELECT
			@id_new
			,name
		   ,payms_value
		   ,id_accounts
		   ,adres
		   ,fio
		   ,telefon
		   ,id_barcode
		   ,bank_account
		   ,laststr1
		   ,penalty_calc_tip
		   ,counter_metod
		   ,counter_votv_ras
		   ,laststr2
		   ,penalty_metod
		   ,occ_min
		   ,occ_max
		   ,occ_prefix_tip
		   ,paym_order
		   ,paym_order_metod
		   ,lastpaym
		   ,namesoderhousing
		   ,Fin_id
		   ,fincloseddata
		   ,PaymClosedData
		   ,PaymClosed
		   ,start_date
		   ,LastPaymDay
		   ,state_id
		   ,logo
		   ,SaldoEditTrue
		   ,email
		   ,paymaccount_minus
		   ,saldo_rascidka
		   ,counter_add_ras_norma
		   ,synonym_name
		   ,inn
		   ,people0_counter_norma
		   ,PaymRaskidkaAlways
		   ,ogrn
		   ,comments
		   ,tip_org_for_account
		   ,tip_paym_blocked
		   ,tip_details
		   ,counter_votv_norma
		   ,ras_paym_fin_new
		   ,people_reg_blocked
		   ,kpp
		   ,is_PrintFioPrivat
		   ,is_ValueBuildMinus
		   ,is_2D_Code
		   ,raschet_no
		   ,raschet_agri
		   ,is_counter_cur_tarif
		   ,is_paying_saldo_no_paid
		   ,is_not_allocate_economy
		   ,telefon_pasp
		   ,barcode_charset
		   ,ras_no_counter_poverka
		   ,only_pasport
		   ,only_value
		   ,account_rich
		   ,is_counter_add_balance
		   ,web_site
		   ,adres_fact
		   ,rezhim_work
		   ,email_subscribe
		   ,PenyBeginDolg
		   ,tip_occ
		   ,blocked_counter_add_ras_norma
		   ,export_gis
		   ,Bank_format_out
		   ,bank_file_out
		   ,watermark_text
		   ,watermark_dolg_mes
		   ,is_only_quarter
		   ,is_calc_subs12
		   ,tip_nalog
		   ,is_cash_serv
		   ,peny_paym_blocked
		FROM #t_type tt

	COMMIT TRAN

	SELECT @id_new

END
go

