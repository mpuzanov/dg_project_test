CREATE   PROCEDURE [dbo].[k_intPrintDetail]
(
	@fin_id1	SMALLINT
	,@occ1		INT				= 0
	,@build		INT				= 0 -- Код дома
	,@jeu		SMALLINT		= 0 -- Участок
	,@tip_id		SMALLINT		= NULL -- жилой фонд
	,@ops		INT				= 0 --ops
	,@notocc		SMALLINT		= 0
	,@sum_dolg	DECIMAL(9, 2)	= 0 -- если не равно 0 вывод только с долгом более этой суммы
	,@group_id	INT				= 0
	,@col1		SMALLINT		= 1 -- колонка
)
AS
	/*
	Выдаем информацию по услугам для единой квитанции
	
	*/
	SET NOCOUNT ON

	DECLARE @fin_current1 SMALLINT
	SELECT
		@fin_current1 = dbo.Fun_GetFinCurrent(@tip_id, @build, NULL, @occ1)

	DECLARE @t_occ TABLE
		(
			occ		INT
			,tip_id	SMALLINT
		)

	IF @build > 0
	BEGIN
		INSERT
		INTO @t_occ
		(	occ
			,tip_id)
			SELECT
				occ
				,o.tip_id
			FROM dbo.OCCUPATIONS AS o 
			JOIN FLATS AS f 
				ON o.flat_id = f.id
			WHERE f.bldn_id = @build
			AND o.status_id <> 'закр'
			AND NOT EXISTS (SELECT 1					
				FROM dbo.OCC_NOT_print AS onp
				WHERE onp.flag = 1
				AND onp.occ = o.occ)
		GOTO LABEL1
	END

	IF @jeu > 0
	BEGIN
		INSERT
		INTO @t_occ
		(	occ
			,tip_id)
			SELECT
				occ
				,o.tip_id
			FROM dbo.OCCUPATIONS AS o 
			JOIN dbo.FLATS AS f 
				ON o.flat_id = f.id
			JOIN dbo.BUILDINGS AS b 
				ON f.bldn_id = b.id
			WHERE b.sector_id = @jeu
			AND (o.status_id <> 'закр'
			OR o.proptype_id = 'арен')
			AND NOT EXISTS (SELECT
					*
				FROM dbo.OCC_NOT_print AS onp
				WHERE onp.flag = 1
				AND onp.occ = o.occ)
		GOTO LABEL1
	END

	IF @ops > 0
	BEGIN
		INSERT
		INTO @t_occ
		(	occ
			,tip_id)
			SELECT
				occ
				,o.tip_id
			FROM dbo.OCCUPATIONS AS o 
			JOIN dbo.FLATS AS f 
				ON o.flat_id = f.id
			JOIN dbo.BUILDINGS AS b 
				ON f.bldn_id = b.id
			WHERE b.index_id = @ops
			AND (o.status_id <> 'закр'
			OR o.proptype_id = 'арен')
			AND NOT EXISTS (SELECT
					*
				FROM dbo.OCC_NOT_print AS onp
				WHERE onp.flag = 1
				AND onp.occ = o.occ)
		GOTO LABEL1
	END

	IF @notocc > 0
	BEGIN
		INSERT
		INTO @t_occ
		(	occ
			,tip_id)
			SELECT
				onp.occ
				,o.tip_id
			FROM dbo.OCC_NOT_print AS onp 
			JOIN dbo.OCCUPATIONS AS o 
				ON onp.occ = o.occ
			WHERE onp.flag = 0
		GOTO LABEL1
	END

	IF @group_id > 0
	BEGIN
		INSERT
		INTO @t_occ
		(	occ
			,tip_id)
			SELECT DISTINCT
				po.occ
				,o.tip_id
			FROM dbo.PRINT_OCC AS po 
			JOIN dbo.OCCUPATIONS AS o 
				ON po.occ = o.occ
			WHERE po.group_id = @group_id
		GOTO LABEL1
	END

	IF @occ1 > 0
	BEGIN
		INSERT
		INTO @t_occ
		(	occ
			,tip_id)
			SELECT
				occ
				,o.tip_id
			FROM dbo.OCCUPATIONS AS o 
			WHERE occ = @occ1
			AND o.status_id <> 'закр'
	END

