-- =============================================
-- Author:		Пузанов М.А.
-- Create date: 25.09.2014
-- Description:	Раскидка пени по услугам по лицевому счёту
-- =============================================
CREATE                 PROCEDURE [dbo].[k_raschet_peny_serv]
(
	  @occ INT
	, @fin_id SMALLINT
	, @sup_id INT = NULL
	, @debug BIT = 0
	, @res BIT = 0
)
AS
/*
exec [k_raschet_peny_serv] 30003,232,NULL,1
exec [k_raschet_peny_serv] 480007,232,null,1

exec [k_raschet_peny_serv] 700005621,152,NULL,1

exec k_raschet_peny_serv 6040385, 190, null, 1

Если поставщик задан то раскидываем только на услуги поставщика
если нет то исключить услуги с отдельной квитанцией "account_one=1"
*/
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON

	DECLARE @penalty_value DECIMAL(9, 2)
		  , @penalty_added DECIMAL(9, 2)
		  , @penalty DECIMAL(9, 2)
		  , @paymaccount_peny_itog DECIMAL(9, 2)
		  , @paid DECIMAL(9, 2)
		  , @service_id VARCHAR(10)
		  , @strerror VARCHAR(800)
		  , @is_peny_serv BIT
		  , @peny_service_id VARCHAR(10)

	IF @sup_id IS NULL
		SET @sup_id = 0

	IF @sup_id = 0
		SELECT @penalty = o.penalty_value + o.Penalty_added
			 , @penalty_value = o.penalty_value
			 , @penalty_added = o.Penalty_added
			 , @paymaccount_peny_itog = o.PaymAccount_peny
			 , @is_peny_serv = ot.is_peny_serv
			 , @peny_service_id = COALESCE(b.peny_service_id, COALESCE(ot.peny_service_id, ''))  
		FROM dbo.View_occ_all_lite AS o 
			JOIN dbo.Occupation_Types AS ot 
				ON o.tip_id = ot.id
			JOIN dbo.Buildings AS b
				ON o.build_id=b.id
		WHERE o.Occ = @occ
			AND o.fin_id = @fin_id
	ELSE
		SELECT @penalty = os.penalty_value + os.Penalty_added
			 , @penalty_value = os.penalty_value
			 , @penalty_added = os.Penalty_added
			 , @paymaccount_peny_itog = os.PaymAccount_peny
			 , @is_peny_serv = 0  --ot.is_peny_serv  -- не для поставщиков
			 , @peny_service_id = '' --COALESCE(ot.peny_service_id, '')
		FROM dbo.Occ_Suppliers AS os
			JOIN dbo.Occupations o 
				ON os.Occ = o.Occ
			JOIN dbo.Occupation_Types AS ot 
				ON o.tip_id = ot.id
		WHERE os.Occ = @occ
			AND os.fin_id = @fin_id
			AND os.sup_id = @sup_id

	-- ************** Раскидка оплаты пени у платежей с ручной оплатой пеней
	DECLARE @paying_id INT
		  , @peny_save BIT
		  , @paymaccount_peny1 DECIMAL(9, 2)

	DECLARE cur CURSOR LOCAL FOR
		SELECT p.id
			 , p.peny_save
			 , p.PaymAccount_peny
		FROM dbo.Payings AS p
			JOIN dbo.Paydoc_packs pp 
				ON p.pack_id = pp.id
		WHERE pp.fin_id = @fin_id
			AND p.Occ = @occ
			AND p.sup_id = @sup_id
			--AND p.peny_save = 1
			AND pp.forwarded = 1

	OPEN cur
	FETCH NEXT FROM cur INTO @paying_id, @peny_save, @paymaccount_peny1

	WHILE @@fetch_status = 0
	BEGIN
		IF @debug = 1
			PRINT 'k_paying_serv_peny ' + STR(@paying_id) + ' @paymaccount_peny_itog=' + STR(@paymaccount_peny_itog, 9, 2) + ' @paymaccount_peny1=' + STR(@paymaccount_peny1, 9, 2)

		IF (@peny_save = 1
			OR @paymaccount_peny_itog = 0)
			EXEC k_paying_serv_peny @paying_id = @paying_id
								  , @Paymaccount_peny = 0
								  , @sup_id = @sup_id
		ELSE
			EXEC k_paying_serv_peny @paying_id = @paying_id
								  , @Paymaccount_peny = @paymaccount_peny1
								  , @sup_id = @sup_id

		FETCH NEXT FROM cur INTO @paying_id, @peny_save, @paymaccount_peny1
	END

	CLOSE cur
	DEALLOCATE cur
	-- ******************************************************

	IF @debug = 1
		PRINT 'k_raschet_peny_serv ' + STR(@occ) + ' ' + STR(@penalty, 9, 2)

	IF @debug = 1
		PRINT '@is_peny_serv' + STR(@is_peny_serv)

	BEGIN TRY


		IF COALESCE(@penalty, 0) = 0
		BEGIN
			IF @debug = 1
				PRINT 'Пени нет - очищаем таблички и выходим'

			BEGIN TRAN

			IF @is_peny_serv = 0
			BEGIN
				UPDATE dbo.Paym_list
				SET penalty_serv = 0
				WHERE fin_id = @fin_id
					AND Occ = @occ
					AND sup_id = @sup_id;
			END
			ELSE
				UPDATE dbo.Paym_list
				SET Value = 0
				  , Added = 0
				WHERE fin_id = @fin_id
					AND Occ = @occ
					AND sup_id = @sup_id
					AND service_id = 'пени';

			COMMIT TRAN

			RETURN 0
		END

		UPDATE dbo.Paym_list
		SET penalty_serv = 0
		WHERE fin_id = @fin_id
			AND Occ = @occ
			AND sup_id = @sup_id

		IF (@is_peny_serv = 1)
		BEGIN
			IF @debug = 1
				PRINT 'пени как услуга'

			BEGIN TRAN

			-- по услуге пени ставим value и added
			MERGE dbo.Paym_list AS Target USING (VALUES(@penalty_value, @penalty_added))
			AS Source (penalty_value, penalty_added)
			ON Target.Occ = @occ
				AND Target.fin_id = @fin_id
				AND Target.service_id = 'пени'
				AND Target.sup_id = @sup_id
			WHEN MATCHED
				THEN UPDATE
					SET Value = Source.penalty_value
					  , Added = Source.penalty_added
			WHEN NOT MATCHED BY Target
				THEN INSERT (Occ
						   , fin_id
						   , service_id
						   , sup_id
						   , Value
						   , Added)
					VALUES(@occ
						 , @fin_id
						 , 'пени'
						 , @sup_id
						 , @penalty_value
						 , @penalty_added)
			;

			COMMIT TRAN

			RETURN 0
		END


		DECLARE @dolg DECIMAL(9, 2) = 0
			  , @ostatok DECIMAL(9, 2) = 0
			  , @koef DECIMAL(16, 8)
			  , @penalty_value_out DECIMAL(9, 2) = 0

		DECLARE @t TABLE (
			  id INT IDENTITY (1, 1) NOT NULL
			, service_id VARCHAR(10)
			, sup_id INT DEFAULT NULL
			, dolg DECIMAL(9, 2) DEFAULT 0
			, paid DECIMAL(9, 2) DEFAULT 0
			, penalty_old DECIMAL(9, 2) DEFAULT 0
			, penalty_value DECIMAL(9, 2)
			, penalty_new DECIMAL(9, 2) DEFAULT 0
		)

		IF @peny_service_id <> ''
		BEGIN
			INSERT INTO @t (service_id
						  , sup_id
						  , dolg)
			VALUES(@peny_service_id
				 , @sup_id
				 , 999)
		END
		ELSE
			INSERT INTO @t (service_id
						  , sup_id
						  , dolg
						  , paid
						  , penalty_old
						  , penalty_value)
			SELECT pl.service_id
				 , pl.sup_id
				 , pl.SALDO
				 , pl.paid
				 , penalty_old
				 , 0
			FROM dbo.Paym_list AS pl
				JOIN dbo.Services AS s 
					ON pl.service_id = s.id
					AND s.is_peny = 1
			WHERE pl.fin_id = @fin_id
				AND pl.Occ = @occ
				AND pl.sup_id = @sup_id
				AND pl.account_one =
									CASE
										WHEN @sup_id = 0 THEN 0
										ELSE 1
									END
			ORDER BY pl.SALDO DESC

		SELECT @dolg = COALESCE(SUM(dolg), 0)
			 , @paid = COALESCE(SUM(paid), 0)
		FROM @t

		IF @dolg <= 0
			AND @paid > 0
		BEGIN
			UPDATE @t
			SET dolg = paid
			SET @dolg = @paid
		END

		IF @debug = 1
		BEGIN
			PRINT 'Раскидываем пени: ' + STR(@penalty, 9, 2) + ' Долг:' + STR(@dolg, 9, 2)
			SELECT *
			FROM @t
		END

		-- Раскидываем пени
		IF (@peny_service_id <> '')
			AND (@penalty <> 0)
		BEGIN -- раскидка на одну услугу
			;WITH cte AS (
				SELECT TOP (1) * FROM @t
			)
			UPDATE cte
			SET penalty_value = @penalty;			
		END
		ELSE
		IF (@penalty > 0)
			AND (@dolg > 0)
		BEGIN
			SELECT @dolg = COALESCE(SUM(dolg), 0)
			FROM @t
			WHERE dolg > 0
			SET @koef = @penalty / @dolg

			IF @debug = 1
				PRINT 'Коэффициент: ' + STR(@koef, 9, 6) + ' ' + STR(ROUND(@koef, 3))
			IF ROUND(@koef, 3) <> 0
				UPDATE @t
				SET penalty_value = dolg * @koef
				WHERE dolg > 0
			ELSE -- когда оплата очень маленькая(0.01), пишем его на одну услугу            
				UPDATE @t
				SET penalty_value = @penalty
				FROM @t AS p
				WHERE id = (
						SELECT TOP (1) id
						FROM @t
						WHERE dolg > 0
						ORDER BY dolg DESC
					)
		END --if @penalty>0 AND @dolg > 0
		ELSE
		BEGIN
			IF @penalty < 0
				AND @dolg < 0
			BEGIN
				SELECT @dolg = COALESCE(SUM(dolg), 0)
				FROM @t
				WHERE dolg < 0

				SET @koef = @penalty / @dolg

				IF @debug = 1
					PRINT 'Коэффициент: ' + STR(@koef, 9, 6) + ' ' + STR(ROUND(@koef, 3))
				IF ROUND(@koef, 3) <> 0
					UPDATE @t
					SET penalty_old = dolg * @koef
					WHERE dolg < 0
				ELSE
					-- когда оплата очень маленькая(0.01), пишем его на одну услугу            
					UPDATE @t
					SET penalty_old = @penalty
					FROM @t AS p
					WHERE id = (
							SELECT TOP (1) id
							FROM @t
							WHERE dolg < 0
							ORDER BY dolg
						)
			END
			ELSE
			IF (@penalty <> 0)
				AND (@dolg = 0)
			BEGIN
				IF @debug = 1
					PRINT 'пробуем раскидать по старому пени'
				SELECT @dolg = COALESCE(SUM(penalty_old), 0)
				FROM @t

				IF @dolg <> 0
					SET @koef = @penalty / @dolg
				ELSE
					SET @koef = 0

				IF @debug = 1
					PRINT 'Коэффициент: ' + STR(@koef, 9, 6)

				IF ROUND(@koef, 3) <> 0					
					UPDATE @t
					SET penalty_value = penalty_old * @koef
					WHERE penalty_old <> 0

				ELSE -- когда оплата очень маленькая(0.01), пишем его на одну услугу            
					UPDATE @t
					SET penalty_value = @penalty
					FROM @t AS p
					WHERE id = (
							SELECT TOP (1) id
							FROM @t
							ORDER BY penalty_old DESC
						)
			END
		END

		-- Проверяем остатки
		SELECT @ostatok = @penalty - SUM(penalty_value)
		FROM @t

		IF @ostatok <> 0
		BEGIN
			IF @debug=1 PRINT 'Остаток 1: ' + STR(@ostatok, 9, 2)

			UPDATE @t
			SET penalty_value = penalty_value + @ostatok
			FROM @t AS p
			WHERE id = (
					SELECT TOP (1) id
					FROM @t
					WHERE (dolg <> 0 OR paid <> 0)
					ORDER BY dolg DESC
						   , paid DESC
				)
			IF EXISTS (
					SELECT SUM(penalty_value)
					FROM @t
					HAVING SUM(penalty_value) = 0
				)
			BEGIN
				IF @debug = 1 PRINT 'если пени вообще не раскидали - кидаем на любую услугу'
				
				;WITH cte AS (
					SELECT TOP (1) * FROM @t
				)
				UPDATE cte
				SET penalty_value = penalty_value + @ostatok;				
			END
		END

		IF @debug = 1
		BEGIN
			SELECT @ostatok = @penalty - SUM(penalty_value)
			FROM @t			
			PRINT 'Остаток 2: ' + STR(@ostatok, 9, 2)
		END

		BEGIN TRAN

		UPDATE ps
		SET ps.penalty_serv = COALESCE(t.penalty_value, 0)
		FROM dbo.Paym_list AS ps
			LEFT JOIN @t AS t ON 
				ps.service_id = t.service_id
		WHERE 
			ps.Occ = @occ
			AND ps.fin_id = @fin_id
			AND ps.sup_id = @sup_id;

		-- для проверки
		SELECT @penalty_value_out = SUM(COALESCE(pl.penalty_serv, 0))
		FROM dbo.Paym_list AS pl
		WHERE pl.Occ = @occ
			AND pl.fin_id = @fin_id
			AND pl.sup_id = @sup_id

		IF @peny_service_id <> ''
			AND @penalty_value_out = 0
		BEGIN
			IF @debug = 1
				PRINT 'MERGE'

			MERGE dbo.Paym_list AS Target USING (SELECT * FROM @t) AS Source
			ON Target.Occ = @occ
				AND Target.fin_id = @fin_id
				AND Target.service_id = Source.service_id
				AND Target.sup_id = Source.sup_id
			WHEN MATCHED
				THEN UPDATE
					SET penalty_serv = Source.penalty_value
			WHEN NOT MATCHED BY Target
				THEN INSERT (Occ
						   , fin_id
						   , service_id
						   , sup_id
						   , penalty_serv)
					VALUES(@occ
						 , @fin_id
						 , Source.service_id
						 , COALESCE(@sup_id, 0)
						 , @penalty_value);

			SELECT @penalty_value_out = SUM(COALESCE(pl.penalty_serv, 0))
			FROM dbo.Paym_list AS pl
			WHERE 
				pl.Occ = @occ
				AND pl.fin_id = @fin_id
				AND pl.sup_id = @sup_id;
		END

		COMMIT TRAN

		SET @res = CASE
                       WHEN @penalty = @penalty_value_out THEN 1
                       ELSE 0
            END

		IF @debug = 1
		BEGIN
			PRINT 'Результат: ' + CASE
                                      WHEN @res = 1 THEN 'Истина'
                                      ELSE 'Ложь'
                END
			SELECT 'Результат'
				 , *
			FROM @t
			SELECT 'Результат'
				 , *
			FROM Paym_list pl
			WHERE pl.Occ = @occ
				AND pl.fin_id = @fin_id
				AND pl.sup_id = @sup_id
		END

	/*		*/

	END TRY

	BEGIN CATCH
		SET @strerror = @strerror + ' Лицевой: ' + LTRIM(STR(@occ))

		EXECUTE k_GetErrorInfo @visible = @debug
							 , @strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1)

	END CATCH

END
go

