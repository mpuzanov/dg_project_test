CREATE   PROCEDURE [dbo].[k_intPrint_occ_pid]
(
	@fin_id1 SMALLINT = NULL
   ,@occ1	 INT	  = 0
   ,@build	 INT	  = 0 -- Код дома
   ,@ops	 INT	  = 0 -- ОПС
   ,@sup_id	 INT	  = NULL
   ,@tip_id	 SMALLINT = NULL
   ,@pid_tip SMALLINT = 1
   ,@id		 INT	  = NULL
   ,@debug	 BIT	  = 0
)
AS
	/*

Формирование Уведомлений о задолженности
EXEC	[dbo].[k_intPrint_occ_pid]	@id=10526,@debug=1
EXEC	[dbo].[k_intPrint_occ_pid]	@fin_id1 = 126,	@sup_id = 315,	@tip_id = 10,	@pid_tip = 1
EXEC	[dbo].[k_intPrint_occ_pid]	@fin_id1 = 126,	@occ1=680001528, @sup_id = 345,	@pid_tip = 4, @id=5192 ,@debug=1

*/
	SET NOCOUNT ON

	DECLARE @dog_int INT

	IF @id = 0
		SET @id = NULL

	IF @id IS NOT NULL
	BEGIN
		SELECT
			@fin_id1 = fin_id
		   ,@sup_id = sup_id
		   ,@pid_tip = P.pid_tip
		   ,@occ1 = P.occ
		FROM dbo.PID AS P
		WHERE ID = @id
		IF @debug = 1
			SELECT
				@fin_id1 AS fin_id
			   ,@sup_id AS sup_id
	END

	DECLARE @t myTypeTableOcc

	DECLARE @t_schet TABLE
		(
			occ				INT			  PRIMARY KEY
		   ,NameFirma		VARCHAR(100)  DEFAULT NULL
		   ,BANK			VARCHAR(50)	  DEFAULT NULL
		   ,rasscht			VARCHAR(30)	  DEFAULT NULL
		   ,korscht			VARCHAR(30)	  DEFAULT NULL
		   ,bik				VARCHAR(20)	  DEFAULT NULL
		   ,inn				VARCHAR(20)	  DEFAULT NULL
		   ,kpp				VARCHAR(20)	  DEFAULT NULL
		   ,tip_id			SMALLINT	  DEFAULT 1
		   ,id_barcode		SMALLINT	  DEFAULT 0
		   ,licbank			BIGINT		  DEFAULT 0
		   ,adres			VARCHAR(60)	  DEFAULT ''
		   ,Initials		VARCHAR(100)  DEFAULT ''
		   ,NameFirma_str2  VARCHAR(100)  DEFAULT NULL
		   ,STREET			VARCHAR(50)	  DEFAULT ''
		   ,NOM_DOM			VARCHAR(12)	  DEFAULT ''
		   ,NOM_KVR			VARCHAR(20)	  DEFAULT ''
		   ,BankRasschetStr VARCHAR(1000) DEFAULT ''
		)

	IF @tip_id > 0
		AND @build = 0
		AND @ops = 0
	BEGIN
		IF @debug = 1
			PRINT '1'
		INSERT INTO @t
		(occ)
			SELECT DISTINCT
				occ
			FROM dbo.OCCUPATIONS AS o 
			JOIN dbo.FLATS AS f 
				ON o.flat_id = f.ID
			JOIN dbo.View_DOG_ALL AS bs 
				ON f.bldn_id = bs.build_id
			WHERE o.status_id <> 'закр'
			AND bs.sup_id = @sup_id
			AND bs.fin_id = @fin_id1
			AND (o.tip_id = @tip_id
			OR @tip_id IS NULL)
			AND NOT EXISTS (SELECT
					1
				FROM dbo.OCC_NOT_print AS onp
				WHERE o.occ = onp.occ
				AND onp.flag = 1)
		GOTO LABEL1
	END

	IF @build > 0
	BEGIN
		IF @debug = 1
			PRINT '2'
		INSERT INTO @t
		(occ)
			SELECT DISTINCT
				occ
			FROM dbo.OCCUPATIONS AS o 
			JOIN dbo.FLATS AS f 
				ON o.flat_id = f.ID
			JOIN dbo.View_DOG_ALL AS bs 
				ON f.bldn_id = bs.build_id
			WHERE f.bldn_id = @build
			AND o.status_id <> 'закр'
			AND bs.sup_id = @sup_id
			AND bs.fin_id = @fin_id1
			AND (o.tip_id = @tip_id
			OR @tip_id IS NULL)
			AND NOT EXISTS (SELECT
					1
				FROM dbo.OCC_NOT_print AS onp
				WHERE o.occ = onp.occ
				AND onp.flag = 1)
		GOTO LABEL1
	END

	IF @ops > 0
		OR @ops = -1
	BEGIN
		IF @debug = 1
			PRINT '3'
		INSERT INTO @t
		(occ)
			SELECT DISTINCT
				occ
			FROM dbo.OCCUPATIONS AS o 
			JOIN dbo.FLATS AS f 
				ON o.flat_id = f.ID
			JOIN dbo.BUILDINGS AS b 
				ON f.bldn_id = b.ID
			JOIN dbo.View_DOG_ALL AS bs 
				ON f.bldn_id = bs.build_id
			WHERE b.index_id =
				CASE
					WHEN @ops = -1 THEN b.index_id
					ELSE @ops
				END
			AND (o.status_id <> 'закр'
			OR o.PROPTYPE_ID = 'арен')
			AND bs.sup_id = @sup_id
			AND bs.fin_id = @fin_id1
			AND (o.tip_id = @tip_id
			OR @tip_id IS NULL)
			AND NOT EXISTS (SELECT
					1
				FROM dbo.OCC_NOT_print AS onp
				WHERE o.occ = onp.occ
				AND onp.flag = 1)
		GOTO LABEL1
	END

	IF @occ1 > 0
	BEGIN
		IF @debug = 1
			PRINT '4'
		INSERT INTO @t
		(occ)
			SELECT DISTINCT
				o.occ
			FROM dbo.OCCUPATIONS AS o 
			LEFT JOIN dbo.OCC_SUPPLIERS os 
				ON o.occ = os.occ
				AND os.sup_id = @sup_id
				AND os.fin_id = @fin_id1
			WHERE o.occ = @occ1
			AND o.status_id <> 'закр'
	END

