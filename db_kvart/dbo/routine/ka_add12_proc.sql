-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE                       PROCEDURE [dbo].[ka_add12_proc]
(
	@build_id   INT
   ,@service_id VARCHAR(10)
   ,@debug		BIT = 0
)
AS
/*
EXEC ka_add12_proc @build_id=1,@service_id='хвод',@debug=1
EXEC ka_add12_proc @build_id=4249,@service_id='отоп',@debug=1
EXEC ka_add12_proc @build_id=5862,@service_id='гвод',@debug=1
*/
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON

	DECLARE @add_type			TINYINT		   = 15  -- тип разового "Субсидия 12% РСО"
		   ,@fin_dec			SMALLINT	   = 161 -- фин.период для сравнения  июнь 2015
		   ,@fin_dec_tarif		SMALLINT	   = 161 -- фин.период для сравнения
		   ,@DB_NAME			VARCHAR(30)	   = UPPER(DB_NAME())
		   ,@occ				INT
		   ,@Procent			DECIMAL(9, 4)  = 1.061  -- 6.1%
		   ,@Procent_tarif		DECIMAL(9, 4)  = 1.106  -- 10.6%
		   ,@Procent_tarif2		DECIMAL(9, 4)  = 1.1123 -- 11.23%
		   ,@Procent_tarif3		DECIMAL(9, 4)  = 1.057  -- 5.7%
		   ,@Procent_tarif_0119 DECIMAL(9, 4)  = 1.017  -- 1.7%      01.2019   10,6% * 6,1% * 11,23% * 5,7% * 1.7%
		   ,@Procent_tarif_0719 DECIMAL(9, 4)  = 1.06   -- 6% с 07.19
		   ,@Procent_tarif_0720 DECIMAL(9, 4)  = 1.1213 -- 12,13% с 07.20
		   ,@value				DECIMAL(9, 2)
		   ,@paid				DECIMAL(9, 2)
		   ,@value12			DECIMAL(9, 2)
		   ,@value_new			DECIMAL(9, 2)
		   ,@value_max			DECIMAL(9, 2)
		   ,@add				DECIMAL(9, 2)
		   ,@kol				DECIMAL(12, 6)
		   ,@kol_people			DECIMAL(12, 6)
		   ,@kol_odn			DECIMAL(12, 6)
		   ,@kol_odn12			DECIMAL(12, 6) -- тек.ОДН для расчёта максимального(если минус то зануляю)
		   ,@unit_id			VARCHAR(10)
		   ,@tarif				DECIMAL(10, 4)
		   ,@tarif12			DECIMAL(10, 4)
		   ,@is_counter			BIT
		   ,@norma12			DECIMAL(12, 6)
		   ,@norma				DECIMAL(12, 6)
		   ,@is_counter_build   BIT
		   ,@fin_id				SMALLINT
		   ,@mode_id			INT
		   ,@mode_id12			INT
		   ,@source_id			INT
		   ,@source_id12		INT
		   ,@serv_dom			VARCHAR(10)
		   ,@comments			VARCHAR(70)
		   ,@doc1				VARCHAR(100)   = 'Субсидия 12% РСО'
		   ,@nom_kvr			VARCHAR(20)
		   ,@tip_id				SMALLINT		   
		   ,@raschet_agri		BIT			   = 0
		   ,@value_agri			DECIMAL(9, 2)  = 0
		   ,@kol_agri			DECIMAL(12, 6) = 0
		   ,@is_history			BIT			   = 0 -- 0 нет истории по дому, 1-есть
		   ,@adres				VARCHAR(50)	   = ''
		   ,@sup_id				INT
		   ,@user_id1			SMALLINT

	SELECT
		@fin_id = dbo.Fun_GetFinCurrent(NULL, @build_id, NULL, NULL)
	   ,@user_id1 = dbo.Fun_GetCurrentUserId()

	--создаём таблицу с коэф. тарифов
	DECLARE @table_koef TABLE(val DECIMAL(9,4))
	DECLARE @ListProcTarif VARCHAR(100)='6.1;10.6;11.23;5.7;1.7;6;12.13'

	SELECT @ListProcTarif=procSubs12 FROM dbo.GLOBAL_VALUES WHERE fin_id=@fin_id

	INSERT INTO @table_koef(val)
		SELECT
			CAST(REPLACE(value,',','.') AS DECIMAL(9,4))*0.01+1
		FROM STRING_SPLIT(@ListProcTarif, ';')
		WHERE RTRIM(value) <> ''

	DECLARE @tarif_koef	DECIMAL(18,14)=(SELECT EXP(SUM(LOG(val))) FROM @table_koef)  -- произведение колонки
	--if @debug=1 select @tarif_koef AS tarif_koef, (1.061*1.106*1.1123*1.057*1.017*1.06*1.1213) AS tarif_koef2

	DROP TABLE IF EXISTS #t;

	SELECT TOP (1)
		@serv_dom = id
	FROM dbo.SERVICES S
	WHERE 
		is_build_serv = @service_id
		AND is_build = 1;

	IF @serv_dom IS NULL
		SET @serv_dom = ''
	--RETURN

	SELECT
		@tip_id = tip_id
	   ,@raschet_agri = COALESCE(OT.raschet_agri, 0)
	   ,@adres = vb.adres
	FROM dbo.View_BUILDINGS vb 
	JOIN dbo.Occupation_Types OT ON 
		vb.tip_id = OT.id
	WHERE vb.id = @build_id

	IF EXISTS (SELECT
				1
			FROM dbo.View_build_all_lite vba 
			WHERE fin_id = @fin_dec
			AND bldn_id = @build_id)
		SET @is_history = 1

	SELECT
		O.occ
	   ,F.nom_kvr
	   ,COALESCE(PL.kol, 0) AS kol
	   ,PL.unit_id
	   ,CASE
			WHEN PL.tarif = 0 THEN [dbo].[Fun_GetCounterTarfServ](@fin_id, O.occ, PL.service_id, PL.unit_id)
			ELSE PL.tarif
		END AS tarif
	   ,CASE
			WHEN o.tip_id IN (192) AND (dbo.strpos('KOMP', @DB_NAME)>0) -- Парус (нет истории)
			 THEN (SELECT TOP (1)
					COALESCE(tarif, 0)
				FROM [dbo].[RATES_COUNTER]
				WHERE fin_id = @fin_dec_tarif
				AND tipe_id = o.tip_id
				AND service_id = PL.service_id
				AND unit_id = COALESCE(PL.unit_id, unit_id)
				AND (mode_id = CL.mode_id)
				AND (source_id = CL.source_id)
				AND tarif > 0)
			WHEN o.tip_id IN (88) AND (dbo.strpos('KOMP', @DB_NAME)>0)  -- Тсж Петровский на м2
			 THEN (SELECT TOP (1)
					COALESCE(r.value, 0)
				FROM [dbo].[RATES] AS r
				WHERE 
					finperiod = @fin_dec_tarif
					AND tipe_id = o.tip_id
					AND service_id = PL.service_id
					AND (mode_id = CL.mode_id)
					AND (source_id = CL.source_id)
					AND r.value> 0)

			ELSE (SELECT TOP (1)
					COALESCE(r.value, 0)
				FROM [dbo].[RATES] AS r
				WHERE 
					finperiod = @fin_dec_tarif
					AND tipe_id = o.tip_id
					AND service_id = PL.service_id
					AND (mode_id = CL.mode_id)
					AND (source_id = CL.source_id))
		--AND r.Value > 0)					
		--[dbo].[Fun_GetCounterTarfServ](@fin_dec_tarif, O.occ, PL.service_id, PL.unit_id) -- 01/02/2017
		END AS tarif12
	   ,CASE
			WHEN (PL.is_counter = 2) OR
			(PL.metod_old IN (2, 3)) THEN 1
			ELSE 0
		END AS is_counter
	   ,CASE
			WHEN PL.unit_id = 'квтч' THEN [dbo].[Fun_GetNormaSingleEE](O.occ, PH.fin_id, PH.mode_id, O.ROOMS, O.kol_people)
			WHEN PL.unit_id = 'ггкл' THEN O.Total_sq * CASE WHEN COALESCE(b.norma_gkal,0)=0 THEN 0.021 ELSE COALESCE(b.norma_gkal,0) END
			WHEN PL.unit_id = 'гкоп' THEN O.TEPLO_SQ * CASE WHEN COALESCE(b.norma_gkal,0)=0 THEN 0.021 ELSE COALESCE(b.norma_gkal,0) END
			WHEN PL.unit_id = 'кубм' THEN dbo.Fun_GetNormaSingle(PL.unit_id, PH.mode_id, PL.is_counter, O.tip_id, PH.fin_id)
			ELSE dbo.Fun_GetNormaSingle(PL.unit_id, PH.mode_id, 1, O.tip_id, PH.fin_id)
		END AS norma12
	   ,CASE
			WHEN PL.unit_id = 'квтч' THEN [dbo].[Fun_GetNormaSingleEE](O.occ, PL.fin_id, CL.mode_id, O.ROOMS, O.kol_people)
			WHEN PL.unit_id = 'ггкл' THEN O.Total_sq * CASE WHEN COALESCE(b.norma_gkal,0)=0 THEN 0.021 ELSE COALESCE(b.norma_gkal,0) END
			WHEN PL.unit_id = 'гкоп' THEN O.TEPLO_SQ * CASE WHEN COALESCE(b.norma_gkal,0)=0 THEN 0.021 ELSE COALESCE(b.norma_gkal,0) END
			WHEN PL.unit_id = 'кубм' THEN dbo.Fun_GetNormaSingle(PL.unit_id, CL.mode_id, PL.is_counter, O.tip_id, PL.fin_id)
			ELSE dbo.Fun_GetNormaSingle(PL.unit_id, CL.mode_id, 1, O.tip_id, PL.fin_id)
		END AS norma
	   ,CASE
			WHEN EXISTS (SELECT
					1
				FROM dbo.COUNTERS C
				WHERE F.bldn_id = C.build_id
				AND C.service_id = PL.service_id
				AND C.is_build = 1
				AND C.date_del IS NULL) 
				THEN 1
			ELSE 0
		END AS is_counter_build
	   ,PL.value
	   ,PL.value AS Paid
	   ,PH.value AS value12
	   ,@serv_dom AS serv_dom
	   ,O.fin_id
	   ,COALESCE((SELECT
				kol
			FROM dbo.PAYM_LIST PL 
			WHERE occ = O.occ
			AND fin_id = O.fin_id
			AND service_id = @serv_dom)
		, 0) AS kol_odn
	   ,CL.mode_id
	   ,PH.mode_id AS mode_id12
	   ,CL.source_id
	   ,PH.source_id AS source_id12
	   ,CL.sup_id
	INTO #t
	FROM dbo.Occupations O 
	JOIN dbo.Occupation_Types OT 
		ON OT.id = O.tip_id
	JOIN dbo.FLATS F 
		ON O.flat_id = F.id
	JOIN dbo.Buildings b 
		ON F.bldn_id = b.id
	JOIN dbo.PAYM_LIST PL 
		ON O.occ = PL.occ
		AND PL.fin_id = O.fin_id
	JOIN dbo.Consmodes_list CL 
		ON CL.occ = O.occ
		AND CL.service_id = PL.service_id
		AND PL.sup_id = CL.sup_id
	LEFT JOIN dbo.Occ_history OH  --dbo.View_OCC_ALL
		ON O.occ = OH.occ
		AND OH.fin_id = @fin_dec -- декабрь 2012
	LEFT JOIN dbo.Paym_history PH 
		ON PL.occ = PH.occ
		AND PL.service_id = PH.service_id
		AND PH.fin_id = OH.fin_id
		AND PL.sup_id = PH.sup_id
	WHERE 
		F.bldn_id = @build_id
		AND PL.service_id = @service_id
		AND O.proptype_id <> 'арен'
		AND PL.unit_id NOT IN ('люди')
		AND (o.date_start IS NULL OR o.date_start<'20150701')  -- 24.07.2023

	-- удаляем если запрещён расчёт субсидии 12%
	DELETE t
		FROM #t AS t
		JOIN dbo.Suppliers_types st
			ON t.sup_id = st.sup_id
	WHERE st.tip_id = @tip_id
		AND st.service_id = @service_id
		AND sub12_blocked = CAST(1 AS BIT);


	IF @debug = 1
		SELECT
			'1' AS tarif12old
		   ,*
		FROM #t
		ORDER BY dbo.Fun_SortDom(#t.nom_kvr)

	UPDATE #t
	SET tarif12 = tarif12 * @tarif_koef --@Procent * @Procent_tarif * @Procent_tarif2 * @Procent_tarif3 * @Procent_tarif_0119 * @Procent_tarif_0719 * @Procent_tarif_0720

	UPDATE #t
	SET tarif12 = round(tarif12,2)  --29.07.2022

	IF @debug = 1
	BEGIN
		PRINT 'Услуга=' + @service_id
		PRINT 'serv_dom=' + @serv_dom
		PRINT 'tip_id=' + LTRIM(STR(@tip_id))
		PRINT 'raschet_agri=' + LTRIM(STR(@raschet_agri))

		SELECT
			'2' AS tarif12new
		   ,*
		FROM #t t
		ORDER BY dbo.Fun_SortDom(t.nom_kvr)
	END

	DELETE ap
		FROM dbo.Added_Payments ap
		JOIN dbo.Occupations O
			ON O.occ = ap.occ AND ap.fin_id = O.fin_id
		JOIN dbo.FLATS F 
			ON F.id = O.flat_id
		JOIN dbo.Occupation_Types OT
			ON O.tip_id = OT.id
	WHERE 
		F.bldn_id = @build_id
		AND ap.add_type = @add_type
		AND ap.doc_no = '888'		
		AND ap.service_id = @service_id;

	DELETE S12
		FROM dbo.Subsidia12 S12
		JOIN dbo.Occupations O 
			ON O.occ = S12.occ
		JOIN dbo.FLATS F 
			ON F.id = O.flat_id
	WHERE F.bldn_id = @build_id
		AND S12.fin_id = O.fin_id
		AND S12.service_id = @service_id;

	DECLARE cursor_name CURSOR LOCAL FOR
		SELECT
			occ
		   ,nom_kvr
		   ,kol
		   ,unit_id
		   ,tarif
		   ,tarif12
		   ,is_counter
		   ,norma12
		   ,is_counter_build
		   ,value
		   ,COALESCE(value12, 0)
		   ,fin_id
		   ,kol_odn
		   ,CASE
				WHEN norma = 0 THEN 0
				ELSE COALESCE(kol / norma, 0)
			END AS kol_people
		   ,norma
		   ,mode_id
		   ,mode_id12
		   ,source_id
		   ,source_id12
		   ,t.paid
		   ,sup_id
		FROM #t AS t
		ORDER BY dbo.Fun_SortDom(t.nom_kvr)

	OPEN cursor_name;

	FETCH NEXT FROM cursor_name INTO @occ, @nom_kvr, @kol, @unit_id, @tarif, @tarif12, @is_counter, @norma12, @is_counter_build, @value, @value12, @fin_id, @kol_odn, @kol_people, @norma, @mode_id, @mode_id12, @source_id, @source_id12, @paid, @sup_id;

	WHILE @@fetch_status = 0
	BEGIN
		SET @kol_odn12 = @kol_odn
		--IF @kol_odn12 < 0
		--	SET @kol_odn12 = 0

		IF @tarif12 = 0
		BEGIN			
			-- берём тариф по ПУ
			SELECT TOP (1)
				@tarif12 = COALESCE(tarif, 0)
			FROM [dbo].[RATES_COUNTER] 
			WHERE 
				fin_id = @fin_dec
				AND tipe_id = @tip_id
				AND service_id = @service_id
				AND (unit_id = @unit_id or @unit_id is null)
				AND (mode_id = @mode_id)
				AND (source_id = @source_id)
				AND tarif > 0

			--if @debug=1 PRINT '@tarif12='+str(@tarif12,9,4)
			SET @tarif12 = @tarif12 * @tarif_koef -- @Procent * @Procent_tarif * @Procent_tarif2 * @Procent_tarif3 * @Procent_tarif_0119 * @Procent_tarif_0719 * @Procent_tarif_0720
			--if @debug=1 PRINT '@tarif12 new='+str(@tarif12,9,4)
		END
		IF COALESCE(@tarif, 0) = 0
		BEGIN
			SELECT
				@tarif = [dbo].[Fun_GetCounterTarfServ](@fin_id, @occ, @service_id, @unit_id)
		END

		IF COALESCE(@norma, 0) = 0
		BEGIN
			SELECT
				@norma = dbo.Fun_GetNormaSingle(@unit_id, @mode_id, 1, @tip_id, @fin_id)
			IF COALESCE(@norma, 0) = 0
				SELECT
					@norma = dbo.Fun_GetNormaSingle(@unit_id, @mode_id, 0, @tip_id, @fin_id)
		END

		IF COALESCE(@norma12, 0) = 0
		BEGIN
			SELECT
				@norma12 = dbo.Fun_GetNormaSingle(@unit_id, @mode_id, 1, @tip_id, @fin_dec)
			IF COALESCE(@norma12, 0) = 0
				SELECT
					@norma12 = dbo.Fun_GetNormaSingle(@unit_id, @mode_id, 0, @tip_id, @fin_dec)
			IF @norma12 = 0
				AND @norma > 0
				SET @norma12 = @norma
		END

		IF @raschet_agri = 1
			AND @service_id = 'хвод'
		BEGIN
			SELECT
				@value_agri = SUM(value)
			   ,@kol_agri = SUM(kol * kol_norma)
			FROM dbo.AGRICULTURE_OCC AS ao
			JOIN dbo.AGRICULTURE_VID AV ON 
				AV.id = ao.ani_vid
			WHERE 
				fin_id = @fin_id
				AND occ = @occ;

			IF @kol_agri IS NULL
				SET @kol_agri = 0

			SELECT
				@kol_people =
					CASE
						WHEN @norma = 0 THEN 0
						ELSE (@kol - @kol_agri) / @norma
					END
			SELECT
				@value = @value - @value_agri
			   ,@kol_odn = 0
			   ,@kol_odn12 = 0
		END

		IF @service_id in ('гвод','тепл')  -- 25.02.2016
		BEGIN
			--IF @debug = 1
			--	PRINT STR(@paid,9,2)+' '+STR(@value,9,2)+' '+STR(@tarif,9,4)+' '+STR(@kol,9,4)

			SELECT
				@value =
					CASE
						WHEN @paid < 0 THEN 0
						ELSE @paid
					END

			IF @tarif > 0
				SELECT
					@kol = @value / @tarif

			SELECT
				@kol_people =
					CASE
						WHEN @norma = 0 THEN 0
						ELSE @kol / @norma
					END
		END

		SELECT
			@add = 0
		   ,@comments = ''



		IF @is_counter_build = 0
		BEGIN
			IF @is_counter = 0
			BEGIN
				SET @comments = 'ОПУ-нет,ИПУ-нет;Т:' + dbo.NSTR(@tarif12) + ';К:' + dbo.NSTR(@kol_people) +	';Н:' + dbo.NSTR(@norma)
				SELECT
					@value_new = @norma * @tarif12 * @kol_people
			END
			ELSE
			BEGIN
				SET @comments = 'ОПУ-нет,ИПУ-есть;Т:' + dbo.NSTR(@tarif12) + ';К:' + dbo.NSTR(@kol) + ';Кодн:' + dbo.NSTR(@kol_odn12)
				SELECT
					@value_new = (@kol + @kol_odn12) * @tarif12
			END
		END
		ELSE
		BEGIN
			IF @is_counter = 0
			BEGIN
				SET @comments = 'ОПУ-есть,ИПУ-нет;Т:' + dbo.NSTR(@tarif12) + ';К:' + dbo.NSTR(@kol_people) +
				';Кодн:' + dbo.NSTR(@kol_odn12) + ';Н:' + dbo.NSTR(@norma)
				SELECT
					@value_new = (@norma * @tarif12 * @kol_people) + (@kol_odn12 * @tarif12)
			END
			ELSE
			BEGIN
				SET @comments = 'ОПУ-есть,ИПУ-есть;Т:' + dbo.NSTR(@tarif12) + ';К:' + dbo.NSTR(@kol) + ';Кодн:' + dbo.NSTR(@kol_odn12)
				SELECT
					@value_new = (@kol + @kol_odn12) * @tarif12
			END
		END

		-- Устанавливаем %
		SELECT
			@value_max = @value_new

		IF @value <> 0
		BEGIN --  Когда текущего начисления нет то не считаем
			SET @value = (@value + (@kol_odn * @tarif))
			--IF @debug = 1

			SELECT
				@add = @value_max - @value
		END

		IF @add > 0
			SET @add = 0

		IF @debug = 1
		BEGIN
			PRINT CONCAT('@is_counter_build=', @is_counter_build, ' @is_counter=', @is_counter, ' @value_new=', @value_new,' @kol_people=', @kol_people,' @norma=', @norma)
			PRINT CONCAT(@nom_kvr, '; ', @occ, ';', COALESCE(@comments, '-'), ';Субсидия:=', @add, ';VMAX:', @value_max, ';VN:', @value, ';тариф=',@tarif)
		END
		SET @comments = @comments + ';VMAX:' + dbo.NSTR(@value_max) + ';VN:' + dbo.NSTR(@value)
		
		--=================================== 24/05/2023
		IF dbo.strpos('KR1', @DB_NAME)>0 
			IF @value<0 AND @service_id IN ('тепл')  -- 20/05/2023
			BEGIN
				SET @add= -1 * (ABS(@value_max) - ABS(@value))
			END
		--===================================

		IF @add <> 0
		BEGIN
			IF @debug = 1 PRINT 'Субсидия: ' + dbo.NSTR(@add)
	
			BEGIN TRAN

			-- Добавить в таблицу SUBSIDIA12
			INSERT INTO dbo.SUBSIDIA12
			(fin_id
			,occ
			,service_id
			,value_max
			,value
			,paid
			,sub12
			,kol_people
			,tarif12
			,tarif
			,norma12
			,norma
			,value12
			,procent
			,fin_12
			,kol
			,kol_odn)
			VALUES (@fin_id
				   ,@occ
				   ,@service_id
				   ,@value_max
				   ,@value
				   ,@value + @add
				   ,@add
				   ,@kol_people
				   ,@tarif12
				   ,@tarif
				   ,@norma12
				   ,@norma
				   ,@value12
				   ,@Procent
				   ,@fin_dec
				   ,@kol
				   ,@kol_odn)


			-- Добавить в таблицу added_payments
			INSERT INTO dbo.ADDED_PAYMENTS
			(fin_id
			,occ
			,service_id
			,sup_id
			,add_type
			,doc
			,value
			,doc_no
			,doc_date
			,user_edit
			,date_edit
			,comments
			)
			VALUES (@fin_id
				   ,@occ
				   ,@service_id
				   ,@sup_id
				   ,@add_type
				   ,@doc1
				   ,@add
				   ,'888'
				   ,NULL --doc_date
				   ,@user_id1
				   ,CURRENT_TIMESTAMP
				   ,@comments
				   )


			-- Изменить значения в таблице paym_list
			UPDATE pl
			SET added = COALESCE((SELECT
					SUM(value)
				FROM dbo.Added_Payments ap 
				WHERE 
					ap.occ = @occ
					AND ap.service_id = pl.service_id
					AND ap.sup_id = pl.sup_id)
				, 0)
			FROM dbo.Paym_list AS pl
			WHERE occ = @occ;

			COMMIT TRAN
		END
		SELECT
			@norma12 = 0
		FETCH NEXT FROM cursor_name INTO @occ, @nom_kvr, @kol, @unit_id, @tarif, @tarif12, @is_counter, @norma12, @is_counter_build, @value, @value12, @fin_id, @kol_odn, @kol_people, @norma, @mode_id, @mode_id12, @source_id, @source_id12, @paid, @sup_id;
	END

	CLOSE cursor_name;
	DEALLOCATE cursor_name;


	DROP TABLE IF EXISTS #t;

END
go

