-- =============================================
-- Author:		Пузанов
-- Create date: 22.09.2023
-- Description:	Загрузка ОДПУ
-- =============================================
CREATE       PROCEDURE [dbo].[adm_load_counter_opu]
(	  
	  @street_name VARCHAR(50)
	, @nom_dom VARCHAR(12)
	, @tip_id SMALLINT
	, @MARKA VARCHAR(30) -- Тип счётчика
	, @NOMER VARCHAR(20) -- Серийный номер
	, @RAZRAD INT -- Разряд счётчика
	, @DUSTAN SMALLDATETIME -- Дата установки
	, @DPOVER SMALLDATETIME = NULL -- Дата поверки
	, @USLUGA VARCHAR(100) -- Услуга
	, @POSLPOK DECIMAL(12, 4) -- Последнее показание
	, @POSLDATA SMALLDATETIME -- Дата последнего показания
	, @SET_POSLPOK_BEGIN BIT = 0 -- устанавливать последние показания начальными
	, @PeriodLastCheck SMALLDATETIME = NULL -- Последняя Дата поверки
	, @PeriodInterval INT = NULL -- Межповерочный интервал
	, @ResultAdd BIT = 0 OUTPUT-- 0- не добавили, 1-добавили
	, @counter_id INT = NULL OUTPUT
	, @strerror VARCHAR(4000) = '' OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;

	SET @ResultAdd = 0
	--IF @new_ls<99999999 RETURN

	IF @set_POSLPOK_begin IS NULL
		SET @set_POSLPOK_begin = 0

	BEGIN TRY

		IF @MARKA IS NULL
			SET @MARKA = '?'
		IF @NOMER IS NULL
			SET @NOMER = '?'
		IF @DUSTAN IS NULL
			SET @DUSTAN = @POSLDATA

		IF @DUSTAN IS NULL
			RETURN

		IF @DPOVER = @DUSTAN
			SET @DPOVER = NULL

		-- убираем начальные пробелы у серийного номера
		SET @NOMER = LTRIM(@NOMER)
		SET @NOMER = REPLACE(@NOMER, CHAR(9), '')
		SET @NOMER = REPLACE(@NOMER, CHAR(160), '')

		DECLARE @Build_id INT -- код дома
			  , @service_id VARCHAR(10) = NULL
			  , @unit_id VARCHAR(10)
			  , @max_value INT = 9
			  , @fin_current SMALLINT
		
		IF dbo.strpos(@USLUGA, 'Холодная вода Хол.водоснаб. ХВС Холодное водоснабжение Холодное водоснаб.') > 0
			SELECT @service_id = 'хвод'
				 , @unit_id = 'кубм'
		IF dbo.strpos(@USLUGA, 'Горячая вода Гор.водоснаб. ГВС ГВС УКС Горячее водоснабжение Горячее водоснаб.') > 0
			SELECT @service_id = 'гвод'
				 , @unit_id = 'кубм'
		IF dbo.strpos(@USLUGA, 'Газ') > 0
			SELECT @service_id = 'пгаз'
				 , @unit_id = 'кубм'
		IF dbo.strpos(@USLUGA, 'Электричество Электроэнергия эл.энергия Электроснабжение ЭЭ Э/Э') > 0
			SELECT @service_id = 'элек'
				 , @unit_id = 'квтч'
		IF dbo.strpos(@USLUGA, 'Отопление ТЭ') > 0
			SELECT @service_id = 'отоп'
				 , @unit_id = 'ггкл'

		IF @USLUGA = 'Обслуживание жилого фонда'
			RETURN -1

		IF @service_id IS NULL
		BEGIN
			RAISERROR ('Не удалось определить услугу: %s', 16, 1, @USLUGA);
			RETURN -1
		END

		SELECT @build_id=b.id
			,@fin_current=b.fin_current
		FROM dbo.Buildings as b
			JOIN dbo.Streets as s ON b.street_id=s.id
		WHERE b.nom_dom=@nom_dom
			and s.Name=@street_name
			and b.tip_id=@tip_id

		if @build_id is NULL
		BEGIN
			RAISERROR ('Не удалось найти дом в базе по адресу: %s  %s', 16, 1, @street_name, @nom_dom);
			RETURN -1
		END

		SELECT @max_value =
						   CASE
							   WHEN @RAZRAD = 3 THEN 999
							   WHEN @RAZRAD = 4 THEN 9999
							   WHEN @RAZRAD = 5 THEN 99999
							   WHEN @RAZRAD = 6 THEN 999999
							   WHEN @RAZRAD = 7 THEN 9999999
							   WHEN @RAZRAD = 8 THEN 99999999
							   WHEN @RAZRAD = 9 THEN 999999999
							   ELSE CASE
                                        WHEN @service_id = 'элек' THEN 999999
                                        ELSE 99999
                                   END
						   END
	
		IF @PeriodInterval IS NULL
			SELECT @PeriodInterval = CASE 
				WHEN @service_id='элек' THEN 16				
				ELSE 6
			END

		IF @DPOVER IS NOT NULL
			AND @PeriodLastCheck IS NULL
		BEGIN
			SET @PeriodLastCheck=DATEADD(YEAR,-@PeriodInterval,@DPOVER)
			IF @PeriodLastCheck<@DUSTAN
				SET @PeriodLastCheck=@DUSTAN
		END
		
		-- Находим счётчик если есть
		IF NOT EXISTS (
				SELECT 1
				FROM dbo.Counters
				WHERE service_id = @service_id
					AND build_id = @build_id					
					AND serial_number = @NOMER					
			)
		BEGIN -- Добавляем
			INSERT INTO dbo.Counters ([service_id]
									, [serial_number]
									, [type]
									, [build_id]
									, [flat_id]
									, [max_value]
									, [Koef]
									, [unit_id]
									, [count_value]
									, [date_create]
									, [CountValue_del]
									, [date_del]
									, [PeriodCheck]
									, [user_edit]
									, [date_edit]
									, [internal]
									, [is_build]
									, [checked_fin_id]
									, PeriodInterval
									, PeriodLastCheck)
			VALUES(@service_id
				 , @NOMER
				 , @MARKA
				 , @build_id
				 , NULL  --flat_id
				 , @max_value
				 , 1  -- Koef
				 , @unit_id
				 , CASE @set_POSLPOK_begin
					   WHEN 1 THEN @POSLPOK
					   ELSE 0
				   END
				 , @DUSTAN
				 , 0
				 , NULL
				 , @DPOVER
				 , NULL
				 , NULL
				 , 1
				 , 1  --is_build
				 , NULL
				 , @PeriodInterval
				 , @PeriodLastCheck)

			SELECT @counter_id = SCOPE_IDENTITY()
				 , @ResultAdd = 1
		END
		ELSE
			SELECT @counter_id = id
			FROM dbo.Counters
			WHERE service_id = @service_id
				AND build_id = @build_id
				AND serial_number = @NOMER

		IF @set_POSLPOK_begin = 0
		BEGIN
			-- добавляем последне показание
			IF @POSLDATA IS NOT NULL
			BEGIN
				DELETE FROM dbo.Counter_inspector
				WHERE counter_id = @counter_id
					AND tip_value = 2

				INSERT INTO dbo.Counter_inspector ([counter_id]
												 , [tip_value]
												 , [inspector_value]
												 , [inspector_date]
												 , [blocked]
												 , [user_edit]
												 , [date_edit]
												 , [kol_day]
												 , [actual_value]
												 , [value_vday]
												 , [comments]
												 , [fin_id]
												 , [mode_id]
												 , [tarif]
												 , [value_paym])
				VALUES(@counter_id
					 , 2  -- общедомовое показание
					 , @POSLPOK
					 , @POSLDATA
					 , 0 -- blocked
					 , 0 -- user_edit
					 , dbo.Fun_GetOnlyDate(current_timestamp)
					 , 0  -- kol_day
					 , 0  -- actual_value
					 , 0  -- value_vday
					 , NULL  -- comments
					 , @fin_current - 1 -- fin_id
					 , 0  -- mode_id
					 , NULL
					 , NULL)
			END
		END

	END TRY
	BEGIN CATCH
		EXEC dbo.k_err_messages
	END CATCH

END
go

