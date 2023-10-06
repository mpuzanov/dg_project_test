CREATE   PROCEDURE [dbo].[k_intPrintDetail_occ_all]
(
	@Fin_Id1	SMALLINT -- Фин.период
	,@Occ1		INT -- лицевой
	,@Tip_Id	SMALLINT	= NULL--жилой фонд
	,@Debug		BIT			= 0
)
/*
Выдаем информацию по услугам для единой квитанции
с общедомовыми услугами

exec [k_intPrintDetail_occ_all] 138,950000710
*/
AS
	SET NOCOUNT ON

	DECLARE	@Fin_Current1		SMALLINT
			,@NamesOdeRhoUsing	VARCHAR(30)
			,@Total_sq			DECIMAL(9, 2)	= 0
			,@build_id			INT
			,@Db_Name			VARCHAR(20)		= UPPER(DB_NAME())

	SELECT
		@Occ1 = dbo.Fun_GetFalseOccIn(@Occ1)
	SELECT
		@Fin_Current1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @Occ1)

	DECLARE @T TABLE
		(
			occ					INT
			,short_name			VARCHAR(50)
			,short_id			VARCHAR(6)
			,service_id			VARCHAR(10)
			,sup_id				INT				DEFAULT 0
			,tarif				DECIMAL(10, 4)	DEFAULT 0
			,kol				DECIMAL(12, 6)	DEFAULT 0
			,kol_dom			DECIMAL(12, 6)	DEFAULT 0
			,koef				DECIMAL(10, 4)	DEFAULT 1
			,saldo				DECIMAL(9, 2)	DEFAULT 0
			,value				DECIMAL(9, 2)	DEFAULT 0
			,value_dom			DECIMAL(9, 2)	DEFAULT 0
			,value_itog			AS (value + value_dom)
			,added1				DECIMAL(9, 2)	DEFAULT 0
			,added12			DECIMAL(9, 2)	DEFAULT 0
			,added				AS (added1 - added12)
			,paid				DECIMAL(9, 2)	DEFAULT 0
			,paid_dom			DECIMAL(9, 2)	DEFAULT 0
			,paid_itog			AS (paid + paid_dom)
			,debt				DECIMAL(9, 2)	DEFAULT 0
			,sort_no			INT				DEFAULT 100
			,mode_id			INT				DEFAULT NULL
			,unit_id			VARCHAR(10)		DEFAULT NULL
			,service_id_from	VARCHAR(10)		DEFAULT NULL
			,is_build			BIT				DEFAULT 0
			,is_sum				BIT				DEFAULT 1
			,subsid_only		BIT				DEFAULT 0
			,tip_id				SMALLINT		DEFAULT 0
			,VSODER				BIT				DEFAULT 0
			,VYDEL				BIT				DEFAULT 0
			,OWNER_ID			INT				DEFAULT 0
			,[service_name]		VARCHAR(30)		DEFAULT ''
			,OWNER_ID_BUILD		INT				DEFAULT 0
		)

	IF @Fin_Id1 >= @Fin_Current1
	BEGIN
		SELECT
			@Tip_Id = tip_id
			,@Total_sq = TOTAL_SQ
			,@build_id = f.bldn_id
		FROM dbo.OCCUPATIONS AS o 
		JOIN dbo.FLATS AS f 
			ON o.flat_id = f.id
		WHERE occ = @Occ1

		INSERT INTO @T
		(	occ
			,short_name
			,short_id
			,service_id
			,sup_id
			,tarif
			,kol
			,koef
			,saldo
			,value
			,added1
			,paid
			,debt
			,sort_no
			,mode_id
			,unit_id
			,service_id_from
			,is_build
			,subsid_only
			,tip_id
			,VSODER
			,VYDEL
			,OWNER_ID
			,[service_name])
				SELECT
                     o.occ
					,s.short_name
					,CASE
                       WHEN len(st.short_id) > 0 THEN st.short_id
                       ELSE u.short_id
                     END as short_id
					,p.service_id
					,p.sup_id
					,p.tarif
					,ROUND(p.kol, CASE 
                                WHEN u.precision = 0 THEN 4
                                ELSE u.precision
                    END) AS kol
					,p.koef
					,COALESCE(p.saldo, 0)
					,COALESCE(p.value, 0)
					,COALESCE(p.added, 0)
					,COALESCE(p.paid, 0)
					,COALESCE(p.debt, 0)
					,s.sort_no
					,NULL
					,p.unit_id
					,CASE
						WHEN serv_from IS NULL THEN NULL
						ELSE SUBSTRING(serv_from, 1, 4)
					END
					,s.is_build
					,p.subsid_only
					,o.tip_id
					,COALESCE(st.VSODER, 0)
					,COALESCE(st.VYDEL, 0)
					,COALESCE(st.OWNER_ID, 0)
					,COALESCE(st.service_name, '')
				FROM dbo.OCCUPATIONS AS o 
				JOIN dbo.PAYM_LIST AS p 
					ON o.occ = p.occ
				JOIN dbo.SERVICES AS s 
					ON p.service_id = s.id
				LEFT JOIN dbo.UNITS AS u 
					ON p.unit_id = u.id
				LEFT JOIN dbo.SERVICES_TYPES AS st 
					ON st.service_id = s.id
					AND st.tip_id = o.tip_id
				WHERE (o.occ = @Occ1)
				AND (p.account_one = 0
				OR p.account_one IS NULL)
				AND (o.tip_id = @Tip_Id
				OR @Tip_Id IS NULL)

	END
	ELSE
	BEGIN
		SELECT
			@Tip_Id = tip_id
			,@Total_sq = TOTAL_SQ
			,@build_id = f.bldn_id
		FROM dbo.OCC_HISTORY AS oh 
		JOIN dbo.FLATS AS f 
			ON oh.flat_id = f.id
		WHERE occ = @Occ1
		AND fin_id = @Fin_Id1

		INSERT INTO @T
		(	occ
			,short_name
			,short_id
			,service_id
			,sup_id
			,tarif
			,kol
			,koef
			,saldo
			,value
			,added1
			,paid
			,debt
			,sort_no
			,mode_id
			,unit_id
			,service_id_from
			,is_build
			,subsid_only
			,tip_id
			,VSODER
			,VYDEL
			,OWNER_ID
			,[service_name])
				SELECT
                           o.occ
					,      s.short_name
					,      CASE
                               WHEN len(st.short_id) > 0 THEN st.short_id
                               ELSE u.short_id
                               END as short_id
					,      s.id
					,      p.sup_id
					,      p.tarif
					,ROUND(p.kol, CASE
                                            WHEN u.precision = 0 THEN 4
                                            ELSE u.precision
                    END) AS kol
					,p.koef
					,COALESCE(p.saldo, 0)
					,COALESCE(p.value, 0)
					,COALESCE(p.added, 0)
					,COALESCE(p.paid, 0)
					,COALESCE(p.debt, 0)
					,s.sort_no
					,p.mode_id
					,p.unit_id
					,CASE
						WHEN s.serv_from IS NULL THEN NULL
						ELSE SUBSTRING(s.serv_from, 1, 4)
					END
					,s.is_build
					,COALESCE(p.subsid_only, 0)
					,o.tip_id
					,COALESCE(st.VSODER, 0)
					,COALESCE(st.VYDEL, 0)
					,COALESCE(st.OWNER_ID, 0)
					,COALESCE(st.service_name, '')
				FROM dbo.OCC_HISTORY AS o 
				CROSS JOIN dbo.SERVICES AS s 
				LEFT JOIN dbo.PAYM_HISTORY AS p 
					ON o.occ = p.occ
					AND o.fin_id = p.fin_id
					AND s.id = p.service_id
					AND (p.account_one = 0
					OR p.account_one IS NULL) --AND (p.subsid_only = 0)
				LEFT JOIN dbo.SERVICE_UNITS AS su 
					ON s.id = su.service_id
					AND o.ROOMTYPE_ID = su.ROOMTYPE_ID
					AND (o.fin_id = su.fin_id)
					AND (o.tip_id = su.tip_id)
				LEFT JOIN dbo.UNITS AS u 
					ON su.unit_id = u.id
				LEFT JOIN dbo.SERVICES_TYPES AS st 
					ON st.service_id = s.id
					AND st.tip_id = o.tip_id
				WHERE (o.fin_id = @Fin_Id1)
				AND (o.occ = @Occ1)
				AND (o.tip_id = @Tip_Id
				OR @Tip_Id IS NULL)

		-- Обновляем ед.измерения если у режима другой
		UPDATE t
		SET short_id = u.short_id
		FROM @T AS t
		JOIN CONS_MODES_HISTORY AS cm 
			ON t.mode_id = cm.mode_id
		JOIN dbo.UNITS AS u 
			ON cm.unit_id = u.id
		WHERE cm.fin_id = @Fin_Id1

		-- если есть сохранённая ед.измерения
		UPDATE t
		SET short_id = u.short_id
		FROM @T AS t
		JOIN dbo.UNITS AS u 
			ON t.unit_id = u.id
		WHERE t.unit_id IS NOT NULL
	END

	UPDATE t
	SET	VSODER			= COALESCE(sb.VSODER, 0)
		,VYDEL			= COALESCE(sb.VYDEL, 0)
		,OWNER_ID_BUILD	= COALESCE(sb.OWNER_ID, 0)
	FROM @T AS t
	JOIN dbo.SERVICES_BUILD AS sb 
		ON t.service_id = sb.service_id
	WHERE sb.build_id = @build_id

	-- Подставляем общее наименование
	UPDATE t
	SET service_name = COALESCE(sb.service_name, '')
	FROM @T AS t
	JOIN dbo.SERVICES_TYPES AS sb 
		ON t.OWNER_ID = sb.id
	WHERE sb.tip_id = @Tip_Id

	UPDATE t
	SET service_name = COALESCE(sb.service_name, '')
	FROM @T AS t
	JOIN dbo.SERVICES_BUILD AS sb 
		ON t.OWNER_ID_BUILD = sb.id
	WHERE sb.build_id = @build_id

	-- Проставляяем ед.измерения, где нет
	UPDATE t
	SET	unit_id		= U.id
		,short_id	= U.short_id
	FROM @T AS t
	JOIN dbo.SERVICE_UNITS SU 
		ON SU.service_id = t.service_id
	JOIN dbo.UNITS U 
		ON U.id = SU.unit_id
	WHERE t.short_id IS NULL
	AND SU.ROOMTYPE_ID = 'отдк'
	AND SU.fin_id = @Fin_Id1
	AND SU.tip_id = t.tip_id

	UPDATE @T
	SET	value	= 0
		,kol	= 0
		,paid	= 0
		,tarif	= 0
	WHERE subsid_only = 1

	UPDATE @T
	SET	sup_id	= 0
	WHERE sup_id IS NULL

	-- Субсидии 12%   *******************************
	UPDATE t
	SET added12 = t2.value
	FROM @T AS t
	JOIN (SELECT
			vp.service_id
			,vp.sup_id
			,value = SUM(vp.value)
		FROM dbo.View_ADDED_LITE AS vp 
		WHERE vp.occ = @Occ1
		AND vp.fin_id = @Fin_Id1
		AND vp.add_type = 15
		GROUP BY	vp.service_id
					,vp.sup_id) AS t2
		ON t.service_id = t2.service_id
		AND t.sup_id = t2.sup_id
	--*******************************************************

	--select * from @t order by sort_no

	-- Если есть группы услуг 
	--IF EXISTS(SELECT * FROM dbo.SERVICES_TYPES AS st WHERE st.tip_id=@Tip_Id AND st.service_id IS null)	
	--BEGIN
	--END

	IF @Occ1 = 700073654
	BEGIN
		UPDATE t
		SET	OWNER_ID		= 82
			,service_name	= 'Содержание жилья'
			,VYDEL			= 0
		FROM @T t
		WHERE t.service_id IN ('упрд', 'упрв')
	END

	SELECT
		@NamesOdeRhoUsing = NameSoderHousing
	FROM dbo.OCCUPATION_TYPES
	WHERE id = @Tip_Id

	IF @NamesOdeRhoUsing IS NULL
		OR @NamesOdeRhoUsing = ''
		SET @NamesOdeRhoUsing = 'С.жилья в т.ч:'

	---- Удаляем тариф если нет начислений
	UPDATE t
	SET tarif = 0
	FROM @T AS t
	WHERE value = 0
	AND paid = 0
	AND kol_dom = 0

	-- бывает что электричества нет , а Эл.энергия на ОДН есть
	IF NOT EXISTS (SELECT
				1
			FROM @T
			WHERE service_id = 'элек')
		INSERT INTO @T
		(	occ
			,short_name
			,short_id
			,service_id)
		VALUES (@Occ1
				,'Эл.энергия'
				,'кВтч'
				,'элек')

	IF @Debug = 1
		SELECT
			'T1'
			,*
		FROM @T

	-- Заполняем общедомовые колонки
	UPDATE t1
	SET	tarif		=
			CASE
				WHEN t1.tarif = 0 AND
				t2.tarif > 0 THEN t2.tarif
				ELSE t1.tarif
			END
		,kol_dom	= COALESCE(t2.kol, 0)
		,value_dom	= t2.value
		,paid_dom	= t2.paid
		,added1		= t1.added1 + t2.added
		,added12	= t1.added12 + t2.added12
	FROM @T AS t1
	JOIN (SELECT
			g.occ
			,g.sup_id
			,g.service_id_from
			,g.tarif
			,kol = SUM(g.kol)
			,value = SUM(g.value)
			,paid = SUM(g.paid)
			,added = SUM(g.added)
			,added12 = SUM(g.added12)
		FROM @T AS g
		WHERE g.is_build=1
		GROUP BY	g.occ
					,g.sup_id
					,g.service_id_from
					,g.tarif) AS t2
		ON t1.service_id = t2.service_id_from
		AND t1.occ = t2.occ
		AND t1.sup_id = t2.sup_id
	WHERE (t2.value > 0)
	OR (t2.tarif > 0)
	OR (t2.kol > 0)
	OR (t2.added <> 0)

	IF @Debug = 1
		SELECT
			'T2'
			,*
		FROM @T

	INSERT INTO @T
	(	occ
		,short_name
		,short_id
		,service_id
		,tarif
		,kol
		,koef
		,saldo
		,value
		,added1
		,added12
		,paid
		,debt
		,sort_no
		,kol_dom
		,value_dom
		,paid_dom)
			SELECT
				occ
				,service_name
				,t.short_id
				,'итог'
				,tarif =
					CASE
						WHEN short_id = 'м2' THEN SUM(tarif)
						ELSE MAX(tarif)
					END
				,kol =
					CASE
						WHEN short_id = 'м2' THEN @Total_sq
						ELSE SUM(kol)
					END
				,1
				,SUM(saldo)
				,SUM(value)
				,SUM(added1)
				,SUM(added12)
				,SUM(paid)
				,SUM(debt)
				,sort_no =
					CASE
						WHEN short_id = 'м2' THEN 1
						ELSE 2
					END
				,SUM(kol_dom)
				,SUM(value_dom)
				,SUM(paid_dom)
			FROM @T AS t
			WHERE t.OWNER_ID <> 0
			GROUP BY	occ
						,service_name
						,t.short_id
						,t.OWNER_ID
						,t.short_id

		IF @Db_Name = 'KOMP'
			AND @Tip_Id = 57  -- жил.фонд
			DELETE FROM @T
			WHERE (paid_dom = 0
				AND value = 0
				AND added = 0
				AND paid = 0)
				AND VYDEL = 0
		ELSE
			DELETE FROM @T
			WHERE (paid_dom = 0
				AND value = 0
				AND added = 0
				AND paid = 0)

	IF @Debug = 1
		SELECT
			'T3'
			,*
		FROM @T

	--INSERT INTO @T
	--(	occ
	--	,short_name
	--	,short_id
	--	,service_id
	--	,tarif
	--	,kol
	--	,koef
	--	,saldo
	--	,value
	--	,added1
	--	,paid
	--	,debt
	--	,sort_no)
	--	SELECT
	--		occ
	--		,@NamesOdeRhoUsing
	--		,'м2'
	--		,'итог'
	--		,SUM(COALESCE(tarif, 0))
	--		,kol = @Total_sq --SUM(kol)
	--		,1
	--		,SUM(saldo)
	--		,SUM(value)
	--		,SUM(added)
	--		,SUM(paid)
	--		,SUM(debt)
	--		,sort_no = 0
	--	FROM @T AS t
	--	WHERE VSODER = 1
	--	GROUP BY occ

	DELETE t
		FROM @T AS t
	WHERE VSODER = 1
		AND VYDEL = 0

	DELETE t
		FROM @T AS t
	WHERE t.OWNER_ID <> 0
		AND VYDEL = 0

	UPDATE @T
	SET	paid	= 0
		,is_sum	= 0
	FROM @T AS t
	WHERE VSODER = 1
	AND VYDEL = 1

	-- Изменяем если есть названия услуг по разным типам фонда
	UPDATE t
	SET	short_name	= st.service_name
		,t.short_id	=
			CASE
				WHEN LTRIM(COALESCE(st.short_id, '')) <> '' THEN st.short_id
				ELSE t.short_id
			END
	FROM @T AS t
	JOIN dbo.SERVICES_TYPES AS st 
		ON t.service_id = st.service_id
	WHERE st.tip_id = @Tip_Id

	-- Изменяем если есть названия услуг по разным домам
	UPDATE t
	SET short_name = sb.service_name
	FROM @T AS t
	JOIN dbo.SERVICES_BUILD AS sb 
		ON t.service_id = sb.service_id
	WHERE sb.build_id = @build_id


	-- Услугу Эл.энергия МОП выводим в Общедомовых нуждах
	IF @Db_Name NOT IN ('KR1', 'ARX_KR1')
		UPDATE t1
		SET	kol			= 0
			,value		= 0
			,paid		= 0
			,kol_dom	= COALESCE(t2.kol, 0)
			,value_dom	= t2.value
			,paid_dom	= t2.paid
		FROM @T AS t1
		JOIN @T AS t2
			ON t1.service_id = t2.service_id
		WHERE t1.service_id IN ('элмп', 'элм2')
	--

	DELETE FROM @T
	WHERE is_build = 1 --OR (value=0 AND added=0 AND paid=0)

	IF NOT EXISTS (SELECT
				1
			FROM @T)
	BEGIN
		INSERT INTO @T
		(	occ
			,short_name)
		VALUES (@Occ1
				,'')
	END

	-- дорабатываем сортировку в группированых полях
	UPDATE t
	SET sort_no = sort_no * 100
	FROM @T AS t

	UPDATE t
	SET sort_no = t2.sort_no + 1
	FROM @T AS t
	JOIN @T AS t2
		ON t.service_name = t2.short_name
	--************************************************

	SELECT
		*
	FROM @T
	ORDER BY sort_no
go

