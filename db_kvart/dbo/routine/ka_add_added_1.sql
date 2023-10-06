CREATE   PROCEDURE [dbo].[ka_add_added_1]
(
	  @occ1 INT
	,                 -- лицевой счет      
	  @service_id1 VARCHAR(10)
	,  -- код услуги
	  @add_type1 INT
	,            -- тип разового
	  @doc1 VARCHAR(100)
	,        -- документ
	  @value1 DECIMAL(10, 4)
	,        -- сумма    должна быть больше 0
	  @day_count1 SMALLINT
	, @people_count1 SMALLINT
	, @service_all BIT
	,         -- 1 - все услуги
	  @Fin_id1 SMALLINT          -- Финансовый период
)
AS
	--  
	--  НЕ ИСПОЛЬЗУЕТСЯ
	--
	--  Ввод разовых по всем типам кроме
	--  недопоставка услуги и технической корректировки
	--

	IF dbo.Fun_AccessAddLic(@occ1) = 0
	BEGIN
		RAISERROR ('Для Вас работа с Разовыми запрещена', 16, 1)
		RETURN
	END

	IF @value1 < 0
	BEGIN
		RAISERROR ('Сумма должна быть положительной', 16, 1)
		RETURN
	END

	SET NOCOUNT ON

	-- Возврат по отсутствующим(3)  и доначисления по временно проживающим (7)
	IF (@add_type1 = 3)
		OR (@add_type1 = 7)
	BEGIN
		DECLARE @factor SMALLINT
		IF @add_type1 = 3
			SET @factor = -1
		IF @add_type1 = 7
			SET @factor = 1

		CREATE TABLE #added_srvc (
			  SERVICE_ID VARCHAR(10) COLLATE database_default NOT NULL
			, [VALUE] DECIMAL(8, 2) NOT NULL
		)
		-- Вставляем в таблицу услуги на которые будут вводиться разовые
		INSERT #added_srvc
		SELECT s.id
			 , 0
			 , 0
		FROM Occupations AS o
		   , Consmodes_list AS cl
		   , Services AS s
		   , Service_units AS su
		WHERE o.occ = @occ1
			AND cl.occ = o.occ
			AND cl.SERVICE_ID = s.id
			AND (cl.mode_id % 1000) != 0
			AND s.id = su.SERVICE_ID
			AND su.unit_id = 'люди'
			AND su.roomtype_id = o.roomtype_id
		--***************************************

		-- если разовые по одной услуге то удаляем все другие
		IF @service_all = 0
		BEGIN
			DELETE FROM #added_srvc
			WHERE SERVICE_ID != @service_id1
		END
		--
		DECLARE @serv1 VARCHAR(10)
			  , @summa1 DECIMAL(8, 2)
		--*******************************************************************
		BEGIN TRAN

		--  SELECT  @last_add_id = MAX( ID )  FROM ADDED_PAYMENTS
		--  IF ( @last_add_id IS NULL ) SELECT  @last_add_id = 0

		DECLARE ADD_UPD_CUR CURSOR FOR
			SELECT SERVICE_ID
			FROM #added_srvc
		OPEN ADD_UPD_CUR
		FETCH NEXT FROM ADD_UPD_CUR INTO @serv1

		WHILE (@@fetch_status <> -1)
		BEGIN
			--       SELECT @last_add_id = @last_add_id+1
			IF @service_all = 0
			BEGIN
				SET @summa1 = @value1
			END
			ELSE
			BEGIN
				SET @summa1 = dbo.Fun_GetSummaAdd(@occ1, @serv1, @day_count1, @people_count1, @Fin_id1)
			END
			SET @summa1 = @summa1 * @factor

			UPDATE #added_srvc
			SET VALUE = @summa1
			WHERE SERVICE_ID = @serv1
				AND @summa1 <> 0

			FETCH NEXT FROM ADD_UPD_CUR INTO @serv1
		END

		CLOSE ADD_UPD_CUR
		DEALLOCATE ADD_UPD_CUR

		-- Добавить в таблицу added_payments
		INSERT Added_Payments
		SELECT @occ1
			 , SERVICE_ID
			 , @add_type1
			 , @doc1
			 , VALUE
		FROM #added_srvc
		WHERE VALUE <> 0

		DROP TABLE #added_srvc

		-- Изменить значения в таблице paym_list
		UPDATE Paym_list
		SET Added = COALESCE((
			SELECT SUM(VALUE)
			FROM Added_Payments
			WHERE occ = @occ1
				AND SERVICE_ID = pl.SERVICE_ID
		), 0)
		FROM Paym_list AS pl
		WHERE occ = @occ1

		-- сохраняем в историю изменений
		EXEC k_write_log @occ1
					   , 'раз!'

		COMMIT TRAN

	END  --if  (@add_type1=3) OR  (@add_type1=7)
go

