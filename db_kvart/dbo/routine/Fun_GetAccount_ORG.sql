-- =============================================
-- Author:		Пузанов
-- Create date: 14.02.2010
-- Description:	Возвращаем банковский счет для квитанции
-- Пример вызова:  select * from dbo.Fun_GetAccount_ORG(45676,null)
-- =============================================
CREATE       FUNCTION [dbo].[Fun_GetAccount_ORG]
(
	  @occ1 INT
	, @service_id1 VARCHAR(10) = NULL
)
RETURNS @t1 TABLE (
	  id INT
	, occ INT
	, service_id VARCHAR(10) DEFAULT NULL
	, rasschet VARCHAR(20)
	, bik VARCHAR(9)
	, licbank VARCHAR(8)
	, name_str1 VARCHAR(100)
	, bank VARCHAR(50)
	, korschet VARCHAR(20)
	, inn VARCHAR(12)
	, id_barcode VARCHAR(50)
	, name_str2 VARCHAR(100)
	, kpp VARCHAR(9)
	, cbc VARCHAR(20)
	, oktmo VARCHAR(11)
)
AS
BEGIN
	IF @service_id1 IS NULL
		GOTO LABEL_SECTOR
	ELSE
	BEGIN
		-- Поставщик	
		INSERT INTO @t1
			(id
		   , occ
		   , service_id
		   , rasschet
		   , bik
		   , licbank
		   , name_str1
		   , bank
		   , korschet
		   , inn
		   , id_barcode
		   , name_str2
		   , kpp
		   , cbc
		   , oktmo)
		SELECT ao.id
			 , @occ1
			 , @service_id1
			 , ao.rasschet
			 , ao.bik
			 , ao.licbank
			 , ao.name_str1
			 , ao.bank
			 , ao.korschet
			 , ao.inn
			 , ao.id_barcode
			 , ao.name_str2
			 , ao.kpp
			 , ao.cbc
			 , ao.oktmo
		FROM dbo.Consmodes_list AS cl 
			JOIN dbo.View_suppliers AS s 
				ON cl.source_id = s.id
				AND s.account_one = 1
			JOIN dbo.Account_org AS ao 
				ON s.bank_account = ao.id
		WHERE cl.occ = @occ1
			AND cl.service_id = @service_id1

		IF EXISTS (SELECT * FROM @t1)
			RETURN
	END

LABEL_SECTOR:

		-- Лицевой
		INSERT INTO @t1
			(id
		   , occ
		   , service_id
		   , rasschet
		   , bik
		   , licbank
		   , name_str1
		   , bank
		   , korschet
		   , inn
		   , id_barcode
		   , name_str2
		   , kpp
		   , cbc
		   , oktmo)
		SELECT ao.id
			 , @occ1
			 , @service_id1
			 , ao.rasschet
			 , ao.bik
			 , ao.licbank
			 , ao.name_str1
			 , ao.bank
			 , ao.korschet
			 , ao.inn
			 , ao.id_barcode
			 , ao.name_str2
			 , ao.kpp
			 , ao.cbc
			 , ao.oktmo
		FROM dbo.Occupations AS o 
			JOIN dbo.Account_org AS ao 
				ON o.bank_account = ao.id
		WHERE o.occ = @occ1
		IF EXISTS (SELECT * FROM @t1)
			RETURN

	-- Участок	
	INSERT INTO @t1
		(id
	   , occ
	   , service_id
	   , rasschet
	   , bik
	   , licbank
	   , name_str1
	   , bank
	   , korschet
	   , inn
	   , id_barcode
	   , name_str2
	   , kpp
	   , cbc
	   , oktmo)
	SELECT ao.id
		 , @occ1
		 , @service_id1
		 , ao.rasschet
		 , ao.bik
		 , ao.licbank
		 , ao.name_str1
		 , ao.bank
		 , ao.korschet
		 , ao.inn
		 , ao.id_barcode
		 , ao.name_str2
		 , ao.kpp
		 , ao.cbc
		 , ao.oktmo
	FROM dbo.Occupations AS o
		JOIN dbo.Sector AS s 
			ON o.jeu = s.id
		JOIN dbo.Account_org AS ao 
			ON s.bank_account = ao.id
	WHERE o.occ = @occ1
	IF EXISTS (SELECT * FROM @t1)
		RETURN

	-- Дом
	INSERT INTO @t1
		(id
	   , occ
	   , service_id
	   , rasschet
	   , bik
	   , licbank
	   , name_str1
	   , bank
	   , korschet
	   , inn
	   , id_barcode
	   , name_str2
	   , kpp
	   , cbc
	   , oktmo)
	SELECT ao.id
		 , @occ1
		 , @service_id1
		 , ao.rasschet
		 , ao.bik
		 , ao.licbank
		 , ao.name_str1
		 , ao.bank
		 , ao.korschet
		 , ao.inn
		 , ao.id_barcode
		 , ao.name_str2
		 , ao.kpp
		 , ao.cbc
		 , ao.oktmo
	FROM dbo.Occupations AS o
		JOIN dbo.Flats AS f 
			ON o.flat_id = f.id
		JOIN dbo.Buildings AS b 
			ON f.bldn_id = b.id
		JOIN dbo.Account_org AS ao 
			ON b.bank_account = ao.id
	WHERE o.occ = @occ1
	IF EXISTS (SELECT * FROM @t1)
		RETURN

	-- Тип фонда
	INSERT INTO @t1
		(id
	   , occ
	   , service_id
	   , rasschet
	   , bik
	   , licbank
	   , name_str1
	   , bank
	   , korschet
	   , inn
	   , id_barcode
	   , name_str2
	   , kpp
	   , cbc
	   , oktmo)
	SELECT ao.id
		 , @occ1
		 , @service_id1
		 , ao.rasschet
		 , ao.bik
		 , ao.licbank
		 , ao.name_str1
		 , ao.bank
		 , ao.korschet
		 , ao.inn
		 , ao.id_barcode
		 , ao.name_str2
		 , ao.kpp
		 , ao.cbc
		 , ao.oktmo
	FROM dbo.Occupations AS o
		JOIN dbo.Occupation_Types AS t 
			ON o.tip_id = t.id
		JOIN dbo.Account_org AS ao 
			ON t.bank_account = ao.id
	WHERE o.occ = @occ1
	IF EXISTS (SELECT * FROM @t1)
		RETURN

	-- Район
	INSERT INTO @t1
		(id
	   , occ
	   , service_id
	   , rasschet
	   , bik
	   , licbank
	   , name_str1
	   , bank
	   , korschet
	   , inn
	   , id_barcode
	   , name_str2
	   , kpp
	   , cbc
	   , oktmo)
	SELECT ao.id
		 , @occ1
		 , @service_id1
		 , ao.rasschet
		 , ao.bik
		 , ao.licbank
		 , ao.name_str1
		 , ao.bank
		 , ao.korschet
		 , ao.inn
		 , ao.id_barcode
		 , ao.name_str2
		 , ao.kpp
		 , ao.cbc
		 , ao.oktmo
	FROM dbo.Occupations AS o
		JOIN dbo.Flats AS f
			ON o.flat_id = f.id
		JOIN dbo.Buildings AS b 
			ON f.bldn_id = b.id
		JOIN dbo.Divisions AS d 
			ON b.div_id = d.id
		JOIN dbo.Account_org AS ao 
			ON d.bank_account = ao.id
	WHERE o.occ = @occ1

	RETURN
END
go

