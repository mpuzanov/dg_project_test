CREATE   PROCEDURE [dbo].[k_intPrintDetail_occ_sup]
(
	  @fin_id1 SMALLINT -- Фин.период
	, @occ1 INT -- лицевой
	, @col1 SMALLINT = 1 -- колонка
	, @sup_id INT = 0
)
AS
	/*
	Выдаем информацию по услугам для единой квитанции
	
	*/
	SET NOCOUNT ON

	DECLARE @fin_current1 SMALLINT
		  , @tip_id SMALLINT
		  , @NameSoderHousing VARCHAR(30)
	SELECT @fin_current1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	DECLARE @t TABLE (
		  occ INT
		, short_name VARCHAR(50)
		, short_id VARCHAR(6)
		, service_id VARCHAR(10)
		, tarif DECIMAL(10, 4)
		, kol DECIMAL(12, 6)
		, kol_norma DECIMAL(12, 6) DEFAULT 0
		, kol_ipu DECIMAL(12, 6) DEFAULT 0
		, kol_opu DECIMAL(12, 6) DEFAULT 0
		, koef DECIMAL(10, 4)
		, saldo DECIMAL(9, 2)
		, Value DECIMAL(9, 2)
		, Added DECIMAL(9, 2)
		, Paid DECIMAL(9, 2)
		, Debt DECIMAL(9, 2)
		, sort_no TINYINT
		, mode_id INT DEFAULT NULL
		, unit_id VARCHAR(10) DEFAULT NULL
		, sup_id INT DEFAULT 0
		, metod TINYINT DEFAULT NULL
	)

	IF @fin_id1 >= @fin_current1
	BEGIN

		SELECT @tip_id = tip_id
		FROM dbo.Occupations
		WHERE occ = @occ1

		INSERT INTO @t (occ
					  , short_name
					  , short_id
					  , service_id
					  , tarif
					  , kol
					  , koef
					  , saldo
					  , Value
					  , Added
					  , Paid
					  , Debt
					  , sort_no
					  , mode_id
					  , unit_id
					  , sup_id
					  , metod)
		SELECT p.occ
			 , s.short_name
			 , u.short_id
			 , p.service_id
			 , p.tarif
			 , p.kol
			 , p.koef
			 , p.saldo
			 , p.Value
			 , p.Added
			 , p.Paid
			 , p.Debt
			 , s.sort_no
			 , NULL
			 , p.unit_id
			 , cl.sup_id
			 , p.metod
		FROM dbo.Occupations AS o 
			JOIN dbo.Paym_list AS p ON o.occ = p.occ
			JOIN dbo.Services AS s ON p.service_id = s.id
			JOIN dbo.Consmodes_list AS cl ON p.occ = cl.occ
				AND p.service_id = cl.service_id
				AND p.sup_id = cl.sup_id
			LEFT JOIN dbo.Units AS u ON p.unit_id = u.id
		WHERE (o.occ = @occ1)
			AND (s.num_colon = COALESCE(@col1, s.num_colon))
			AND (p.subsid_only = 0)
			--AND (p.account_one=0 OR p.account_one IS NULL)
			--AND (p.saldo<>0  OR p.value<>0 OR p.added<>0 OR p.paid<>0) -- 29.08.2011
			AND (p.Value <> 0 OR p.Added <> 0 OR p.Paid <> 0)
			AND (o.tip_id = @tip_id OR @tip_id IS NULL)

	END
	ELSE
	BEGIN

		SELECT @tip_id = tip_id
		FROM dbo.Occ_history
		WHERE occ = @occ1
			AND fin_id = @fin_id1

		INSERT INTO @t (occ
					  , short_name
					  , short_id
					  , service_id
					  , tarif
					  , kol
					  , koef
					  , saldo
					  , Value
					  , Added
					  , Paid
					  , Debt
					  , sort_no
					  , mode_id
					  , unit_id
					  , sup_id
					  , metod)
		SELECT p.occ
			 , s.short_name
			 , u.short_id
			 , p.service_id
			 , p.tarif
			 , p.kol
			 , 1 --cl.koef
			 , p.saldo
			 , p.Value
			 , p.Added
			 , p.Paid
			 , p.Debt
			 , s.sort_no
			 , p.mode_id
			 , p.unit_id
			 , p.sup_id
			 , p.metod
		FROM dbo.Occ_history AS o
			JOIN dbo.Paym_history AS p ON o.occ = p.occ
				AND o.fin_id = p.fin_id
			JOIN dbo.Services AS s ON s.id = p.service_id
			--   JOIN dbo.service_units AS su  ON s.id=su.service_id AND o.roomtype_id=su.roomtype_id
			--AND (o.fin_id=su.fin_id) AND (o.tip_id=su.tip_id)
			LEFT JOIN dbo.Units AS u  ON p.unit_id = u.id
		WHERE (o.fin_id = @fin_id1)
			AND (o.occ = @occ1)
			AND (s.num_colon = COALESCE(@col1, s.num_colon))
			AND (p.subsid_only = 0)
			--AND (p.account_one=0 OR  p.account_one IS NULL)
			AND (o.tip_id = @tip_id OR @tip_id IS NULL)

		-- Обновляем ед.измерения если у режима другой
		UPDATE t
		SET short_id = u.short_id
		FROM @t AS t
			JOIN Cons_modes_history AS cm ON t.mode_id = cm.mode_id
			JOIN dbo.Units AS u ON cm.unit_id = u.id
		WHERE cm.fin_id = @fin_id1

		-- если есть сохранённая ед.измерения
		UPDATE t
		SET short_id = u.short_id
		FROM @t AS t
			JOIN dbo.Units AS u ON t.unit_id = u.id
		WHERE t.unit_id IS NOT NULL
	END

	IF @col1 = 1
	BEGIN
		DECLARE @dbname NVARCHAR(128)
		SELECT @dbname = DB_NAME()

		--select * from @t order by sort_no

		--print @dbname
		SELECT @NameSoderHousing = namesoderhousing
		FROM dbo.Occupation_Types
		WHERE id = @tip_id
		IF @NameSoderHousing IS NULL
			OR @NameSoderHousing = ''
			SET @NameSoderHousing = 'С.жилья в т.ч:'

		INSERT INTO @t (occ
					  , short_name
					  , short_id
					  , service_id
					  , tarif
					  , kol
					  , koef
					  , saldo
					  , Value
					  , Added
					  , Paid
					  , Debt
					  , sort_no)
		SELECT occ
			 , @NameSoderHousing
			 , 'м2'
			 , 'итог'
			 , SUM(tarif)
			 , kol
			 , 1
			 , SUM(saldo)
			 , SUM(Value)
			 , SUM(Added)
			 , SUM(Paid)
			 , SUM(Debt)
			 , sort_no = 0
		FROM @t AS t
		WHERE EXISTS (
				SELECT service_id
				FROM dbo.Services_types AS st
				WHERE st.tip_id = @tip_id
					AND st.service_id = t.service_id
					AND st.VSODER = 1
			)
		GROUP BY occ
			   , kol

		DELETE t
		FROM @t AS t
		WHERE EXISTS (
				SELECT 1
				FROM dbo.Services_types AS st
				WHERE st.tip_id = @tip_id
					AND st.service_id = t.service_id
					AND st.VSODER = 1
					AND st.VYDEL = 0
			)
		UPDATE @t
		SET Paid = 0
		FROM @t AS t
		WHERE EXISTS (
				SELECT 1
				FROM dbo.Services_types AS st
				WHERE st.tip_id = @tip_id
					AND st.service_id = t.service_id
					AND st.VSODER = 1
					AND st.VYDEL = 1
			)
	END

	-- Изменяем если есть названия услуг по разным типам фонда
	UPDATE t
	SET short_name = st.service_name
	FROM @t AS t
		JOIN dbo.Services_types AS st ON @tip_id = st.tip_id
			AND t.service_id = st.service_id
	WHERE @fin_id1 > 83

	-- Удаляем тариф если нет начислений
	UPDATE t
	SET tarif = 0
	FROM @t AS t
	WHERE Value = 0

	UPDATE t
	SET kol_norma =
				   CASE
					   WHEN metod IS NULL OR
						   metod = 1 THEN kol
				   END
	  , kol_ipu =
				 CASE
					 WHEN metod = 3 THEN kol
				 END
	  , kol_opu =
				 CASE
					 WHEN metod = 4 THEN kol
				 END
	FROM @t AS t

	SELECT *
	FROM @t
	WHERE COALESCE(sup_id, 0) = @sup_id
	ORDER BY sort_no
go

