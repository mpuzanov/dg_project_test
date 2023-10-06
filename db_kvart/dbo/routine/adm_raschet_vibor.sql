CREATE   PROCEDURE [dbo].[adm_raschet_vibor]
(
	  @P1 SMALLINT = 1
	, @tip_id1 SMALLINT = NULL -- тип жилого фонда
	, @div_id1 SMALLINT = NULL
	, @sector_id1 SMALLINT = NULL
	, @build_id1 INT = NULL
	, @sup_id1 INT = NULL
	, @TypeRas SMALLINT = 1
	, @service_id1 VARCHAR(10) = NULL
	, @day_pack SMALLDATETIME = NULL
	, @count INT OUTPUT
	, @is_counter SMALLINT = NULL-- 1- выборка лицевых со счётчиками, 2-без счётчиков, иначе все
	, @group_id INT = NULL
)
AS
	/*
	Выбор лицевых счетов для расчета
	
	declare @count INT=0
	exec adm_raschet_vibor @P1=6, @tip_id1=1, @count=@count

	declare @count INT=0
	exec adm_raschet_vibor @P1=7,@group_id=23, @count=@count
		
	@P1=1 - весь город с учётом типа фонда
	@P1=2 - район  @div_id1
	@P1=3 - участок @sector_id1
	@P1=4 - дом  @build_id1
	@P1=5 - Поставщик @sup_id1
	@P1=6 - День закрытия платежей, по которому нужен перерасчёт
	@P1=7 - Группа лицевых счетов

	@TypeRas = 1 - Комплект пени + квартплата
	1 -Комплект (пени,ипу,квартплата)
	2 -Квартплата
	3 -Пени
	4 -Пени (отд.квитанции)
	5 -По счётчикам(тек.показания)
	6 -Раскидка оплаты по услугам
	7 -Автокорректировка по счётчикам
	8 -Субсидия 12%
	9 -По счётчикам(все показания) 
	10 -Обновление квитанций

	*/
	SET NOCOUNT ON

	IF @P1 IS NULL
		SET @P1 = 1

	IF @div_id1 = 0
		SET @div_id1 = NULL

	IF @sector_id1 = 0
		SET @sector_id1 = NULL

	IF @build_id1 = 0
		SET @build_id1 = NULL

	IF @sup_id1 = 0
		SET @sup_id1 = NULL

	IF @TypeRas IS NULL
		SET @TypeRas = 1

	IF @TypeRas NOT IN (1, 2, 3)
		OR (@is_counter IS NULL)
		SET @is_counter = 3

	CREATE TABLE #t (
		  OCC INT
		, FLAT_ID INT
		, fin_id SMALLINT
		, build_id INT DEFAULT NULL
	)
	CREATE INDEX t_occ ON #t (OCC)

	IF @TypeRas IN (1, 2, 3)
	BEGIN
		--@P1=1 - весь город с учётом типа фонда
		IF @P1 = 1
		BEGIN
			INSERT INTO #t (OCC
						  , FLAT_ID
						  , fin_id
						  , build_id)
			SELECT o.OCC
				 , o.FLAT_ID
				 , o.fin_id
				 , o.bldn_id
			FROM dbo.VOcc AS o 
				JOIN dbo.Occupation_Types AS OT ON 
					o.tip_id = OT.id
			WHERE o.status_id <> 'закр'
				AND (@tip_id1 IS NULL OR o.tip_id = @tip_id1)
				AND (@build_id1 IS NULL OR o.build_id = @build_id1)
				AND OT.payms_value = CASE
                                         WHEN @tip_id1 IS NULL THEN CAST(1 AS BIT)
                                         ELSE OT.payms_value
                END
		END
		--@P1=2 - район  @div_id1
		IF @P1 = 2
		BEGIN
			INSERT INTO #t (OCC
						  , FLAT_ID
						  , fin_id
						  , build_id)
			SELECT OCC
				 , o.FLAT_ID
				 , o.fin_id
				 , o.bldn_id
			FROM dbo.VOcc AS o 
				JOIN dbo.Buildings AS b ON 
					o.bldn_id = b.id
				JOIN dbo.Occupation_Types AS OT ON 
					b.tip_id = OT.id
			WHERE 
				o.status_id <> 'закр'
				AND (@build_id1 IS NULL OR b.id = @build_id1)
				AND (@div_id1 IS NULL OR b.div_id = @div_id1)
				AND (@tip_id1 IS NULL OR b.tip_id = @tip_id1)
				AND OT.payms_value = CASE
                                         WHEN @tip_id1 IS NULL THEN CAST(1 AS BIT)
                                         ELSE OT.payms_value
                END
		END
		--@P1=3 - участок @sector_id1
		IF @P1 = 3
		BEGIN
			INSERT INTO #t (OCC
						  , FLAT_ID
						  , fin_id
						  , build_id)
			SELECT OCC
				 , o.FLAT_ID
				 , o.fin_id
				 , o.bldn_id
			FROM dbo.VOcc AS o 
				JOIN dbo.Buildings AS b ON 
					o.bldn_id = b.id
				JOIN dbo.Occupation_Types AS OT ON 
					b.tip_id = OT.id
			WHERE 
				o.status_id <> 'закр'
				AND (@sector_id1 IS NULL OR b.sector_id = @sector_id1)
				AND (@build_id1 IS NULL OR b.id = @build_id1)
				AND (@tip_id1 IS NULL OR b.tip_id = @tip_id1)
				AND OT.payms_value = CASE
                                         WHEN @tip_id1 IS NULL THEN CAST(1 AS BIT)
                                         ELSE OT.payms_value
                END
		END
		--@P1=4 - дом  @build_id1
		IF @P1 = 4
		BEGIN
			INSERT INTO #t (OCC
						  , FLAT_ID
						  , fin_id
						  , build_id)
			SELECT OCC
				 , o.FLAT_ID
				 , o.fin_id
				 , o.bldn_id
			FROM dbo.VOcc AS o 
				JOIN dbo.Buildings AS b ON 
					o.bldn_id = b.id
				JOIN dbo.Occupation_Types AS OT ON 
					b.tip_id = OT.id
			WHERE 
				o.status_id <> 'закр'
				AND (@build_id1 IS NULL OR b.id = @build_id1)
				AND (@tip_id1 IS NULL OR b.tip_id = @tip_id1)
				AND (@sector_id1 IS NULL OR b.sector_id = @sector_id1)
				AND OT.payms_value = CASE
                                         WHEN @tip_id1 IS NULL THEN CAST(1 AS BIT)
                                         ELSE OT.payms_value
                END
		END

		--@P1=5 - Поставщик @sup_id1
		IF @P1 = 5
		BEGIN
			INSERT INTO #t (OCC
						  , FLAT_ID
						  , fin_id)
			SELECT o.OCC
				 , o.FLAT_ID
				 , o.fin_id
			FROM dbo.VOcc AS o 
				JOIN dbo.Occ_Suppliers AS os ON 
					o.OCC = os.OCC 
					AND os.fin_id = O.fin_id
				JOIN dbo.Occupation_Types AS OT ON 
					o.tip_id = OT.id					
			WHERE 
				o.status_id <> 'закр'
				AND os.sup_id = @sup_id1
				AND (@tip_id1 IS NULL OR o.tip_id = @tip_id1)
				AND OT.payms_value = CASE
                                         WHEN @tip_id1 IS NULL THEN CAST(1 AS BIT)
                                         ELSE OT.payms_value
                END
		END
		
		--@P1=6 - День закрытия платежей, по которому нужен перерасчёт
		IF @P1 = 6
		BEGIN
			INSERT INTO #t (OCC
						  , FLAT_ID
						  , fin_id
						  , build_id)
			SELECT DISTINCT o.OCC
						  , o.FLAT_ID
						  , o.fin_id
						  , o.build_id
			FROM dbo.VOcc AS o 
				JOIN dbo.View_payings AS vp ON 
					o.OCC = vp.OCC
					AND o.fin_id = vp.fin_id
				JOIN dbo.Occupation_Types AS OT ON 
					o.tip_id = OT.id
			WHERE 
				o.status_id <> 'закр'
				AND (@day_pack IS NULL OR dbo.Fun_GetOnlyDate(vp.date_edit) = @day_pack)
				AND (@tip_id1 IS NULL OR o.tip_id = @tip_id1)
				AND (@build_id1 IS NULL OR o.build_id = @build_id1)
				AND OT.payms_value = CASE
                                         WHEN @tip_id1 IS NULL THEN CAST(1 AS BIT)
                                         ELSE OT.payms_value
                END
		END
		--@P1=7 - Группа лицевых счетов
		IF @P1 = 7
			AND @group_id > 0
		BEGIN
			INSERT INTO #t (OCC
						  , FLAT_ID
						  , fin_id
						  , build_id)
			SELECT o.OCC
				 , o.FLAT_ID
				 , o.fin_id
				 , o.bldn_id
			FROM dbo.VOcc AS o 
				JOIN dbo.Buildings AS b ON 
					o.bldn_id = b.id
				JOIN dbo.Occupation_Types AS OT ON 
					b.tip_id = OT.id
				JOIN dbo.Print_occ AS po ON 
					o.OCC = po.OCC
			WHERE 
				o.status_id <> 'закр'
				AND po.group_id = @group_id
				AND (@tip_id1 IS NULL OR b.tip_id = @tip_id1)
				AND OT.payms_value = CASE
                                         WHEN @tip_id1 IS NULL THEN CAST(1 AS BIT)
                                         ELSE OT.payms_value
                END									
		END

	END

	IF @TypeRas = 4
	BEGIN -- Перерасчет пени (отдельные квитанции)

		IF @day_pack IS NOT NULL
		BEGIN -- есть @day_pack
			INSERT INTO #t (OCC
						  , FLAT_ID
						  , fin_id)
			SELECT DISTINCT occ = os.occ_sup
						  , o.FLAT_ID
						  , o.fin_id
			FROM dbo.VOcc AS o 
				JOIN dbo.Occ_Suppliers AS os ON 
					o.occ = os.occ
				JOIN dbo.Buildings AS b ON 
					o.bldn_id = b.id
					AND os.fin_id = b.fin_current
				JOIN dbo.View_payings AS vp ON 
					o.occ = vp.occ
					AND o.fin_id = vp.fin_id
				JOIN dbo.Occupation_Types AS OT ON 
					b.tip_id = OT.id
			WHERE 
				o.status_id <> 'закр'
				AND os.sup_id = @sup_id1
				AND (@tip_id1 IS NULL OR b.tip_id = @tip_id1)
				AND (@div_id1 IS NULL OR b.div_id = @div_id1)
				AND (@sector_id1 IS NULL OR b.sector_id = @sector_id1)
				AND (@build_id1 IS NULL OR b.id = @build_id1)
				AND dbo.Fun_GetOnlyDate(vp.date_edit) = COALESCE(@day_pack, dbo.Fun_GetOnlyDate(vp.date_edit))
				AND OT.payms_value = CASE
                                         WHEN @tip_id1 IS NULL THEN CAST(1 AS BIT)
                                         ELSE OT.payms_value
                END
		END
		ELSE
		BEGIN
			INSERT INTO #t (OCC
						  , FLAT_ID
						  , fin_id)
			SELECT occ = os.occ_sup
				 , o.FLAT_ID
				 , o.fin_id
			FROM dbo.VOcc AS o 
				JOIN dbo.Occ_Suppliers AS os ON 
					o.occ = os.occ
				JOIN dbo.Buildings AS b ON 
					o.bldn_id = b.id
					AND os.fin_id = b.fin_current
				JOIN dbo.Occupation_Types AS OT ON 
					b.tip_id = OT.id
			WHERE 
				o.status_id <> 'закр'
				AND os.sup_id = @sup_id1
				AND (@tip_id1 IS NULL OR b.tip_id = @tip_id1)
				AND (@div_id1 IS NULL OR b.div_id = @div_id1)
				AND (@sector_id1 IS NULL OR b.sector_id = @sector_id1)
				AND (@build_id1 IS NULL OR b.id = @build_id1)
				AND OT.payms_value = CASE
                                         WHEN @tip_id1 IS NULL THEN CAST(1 AS BIT)
                                         ELSE OT.payms_value
                END
		END

	END

	IF @TypeRas = 5
	BEGIN -- перерасчёт по счётчикам
		INSERT INTO #t (OCC
					  , FLAT_ID
					  , fin_id)
		SELECT occ = C.FLAT_ID
			 , C.FLAT_ID
			 , fin_id = b.fin_current
		FROM dbo.Counters AS C
			JOIN dbo.Buildings AS b ON 
				C.build_id = b.id
			JOIN dbo.Occupation_Types AS OT ON 
				b.tip_id = OT.id
		WHERE 
			(@tip_id1 IS NULL OR b.tip_id = @tip_id1)
			AND (@div_id1 IS NULL OR b.div_id = @div_id1)
			AND (@sector_id1 IS NULL OR b.sector_id = @sector_id1)
			AND (@build_id1 IS NULL OR b.id = @build_id1)
			AND (@service_id1 IS NULL OR C.service_id = @service_id1)
			AND OT.payms_value = CASE
                                     WHEN @tip_id1 IS NULL THEN CAST(1 AS BIT)
                                     ELSE OT.payms_value
            END								
	END

	IF @TypeRas = 6
	BEGIN -- отбираем лицевые с цессией
		INSERT INTO #t (OCC
					  , FLAT_ID
					  , fin_id)
		SELECT 0
			 , o.FLAT_ID
			 , o.fin_id
		FROM dbo.VOcc AS o
			JOIN dbo.Buildings AS b ON 
				o.bldn_id = b.id
			JOIN Cessia C ON C.OCC = o.OCC
		WHERE 
			o.status_id <> 'закр'
			AND (@tip_id1 IS NULL OR b.tip_id = @tip_id1)
	END

	IF @TypeRas in (8, 10)
	BEGIN -- отбираем дома по типу фонда
		INSERT INTO #t (OCC
					  , FLAT_ID
					  , fin_id
					  , build_id)
		SELECT 0
			 , 0
			 , b.fin_current
			 , b.id
		FROM dbo.Buildings AS b 
			JOIN dbo.Occupation_Types OT ON 
				b.tip_id = OT.id
		WHERE 
			(@tip_id1 IS NULL OR b.tip_id = @tip_id1)
			AND (@build_id1 IS NULL OR b.id = @build_id1)
			AND (@div_id1 IS NULL OR b.div_id = @div_id1)			
			AND OT.raschet_no = CAST(0 AS BIT)
			AND OT.payms_value = CAST(1 AS BIT)
			AND COALESCE(OT.is_calc_subs12,0) = CASE 
										WHEN @TypeRas=8 THEN CAST(1 AS BIT) -- только тем кому можно считать субсидию
										ELSE COALESCE(OT.is_calc_subs12,0)
									END
	END
	
	IF (@is_counter = 1)
		AND (@TypeRas IN (1, 2, 3))
	BEGIN
		SELECT *
		FROM #t t
		WHERE EXISTS (
				SELECT 1
				FROM dbo.View_counter_all vca 
				WHERE t.OCC = vca.OCC
					AND t.fin_id = vca.fin_id
			)
		SELECT @count = @@rowcount
	END
	IF (@is_counter = 2)
		AND (@TypeRas IN (1, 2, 3))
	BEGIN
		SELECT *
		FROM #t t
		WHERE NOT EXISTS (
				SELECT 1
				FROM dbo.View_counter_all vca 
				WHERE t.OCC = vca.OCC
					AND t.fin_id = vca.fin_id
			)
		SELECT @count = @@rowcount
	END
	IF @is_counter = 3
	BEGIN
		SELECT *
		FROM #t t

		SELECT @count = @@rowcount
	END
go

