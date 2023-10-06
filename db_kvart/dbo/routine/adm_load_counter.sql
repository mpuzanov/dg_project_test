-- =============================================
-- Author:		Пузанов
-- Create date: 22.09.2011
-- Description:	Загрузка данных
-- =============================================
CREATE           PROCEDURE [dbo].[adm_load_counter]
(
	  @NEW_LS INT = NULL -- лицевой счет
	, @MARKA VARCHAR(30) -- Тип счётчика
	, @NOMER VARCHAR(20) -- Серийный номер
	, @RAZRAD INT -- Разряд счётчика
	, @DUSTAN SMALLDATETIME -- Дата установки
	, @DPOVER SMALLDATETIME = NULL -- Дата поверки
	, @USLUGA VARCHAR(100) -- Услуга
	, @VIDSCH VARCHAR(20) = '' -- Кор.назв. услуги + где стоит
	, @POSLPOK DECIMAL(12, 4) -- Последнее показание
	, @POSLDATA SMALLDATETIME -- Дата последнего показания
	, @SET_POSLPOK_BEGIN BIT = 0 -- устанавливать последние показания начальными
	, @PeriodLastCheck SMALLDATETIME = NULL -- Последняя Дата поверки
	, @PeriodInterval INT = NULL -- Межповерочный интервал
	, @ResultAdd BIT = 0 OUTPUT-- 0- не добавили, 1-добавили
	, @counter_id INT = NULL OUTPUT
	, @strerror VARCHAR(4000) = '' OUTPUT
	, @town_name VARCHAR(20) = NULL
	, @street_name VARCHAR(50) = NULL
	, @nom_dom VARCHAR(12) = NULL
	, @nom_kvr VARCHAR(20) = NULL
)
AS
BEGIN

	SET NOCOUNT ON;

	SET @ResultAdd = 0
	--IF @new_ls<99999999 RETURN
	IF @NEW_LS=0
		SET @NEW_LS=NULL
	IF @set_POSLPOK_begin IS NULL
		SET @set_POSLPOK_begin = 0

	IF (@NEW_LS IS NULL)
	BEGIN
		SELECT TOP(1)
			@NEW_LS=o.occ
		FROM dbo.Occupations AS o
		JOIN dbo.Flats AS f
			ON o.flat_id = f.id
		JOIN dbo.Buildings AS b 
			ON f.bldn_id = b.id
		JOIN dbo.VStreets AS s
			ON b.street_id = s.id
		JOIN dbo.Towns as t ON t.ID=b.town_id
		WHERE (s.name=@street_name or s.short_name=@street_name or s.name_socr=@street_name)
			AND b.nom_dom = @Nom_dom 
			AND (@Nom_kvr IS NULL OR f.nom_kvr = @Nom_kvr)
			AND (@town_name is null OR t.NAME=@town_name)
	END
	-- если такого лицевого нет в базе то пропускаем
	IF NOT EXISTS (
			SELECT 1
			FROM dbo.Occupations
			WHERE occ = @NEW_LS
		)
		BEGIN
			SET @strerror='лицевого '+STR(COALESCE(@NEW_LS,0))+' нет в базе'
			RETURN
		END

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

		DECLARE @build_id INT
			  , @flat_id INT
			  , @service_id VARCHAR(10) = NULL
			  , @unit_id VARCHAR(10)
			  , @max_value INT = 9
			  , @fin_current SMALLINT

		-- Находим код дома и квартиры	
		SELECT @build_id = f.bldn_id
			 , @flat_id = f.id
			 , @fin_current = b.fin_current
		FROM dbo.Occupations AS o 
			JOIN dbo.Flats AS f ON o.flat_id = f.id
			JOIN dbo.Buildings AS b ON f.bldn_id=b.id
		WHERE o.occ = @NEW_LS

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
			SELECT @PeriodInterval = CASE @service_id
				WHEN 'элек' THEN 16
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
					AND flat_id = @flat_id
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
									, [comments]
									, [internal]
									, [is_build]
									, [checked_fin_id]
									, PeriodInterval
									, PeriodLastCheck)
			VALUES(@service_id
				 , @NOMER
				 , @MARKA
				 , @build_id
				 , @flat_id
				 , @max_value
				 , 1
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
				 , @VIDSCH
				 , 1
				 , 0
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
				AND flat_id = @flat_id
				AND serial_number = @NOMER

		-- Проверяем есть ли лицевой с этим счётчиком
		DECLARE @occ INT = NULL
		SELECT @occ = occ
		FROM dbo.Counter_list_all
		WHERE counter_id = @counter_id
			AND occ = @NEW_LS
			AND fin_id = @fin_current

		IF @occ IS NULL
		BEGIN -- добавляем лицевые счета в периоды после создания ПУ
			INSERT INTO dbo.Counter_list_all (fin_id
											, [counter_id]
											, [occ]
											, [service_id]
											, [occ_counter]
											, [internal])
			SELECT gv.fin_id
				 , @counter_id
				 , @NEW_LS
				 , @service_id
				 , dbo.Fun_GetService_Occ(@NEW_LS % 1000000, @service_id)
				 , 1
			FROM Global_values gv
			WHERE gv.end_date > @DUSTAN
				AND NOT EXISTS (
					SELECT *
					FROM Counter_list_all cl
					WHERE cl.fin_id = gv.fin_id
						AND cl.occ = @NEW_LS
						AND cl.counter_id = @counter_id
				)
			--VALUES (@fin_current
			--	   ,@counter_id
			--	   ,@NEW_LS
			--	   ,@service_id
			--	   ,dbo.Fun_GetService_Occ(@NEW_LS % 1000000, @service_id)
			--	   ,1)

			SELECT @occ = @NEW_LS
		END

		IF @set_POSLPOK_begin = 0
		BEGIN
			-- добавляем последне показание
			IF @POSLDATA IS NOT NULL
			BEGIN
				DELETE FROM dbo.Counter_inspector
				WHERE counter_id = @counter_id
					AND tip_value = 1

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
					 , 1
					 , @POSLPOK
					 , @POSLDATA
					 , 0
					 , 0
					 , dbo.Fun_GetOnlyDate(current_timestamp)
					 , 0
					 , 0
					 , 0
					 , NULL
					 , @fin_current - 1
					 , 0
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

