-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[ka_add_people_tmp_out]
(
	@owner_id	INT
	,@data1		SMALLDATETIME
	,@data2		SMALLDATETIME
	,@doc		VARCHAR(100)
	,@debug		BIT	= 0
	,@is_noliving BIT = 1
)
AS
/*
Пример запуска:
 [dbo].[ka_add_people_tmp_out]	@owner_id = 49804,@data1 = '20111203',@data2 = '20120110', @doc='', @debug=1
 [dbo].[ka_add_people_tmp_out]	@owner_id = 49804,@data1 = '20120103',@data2 = '20120110', @doc='Тест', @debug=1   
 [dbo].[ka_add_people_tmp_out]	@owner_id = 1072170,@data1 = '20140901',@data2 = '20141016', @doc='Тест', @debug=1   
 
*/
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE	@occ1			INT
			,@status2_id	VARCHAR(10)
			,@tip_id		SMALLINT
			,@Intitials		VARCHAR(50)
			,@fin_current	SMALLINT
			,@build_id		INT
			,@flag			SMALLINT = -1

	SET @is_noliving=COALESCE(@is_noliving, 1)
	IF @is_noliving=0
		SET @flag=1

	SELECT
		@occ1 = p.occ
		,@status2_id = status2_id
		,@tip_id = O.tip_id
		,@Intitials = CONCAT(RTRIM(Last_name),' ',LEFT(First_name,1),'. ',LEFT(Second_name,1),'.')
		,@fin_current = b.fin_current
		,@build_id = f.bldn_id
	FROM dbo.PEOPLE AS p 
	JOIN dbo.OCCUPATIONS AS O 
		ON p.occ = O.occ
	JOIN dbo.FLATS AS f 
		ON O.flat_id = f.id
	JOIN dbo.Buildings AS b ON 
		f.bldn_id=b.id
	WHERE 
		p.id = @owner_id

	DECLARE	@fin_start	SMALLINT
			,@fin_end	SMALLINT
	SELECT
		@fin_start = fin_id
	FROM dbo.Global_values 
	WHERE @data1 BETWEEN start_date AND end_date

	IF @fin_start IS NULL
	BEGIN
		RAISERROR ('Фин.период не найден (%s)', 16, 1, 'Дата начала')
		RETURN
	END

	SELECT
		@fin_end = fin_id
	FROM dbo.Global_values 
	WHERE @data2 BETWEEN start_date AND end_date

	IF @fin_end IS NULL
	BEGIN
		RAISERROR ('Фин.период не найден (%s)', 16, 1, 'Дата окончания')
		RETURN
	END

	IF @debug = 1
		SELECT
			@occ1 AS occ
			,@status2_id AS status2_id
			,@fin_start AS fin_start
			,@fin_end AS fin_end
			,@tip_id AS tip_id
			,@build_id AS build_id

	DECLARE @t_fin TABLE
		(
			fin_id		SMALLINT
			,kolday		SMALLINT
			,kolday_fin	SMALLINT
			,data1		SMALLDATETIME
			,data2		SMALLDATETIME
		)

	INSERT INTO @t_fin
	(	fin_id
		,kolday
		,kolday_fin
		,data1
		,data2)
			SELECT
				fin_id
				,kol_day =
					CASE
						WHEN @data1 BETWEEN start_date AND end_date AND
						@data2 BETWEEN start_date AND end_date THEN DATEDIFF(DAY, @data1, @data2) + 1
						WHEN @data1 BETWEEN start_date AND end_date THEN DATEDIFF(DAY, @data1, end_date) + 1
						WHEN @data2 BETWEEN start_date AND end_date THEN DATEDIFF(DAY, start_date, @data2) + 1
						ELSE DATEDIFF(DAY, start_date, end_date) + 1
					END
				,KolDayFinPeriod --datediff(DAY, start_date, end_date) + 1
				,data1 =
					CASE
						WHEN @data1 BETWEEN start_date AND end_date THEN @data1
						ELSE start_date
					END
				,data2 =
					CASE
						WHEN @data2 BETWEEN start_date AND end_date THEN @data2
						ELSE end_date
					END
			FROM dbo.GLOBAL_VALUES 
			WHERE fin_id BETWEEN @fin_start AND @fin_end

	IF @debug = 1
		SELECT
			'@t_fin', *
		FROM @t_fin

	DECLARE @t_add TABLE
		(
			fin_id			SMALLINT
			,tarif			DECIMAL(10, 4)
			,service_id		VARCHAR(10)
			,sup_id			INT
			,unit_id		VARCHAR(10)
			,kolday			DECIMAL(4, 2)
			,koldayNo		DECIMAL(4, 2)	DEFAULT 0 -- кол-во дней с недопоставкой
			,kolday_fin		SMALLINT
			,koef_day		DECIMAL(6, 4)
			,norma_singl	DECIMAL(11, 6)
			,sum_add		DECIMAL(9, 2)
			,comments		VARCHAR(100)	DEFAULT ''
			,metod			TINYINT
			,value			DECIMAL(9, 2)
			,kol			DECIMAL(11, 6)
			,kol_add		DECIMAL(11, 6)	DEFAULT 0
			,kol_people		TINYINT			DEFAULT 0
			,mode_id		INT
			,kol_add2		DECIMAL(11, 6)	DEFAULT 0
			,source_id INT DEFAULT 0
		)

	if @is_noliving=1  -- отсутствие
	INSERT INTO @t_add
	(	fin_id
		,tarif
		,service_id
		,sup_id
		,unit_id
		,kolday
		,koldayNo
		,kolday_fin
		,koef_day
		,norma_singl
		,sum_add
		,metod
		,value
		,kol
		,kol_people
		,mode_id
		,source_id)
			SELECT
				p.fin_id
				,p.tarif
				,p.service_id
				,p.sup_id
				,unit_id
				,kolday
				,dbo.Fun_GetKolDayNo_Serv(@occ1, p.service_id, tf.data1, tf.data2)
				,kolday_fin
				,0
				,norma_singl =
					CASE
						WHEN p.service_id IN ('тепл') THEN (SELECT TOP 1
								b.norma_gkal_gvs
							FROM dbo.BUILDINGS AS b
							WHERE id = @build_id)
						WHEN dbo.Fun_GetNormaSingle(unit_id, p.mode_id, p.is_counter, @tip_id, p.fin_id) = 0 THEN dbo.Fun_GetNormaSingle(unit_id, p.mode_id, 1, @tip_id, p.fin_id)
						ELSE dbo.Fun_GetNormaSingle(unit_id, p.mode_id, p.is_counter, @tip_id, p.fin_id)
					END
				--,norma_singl = dbo.Fun_GetNormaSingle(unit_id, cl.mode_id, 1, @tip_id, p.fin_id)
				,sum_add = 0
				,COALESCE(metod, 0)
				,value
				,kol
				,kol_people = COALESCE((SELECT
						COUNT(DISTINCT owner_id)
					FROM dbo.View_PEOPLE_ALL AS P2 
					JOIN dbo.PERSON_CALC AS PC2 
						ON P2.status2_id = PC2.status_id
					WHERE P2.fin_id = p.fin_id
					AND P2.occ = @occ1 --p.occ
					AND PC2.service_id = p.service_id
					AND PC2.have_paym = 1)
				, 0)
				,p.mode_id
				,p.source_id
			FROM dbo.View_PAYM AS p
			JOIN @t_fin AS tf
				ON p.fin_id = tf.fin_id
			JOIN dbo.View_PEOPLE_ALL AS P1 
				ON P1.fin_id = p.fin_id 
				AND p1.occ=p.occ
				AND p1.id=@owner_id
			JOIN dbo.PERSON_CALC AS pc 
				ON p.service_id = pc.service_id 
				AND PC.status_id=P1.status2_id
			WHERE p.occ = @occ1
			AND (unit_id IN ('люди', 'кубм', 'квтч','ктон','ротко')
			OR (p.service_id IN ('тепл')))
			--AND pc.status_id = @status2_id
			AND pc.have_paym = 1
			AND p.is_counter = 0
			AND p.value > 0
			AND p.is_build=0

