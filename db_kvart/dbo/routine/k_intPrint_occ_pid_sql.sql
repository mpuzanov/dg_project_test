CREATE   PROCEDURE [dbo].[k_intPrint_occ_pid_sql]
(
	@fin_id1	SMALLINT	= NULL
	,@occ1		INT			= 0
	,@build		INT			= 0 -- Код дома
	,@ops		INT			= 0 -- ОПС
	,@sup_id	INT			= NULL
	,@tip_id	SMALLINT	= NULL
	,@pid_tip	SMALLINT	= 1
	,@id		INT			= NULL
	,@debug		BIT			= 0
)
AS
	/*

Формирование Уведомлений о задолженности или отмены уведомление
с дополнительными условиями

EXEC	[dbo].[k_intPrint_occ_pid_sql]	@fin_id1 = 126,	@sup_id = 315,	@tip_id = 10,	@pid_tip = 1

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
		FROM dbo.PID AS P
		WHERE id = @id
		IF @debug = 1
			SELECT
				@fin_id1
				,@sup_id
	END

	DECLARE @t myTypeTableOcc;

	DECLARE @t_schet TABLE
		(
			occ				INT				PRIMARY KEY
			,NameFirma		VARCHAR(50)		DEFAULT NULL
			,bank			VARCHAR(50)		DEFAULT NULL
			,rasscht		VARCHAR(30)		DEFAULT NULL
			,korscht		VARCHAR(30)		DEFAULT NULL
			,bik			VARCHAR(20)		DEFAULT NULL
			,inn			VARCHAR(20)		DEFAULT NULL
			,tip_id			SMALLINT		DEFAULT 1
			,id_barcode		SMALLINT		DEFAULT 0
			,licbank		BIGINT			DEFAULT 0
			,adres			VARCHAR(50)		DEFAULT ''
			,Initials		VARCHAR(100)	DEFAULT ''
			,NameFirma_str2	VARCHAR(50)		DEFAULT NULL
		)

	IF @tip_id > 0
		AND @build = 0
		AND @ops = 0
	BEGIN
		IF @debug = 1
			PRINT '1'
		INSERT
		INTO @t
		(occ)
			SELECT DISTINCT
				occ
			FROM dbo.OCCUPATIONS AS o 
			JOIN dbo.FLATS AS f 
				ON o.flat_id = f.id
			JOIN dbo.View_DOG_ALL AS bs 
				ON f.bldn_id = bs.build_id
			WHERE o.status_id <> 'закр'
			AND bs.sup_id = @sup_id
			AND bs.fin_id = @fin_id1
			AND o.tip_id = COALESCE(@tip_id, o.tip_id)
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
		INSERT
		INTO @t
		(occ)
			SELECT DISTINCT
				occ
			FROM dbo.OCCUPATIONS AS o 
			JOIN dbo.FLATS AS f 
				ON o.flat_id = f.id
			JOIN dbo.View_DOG_ALL AS bs 
				ON f.bldn_id = bs.build_id
			WHERE f.bldn_id = @build
			AND o.status_id <> 'закр'
			AND bs.sup_id = @sup_id
			AND bs.fin_id = @fin_id1
			AND o.tip_id = COALESCE(@tip_id, o.tip_id)
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
		INSERT
		INTO @t
		(occ)
			SELECT DISTINCT
				occ
			FROM dbo.OCCUPATIONS AS o 
			JOIN dbo.FLATS AS f 
				ON o.flat_id = f.id
			JOIN dbo.BUILDINGS AS b 
				ON f.bldn_id = b.id
			JOIN dbo.View_DOG_ALL AS bs 
				ON f.bldn_id = bs.build_id
			WHERE b.index_id =
				CASE
					WHEN @ops = -1 THEN b.index_id
					ELSE @ops
				END
			AND (o.status_id <> 'закр'
			OR o.proptype_id = 'арен')
			AND bs.sup_id = @sup_id
			AND bs.fin_id = @fin_id1
			AND o.tip_id = COALESCE(@tip_id, o.tip_id)
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
		INSERT
		INTO @t
		(occ)
			SELECT DISTINCT
				occ
			FROM dbo.OCCUPATIONS AS o 
			JOIN dbo.FLATS AS f 
				ON o.flat_id = f.id
			JOIN dbo.View_DOG_ALL AS bs 
				ON f.bldn_id = bs.build_id
			WHERE occ = @occ1
			AND o.status_id <> 'закр'
			AND bs.sup_id = @sup_id
			AND bs.fin_id = @fin_id1
	END

LABEL1:
	IF @debug = 1
		SELECT
			*
		FROM @t

	DROP TABLE IF EXISTS #t_sort;
	CREATE TABLE #t_sort
	(
		occ				INT
		,index_id		INT
		,index_postal	INT
		,tip_id			SMALLINT
		,sort_id		INT
		,sort_no		INT
	)
	CREATE INDEX occ ON #t_sort (occ)
	CREATE INDEX sort_no ON #t_sort (sort_no)

	INSERT
	INTO #t_sort
	(	occ
		,tip_id
		,index_id
		,index_postal
		,sort_id)
		SELECT
			t.occ
			,o.tip_id
			,b.index_id
			,b.index_postal
			,ROW_NUMBER() OVER (ORDER BY s.name, dbo.Fun_SortDom(b.nom_dom), dbo.Fun_SortDom(f.nom_kvr))
		FROM @t AS t
		JOIN dbo.OCCUPATIONS AS o 
			ON t.occ = o.occ
		JOIN dbo.FLATS AS f 
			ON o.flat_id = f.id
		JOIN dbo.BUILDINGS AS b
			ON f.bldn_id = b.id
		JOIN dbo.VSTREETS AS s
			ON b.street_id = s.id
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
	INSERT
	INTO @t_schet
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
		,adres
		,Initials
		,NameFirma_str2)
		SELECT
			o.occ
			,ban.name_str1
			,ban.bank
			,ban.rasschet
			,ban.korschet
			,ban.bik
			,ban.inn
			,o.tip_id
			,ban.id_barcode
			,ban.licbank
			,o.address
			,dbo.Fun_Initials_All(t.occ)
			,ban.name_str2
		FROM @t AS t
		JOIN dbo.OCCUPATIONS AS o
			ON t.occ = o.occ
		LEFT JOIN dbo.Fun_GetAccount_ORG_DOG(@t, @dog_int) AS ban
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

	IF EXISTS (SELECT
				*
			FROM dbo.GLOBAL_VALUES
			WHERE fin_id = @fin_id1
			AND BlokedPrintAccount = 1)
	BEGIN -- Блокируем печать квитанций
		DELETE FROM @t_schet
	END
	--select * from @t_schet order by occ

	DECLARE @pid TABLE
		(
			occ				INT
			,data_create	SMALLDATETIME
			,sup_id			INT
			,pid_tip		TINYINT
			,id				INT
			,data_end		SMALLDATETIME
			,Summa			DECIMAL(9, 2)
			,fin_id			SMALLINT
			,occ_sup		INT
			,dog_data		SMALLDATETIME	DEFAULT NULL
			,dog_name		VARCHAR(50)		DEFAULT ''
		)

	IF @id IS NULL
		-- выбираем для печати последние записи
		INSERT
		INTO @pid
		(	occ
			,data_create
			,sup_id
			,pid_tip
			,id
			,data_end
			,Summa
			,fin_id
			,occ_sup)
			SELECT
				p1.occ
				,data_create
				,sup_id
				,pid_tip
				,p1.id
				,data_end
				,Summa
				,fin_id
				,occ_sup
			FROM dbo.PID AS p1
			JOIN (SELECT
					occ
					,MAX(id) AS id
				FROM dbo.PID AS p2 
				WHERE --p2.fin_id = @fin_id1 and
				p2.pid_tip = @pid_tip
				AND sup_id = COALESCE(@sup_id, sup_id)
				GROUP BY occ) AS p3
				ON p1.id = p3.id

	ELSE -- только заданную
		INSERT
		INTO @pid
		(	occ
			,data_create
			,sup_id
			,pid_tip
			,id
			,data_end
			,Summa
			,fin_id
			,occ_sup)
			SELECT
				occ
				,data_create
				,sup_id
				,pid_tip
				,id
				,data_end
				,Summa
				,fin_id
				,occ_sup
			FROM dbo.PID AS p1
			WHERE id = @id

	IF @pid_tip = 1
		UPDATE p
		SET	dog_data	= dog.dog_date
			,dog_name	= dog.dog_name
		FROM @pid AS p
		JOIN dbo.CESSIA AS ces 
			ON p.occ_sup = ces.occ_sup
		JOIN dbo.DOG_SUP AS dog 
			ON ces.dog_int = dog.id

	IF @debug = 1
		SELECT
			*
		FROM @t_schet
	IF @debug = 1
		SELECT
			*
		FROM @pid

	SELECT
		ts.sort_no
		,p.*
		,
		--i.*,
		t.NameFirma
		,t.NameFirma_str2
		,[EAN] = dbo.Fun_GetScaner_Kod_SUP_EAN(t.occ, @sup_id, @fin_id1, i.Whole_payment, t.id_barcode)
		,[EAN_2D] = dbo.Fun_GetScaner_Kod_PDF417(t.occ, NULL, @fin_id1, i.Whole_payment, t.adres, t.Initials, t.NameFirma, t.bik, t.rasscht, t.licbank)
		,t.bank
		,t.rasscht
		,t.korscht
		,t.bik
		,t.inn
		,[INDEX] = ts.index_id
		,index_postal = ts.index_postal
		,t.tip_id
		,CASE
				WHEN ot.synonym_name IS NULL OR
				ot.synonym_name = '' THEN ot.name
				ELSE ot.synonym_name
		END as tip_name
		,adres_tip = '' --ot.adres
		,telefon_tip = '' --ot.telefon
		,t.adres
		,Initials
		,(SELECT
				StrMes
			FROM dbo.global_values
			WHERE fin_id = @fin_id1) as StrFinPeriod
		,COALESCE(sup.synonym_name, sup.name) as sup_name
	FROM @t_schet AS t
	JOIN @pid AS p
		ON t.occ = p.occ
		AND pid_tip = @pid_tip
	LEFT JOIN #t_sort AS ts
		ON t.occ = ts.occ
	LEFT JOIN dbo.OCC_SUPPLIERS AS i 
		ON t.occ = i.occ
		AND i.fin_id = p.fin_id
	LEFT JOIN dbo.OCCUPATION_TYPES AS ot
		ON t.tip_id = ot.id
	JOIN dbo.SUPPLIERS_ALL AS sup 
		ON i.sup_id = sup.id
	WHERE p.id = COALESCE(@id, p.id)
	--AND p.fin_id = coalesce(@fin_id1,p.fin_id)
	AND NOT EXISTS (SELECT *
		FROM dbo.PAYINGS AS P1
		WHERE P1.occ = t.occ)  -- если нет платежей
	ORDER BY ts.sort_no
go

