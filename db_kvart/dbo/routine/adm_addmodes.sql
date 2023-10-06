CREATE   PROCEDURE [dbo].[adm_addmodes]
(
	  @service_id1 VARCHAR(10)
	, @name1 VARCHAR(30)
	, @kod INT = NULL -- желаемый код   @service_no1 * 1000+@kod
	, @debug BIT = 0
)
AS
/*
	Добавляем режим потребления
	exec adm_addmodes 'пени', 'Пени', NULL, 1
*/
	SET NOCOUNT ON

	IF EXISTS (
			SELECT *
			FROM dbo.Cons_modes 
			WHERE service_id = @service_id1
				AND name = @name1
		)
	BEGIN
		RAISERROR ('Такой режим потребления уже есть', 16, 1)
		RETURN 1
	END

	IF @kod = 0
		SET @kod = NULL

	DECLARE @service_no1 SMALLINT

	SELECT @service_no1 = service_no
	FROM dbo.Services AS s 
	WHERE s.id = @service_id1

	IF @debug = 1
		PRINT @service_no1

	IF @kod IS NOT NULL
		SET @kod = @service_no1 * 1000 + @kod

	IF @kod IS NULL
		OR NOT EXISTS (
			SELECT *
			FROM dbo.Cons_modes 
			WHERE service_id = @service_id1
		)
	BEGIN
		SET @kod = @service_no1 * 1000
	END

	IF @debug = 1
		PRINT @kod

	-- если существует режим с кодом @kod то создаем по обычной схеме
	IF EXISTS (
			SELECT *
			FROM dbo.Cons_modes 
			WHERE id = @kod
		)
	BEGIN
		--*************************************************
		DECLARE @min INT
			  , @max INT
			  , @rang INT = 100

		SELECT @min = @service_no1 * 1000
			 , @max = (@service_no1 + 1) * 1000 - 1
		SET @rang = @max - @min;

		IF @rang > 1000
			SELECT @rang = 1000;

		SELECT TOP 1 @kod = t2.kod
		FROM (
			SELECT TOP (@rang) ROW_NUMBER() OVER (ORDER BY t.n) + @min AS kod
			FROM dbo.Fun_GetNums(@min, @max) AS t
		) AS t2
			LEFT JOIN dbo.Cons_modes AS o ON t2.kod = o.id
		WHERE o.id IS NULL
		ORDER BY t2.kod
		OPTION (MAXDOP 1);

		--*************************************************
		IF @kod IS NULL
			SELECT @kod = MAX(id) + 1
			FROM dbo.Cons_modes
			WHERE service_id = @service_id1;
	END

	IF @debug = 1
		PRINT @kod

	IF NOT EXISTS (
			SELECT *
			FROM dbo.Measurement_units AS mu 
			WHERE mode_id = 0
				AND is_counter = 0
		)
	BEGIN
		INSERT INTO dbo.Measurement_units (fin_id
										 , unit_id
										 , mode_id
										 , is_counter
										 , tip_id
										 , q_single
										 , two_single
										 , three_single
										 , four_single
										 , q_member)
		SELECT 0
			 , id
			 , 0
			 , 0
			 , 0
			 , 0
			 , 0
			 , 0
			 , 0
			 , 0
		FROM dbo.Units AS u
	END
	
	IF @debug = 1 PRINT 'добавили запись в Measurement_units 0'

	BEGIN TRAN

		INSERT INTO dbo.Cons_modes (id
								  , service_id
								  , name)
		VALUES(@kod
			 , @service_id1
			 , @name1)
		IF @debug = 1 PRINT 'добавили запись в Cons_modes'

		-- Добавляем записи в файл MEASUREMENT_UNITS
		-- по норме
		INSERT INTO dbo.Measurement_units (fin_id
										 , unit_id
										 , mode_id
										 , is_counter
										 , tip_id
										 , q_single
										 , two_single
										 , three_single
										 , four_single
										 , q_member)
		SELECT DISTINCT su.fin_id
					  , su.unit_id
					  , mode_id = cm.id
					  , is_counter = 0
					  , su.tip_id
					  , q_single = 0
					  , two_single = 0
					  , three_single = 0
					  , four_single = 0
					  , q_member = 0
		FROM dbo.Service_units AS su
			JOIN dbo.Cons_modes AS cm 
				ON su.service_id = cm.service_id
			LEFT JOIN dbo.Measurement_units AS mu 
				ON is_counter = 0
				AND su.unit_id = mu.unit_id
				AND cm.id = mu.mode_id
				AND su.tip_id = mu.tip_id
		WHERE mu.mode_id IS NULL
			AND cm.id = @kod

		IF @debug = 1 PRINT 'добавили запись в Measurement_units по норме'

		-- по счётчикам
		INSERT INTO dbo.Measurement_units (fin_id
										 , unit_id
										 , mode_id
										 , is_counter
										 , tip_id
										 , q_single
										 , two_single
										 , three_single
										 , four_single
										 , q_member)
		SELECT DISTINCT su2.fin_id
					  , su.unit_id
					  , mode_id = cm.id
					  , is_counter = 1
					  , su2.tip_id
					  , q_single = 0
					  , two_single = 0
					  , three_single = 0
					  , four_single = 0
					  , q_member = 0
		FROM dbo.Service_units_counter AS su
			JOIN dbo.Service_units AS su2 
				ON su.service_id = su2.service_id
				AND su.unit_id = su2.unit_id
			JOIN dbo.Cons_modes AS cm 
				ON su.service_id = cm.service_id
			LEFT JOIN dbo.Measurement_units AS mu 
				ON is_counter = 1
				AND su.unit_id = mu.unit_id
				AND cm.id = mu.mode_id
				AND su2.tip_id = mu.tip_id
		WHERE mu.mode_id IS NULL
			AND cm.id = @kod;
				
		COMMIT TRAN

		IF @debug = 1 PRINT 'добавили запись в Measurement_units по счётчикам'
go

