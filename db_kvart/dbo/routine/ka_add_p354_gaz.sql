-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[ka_add_p354_gaz]
	  @bldn_id1 INT
	, @fin_id1 SMALLINT
	
	, @volume_gaz_opu decimal(15, 6) = 0
	, @volume_otop_opu decimal(15, 6) = 0
	
	, @debug BIT = 0
	, @addyes INT = 0 OUTPUT -- если 1 то разовые добавили
	, @is_calculation_rent BIT = 0  -- рассчитать квартплату
	, @is_add_volume_pu BIT = 1 -- добавить показания по ОДПУ
AS
BEGIN
/*

	гГВС - газ для ГВС	
	газОтоп - газ для Отопления

	находим сумму перерасчетов по газу на ГВС в заданном периоде
	расчитаем коэффициента G	
	находим объём ГВС без перерасчетов
	находим объём по Отоплению ОДН с перерасчетами
	расчитаем объём Гкал на ГВС
	расчитаем объём Гкал на Отопление

DECLARE @addyes INT
EXEC ka_add_p354_gaz @bldn_id1=6795, @fin_id1=254, @volume_gaz_opu=28.769, @volume_otop_opu=226.41, @debug=TRUE, @addyes=@addyes OUT
SELECT @addyes AS '@addyes'

*/

	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	
	IF @debug=1 
		PRINT OBJECT_NAME(@@PROCID)
	
	IF dbo.Fun_AccessAddBuild(@bldn_id1) = 0
	BEGIN
		RAISERROR ('Для Вас работа с Разовыми запрещена', 16, 1)
		RETURN
	END
	
	declare 
		@service_id_gaz varchar(10)='гГВС' -- газ для ГВС	
		, @service_id_otop varchar(10)='газОтоп' -- газ для Отопления

		, @volume_add_ggvs decimal(15, 6) -- сумму перерасчетов по газу на ГВС в заданном периоде
		, @koef_g decimal(15, 6)        -- коэффициент G
		, @norma_gaz_gvs decimal(9,6)   -- норматив на подогрев ГВС
		, @str_koef VARCHAR(50)
		
		, @total_sq DECIMAL(10, 4)
		, @build_total_area DECIMAL(10, 4)  -- площадь дома по паспорту
		, @build_total_sq DECIMAL(10, 4)

		, @db_name VARCHAR(20) = upper(db_name())
		, @is_ivc BIT = 0
		, @start_date SMALLDATETIME
		, @fin_current SMALLINT

		, @volume_gaz_opu2 decimal(15, 6) = 0   -- объём Газа по ОДПУ с учётом перерасчетов
		, @volume_gvs DECIMAL(15, 6)            -- объём ГВС без перерасчетов
		, @volume_otop_odn DECIMAL(15, 6)       -- объём по Отоплению ОДН с перерасчетами
		, @volume_gkal_gvs DECIMAL(15, 6)       -- объём ГКал на воду
		, @volume_gkal_otop DECIMAL(15, 6)      -- объём ГКал на Отопление
		, @volume_gaz_gvs_build decimal(15, 6)  -- объём Газа на подогрев воды по дому
		, @volume_gaz_otop_build decimal(15, 6) -- объём Газа на отопление по дому
		, @volume_otop_ipu decimal(15, 6)       -- объём ИПУ по отоплению с учетом перерасчетов
		, @tarif decimal(10,4)
		, @unit_id varchar(10) = ''
		
		, @counter_id1 INT = NULL
		, @Sum_Actual_value DECIMAL(12, 4)
		, @inspector_date1 SMALLDATETIME
		, @serial_number_house VARCHAR(20) 

	set @is_calculation_rent=coalesce(@is_calculation_rent, 0)
	set @is_add_volume_pu=coalesce(@is_add_volume_pu, 1)

	IF dbo.strpos('KR1', @db_name) > 0 SET @is_ivc=1

	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, @bldn_id1, NULL, NULL);

	SELECT @start_date = start_date, @inspector_date1 = dbo.Fun_GetOnlyDate(end_date)
	FROM dbo.Global_values AS GV 
	WHERE fin_id = @fin_current;

	--SELECT @norma_gaz_gvs = coalesce(norma_gaz_gvs,0), @build_total_area = coalesce(b.build_total_area,0)
	--FROM dbo.view_build_all_lite as b
	--WHERE build_id = @bldn_id1
	--	and fin_id=@fin_id1	

	SELECT @norma_gaz_gvs = coalesce(norma_gaz_gvs,0), @build_total_area = coalesce(b.build_total_area,0)
	FROM dbo.Buildings as b
	WHERE id = @bldn_id1

	SELECT
		@volume_add_ggvs=sum(coalesce(kol_added,0)), @tarif = max(vp.tarif), @unit_id = max(vp.unit_id)
	FROM dbo.View_paym as vp
	WHERE 
		vp.fin_id=@fin_id1
		and vp.build_id=@bldn_id1
		and vp.service_id=@service_id_gaz

	SELECT @volume_gaz_opu2=@volume_gaz_opu-@volume_add_ggvs

	-- Расчет коэффициента G
	SELECT @koef_g = @volume_gaz_opu2 / @volume_otop_opu;

	--находим объём ГВС без перерасчетов
	SELECT
		@volume_gvs=sum(coalesce(kol,0))
	FROM dbo.View_paym as vp
	WHERE 
		vp.fin_id=@fin_id1
		and vp.build_id=@bldn_id1
		and vp.service_id='гвод'
		
	--находим объём по Отоплению ОДН с перерасчетами ()
	SELECT
		@volume_otop_odn=sum(coalesce(kol,0))+sum(coalesce(vp.kol_added,0))
		, @build_total_sq = sum(vo.total_sq * vp.koef_day)
	FROM dbo.View_paym as vp
		JOIN dbo.view_occ_all_lite vo ON
			vo.occ=vp.Occ
			and vo.fin_id=vp.fin_id
	WHERE 
		vp.fin_id=@fin_id1
		and vp.build_id=@bldn_id1
		and vp.service_id='отоп'
		and (vp.source_id % 1000) <> 0

	--расчитаем объём Гкал на ГВС
	SELECT @volume_gkal_gvs = @norma_gaz_gvs * @volume_gvs
	SELECT @volume_gaz_gvs_build = @koef_g * @volume_gkal_gvs

	--расчитаем объём Гкал на Отопление
	SELECT @volume_gkal_otop = @volume_otop_opu - @volume_gkal_gvs
	SELECT @volume_gaz_otop_build = @koef_g * (@volume_gkal_otop - @volume_otop_odn)

	if @debug=1
		SELECT @volume_add_ggvs as volume_add_ggvs
		    , @volume_gaz_opu as volume_gaz_opu
			, @volume_gaz_opu2 as volume_gaz_opu2
			, @volume_otop_opu as volume_otop_opu
			, @koef_g as koef_g
			, @norma_gaz_gvs as norma_gaz_gvs
			, @volume_gvs as volume_gvs
			, @volume_otop_odn as volume_otop_odn
			, @volume_gkal_gvs as volume_gkal_gvs
			, @volume_gkal_otop as volume_gkal_otop
			, @volume_gaz_gvs_build as volume_gaz_gvs_build
			, @volume_gaz_otop_build as volume_gaz_otop_build
			, @build_total_sq as build_total_sq
			, @build_total_area as build_total_area
			, @tarif as tarif


	SELECT
		vp.occ, vo.nom_kvr, coalesce(vp.kol,0) as kol
		,concat(
			ltrim(str(@koef_g,9,6)),'*',ltrim(str(@norma_gaz_gvs,9,6)),'*',dbo.nstr(kol)
		) as comments
		,cast(@koef_g * @norma_gaz_gvs * kol AS DECIMAL(12,6)) as kol_itog
		,@tarif as tarif
		,cast(@koef_g * @norma_gaz_gvs * kol * @tarif AS DECIMAL(9,2)) as sum_value		
		, vo.nom_kvr_sort
		, coalesce(vp.koef_day,1) as koef_day
	INTO #t_gaz
	FROM dbo.View_paym as vp
		JOIN dbo.view_occ_all_lite vo ON
			vo.occ=vp.Occ
			and vo.fin_id=vp.fin_id
	WHERE 
		vp.fin_id=@fin_id1
		and vp.build_id=@bldn_id1
		and vp.service_id='гвод'
		and (vp.source_id % 1000) <> 0	

	if @debug=1
		SELECT '#t_gaz' as t,* from #t_gaz ORDER BY nom_kvr_sort

	;WITH cte_otop AS
	(
	SELECT
		vp.occ
		, CASE 
			WHEN vp.metod=3 THEN coalesce(vp.kol,0)+coalesce(vp.kol_added,0)
			WHEN coalesce(vp.metod,1) IN (1,2,9) THEN coalesce(vp.kol,0)+coalesce(vp.kol_added,0)  -- 22.10.23  по норме и среднему
			ELSE 0
		  END as kol
		, vo.total_sq
		, vo.nom_kvr
		, vo.nom_kvr_sort
		, coalesce(vp.koef_day,1) as koef_day
	FROM dbo.View_paym as vp
		JOIN dbo.view_occ_all_lite vo ON
			vo.occ=vp.Occ
			and vo.fin_id=vp.fin_id
	WHERE 
		vp.fin_id=@fin_id1
		and vp.build_id=@bldn_id1
		and vp.service_id='отоп'
		and (vp.source_id % 1000) <> 0		
	)
	SELECT
		occ, nom_kvr, kol
		,concat(
			ltrim(str(@koef_g,9,6)),'*(',dbo.nstr(kol),'+(',ltrim(str(@volume_gkal_otop,9,4)),'-',ltrim(str(@volume_otop_odn,9,4)),')*',
			dbo.nstr(cast(total_sq*koef_day AS DECIMAL(9,2))),'/',dbo.nstr(@build_total_sq),')'
		) as comments
		,cast(@koef_g * (kol + ((@volume_gkal_otop - @volume_otop_odn) * (total_sq*koef_day) / @build_total_sq)) AS DECIMAL(12,6)) as kol_itog
		,@tarif as tarif
		,cast(@koef_g * (kol + ((@volume_gkal_otop - @volume_otop_odn) * (total_sq*koef_day) / @build_total_sq)) * @tarif AS DECIMAL(9,2)) as sum_value
		,nom_kvr_sort
		,koef_day
	INTO #t_otop
	FROM cte_otop

	if @debug=1
		SELECT '#t_otop' as t, * from #t_otop ORDER BY nom_kvr_sort

	if @fin_id1=@fin_current
	BEGIN
	  if @debug=1 print 'будем добавлять в общедомовые'

	  BEGIN TRAN;

		DELETE pcb
		FROM dbo.Paym_occ_build AS pcb
			JOIN #t_gaz AS t ON 
				pcb.occ = t.occ
		WHERE pcb.fin_id = @fin_current
			AND pcb.service_id=@service_id_gaz;

		INSERT INTO dbo.Paym_occ_build 
			(fin_id
		   , occ
		   , service_id
		   , kol
		   , tarif
		   , value
		   , comments
		   , unit_id
		   , procedura
		   , koef_day)
		SELECT @fin_current
			 , t.occ
			 , @service_id_gaz
			 , t.kol_itog
			 , t.tarif
			 , t.sum_value
			 , t.comments
			 , coalesce(@unit_id,'') AS unit_id
			 , OBJECT_NAME(@@PROCID) AS procedura
			 , t.koef_day
		FROM #t_gaz AS t
		SELECT @addyes = @@rowcount;


		DELETE pcb
		FROM dbo.Paym_occ_build AS pcb
			JOIN #t_otop AS t ON 
				pcb.occ = t.occ
		WHERE pcb.fin_id = @fin_current
			AND pcb.service_id=@service_id_otop;

		INSERT INTO dbo.Paym_occ_build 
			(fin_id
		   , occ
		   , service_id
		   , kol
		   , tarif
		   , value
		   , comments
		   , unit_id
		   , procedura
		   , koef_day)
		SELECT @fin_current
			 , t.occ
			 , @service_id_otop
			 , t.kol_itog
			 , t.tarif
			 , t.sum_value
			 , t.comments
			 , coalesce(@unit_id,'') AS unit_id
			 , OBJECT_NAME(@@PROCID) AS procedura
			 , t.koef_day
		FROM #t_otop AS t

	COMMIT TRAN;

	--===============================================================================================
	IF @is_add_volume_pu = 1
	BEGIN
		IF @debug = 1
			RAISERROR (N'добавляем показания по ОДПУ', 10, 1) WITH NOWAIT;

		DECLARE @t_counter TABLE (id INT, counter_id INT, actual_value DECIMAL(12, 4));
						
		-- ОДПУ по Отоплению ============================================
		if @volume_otop_opu>0
		BEGIN			
			SET @counter_id1 = null;

			SELECT @counter_id1 = id
			FROM dbo.View_counter_build AS vcb
			WHERE build_id = @bldn_id1
				AND service_id = 'отоп'
				AND vcb.date_del is NULL
		
			IF @counter_id1 IS NULL
			BEGIN
				IF @debug = 1
					PRINT N'Если нет домового счётчика по этой услуге то заводим его'

				SET @serial_number_house =ltrim(str(@bldn_id1, 6)) + ' отоп';

				EXEC k_counter_add @build_id1 = @bldn_id1
									, @flat_id1 = NULL
									, @service_id1 = 'отоп'
									, @serial_number1 = @serial_number_house
									, @type1 = 'HOUSE'
									, @max_value1 = 999999
									, @koef1 = 1
									, @unit_id1 = @unit_id
									, @count_value1 = 0
									, @date_create1 = @start_date
									, @periodcheck = NULL
									, @comments1 = N'создан автоматически при расчёте ОПУ'
									, @internal = 0
									, @is_build = 1
									, @counter_id_out = @counter_id1 OUTPUT;
			END

			INSERT INTO @t_counter
				(id
			   , counter_id
			   , actual_value)
			SELECT id
				 , counter_id
				 , COALESCE(actual_value, 0)
			FROM dbo.View_counter_insp_build
			WHERE build_id = @bldn_id1
				AND fin_id = @fin_current
				AND service_id = 'отоп';

			SELECT @Sum_Actual_value = COALESCE(SUM(actual_value), 0)
			FROM @t_counter;

			IF @Sum_Actual_value <> @volume_otop_opu
			BEGIN
				DELETE ci
				FROM dbo.Counter_inspector AS ci
					JOIN @t_counter AS t ON 
						ci.id = t.id;
				SET @Sum_Actual_value = 0;
			END;

			IF @Sum_Actual_value = 0
				AND @counter_id1 > 0
			BEGIN
				IF @debug = 1
					RAISERROR (N'заполняем данные по ОПУ', 10, 1) WITH NOWAIT;

				EXEC k_counter_value_add3 @counter_id1 = @counter_id1
										, @inspector_value1 = 0
										, @inspector_date1 = @inspector_date1
										, @actual_value = @volume_otop_opu
										, @blocked1 = 0
										, @comments1 = N'взято из перерасчётов'
			END;
		END; -- if @volume_otop_opu>0

		-- ОДПУ по газу ==========================================		
		if @volume_gaz_opu>0
		BEGIN
			SET @counter_id1 = null;

			SELECT @counter_id1 = id
			FROM dbo.View_counter_build AS vcb
			WHERE build_id = @bldn_id1
				AND service_id = 'пгаз'
				AND vcb.date_del is NULL
		
			IF @counter_id1 IS NULL
			BEGIN
				IF @debug = 1
					PRINT N'Если нет домового счётчика по этой услуге то заводим его'

				SET @serial_number_house = ltrim(str(@bldn_id1, 6)) + ' пгаз'

				EXEC k_counter_add @build_id1 = @bldn_id1
									, @flat_id1 = NULL
									, @service_id1 = 'пгаз'
									, @serial_number1 = @serial_number_house
									, @type1 = 'HOUSE'
									, @max_value1 = 999999
									, @koef1 = 1
									, @unit_id1 = @unit_id
									, @count_value1 = 0
									, @date_create1 = @start_date
									, @periodcheck = NULL
									, @comments1 = N'создан автоматически при расчёте ОПУ'
									, @internal = 0
									, @is_build = 1
									, @counter_id_out = @counter_id1 OUTPUT;
			END

			DELETE FROM @t_counter;
			INSERT INTO @t_counter(id, counter_id, actual_value)
			SELECT id
				 , counter_id
				 , COALESCE(actual_value, 0)
			FROM dbo.View_counter_insp_build
			WHERE build_id = @bldn_id1
				AND fin_id = @fin_current
				AND service_id = 'пгаз';

			SELECT @Sum_Actual_value = COALESCE(SUM(actual_value), 0) FROM @t_counter;

			IF @Sum_Actual_value <> @volume_gaz_opu
			BEGIN
				DELETE ci
				FROM dbo.Counter_inspector AS ci
					JOIN @t_counter AS t ON 
						ci.id = t.id;
				SET @Sum_Actual_value = 0;
			END;

			IF @Sum_Actual_value = 0
				AND @counter_id1 > 0
			BEGIN
				IF @debug = 1
					RAISERROR (N'заполняем данные по ОПУ', 10, 1) WITH NOWAIT;

				EXEC k_counter_value_add3 @counter_id1 = @counter_id1
										, @inspector_value1 = 0
										, @inspector_date1 = @inspector_date1
										, @actual_value = @volume_gaz_opu
										, @blocked1 = 0
										, @comments1 = N'взято из перерасчётов'
			END;
		END

	END -- IF @is_add_volume_pu = 1
	--===============================================================================================

	IF @is_calculation_rent = 1
	BEGIN
		IF @debug = 1
			RAISERROR (N'делаем перерасчёт по дому', 10, 1) WITH NOWAIT;
		EXEC dbo.k_raschet_build @build_id = @bldn_id1;

		IF @debug = 1
			RAISERROR (N'выполнен', 10, 1) WITH NOWAIT;
	END

	END --if @fin_id1=@fin_current

END
go

