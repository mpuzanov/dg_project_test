-- =============================================
-- Author:		Пузанов
-- Create date: 14.02.2010
-- Description:	Возвращаем банковский счет для квитанции
-- Пример вызова:  select * from dbo.Fun_GetAccount_ORG(@t)
-- =============================================
CREATE       FUNCTION [dbo].[Fun_GetAccount_ORG_Table]
(
	  @intable dbo.myTypeTableOcc READONLY
)
RETURNS @t1 TABLE (
	  id INT
	, occ INT PRIMARY KEY
	, service_id VARCHAR(10) DEFAULT NULL
	, rasschet VARCHAR(20)
	, bik VARCHAR(9)
	, licbank BIGINT
	, name_str1 VARCHAR(100)
	, BANK VARCHAR(50)
	, korschet VARCHAR(20)
	, inn VARCHAR(12)
	, id_barcode VARCHAR(50)
	, name_str2 VARCHAR(100)
	, tip_account_org SMALLINT
	, BARCODE_TYPE SMALLINT
	, kpp VARCHAR(9)
	, cbc VARCHAR(20)
	, oktmo VARCHAR(11)
)
AS
BEGIN

	-- Лицевой счёт	
	INSERT INTO @t1
		(id
	   , occ
	   , service_id
	   , rasschet
	   , bik
	   , licbank
	   , name_str1
	   , BANK
	   , korschet
	   , inn
	   , id_barcode
	   , name_str2
	   , tip_account_org
	   , BARCODE_TYPE
	   , kpp
	   , cbc
	   , oktmo)
	SELECT ao.id
		 , t.occ
		 , t.service_id
		 , ao.rasschet
		 , ao.bik
		 , ao.licbank
		 , ao.name_str1
		 , ao.BANK
		 , ao.korschet
		 , ao.inn
		 , COALESCE(ao.id_barcode, '')
		 , ao.name_str2
		 , ao.tip
		 , ao.BARCODE_TYPE
		 , ao.kpp
		 , ao.cbc
		 , ao.oktmo
	FROM @intable AS t
		JOIN dbo.Occupations AS o 
			ON t.occ = o.occ
		JOIN dbo.Account_org AS ao 
			ON o.bank_account = ao.id
	--WHERE NOT EXISTS (
	--		SELECT 1
	--		FROM @t1
	--		WHERE occ = t.occ
	--	)

	-- Поставщик	
	INSERT INTO @t1
		(id
	   , occ
	   , service_id
	   , rasschet
	   , bik
	   , licbank
	   , name_str1
	   , BANK
	   , korschet
	   , inn
	   , id_barcode
	   , name_str2
	   , tip_account_org
	   , BARCODE_TYPE
	   , kpp
	   , cbc
	   , oktmo)
	SELECT ao.id
		 , t.occ
		 , t.service_id
		 , ao.rasschet
		 , ao.bik
		 , ao.licbank
		 , ao.name_str1
		 , ao.BANK
		 , ao.korschet
		 , ao.inn
		 , COALESCE(ao.id_barcode, '') AS id_barcode
		 , ao.name_str2
		 , ao.tip
		 , ao.BARCODE_TYPE
		 , ao.kpp
		 , ao.cbc
		 , ao.oktmo
	FROM @intable AS t
		JOIN dbo.Consmodes_list AS cl 
			ON t.occ = cl.occ
			AND t.service_id = cl.service_id
		JOIN dbo.View_suppliers AS s 
			ON cl.source_id = s.id
			AND s.account_one = 1
		JOIN dbo.Account_org AS ao 
			ON s.bank_account = ao.id
	WHERE NOT EXISTS (
			SELECT 1
			FROM @t1
			WHERE occ = t.occ
		)
	--if exists(select * from @t1) RETURN

	-- Участок	
	INSERT INTO @t1
		(id
	   , occ
	   , service_id
	   , rasschet
	   , bik
	   , licbank
	   , name_str1
	   , BANK
	   , korschet
	   , inn
	   , id_barcode
	   , name_str2
	   , tip_account_org
	   , BARCODE_TYPE
	   , kpp
	   , cbc
	   , oktmo)
	SELECT ao.id
		 , t.occ
		 , t.service_id
		 , ao.rasschet
		 , ao.bik
		 , ao.licbank
		 , ao.name_str1
		 , ao.BANK
		 , ao.korschet
		 , ao.inn
		 , COALESCE(ao.id_barcode, '')
		 , ao.name_str2
		 , ao.tip
		 , ao.BARCODE_TYPE
		 , ao.kpp
		 , ao.cbc
		 , ao.oktmo
	FROM @intable AS t
		JOIN dbo.Occupations AS o
			ON t.occ = o.occ
		JOIN dbo.Sector AS s 
			ON o.jeu = s.id
		JOIN dbo.Account_org AS ao 
			ON s.bank_account = ao.id
	WHERE NOT EXISTS (
			SELECT 1
			FROM @t1
			WHERE occ = t.occ
		)

	--if exists(select * from @t1) RETURN

	-- Дом
	INSERT INTO @t1
		(id
	   , occ
	   , service_id
	   , rasschet
	   , bik
	   , licbank
	   , name_str1
	   , BANK
	   , korschet
	   , inn
	   , id_barcode
	   , name_str2
	   , tip_account_org
	   , BARCODE_TYPE
	   , kpp
	   , cbc
	   , oktmo)
	SELECT ao.id
		 , t.occ
		 , t.service_id
		 , ao.rasschet
		 , ao.bik
		 , ao.licbank
		 , ao.name_str1
		 , ao.BANK
		 , ao.korschet
		 , ao.inn
		 , COALESCE(ao.id_barcode, '')
		 , ao.name_str2
		 , ao.tip
		 , ao.BARCODE_TYPE
		 , ao.kpp
		 , ao.cbc
		 , ao.oktmo
	FROM @intable AS t
		JOIN dbo.Occupations AS o 
			ON t.occ = o.occ
		JOIN dbo.Flats AS f 
			ON o.flat_id = f.id
		JOIN dbo.Buildings AS b 
			ON f.bldn_id = b.id
		JOIN dbo.Account_org AS ao 
			ON b.bank_account = ao.id
	WHERE NOT EXISTS (
			SELECT 1
			FROM @t1
			WHERE occ = t.occ
		)

	-- Тип фонда
	INSERT INTO @t1
		(id
	   , occ
	   , service_id
	   , rasschet
	   , bik
	   , licbank
	   , name_str1
	   , BANK
	   , korschet
	   , inn
	   , id_barcode
	   , name_str2
	   , tip_account_org
	   , BARCODE_TYPE
	   , kpp
	   , cbc
	   , oktmo)
	SELECT ao.id
		 , t.occ
		 , t.service_id
		 , ao.rasschet
		 , ao.bik
		 , ao.licbank
		 , ao.name_str1
		 , ao.BANK
		 , ao.korschet
		 , ao.inn
		 , COALESCE(ao.id_barcode, '')
		 , ao.name_str2
		 , ao.tip
		 , ao.BARCODE_TYPE
		 , ao.kpp
		 , ao.cbc
		 , ao.oktmo
	FROM @intable AS t
		JOIN dbo.Occupations AS o 
			ON t.occ = o.occ
		JOIN dbo.Occupation_Types AS ot
			ON o.tip_id = ot.id
		JOIN dbo.Account_org AS ao
			ON ot.bank_account = ao.id
	WHERE NOT EXISTS (
			SELECT 1
			FROM @t1
			WHERE occ = t.occ
		)

	--if exists(select * from @t1) RETURN

	-- Район
	INSERT INTO @t1
		(id
	   , occ
	   , service_id
	   , rasschet
	   , bik
	   , licbank
	   , name_str1
	   , BANK
	   , korschet
	   , inn
	   , id_barcode
	   , name_str2
	   , tip_account_org
	   , BARCODE_TYPE
	   , kpp
	   , cbc
	   , oktmo)
	SELECT ao.id
		 , t.occ
		 , t.service_id
		 , ao.rasschet
		 , ao.bik
		 , ao.licbank
		 , ao.name_str1
		 , ao.BANK
		 , ao.korschet
		 , ao.inn
		 , COALESCE(ao.id_barcode, '')
		 , ao.name_str2
		 , ao.tip
		 , ao.BARCODE_TYPE
		 , ao.kpp
		 , ao.cbc
		 , ao.oktmo
	FROM @intable AS t
		JOIN dbo.Occupations AS o
			ON t.occ = o.occ
		JOIN dbo.Flats AS f
			ON o.flat_id = f.id
		JOIN dbo.Buildings AS b
			ON f.bldn_id = b.id
		JOIN dbo.Divisions AS d 
			ON b.div_id = d.id
		JOIN dbo.Account_org AS ao
			ON d.bank_account = ao.id
	WHERE NOT EXISTS (
			SELECT 1
			FROM @t1
			WHERE occ = t.occ
		)
	RETURN
END
go

