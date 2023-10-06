CREATE   PROCEDURE [dbo].[k_raschet_paymaccount]
(
	  @occ1 INT
	, @debug BIT = 0
	, @RaskidkaOcc BIT = 0-- Раскидывать всегда
)
AS
	/*
	exec [k_raschet_paymaccount] 210024811,1
	
	Раскидываем оплату(оплату пени) по услугам
	по единой квитанции
	

	09.08.2018 убрал удаление из PAYING_SERV
	*/
	SET NOCOUNT ON

	DECLARE @Paymaccount1 DECIMAL(9, 2) -- оплата по единой квитанции
		  , @Paymaccount_peny1 DECIMAL(9, 2) -- оплата пени по единой квитанции
		  , @Db_Name VARCHAR(20) = UPPER(DB_NAME())
		  , @fin_id1 SMALLINT -- код фин.периода
		  , @paying_id1 INT
		  , @err INT
		  , @ostatok DECIMAL(9, 2)
		  , @koef DECIMAL(16, 8)
		  , @tip_id SMALLINT
		  , @paymaccount_minus BIT = 0 -- можно формировать отрицательные оплаты
		  , @PaymRaskidkaAlways BIT = 0 -- всегда раскидывать по услугам
		  , @tip_paym_blocked BIT = 0 -- блокировка оплаты по типу фонда
		  , @is_recom_for_payment BIT = 0 -- по методическим рекомендациям раскидки платежей

	IF @RaskidkaOcc IS NULL
		SET @RaskidkaOcc = 0

	-- текущий фин.период
	SELECT @fin_id1 = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	SELECT @tip_id = ot.id
		 , @paymaccount_minus = COALESCE(ot.paymaccount_minus, 0)
		 , @PaymRaskidkaAlways = COALESCE(ot.PaymRaskidkaAlways, 0)
		 , @tip_paym_blocked = COALESCE(ot.tip_paym_blocked, 0)
		 , @is_recom_for_payment = ot.is_recom_for_payment
	FROM dbo.Occupations AS o 
		JOIN dbo.Occupation_Types AS ot ON 
			o.tip_id = ot.id
	WHERE o.occ = @occ1

	IF @debug = 1
		SELECT @tip_id AS tip_id
			 , @paymaccount_minus AS paymaccount_minus
			 , @PaymRaskidkaAlways AS PaymRaskidkaAlways
			 , @tip_paym_blocked AS tip_paym_blocked
			 , @is_recom_for_payment AS is_recom_for_payment

	IF @RaskidkaOcc = 1
		SET @PaymRaskidkaAlways = 1

	BEGIN TRY

		DECLARE @t_payings TABLE (
			  paying_id INT PRIMARY KEY
			, [date_paym] SMALLDATETIME
		)

		INSERT INTO @t_payings (paying_id
							  , [date_paym])
		SELECT p.id
			 , pd.day
		FROM dbo.Paydoc_packs AS pd
			JOIN dbo.Payings AS p ON 
				pd.id = p.pack_id
		WHERE pd.fin_id = @fin_id1   -- 04.03.22 убрал знак >=
			AND p.occ = @occ1
			AND p.forwarded = 1 -- 27/08/2012

		IF NOT EXISTS (SELECT 1 FROM @t_payings)
			OR @tip_paym_blocked = 1
		BEGIN -- платежей нет
			IF @debug = 1
				RAISERROR ('Платежей нет. Зачищаем поля', 10, 1, @paying_id1)

			UPDATE p
			SET Paymaccount = 0
			  , Paymaccount_peny = 0
			FROM dbo.Paym_list AS p
			WHERE occ = @occ1

			RETURN
		END

		-- Удаляем платежи которых сейчас нет в тек.месяце
		--DELETE ps WITH (ROWLOCK)
		--	FROM dbo.PAYING_SERV ps
		--WHERE ps.fin_id = @fin_id1
		--	AND ps.occ = @occ1
		--	AND NOT EXISTS (SELECT
		--			1
		--		FROM @t_payings t
		--		WHERE t.paying_id = ps.paying_id)

		DECLARE some_cur1 CURSOR LOCAL FOR
			SELECT paying_id
			FROM @t_payings
			ORDER BY paying_id --date_paym

		OPEN some_cur1

		WHILE 1 = 1
		BEGIN
			FETCH NEXT FROM some_cur1 INTO @paying_id1

			IF @@fetch_status <> 0
				BREAK

			IF @PaymRaskidkaAlways = 1
				OR -- Раскидываем кому надо всегда
				-- раскидываем по услугам только не раскиданные ещё
				NOT EXISTS (
					SELECT 1
					FROM dbo.Paying_serv
					WHERE paying_id = @paying_id1
						AND occ = @occ1
				)
			BEGIN
				
				if @is_recom_for_payment = 1 
				BEGIN -- новая процедура раскидки
					IF @debug = 1
						RAISERROR ('EXEC k_payings_serv_add5 @paying_id = %d, @debug = 0', 10, 1, @paying_id1)

					EXEC dbo.k_payings_serv_add5 @paying_id = @paying_id1, @debug = @debug
				END
				ELSE
				BEGIN
					IF @debug = 1
						RAISERROR ('Код платежа: %d.раскидка с отриц.оплатами в k_payings_serv_add4 %d', 10, 1, @paying_id1, @paying_id1)
					EXEC dbo.k_payings_serv_add4 @paying_id = @paying_id1, @debug = @debug
				END;
				
			--ELSE
			--	EXEC dbo.k_payings_serv_add3 @paying_id = @paying_id1
			--								,@debug = @debug
			END
			ELSE
			IF @debug = 1
				RAISERROR (' %d уже раскидан по услугам', 10, 1, @paying_id1)
		END

		CLOSE some_cur1
		DEALLOCATE some_cur1


		--select * from dbo.PAYING_SERV WHERE fin_id=@fin_id1 AND occ=@occ1

		-- временная таблица для обработки
		DECLARE @t1 TABLE (
			  occ INT
			, service_id VARCHAR(10)
			, sup_id INT DEFAULT NULL
			, Paymaccount DECIMAL(9, 2) DEFAULT 0
			, Paymaccount_peny DECIMAL(9, 2) DEFAULT 0
			, account_one BIT DEFAULT NULL
		--,PRIMARY KEY (occ,service_id,sup_id) 
		)

		-- для раскидки остатка
		INSERT INTO @t1
		SELECT DISTINCT @occ1
			 , s.id AS service_id
			 , CASE
                   WHEN PL.sup_id IS NULL THEN COALESCE(cl.sup_id, 0)
                   ELSE PL.sup_id
            END
			 , 0 AS Paymaccount
			 , 0 AS Paymaccount_peny
			 , CASE
                   WHEN PL.account_one IS NULL THEN COALESCE(cl.account_one, 0)
                   ELSE PL.account_one
            END
		FROM dbo.Services s
			LEFT JOIN dbo.Paym_list AS PL ON 
				PL.occ = @occ1
				AND s.id = PL.service_id 
				AND pl.occ = @occ1 
			LEFT JOIN dbo.Consmodes_list AS cl ON 
				s.id = cl.service_id
				AND cl.occ=pl.occ	 	
				AND (PL.sup_id = cl.sup_id OR PL.source_id = cl.source_id)

		UPDATE t1
		SET Paymaccount = COALESCE(p.Paymaccount, 0)
		  , Paymaccount_peny = COALESCE(p.Paymaccount_peny, 0)
		  , sup_id = COALESCE(p.sup_id, 0)
		FROM @t1 AS t1
			JOIN (
				SELECT ps.service_id
					 , ps.sup_id
					 , COALESCE(SUM(value), 0) AS paymaccount
					 , SUM(COALESCE(ps.paymaccount_peny, 0)) AS paymaccount_peny
				FROM dbo.Paying_serv AS ps
					JOIN @t_payings t ON 
						t.paying_id = ps.paying_id
				WHERE ps.occ = @occ1
				GROUP BY ps.service_id
					   , ps.sup_id
			) AS p ON 
				p.service_id = t1.service_id
				AND p.sup_id = t1.sup_id

		--SELECT
		--	@Paymaccount1 = SUM(Paymaccount), @Paymaccount_peny1=SUM(Paymaccount_peny)
		--FROM @t1
		IF @debug = 1
			SELECT '@t1 2', *	FROM @t1

		DELETE FROM @t1 WHERE Paymaccount=0 AND Paymaccount_peny=0

		IF @debug = 1
		BEGIN
			SELECT '@t1'
				 , *
			FROM @t1
			WHERE Paymaccount <> 0
				OR Paymaccount_peny <> 0
			
			SELECT 'Paying_serv', *
				FROM dbo.Paying_serv AS ps
				JOIN dbo.Payings p ON 
					ps.paying_id = p.id
				WHERE p.occ = @occ1
					AND p.fin_id=@fin_id1
		END

		IF EXISTS (
				SELECT 1
				FROM @t1
				WHERE Paymaccount <> 0
					OR Paymaccount_peny <> 0
			)
		BEGIN
			IF @debug = 1
				PRINT 'MERGE dbo.PAYM_LIST'
			--IF @debug = 1
			--	SELECT * from PAYM_LIST WHERE occ=@occ1

			MERGE dbo.Paym_list AS p USING @t1 AS t
			ON p.occ = t.occ
				AND p.service_id = t.service_id
				AND p.sup_id = t.sup_id
			WHEN MATCHED
				AND (p.Paymaccount <> t.Paymaccount OR p.Paymaccount_peny <> t.Paymaccount_peny)
				THEN UPDATE
					SET -- обновляем оплату
					Paymaccount = t.Paymaccount
				  , Paymaccount_peny = t.Paymaccount_peny
				  , account_one =
								 CASE
									 WHEN p.account_one = 0 THEN t.account_one
									 ELSE p.account_one
								 END
			WHEN NOT MATCHED -- добавляем строки с оплатой
				THEN INSERT (fin_id
						   , occ
						   , service_id
						   , sup_id
						   , subsid_only
						   , account_one
						   , tarif
						   , koef
						   , kol
						   , saldo
						   , value
						   , added
						   , Paymaccount
						   , Paymaccount_peny
						   , paid)
					VALUES(@fin_id1
						 , t.occ
						 , t.service_id
						 , t.sup_id
						 , 0 -- subsid_only
						 , t.account_one
						 , 0 -- tarif
						 , 1 -- KOEF
						 , 0 -- kol
						 , 0 -- saldo
						 , 0 -- value
						 , 0 -- added
						 , t.Paymaccount
						 , t.Paymaccount_peny
						 , 0 -- paid
					);
		END

	LABEL_END:
		IF @debug = 1
			SELECT '@t1'
				 , *
			FROM @t1
		IF @debug = 1
			SELECT 'Paym_list', *
			FROM dbo.Paym_list
			WHERE occ = @occ1
		RETURN

	END TRY
	BEGIN CATCH

		EXEC dbo.k_err_messages

	END CATCH
go