LABEL1:
	IF @debug = 1
		SELECT
			*
		FROM @t

	DROP TABLE IF EXISTS #t_sort;
	CREATE TABLE #t_sort
	(
		occ			 INT
	   ,index_id	 INT
	   ,index_postal INT
	   ,tip_id		 SMALLINT
	   ,sort_id		 INT
	   ,sort_no		 INT
	)
	CREATE INDEX occ ON #t_sort (occ)
	CREATE INDEX sort_no ON #t_sort (sort_no)

	INSERT INTO #t_sort
	(occ
	,tip_id
	,index_id
	,index_postal
	,sort_id)
		SELECT
			t.occ
		   ,o.tip_id
		   ,b.index_id
		   ,b.index_postal
		   ,ROW_NUMBER() OVER (ORDER BY s.name, dbo.Fun_SortDom(b.NOM_DOM), dbo.Fun_SortDom(f.NOM_KVR))
		FROM @t AS t
		JOIN dbo.OCCUPATIONS AS o 
			ON t.occ = o.occ
		JOIN dbo.FLATS AS f 
			ON o.flat_id = f.ID
		JOIN dbo.BUILDINGS AS b
			ON f.bldn_id = b.ID
		JOIN dbo.VSTREETS AS s
			ON b.street_id = s.ID
		WHERE b.blocked_house = 0

	UPDATE #t_sort
	SET sort_no = sort_id

	--select t.*,o.address from #t_sort as t join dbo.OCCUPATIONS as o ON t.occ=o.occ
	--SELECT * FROM @t
	--select * FROM #t_sort
	SELECT TOP 1
		@dog_int = OS.dog_int
	FROM @t AS t
	JOIN dbo.OCC_SUPPLIERS AS OS 
		ON t.occ = OS.occ
	WHERE OS.fin_id = @fin_id1
	AND OS.sup_id = @sup_id

	-- Записываем банковские реквизиты у поставщика
	INSERT INTO @t_schet
	(occ
	,NameFirma
	,BANK
	,rasscht
	,korscht
	,bik
	,inn
	,kpp
	,tip_id
	,id_barcode
	,licbank
	,adres
	,Initials
	,NameFirma_str2
	,STREET
	,NOM_DOM
	,NOM_KVR
	,BankRasschetStr)
		SELECT
			o.occ
		   ,ban.name_str1
		   ,ban.BANK
		   ,ban.rasschet
		   ,ban.korschet
		   ,ban.bik
		   ,ban.inn
		   ,ban.kpp
		   ,o.tip_id
		   ,ban.id_barcode
		   ,ban.licbank
		   ,o.address
		   ,dbo.Fun_Initials_All(t.occ)
		   ,ban.name_str2
		   ,vb.socr_street
		   ,vb.NOM_DOM
		   ,f.NOM_KVR
		   ,ban.BankRasschetStr
		FROM @t AS t
		JOIN dbo.OCCUPATIONS AS o 
			ON t.occ = o.occ
		JOIN dbo.FLATS f 
			ON o.flat_id = f.ID
		JOIN dbo.View_BUILDINGS vb 
			ON f.bldn_id = vb.ID
		LEFT JOIN dbo.Fun_GetAccount_ORG_DOG(@t, @dog_int) AS ban
			ON t.occ = ban.occ

	IF @pid_tip IN (1)
		AND EXISTS (SELECT
				BANK
			FROM @t_schet AS t
			WHERE rasscht IS NULL
			OR rasscht = '')
	BEGIN
		RAISERROR ('Нет банковских реквизитов!', 16, 1)
		RETURN
	END

	IF EXISTS (SELECT
				1
			FROM dbo.GLOBAL_VALUES 
			WHERE fin_id = @fin_id1
			AND BlokedPrintAccount = 1)
	BEGIN -- Блокируем печать квитанций
		DELETE FROM @t_schet
	END
	--select * from @t_schet order by occ

	DECLARE @pid TABLE
		(
			occ			INT
		   ,data_create SMALLDATETIME
		   ,sup_id		INT
		   ,pid_tip		TINYINT
		   ,ID			INT
		   ,data_end	SMALLDATETIME
		   ,Summa		DECIMAL(9, 2)
		   ,fin_id		SMALLINT
		   ,occ_sup		INT
		   ,dog_data	SMALLDATETIME DEFAULT NULL
		   ,dog_id		VARCHAR(15)	  DEFAULT ''
		   ,dog_name	VARCHAR(50)	  DEFAULT ''
		   ,owner_id	INT			  DEFAULT NULL
		   ,is_peny		BIT			  DEFAULT NULL
		)

	IF @id IS NULL
		-- выбираем для печати последние записи
		INSERT INTO @pid
		(occ
		,data_create
		,sup_id
		,pid_tip
		,ID
		,data_end
		,Summa
		,fin_id
		,occ_sup
		,owner_id
		,is_peny)
			SELECT
				p1.occ
			   ,data_create
			   ,sup_id
			   ,pid_tip
			   ,p1.ID
			   ,data_end
			   ,Summa
			   ,fin_id
			   ,occ_sup
			   ,owner_id
			   ,is_peny
			FROM dbo.PID AS p1 
			JOIN (SELECT
					occ
				   ,MAX(ID) AS ID
				FROM dbo.PID AS p2 
				WHERE p2.fin_id = @fin_id1
				AND p2.pid_tip = @pid_tip
				AND sup_id = COALESCE(@sup_id, sup_id)
				GROUP BY occ) AS p3
				ON p1.ID = p3.ID

	ELSE -- только заданную
		INSERT INTO @pid
		(occ
		,data_create
		,sup_id
		,pid_tip
		,ID
		,data_end
		,Summa
		,fin_id
		,occ_sup
		,owner_id
		,is_peny)
			SELECT
				occ
			   ,data_create
			   ,sup_id
			   ,pid_tip
			   ,ID
			   ,data_end
			   ,Summa
			   ,fin_id
			   ,occ_sup
			   ,owner_id
			   ,is_peny
			FROM dbo.PID AS p1
			WHERE ID = @id

	--IF @pid_tip = 1
	UPDATE p
	SET dog_data = dog.dog_date
	   ,dog_name = dog.dog_name
	   ,dog_id	 = dog.dog_id
	FROM @pid AS p
	JOIN dbo.OCC_SUPPLIERS os 
		ON p.occ_sup = os.occ_sup
		AND p.fin_id = os.fin_id
	JOIN dbo.DOG_SUP AS dog 
		ON os.dog_int = dog.ID

	IF @debug = 1
		SELECT
			'table @pid'
		   ,*
		FROM @pid

	SELECT
		ts.sort_no
	   ,p.occ
	   ,p.data_create
	   ,p.sup_id
	   ,p.pid_tip
	   ,p.ID
	   ,p.data_end
	   ,p.Summa
	   ,p.fin_id
	   ,p.occ_sup
	   ,p.dog_id
	   ,p.dog_data
	   ,p.dog_name
	   ,t.NameFirma
	   ,t.NameFirma_str2
	   ,[EAN] = dbo.Fun_GetScaner_Kod_SUP_EAN(t.occ, @sup_id, @fin_id1, i.Whole_payment, t.id_barcode)
	   ,[EAN_2D] = dbo.Fun_GetScaner_Kod_PDF417(t.occ, NULL, @fin_id1, i.Whole_payment, t.adres, t.Initials, t.NameFirma, t.bik, t.rasscht, t.licbank)
	   ,t.BANK
	   ,t.rasscht
	   ,t.korscht
	   ,t.bik
	   ,t.inn
	   ,t.kpp
	   ,ts.index_id AS [INDEX]
	   ,ts.index_postal AS index_postal
	   ,t.tip_id
	   ,[tip_name] =
			CASE
				WHEN ot.synonym_name IS NULL OR
				ot.synonym_name = '' THEN ot.name
				ELSE ot.synonym_name
			END
	   ,adres_tip = '' --ot.adres
	   ,telefon_tip = '' --ot.telefon
	   ,t.adres
	   ,t.STREET
	   ,t.NOM_DOM
	   ,t.NOM_KVR
	   ,Initials
	   ,gb.StrMes AS StrFinPeriod
	   ,gb.start_date
	   ,COALESCE(sup.synonym_name, sup.name) as sup_name
	   ,CASE
			WHEN p.owner_id IS NOT NULL THEN dbo.Fun_InitialsPeople(p.owner_id)
			ELSE Initials
		END AS owner_name
	   ,t.BankRasschetStr
	   ,i.Penalty_old AS Penalty_itog
	   ,p.is_peny
	   ,ot.fio AS director
	FROM @t_schet AS t
	JOIN @pid AS p
		ON t.occ = p.occ
		AND p.fin_id = @fin_id1
		AND pid_tip = @pid_tip
	LEFT JOIN #t_sort AS ts
		ON t.occ = ts.occ
	LEFT JOIN dbo.OCC_SUPPLIERS AS i 
		ON t.occ = i.occ
		AND i.fin_id = p.fin_id
		AND i.sup_id = p.sup_id
	LEFT JOIN dbo.OCCUPATION_TYPES AS ot
		ON t.tip_id = ot.ID
	LEFT JOIN dbo.SUPPLIERS_ALL AS sup 
		ON i.sup_id = sup.ID
	LEFT JOIN dbo.GLOBAL_VALUES AS gb
		ON p.fin_id = gb.fin_id
	WHERE (p.ID = @id
	OR @id IS NULL)
	ORDER BY ts.sort_no
go