LABEL1:

	DECLARE @t TABLE
		(
			occ			INT
			,short_name	VARCHAR(20)
			,short_id	VARCHAR(6)
			,service_id	VARCHAR(10)
			,tarif		DECIMAL(10, 4)
			,kol		DECIMAL(9, 2)
			,koef		DECIMAL(10, 4)
			,fullvalue	DECIMAL(9, 2)
			,value		DECIMAL(9, 2)
			,discount	DECIMAL(9, 2)
			,added		DECIMAL(9, 2)
			,compens	DECIMAL(9, 2)
			,paid		DECIMAL(9, 2)
			,sort_no	TINYINT
			,mode_id	INT
		)

	IF @fin_id1 >= @fin_current1
	BEGIN

		SELECT
			@tip_id = tip_id
		FROM dbo.OCCUPATIONS
		WHERE occ = @occ1

		INSERT
		INTO @t
		(	occ
			,short_name
			,short_id
			,service_id
			,tarif
			,kol
			,koef
			,fullvalue
			,value
			,added
			,paid
			,sort_no
			,mode_id)
			SELECT
				p.occ
				,s.short_name
				,u.short_id
				,p.service_id
				,p.tarif
				,p.kol
				,p.koef
				,p.value
				,p.value
				,p.added
				,p.paid
				,s.sort_no
				,cl.mode_id
			FROM @t_occ AS t
			JOIN dbo.OCCUPATIONS AS o 
				ON t.occ = o.occ
			JOIN dbo.PAYM_LIST AS p 
				ON o.occ = p.occ
			JOIN dbo.SERVICES AS s 
				ON p.service_id = s.id
			JOIN dbo.SERVICE_UNITS AS su 
				ON s.id = su.service_id
				AND o.roomtype_id = su.roomtype_id
				AND o.tip_id = su.tip_id
			JOIN dbo.UNITS AS u 
				ON su.unit_id = u.id
			JOIN dbo.CONSMODES_LIST AS cl 
				ON cl.occ = o.occ
				AND p.service_id = cl.service_id
				AND p.sup_id = cl.sup_id
			WHERE (s.num_colon = @col1)
			AND (su.fin_id = @fin_id1)
			AND (p.subsid_only = 0)
			AND (p.account_one = 0
			OR p.account_one IS NULL)
			AND (p.value <> 0
			OR p.added <> 0
			OR p.paid <> 0)
			AND (o.tip_id = @Tip_Id OR @Tip_Id IS NULL)

		-- Обновляем ед.измерения если у режима другой
		UPDATE t
		SET short_id = u.short_id
		FROM @t AS t
		JOIN dbo.CONS_MODES AS cm
			ON t.mode_id = cm.id
		JOIN dbo.UNITS AS u 
			ON cm.unit_id = u.id

	END
	ELSE
	BEGIN

		SELECT
			@tip_id = tip_id
		FROM dbo.OCC_HISTORY
		WHERE occ = @occ1
		AND fin_id = @fin_id1

		INSERT
		INTO @t
		(	occ
			,short_name
			,short_id
			,service_id
			,tarif
			,kol
			,koef
			,fullvalue
			,value
			,discount
			,added
			,compens
			,paid
			,sort_no
			,mode_id)
			SELECT
				p.occ
				,s.short_name
				,u.short_id
				,p.service_id
				,p.tarif
				,p.kol
				,1 --cl.koef
				,p.value
				,p.value
				,p.discount
				,p.added
				,p.compens
				,p.paid
				,s.sort_no
				,p.mode_id
			FROM @t_occ AS t
			JOIN dbo.OCC_HISTORY AS o 
				ON t.occ = o.occ
			JOIN dbo.PAYM_HISTORY AS p 
				ON o.occ = p.occ
				AND o.fin_id = p.fin_id
			JOIN dbo.SERVICES AS s 
				ON s.id = p.service_id
			JOIN dbo.SERVICE_UNITS AS su 
				ON s.id = su.service_id
				AND o.roomtype_id = su.roomtype_id
				AND (o.fin_id = su.fin_id)
				AND (o.tip_id = su.tip_id)
			JOIN dbo.UNITS AS u 
				ON su.unit_id = u.id
			WHERE (o.fin_id = @fin_id1)
			AND (s.num_colon = @col1)
			AND (p.subsid_only = 0)
			AND (p.account_one = 0
			OR p.account_one IS NULL)
			AND (o.tip_id = @Tip_Id OR @Tip_Id IS NULL)

		-- Обновляем ед.измерения если у режима другой
		UPDATE t
		SET short_id = u.short_id
		FROM @t AS t
		JOIN dbo.CONS_MODES_HISTORY AS cm
			ON t.mode_id = cm.mode_id
		JOIN dbo.UNITS AS u 
			ON cm.unit_id = u.id
		WHERE cm.fin_id = @fin_id1
	END

	--select * from @t_occ
	--select * from @t as t

	IF @tip_id IS NULL
		SELECT TOP 1
			@tip_id = tip_id
		FROM @t_occ AS t

	IF @col1 = 1
	BEGIN
		INSERT
		INTO @t
		(	occ
			,short_name
			,short_id
			,service_id
			,tarif
			,kol
			,koef
			,fullvalue
			,value
			,discount
			,added
			,compens
			,paid
			,sort_no)
			SELECT
				occ
				,CASE
					WHEN (@tip_id IN (1, 55) AND
					@fin_id1 > 83) THEN 'Сод.и тек.ремонт:'  --'Сод.и тек.ремонт:'
					WHEN (@tip_id IN (57, 59) AND
					@fin_id1 > 83) THEN 'С.жилья,усл.УК:'
					ELSE 'С.жилья в т.ч:'
				END
				,'м2'
				,'итог'
				,SUM(tarif)
				,kol
				,1
				,SUM(fullvalue)
				,SUM(value)
				,SUM(discount)
				,SUM(added)
				,SUM(compens)
				,SUM(paid)
				,sort_no = 0
			FROM @t
			WHERE service_id IN ('площ', 'лифт', 'втбо', 'муср', 'ремт')
			GROUP BY	occ
						,kol


		UPDATE @t
		SET short_name = ' в т.ч. обсл.дом'
		WHERE service_id = 'площ'
		AND @tip_id IN (57, 59)
		AND @fin_id1 > 83
		UPDATE @t
		SET short_name = ' в т.ч. тек.ремонт'
		WHERE service_id = 'ремт'
		AND @tip_id IN (57, 59)
		AND @fin_id1 > 83


		DELETE FROM @t
		WHERE service_id IN ('площ', 'лифт', 'втбо', 'муср', 'ремт')
			AND @tip_id IN (1, 55)
			AND @fin_id1 > 83

		-- удаляем стоку обсл.дома если она равна итого (т.е. один тариф)
		DECLARE @itog DECIMAL(10, 4)
		SELECT
			@itog = tarif
		FROM @t
		WHERE service_id = 'итог'
		DELETE FROM @t
		WHERE service_id = 'площ'
			AND tarif = @itog --and @tip_id<>50
		DELETE FROM @t
		WHERE service_id IN ('площ', 'лифт', 'втбо', 'муср', 'ремт')
			AND tarif = 0

		UPDATE @t
		SET short_name = 'Сод.общего имущ.:'
		WHERE service_id IN ('итог')
		AND @tip_id = 50
		AND @fin_id1 > 83

		UPDATE @t
		SET paid = 0
		WHERE service_id IN ('площ', 'лифт', 'втбо', 'муср', 'ремт')

	END

	DELETE FROM @t
	WHERE paid = 0
		AND tarif = 0

	SELECT
		*
	FROM @t
	ORDER BY occ, sort_no
go

