CREATE   PROCEDURE [dbo].[ka_add_paym]
(
	  @occ1 INT
	, @fin_id1 SMALLINT
	, @Add_type1 SMALLINT = 0 -- тип разового
	, @People_list BIT = 0 -- заносить расширенную информацию по расчету в PEOPLE_LIST_RAS
	, @mode_history BIT = 0 -- при перерасчетах режимы брать из истории
	, @debug BIT = 0

)
AS
	/*
	--  Показываем суммы для 
	--  Перерасчета (возврат по отсутсвующим, доначисления)
	--  в картотечнике
	--
	--***************************
	*/
	SET NOCOUNT ON

	DECLARE @build_id INT
	SELECT @build_id = bldn_id
	FROM dbo.View_occ_all_lite
	WHERE fin_id = @fin_id1
		AND occ = @occ1

	IF @Add_type1 IN (3, 7)
		EXEC k_raschet_2 @occ1
					   , @fin_id1
					   , @added = 1
					   , @lgotadayno = 1
					   , @People_list = @People_list
					   , @mode_history = @mode_history
					   , @debug = @debug
	ELSE
		EXEC k_raschet_2 @occ1
					   , @fin_id1
					   , @added = 1
					   , @People_list = @People_list
					   , @mode_history = @mode_history
					   , @debug = @debug



	--select * from paym_history where fin_id=@fin_id1 and occ=@occ1
	--select * from paym_add where occ=@occ1


	DECLARE @t TABLE (
		  service_id VARCHAR(10)
		, serv VARCHAR(100)
		, sup_id INT DEFAULT 0
		, sup_name VARCHAR(50) DEFAULT ''
		, tarif DECIMAL(9, 3) DEFAULT 0
		, is_counter BIT DEFAULT 0
		, phvalue DECIMAL(9, 2) DEFAULT 0
		, phdiscount DECIMAL(9, 2) DEFAULT 0
		, phcompens DECIMAL(9, 2) DEFAULT 0
		, pavalue DECIMAL(9, 2) DEFAULT 0
		, padiscount DECIMAL(9, 2) DEFAULT 0
		, pacompens DECIMAL(9, 2) DEFAULT 0
		, ph_summa DECIMAL(9, 2) DEFAULT 0
		, pa_summa DECIMAL(9, 2) DEFAULT 0
		, [ADD] AS pa_summa - ph_summa
		, short_id VARCHAR(10) DEFAULT NULL
	)

	INSERT INTO @t
		(service_id
	   , serv
	   , sup_id
	   , sup_name)
	SELECT cl.service_id
		 , s.name
		 , cl.sup_id
		 , s1.name
	FROM Consmodes_list cl
		JOIN Services s  ON cl.service_id = s.id
		JOIN Suppliers s1 ON cl.source_id = s1.id
	WHERE occ = @occ1
	ORDER BY s.name

	--SELECT
	--	'service_id' = id
	--	,'serv' = name
	--FROM dbo.Fun_GetServBuild(@build_id)
	--ORDER BY sort_no

	UPDATE @t
	SET tarif = pa.tarif
	  , pavalue = pa.Value
		--,padiscount	= pa.discount
	  , short_id = u.short_id
	FROM @t AS t
		JOIN dbo.Paym_add AS pa ON t.service_id = pa.service_id
			AND t.sup_id = pa.sup_id
		LEFT JOIN dbo.Units AS u  ON pa.unit_id = u.id
	WHERE pa.occ = @occ1

	UPDATE @t
	SET phvalue = ph.Value
		--,phdiscount	= ph.discount
		--,phcompens	= ph.Compens
		--,pacompens	= ph.Compens
	  , is_counter = ph.is_counter
	FROM @t AS t
		JOIN dbo.View_paym AS ph ON t.service_id = ph.service_id
	WHERE ph.occ = @occ1
		AND ph.fin_id = @fin_id1


	IF @Add_type1 = 6 -- возврат по льготе
		UPDATE @t
		SET pa_summa = -padiscount
		  , ph_summa = -phdiscount
		  , pavalue = 0
		  , phvalue = 0
		  , phcompens = 0
		  , pacompens = 0
	ELSE
		UPDATE @t
		SET pa_summa = pavalue - pacompens - padiscount
		  , ph_summa = phvalue - phcompens - phdiscount

	-- update #t set [add]=pa_summa-ph_summa

	SELECT service_id
		 , serv
		 , sup_id
		 , sup_name
		 , is_counter
		 , CASE
               WHEN tarif = 0 THEN NULL
               ELSE tarif
        END AS tarif
		 , CASE
               WHEN phvalue = 0 THEN NULL
               ELSE phvalue
        END AS phvalue
		 , CASE
               WHEN phdiscount = 0 THEN NULL
               ELSE phdiscount
        END AS phdiscount
		 , CASE
               WHEN phcompens = 0 THEN NULL
               ELSE phcompens
        END AS phcompens
		 , CASE
               WHEN pavalue = 0 THEN NULL
               ELSE pavalue
        END AS pavalue
		 , CASE
               WHEN padiscount = 0 THEN NULL
               ELSE padiscount
        END AS padiscount
		 , CASE
               WHEN pacompens = 0 THEN NULL
               ELSE pacompens
        END AS pacompens
		 , CASE
               WHEN ph_summa = 0 THEN NULL
               ELSE ph_summa
        END AS ph_summa
		 , CASE
               WHEN pa_summa = 0 THEN NULL
               ELSE pa_summa
        END AS pa_summa
		 , CASE
               WHEN [ADD] = 0 THEN NULL
               ELSE [ADD]
        END AS [ADD]
		 , short_id
	FROM @t
	--where (phvalue>0 or pavalue>0)
	ORDER BY [ADD] DESC
		   , serv
go

