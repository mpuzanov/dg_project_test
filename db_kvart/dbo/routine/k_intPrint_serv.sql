-- Batch submitted through debugger: SQLQuery1.sql|5|0|C:\Documents and Settings\manager\Local Settings\Temp\~vs4A.sql

CREATE   PROCEDURE [dbo].[k_intPrint_serv]
(
	@fin_id1		SMALLINT
	,@service_id1	VARCHAR(10) -- код услуги
	,@occ1			INT			= NULL
	,@build			INT			= NULL -- Код дома
	,@jeu			SMALLINT	= NULL -- Участок
	,@tip_id		SMALLINT	= NULL
	,@source_id1	INT			= NULL-- код поставщика
)
AS
	--
	--  Показываемчасть информации по счету-квитанции
	--
	/*
	дата изменения: 01.04.2010
	автор изменения: Пузанов
	
	*/
	SET NOCOUNT ON


	IF @occ1 = 0
		SET @occ1 = NULL
	IF @build = 0
		SET @build = NULL
	IF @jeu = 0
		SET @jeu = NULL
	IF @source_id1 = 0
		SET @source_id1 = NULL
	IF @tip_id = 0
		SET @tip_id = NULL
	IF @service_id1 = ''
		SET @service_id1 = NULL


	DECLARE @t myTypeTableOcc

	DECLARE @t_schet TABLE
		(
			occ				INT			PRIMARY KEY
			,NameFirma		VARCHAR(50)	DEFAULT NULL
			,bank			VARCHAR(50)	DEFAULT NULL
			,rasscht		VARCHAR(30)	DEFAULT NULL
			,korscht		VARCHAR(30)	DEFAULT NULL
			,bik			VARCHAR(20)	DEFAULT NULL
			,inn			VARCHAR(20)	DEFAULT NULL
			,tip_id			SMALLINT	DEFAULT 1
			,id_barcode		SMALLINT	DEFAULT 0
			,licbank		BIGINT		DEFAULT 0
			,barcode_type	SMALLINT	DEFAULT 0
		)


	INSERT INTO @t
	(occ)
		SELECT
			o.occ
		FROM dbo.OCCUPATIONS AS o
		JOIN dbo.CONSMODES_LIST AS cl 
			ON o.occ = cl.occ
		JOIN dbo.FLATS AS f
			ON o.flat_id = f.id
		JOIN dbo.BUILDINGS AS b 
			ON f.bldn_id = b.id
		WHERE o.occ = coalesce(@occ1, o.occ)
		AND cl.source_id = coalesce(@source_id1, cl.source_id)
		AND cl.service_id = @service_id1
		AND o.status_id <> 'закр'
		AND o.tip_id = coalesce(@tip_id, o.tip_id)
		AND f.bldn_id = coalesce(@build, f.bldn_id)
		AND b.sector_id = coalesce(@jeu, b.sector_id)


	IF @service_id1 IS NULL
		RETURN


	UPDATE dbo.CONSMODES_LIST
	SET occ_serv = dbo.Fun_GetService_Occ(occ, @service_id1)
	WHERE occ = @occ1
	AND service_id = @service_id1
	AND occ_serv < 9999999

	DECLARE	@Initials		VARCHAR(30)
			,@adres			VARCHAR(50)
			,@SumPaym		DECIMAL(9, 2)
			,@Str1			VARCHAR(60)
			,@PROPTYPE_ID	VARCHAR(10)

	DECLARE	@start_date		SMALLDATETIME
			,@end_date		SMALLDATETIME
			,@StrFinPeriod	VARCHAR(20)
			,@DateCurrent	SMALLDATETIME

	DECLARE	@StrLgota	VARCHAR(20)
			,@month3	VARCHAR(20)

	DECLARE	@LastDayPaym	SMALLDATETIME
			,@LastDayPaym2	SMALLDATETIME
			,@PersonStatus1	VARCHAR(30)

	DECLARE	@StrLast1		VARCHAR(70) -- для последней строки
			,@StrLast2		VARCHAR(20)
			,@KolMesDolg	DECIMAL(5, 1)

	SELECT
		@start_date = start_date
		,@end_date = end_date
	FROM dbo.GLOBAL_VALUES 
	WHERE fin_id = @fin_id1

	-- инициалы квартиросьемщика
	SET @Initials = dbo.Fun_Initials(@occ1)

	--******************************** 
	SELECT
		@StrFinPeriod = name
		, -- выдаем типа:   август 2001
		@month3 = name3 -- выдаем типа:   августе
	FROM dbo.MONTH
	WHERE id = DATEPART(MONTH, @start_date)

	SELECT
		@StrFinPeriod = @StrFinPeriod + ' ' + DATENAME(YEAR, @start_date)
		,@DateCurrent = dbo.Fun_GetOnlyDate(current_timestamp) -- Дата формирования квитанции
		,@LastDayPaym = dbo.Fun_GetOnlyDate(@start_date)

	--select * from @t 

	-- Записываем банковские реквизиты
	INSERT INTO @t_schet
	(	occ
		,NameFirma
		,bank
		,rasscht
		,korscht
		,bik
		,inn
		,tip_id
		,id_barcode
		,licbank
		,barcode_type)
		SELECT
			ban.occ
			,ban.name_str1
			,ban.bank
			,ban.rasschet
			,ban.korschet
			,ban.bik
			,ban.inn
			,o.tip_id
			,ban.id_barcode
			,ban.licbank
			,ban.barcode_type
		FROM @t AS t
		JOIN dbo.OCCUPATIONS AS o
			ON t.occ = o.occ
		JOIN dbo.Fun_GetAccount_ORG_Table(@t) AS ban
			ON t.occ = ban.occ

	IF EXISTS (SELECT
				bank
			FROM @t_schet AS t
			WHERE rasscht IS NULL
			OR rasscht = '')
	BEGIN
		RAISERROR ('Нет банковских реквизитов!', 16, 1)
		RETURN
	END

	--select * from @t_schet

	SELECT
		o.occ
		,CASE
			WHEN p.Debt < 0 THEN 0
			ELSE p.Debt
		END AS SumPaym
		,o.JEU
		,SUBSTRING(sec.name, 1, 20) AS jeu_name
		,dbo.Fun_Initials(o.occ) AS Initials
		,o.address AS Adres
		,dbo.Fun_LgotaStr(o.occ) AS Lgota
		,o.kol_people AS total_people
		,total_sq
		,LIVING_SQ
		,@start_date AS FinPeriod
		,@StrFinPeriod AS StrFinPeriod
		,p.Saldo AS Saldo
		,p.PaymAccount AS PaymAccount
		,p.PaymAccount_peny AS PaymAccount_peny
		,p.Debt AS Debt
		,@LastDayPaym AS LastDayPaym
		,dbo.Fun_PersonStatusStr(o.occ) AS PersonStatus
		,@month3 AS month3
		,0 AS Penalty_value
		,ot.LastStr1 AS LastStr1
		,ot.LastStr2 AS LastStr2
		,sp.Adres AS adres_tip
		,sp.telefon AS telefon_tip
		,dbo.Fun_DolgMesServ(@fin_id1, o.occ, @service_id1) AS KolMesDolg
		,@DateCurrent AS DateCreate
		,cl.occ_serv AS occ_serv
		,@service_id1 AS service_id
		,dbo.Fun_GetScaner_Kod_EAN(o.occ, @service_id1, @fin_id1, p.Debt, t.id_barcode, t.barcode_type, t.inn) AS EAN
		,sp.name AS source_name
		,t.NameFirma
		,t.bank
		,t.rasscht
		,t.korscht
		,t.bik
		,t.inn
	FROM @t_schet AS t
	JOIN dbo.OCCUPATIONS AS o 
		ON t.occ = o.occ
	JOIN dbo.CONSMODES_LIST AS cl 
		ON o.occ = cl.occ
	JOIN dbo.View_SUPPLIERS AS sp 
		ON cl.source_id = sp.id
	JOIN dbo.FLATS AS f 
		ON o.flat_id = f.id
	JOIN dbo.BUILDINGS AS b 
		ON f.bldn_id = b.id
	JOIN dbo.VSTREETS AS s 
		ON b.street_id = s.id
	JOIN dbo.OCCUPATION_TYPES AS ot 
		ON o.tip_id = ot.id
	LEFT JOIN dbo.SECTOR AS sec 
		ON b.sector_id = sec.id
	LEFT JOIN dbo.View_PAYM AS p 
		ON t.occ = p.occ AND p.service_id = @service_id1 AND p.fin_id = @fin_id1
	WHERE cl.service_id = @service_id1
	AND cl.account_one = 1
	AND cl.subsid_only = 0
	AND (cl.source_id % 1000 <> 0) --должен быть поставщик услуг
	ORDER BY s.name,
		b.nom_dom_sort, f.nom_kvr_sort
go