if @is_noliving=0 -- присутствие
	INSERT INTO @t_add
	(	fin_id
		,tarif
		,service_id
		,sup_id
		,unit_id
		,kolday
		,koldayNo
		,kolday_fin
		,koef_day
		,norma_singl
		,sum_add
		,metod
		,value
		,kol
		,kol_people
		,mode_id
		,source_id)
			SELECT
				p.fin_id
				,p.tarif
				,p.service_id
				,p.sup_id
				,unit_id
				,kolday
				,dbo.Fun_GetKolDayNo_Serv(@occ1, p.service_id, tf.data1, tf.data2)
				,kolday_fin
				,0
				,norma_singl =
					CASE
						WHEN p.service_id IN ('тепл') THEN (SELECT TOP 1
								b.norma_gkal_gvs
							FROM dbo.BUILDINGS AS b 
							WHERE id = @build_id)
						WHEN dbo.Fun_GetNormaSingle(unit_id, p.mode_id, p.is_counter, @tip_id, p.fin_id) = 0 THEN dbo.Fun_GetNormaSingle(unit_id, p.mode_id, 1, @tip_id, p.fin_id)
						ELSE dbo.Fun_GetNormaSingle(unit_id, p.mode_id, p.is_counter, @tip_id, p.fin_id)
					END
				--,norma_singl = dbo.Fun_GetNormaSingle(unit_id, cl.mode_id, 1, @tip_id, p.fin_id)
				,sum_add = 0
				,COALESCE(metod, 0)
				,value
				,kol
				,kol_people = COALESCE((SELECT
						COUNT(DISTINCT owner_id)
					FROM dbo.View_PEOPLE_ALL AS P2 
					JOIN dbo.PERSON_CALC AS PC2 
						ON P2.status2_id = PC2.status_id
					WHERE P2.fin_id = p.fin_id
					AND P2.occ = @occ1 --p.occ
					AND PC2.service_id = p.service_id
					AND PC2.have_paym = 1)
				, 0)
				,p.mode_id
				,p.source_id
			FROM dbo.View_PAYM AS p
			JOIN @t_fin AS tf
				ON p.fin_id = tf.fin_id
			JOIN dbo.View_PEOPLE AS P1 
				ON p1.occ=p.occ
				AND p1.id=@owner_id
			JOIN dbo.PERSON_CALC AS pc 
				ON p.service_id = pc.service_id 
				AND PC.status_id=P1.status2_id
			WHERE p.occ = @occ1
			AND (unit_id IN ('люди', 'кубм', 'квтч','ктон','ротко')
			OR (p.service_id IN ('тепл')))
			--AND pc.status_id = @status2_id
			AND pc.have_paym = 1
			AND p.is_counter = 0
			--AND p.value > 0
			AND p.is_build=0

	IF @debug = 1
		SELECT
			'@t_add', *
		FROM @t_add

	UPDATE t
	SET	koef_day		=
			CASE
				WHEN kolday > koldayNo THEN (CAST((kolday - koldayNo) AS DECIMAL(6, 4)) / kolday_fin)
				ELSE 0
			END
		,norma_singl	=
			CASE
				WHEN unit_id = 'кубм' AND
				service_id = 'вотв' THEN (SELECT
						SUM(norma_singl)
					FROM @t_add
					WHERE service_id IN ('хвод', 'хвс2', 'гвод', 'гвс2')
					AND fin_id = t.fin_id)
				WHEN unit_id = 'квтч' AND
				service_id = 'элмп' THEN dbo.Fun_GetNormaSingle(unit_id, t.mode_id, 0, @tip_id, t.fin_id)
				ELSE norma_singl
			END
	FROM @t_add AS t

	UPDATE @t_add
	SET kol = kol / kol_people
	WHERE kol_people <> 0

	UPDATE @t_add
	SET kol_add2 = @flag * kol * koef_day
	WHERE kol <> 0

	UPDATE @t_add
	SET kol_add =
		CASE
			WHEN unit_id = 'люди' THEN CAST((@flag * koef_day) AS DECIMAL(9, 4))
			WHEN (unit_id = 'кубм') AND
			metod = 4 THEN -- был расчет по ОПУ
			CAST((@flag * koef_day) AS DECIMAL(9, 4))
			WHEN unit_id = 'кубм' THEN CAST((@flag * norma_singl * koef_day) AS DECIMAL(9, 4))
			WHEN unit_id in ('ктон','ротко') THEN CAST((@flag * norma_singl * koef_day) AS DECIMAL(12, 6))
			WHEN (unit_id = 'квтч') AND
			(service_id = 'элмп') AND
			metod IS NULL THEN CAST((@flag * norma_singl * koef_day) AS DECIMAL(9, 4))
			ELSE 0
		END

	UPDATE t1
	SET kol_add = t2.kol_add * t1.norma_singl
	FROM @t_add AS t1
	JOIN @t_add AS t2
		ON t1.fin_id = t2.fin_id
	WHERE t1.service_id = 'тепл'
	AND t2.service_id IN ('гвод', 'гвс2')

	--SELECT * FROM @t_add

	UPDATE @t_add
	SET	sum_add		=
			CASE
				WHEN (unit_id = 'кубм') AND	service_id IN ('вотв', 'вот2') 
					THEN CAST((tarif * kol_add2) AS DECIMAL(9, 2))
				WHEN unit_id IN ('люди', 'кубм', 'квтч','ктон','ротко') AND	metod <> 4 
					THEN CAST((tarif * kol_add) AS DECIMAL(9, 2))
				WHEN (unit_id = 'кубм') AND	metod = 4 -- был расчет по ОПУ
					THEN CAST((value / kol_people * kol_add) AS DECIMAL(9, 2))
				WHEN service_id IN ('тепл') 
					THEN CAST((tarif * kol_add) AS DECIMAL(9, 2))				
				ELSE 0
			END
		,comments	=
			CASE
				WHEN (unit_id = 'кубм') AND	service_id IN ('вотв', 'вот2') 
					THEN 'дн.:' + LTRIM(STR(kolday - koldayNo, 4, 1)) + ' кол.:' + STR(kol_add2, 6, 4) + '*тариф:' + STR(tarif, 6, 3)
				WHEN unit_id = 'люди' 
					THEN 'дн.:' + LTRIM(STR(kolday - koldayNo, 4, 1)) + ' тариф:' + STR(tarif, 6, 4)
				WHEN (unit_id = 'кубм') AND	metod = 4 
					THEN 'дн.:' + LTRIM(STR(kolday - koldayNo, 4, 1)) + ' кол.в день:' + STR(kol / kolday_fin, 6, 4)
				WHEN unit_id IN ('кубм', 'квтч','ктон','ротко') 
					THEN 'дн.:' + LTRIM(STR(kolday - koldayNo, 4, 1)) + ' норма:' + dbo.FSTR(norma_singl, 6, 4) + '=' + dbo.FSTR(kol_add, 8, 6) + '*тариф:' + STR(tarif, 6, 3)
				WHEN service_id IN ('тепл') 
					THEN 'тариф:' + STR(tarif, 6, 4) + ' * кол.:' + STR(kol_add, 6, 4)
				ELSE ''
			END

	--UPDATE @t_add
	--SET
	--	sum_add = (SELECT sum(coalesce(kol_add,0)) FROM @t_add WHERE service_id IN ('хвод','гвод','гвс2'))*tarif 
	--	,comments = 'сумма гвс и хвс: '+str((SELECT sum(coalesce(kol_add,0)) FROM @t_add WHERE service_id IN ('хвод','гвод','гвс2')),6,3)+ ' * тариф:' +str(tarif, 6, 3)
	--WHERE service_id='вотв'	AND unit_id = 'кубм'

	-- блокируем расчёт по поставщику кому не начисляем
	UPDATE t1
	SET	value	= 0
		,kol	= 0
		,sum_add= 0
	--IF @debug=1 SELECT *
	FROM @t_add AS t1
	JOIN SUPPLIERS s 
		ON t1.source_id=s.id AND t1.service_id = s.service_id
	JOIN dbo.SUPPLIERS_TYPES AS ST 
		ON (t1.service_id = ST.service_id OR ST.service_id='')
		AND s.sup_id = ST.sup_id
	WHERE ST.tip_id = @tip_id
	--AND t1.sup_id > 0
	AND (ST.paym_blocked = 1 OR st.add_blocked=1);
 
	IF @debug = 1
		SELECT
			*
		FROM @t_add

	IF EXISTS (SELECT
				1
			FROM @t_add
			WHERE sum_add <> 0)
	BEGIN
		DECLARE	@sum_add		DECIMAL(9, 2)
				,@service_id	VARCHAR(10)
				,@user_id		SMALLINT
				,@comments		VARCHAR(100)
				,@sup_id		INT
		SELECT
			@user_id = dbo.Fun_GetCurrentUserId()

		DECLARE curs CURSOR LOCAL LOCAL FOR
			SELECT
				service_id
				,sup_id
				,SUM(sum_add)
			FROM @t_add
			GROUP BY	service_id
						,sup_id
			HAVING SUM(sum_add) <> 0
		OPEN curs
		FETCH NEXT FROM curs INTO @service_id, @sup_id, @sum_add

		WHILE (@@fetch_status = 0)
		BEGIN
			SELECT
				@comments = NULL;
			SELECT
				@comments = COALESCE(@comments + '; ', '') + comments
			FROM @t_add
			WHERE service_id = @service_id
			AND COALESCE(comments,'')<>''

			IF @debug = 1
				PRINT @service_id + ' = ' + @comments

			-- Проверяем есть ли разовый такого типа

			-- Добавить Разовые	
			INSERT dbo.ADDED_PAYMENTS
			(	occ
				,service_id
				,sup_id
				,add_type
				,value
				,doc_no
				,doc
				,comments
				,dsc_owner_id
				,user_edit
				,data1
				,data2
				,fin_id)
			VALUES (@occ1
					,@service_id
					,@sup_id
					,3
					,@sum_add
					,'888'
					,@doc
					,@comments
					,@owner_id
					,@user_id
					,@data1
					,@data2
					,@fin_current)

			UPDATE pl
			SET Added = COALESCE(
				(SELECT
					SUM(value)
				FROM dbo.Added_Payments AS ap
				WHERE 
					ap.occ = pl.occ
					AND ap.service_id = pl.service_id
					AND ap.fin_id = pl.fin_id)
				, 0)
			FROM dbo.Paym_list AS pl
			WHERE 
				pl.occ = @occ1
				AND pl.fin_id = @fin_current

			IF @debug = 1
				SELECT
					@service_id
					,@sup_id
					,@sum_add
					,@comments

			FETCH NEXT FROM curs INTO @service_id, @sup_id, @sum_add
		END
		CLOSE curs;
		DEALLOCATE curs;

		EXEC k_write_log	@occ1
							,'раз!'
							,@Intitials
	END

END
go

