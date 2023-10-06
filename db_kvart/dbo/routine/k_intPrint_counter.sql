CREATE   PROCEDURE [dbo].[k_intPrint_counter]
(
	  @service_id1 VARCHAR(10)
	, @build_id1 INT = NULL
	, @flat_id1 INT = NULL
	, @occ1 INT = NULL
	, @jeu_id1 SMALLINT = NULL   -- Участок
)
AS
	--
	--  Показываем часть информации по счету-квитанции для счетчиков
	--
	/*
	дата изменения: 10.05.04
	автор: Пузанов
	
	изменил:
	
	*/
	SET NOCOUNT ON

	IF @jeu_id1 = 0
		SET @jeu_id1 = NULL
	IF @flat_id1 = 0
		SET @flat_id1 = NULL
	IF @build_id1 = 0
		SET @build_id1 = NULL
	IF @occ1 = 0
		SET @occ1 = NULL

	DECLARE @t myTypeTableOcc

	DECLARE @t_schet TABLE (
		  occ INT PRIMARY KEY
		, NameFirma VARCHAR(50) DEFAULT NULL
		, bank VARCHAR(50) DEFAULT NULL
		, rasscht VARCHAR(30) DEFAULT NULL
		, korscht VARCHAR(30) DEFAULT NULL
		, bik VARCHAR(20) DEFAULT NULL
		, inn VARCHAR(20) DEFAULT NULL
		, tip_id SMALLINT DEFAULT 1
		, id_barcode SMALLINT DEFAULT 0
		, licbank BIGINT DEFAULT 0
		, barcode_type SMALLINT DEFAULT 0
	)

	INSERT INTO @t (occ)
	SELECT DISTINCT o.occ
	FROM dbo.Occupations AS o 
		LEFT JOIN dbo.Sector AS sec 
			ON o.jeu = sec.id
		JOIN dbo.Flats AS f 
			ON o.flat_id = f.id
		JOIN dbo.View_counter_all AS cl 
			ON o.occ = cl.occ
			AND o.flat_id = cl.flat_id
		JOIN dbo.Services AS s 
			ON cl.service_id = s.id
		JOIN dbo.Counters AS c 
			ON cl.counter_id = c.id
	WHERE o.status_id <> 'закр'
		AND o.occ BETWEEN COALESCE(@occ1, 0) AND COALESCE(@occ1, 9999999)
		AND o.flat_id BETWEEN COALESCE(@flat_id1, 0) AND COALESCE(@flat_id1, 9999999)
		AND o.jeu BETWEEN COALESCE(@jeu_id1, 0) AND COALESCE(@jeu_id1, 9999)
		AND s.id = @service_id1
		AND f.bldn_id BETWEEN COALESCE(@build_id1, 0) AND COALESCE(@build_id1, 9999999)
		AND c.date_del IS NULL  -- 
		AND cl.internal = 0


	--select * from @t

	-- Записываем банковские реквизиты
	INSERT INTO @t_schet (occ
						, NameFirma
						, bank
						, rasscht
						, korscht
						, bik
						, inn
						, tip_id
						, id_barcode
						, licbank
						, barcode_type)
	SELECT ban.occ
		 , ban.name_str1
		 , ban.bank
		 , ban.rasschet
		 , ban.korschet
		 , ban.bik
		 , ban.inn
		 , o.tip_id
		 , ban.id_barcode
		 , ban.licbank
		 , ban.barcode_type
	FROM @t AS t
		JOIN dbo.Occupations AS o ON t.occ = o.occ
		JOIN (
			SELECT *
			FROM dbo.Fun_GetAccount_ORG_Table(@t)
		) AS ban ON t.occ = ban.occ

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

	--select * from @t_schet

	SELECT o.occ
		 , cl.occ_counter AS service_occ
		 , --dbo.Fun_GetService_Occ(o.occ,@service_id1),
		   serv.id AS service_id
		 , serv.short_name AS [service_name]
		 , Kod_EAN = dbo.Fun_GetScaner_Kod_EAN(o.occ, @service_id1, 0, 0, t.id_barcode, t.barcode_type, t.inn)
		 , o.jeu AS jeu
		 , SUBSTRING(sec.name, 1, 15) AS jeu_name
		 , dbo.Fun_Initials(o.occ) AS Initials
		 , o.address AS adres
		 , dbo.Fun_LgotaStr(o.occ) AS LgotaStr
		 , t.NameFirma
		 , t.bank
		 , t.rasscht
		 , t.korscht
		 , t.bik
		 , t.inn
		 , s.name
		 , b.nom_dom
		 , f.nom_kvr
	FROM @t_schet AS t
		JOIN dbo.Occupations AS o 
			ON t.occ = o.occ
		JOIN dbo.Sector AS sec 
			ON o.jeu = sec.id
		JOIN dbo.Flats AS f
			ON o.flat_id = f.id
		JOIN dbo.Buildings AS b 
			ON f.bldn_id = b.id
		JOIN dbo.View_counter_all AS cl 
			ON o.occ = cl.occ
			AND o.flat_id = cl.flat_id 
			AND cl.fin_id = O.fin_id
		JOIN dbo.Counters AS c 
			ON c.id = cl.counter_id
		JOIN dbo.Services AS serv 
			ON serv.id = cl.service_id
		JOIN dbo.VStreets AS s
			ON b.street_id = s.id
	WHERE o.status_id <> 'закр'
		AND serv.id = @service_id1
		AND c.date_del IS NULL

	ORDER BY s.name
		   , b.nom_dom_sort
		   , f.nom_kvr_sort
go

