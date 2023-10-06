-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE             TRIGGER [dbo].[tr_counter_update]
ON [dbo].[Counters]
AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (
			SELECT
				i.id
				,i.PeriodLastCheck
				,i.PeriodInterval
				,i.PeriodCheck
				,i.id_pu_gis
			FROM INSERTED i
			EXCEPT
			SELECT
				d.id
				,d.PeriodLastCheck
				,d.PeriodInterval
				,d.PeriodCheck
				,d.id_pu_gis
			FROM DELETED d
			)
	BEGIN
		DECLARE @PeriodCheckOld	 SMALLDATETIME
			   ,@PeriodCheckNew	 SMALLDATETIME
			   ,@PeriodLastCheck SMALLDATETIME
			   ,@service_id		 CHAR
			   ,@id				 INT
			   ,@flat_id		 INT
			   ,@id_pu_gis		 VARCHAR(15)
			   ,@id_pu_gis_new	 VARCHAR(15)
			   ,@msg			 VARCHAR(100) = ''

		SELECT
			@PeriodCheckOld = d.PeriodCheck
		   ,@PeriodCheckNew = I.PeriodCheck
		   ,@PeriodLastCheck = I.PeriodLastCheck
		   ,@service_id = d.service_id
		   ,@id = d.id
		   ,@flat_id = d.flat_id
		   ,@id_pu_gis = d.id_pu_gis
		   ,@id_pu_gis_new = i.id_pu_gis
		FROM DELETED AS d
		JOIN INSERTED AS I ON 
			d.id = I.id

		IF @PeriodLastCheck > current_timestamp
		BEGIN
			RAISERROR ('Последний период поверки не может быть больше текущей даты! Исправьте.', 16, 10)
			ROLLBACK TRANSACTION
			RETURN
		END

		IF @id_pu_gis IS NOT NULL AND @id_pu_gis<>@id_pu_gis_new
		BEGIN
			SET @msg='Старое знач кода ПУ в ГИС '+ @id_pu_gis

			IF (system_user NOT IN ('sa')) -- sa не логировать
				EXEC k_counter_write_log @counter_id1 = @id
										,@oper1 = 'счпв'
										,@comments1 = @msg
		END
		
		ELSE
		
		IF (@PeriodCheckOld <> @PeriodCheckNew)
			OR (@PeriodCheckOld IS NULL
			AND @PeriodCheckNew IS NOT NULL)
		BEGIN
			-- Сохраняем старое значение
			UPDATE Counters
			SET PeriodCheckOld  = @PeriodCheckOld
			   ,PeriodCheckEdit = current_timestamp
			WHERE id = @id

			-- сохраняем в историю изменений			
			IF @PeriodCheckOld IS NULL
				SET @msg = 'Новое знач периода поверки:' + CONVERT(VARCHAR(10), @PeriodCheckNew, 104)
			ELSE
				SET @msg = 'Старое знач периода поверки: ' + CONVERT(VARCHAR(10), @PeriodCheckOld, 104) + '; Новое:' + CONVERT(VARCHAR(10), @PeriodCheckNew, 104)

			IF (system_user NOT IN ('sa')) -- sa не логировать
				EXEC k_counter_write_log @counter_id1 = @id
										,@oper1 = 'счпв'
										,@comments1 = @msg

			-- Надо пересчитать	колонку "KolmesForPeriodCheck"	
			UPDATE cl
			SET KolmesForPeriodCheck = KolmesForPeriodCheck2
			FROM dbo.Occupations AS o 
				JOIN dbo.Occupation_Types ot ON 
					o.tip_id = ot.id
				JOIN dbo.Counter_list_all AS cl ON 
					o.Occ = cl.Occ
				JOIN dbo.Counters c ON 
					cl.counter_id = c.id
				CROSS APPLY (SELECT KolmesForPeriodCheck2 = dbo.Fun_GetKolMonthPeriodCheck(cl.Occ, cl.fin_id, cl.service_id)) AS t
				WHERE 
					cl.fin_id < o.fin_id
					AND o.status_id <> 'закр'
					AND c.PeriodCheck IS NOT NULL
					AND o.flat_id = @flat_id
					AND c.date_del IS NULL
					AND cl.fin_id >= (ot.fin_id-12*3)  -- за 3 года
					AND ot.payms_value = CAST(1 AS BIT)	
					AND KolmesForPeriodCheck <> t.KolmesForPeriodCheck2

			--UPDATE T
			--SET KolmesForPeriodCheck = KolmesForPeriodCheck2
			--FROM (SELECT
			--		cl.Occ
			--	   ,cl.KolmesForPeriodCheck
			--	   ,KolmesForPeriodCheck2 = dbo.Fun_GetKolMonthPeriodCheck(cl.Occ, cl.fin_id, cl.service_id)
			--	FROM dbo.OCCUPATIONS AS o
			--	JOIN dbo.OCCUPATION_TYPES ot
			--		ON o.tip_id = ot.id
			--	JOIN dbo.COUNTER_LIST_ALL AS cl
			--		ON o.Occ = cl.Occ
			--	JOIN dbo.COUNTERS c
			--		ON cl.counter_id = c.id
			--	WHERE cl.fin_id < ot.fin_id
			--	AND o.STATUS_ID <> 'закр'
			--	AND o.flat_id = @flat_id
			--	AND c.date_del IS NULL) AS T
			--WHERE KolmesForPeriodCheck <> KolmesForPeriodCheck2

		END

	END

	--дату редактирования меняем если изменились важные поля
	-- если есть изменения в этих полях то ведём лог
	IF EXISTS (
			SELECT
				i.id
			   ,i.serial_number
			   ,i.type
			   ,i.build_id
			   ,i.flat_id
			   ,i.date_create
			   ,i.count_value
			   ,i.date_del
			   ,i.CountValue_del
			   ,i.PeriodCheck
			   ,i.PeriodInterval
			   ,i.PeriodLastCheck
			   ,i.is_sensor_temp
			   ,i.is_sensor_press
			   ,i.is_remot_reading
			FROM INSERTED i
			EXCEPT
			SELECT
				d.id
			   ,d.serial_number
			   ,d.type
			   ,d.build_id
			   ,d.flat_id
			   ,d.date_create
			   ,d.count_value
			   ,d.date_del
			   ,d.CountValue_del
			   ,d.PeriodCheck
			   ,d.PeriodInterval
			   ,d.PeriodLastCheck
			   ,d.is_sensor_temp
			   ,d.is_sensor_press
			   ,d.is_remot_reading
			FROM DELETED d
			)
	BEGIN
		UPDATE t
		SET date_edit = dbo.Fun_GetOnlyDate(
			CASE
				WHEN t.date_edit IS NULL AND
				t.date_del IS NULL THEN t.date_create
				WHEN t.date_edit IS NULL AND
				t.date_del IS NOT NULL THEN t.date_del
				ELSE current_timestamp
			END )
		FROM dbo.Counters AS t
		JOIN INSERTED AS i ON 
			t.id = i.id

	END



END
go

