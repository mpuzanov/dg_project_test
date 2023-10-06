-- =============================================
-- Author:		Пузанов М.А.
-- Create date: 25.09.2014
-- Description:	Раскидка пени по услугам по лицевому счёту
-- =============================================
CREATE               PROCEDURE [dbo].[k_raschet_peny_serv_old]
(
	  @occ INT -- лиц/счёт
	, @fin_id SMALLINT
	, @sup_id INT = 0
	, @debug BIT = 0
	, @res BIT = 0
)
AS
/*
exec [k_raschet_peny_serv_old] 30003,232,null,1
exec [k_raschet_peny_serv_old] 480007,232,null,1

exec [k_raschet_peny_serv_old] 700007784,152,null,1
exec [k_raschet_peny_serv_old] 242508, 144, null, 1
exec [k_raschet_peny_serv_old] 137137, 173, 300, 1

Если поставщик задан то раскидываем только на услуги поставщика
если нет то исключить услуги с отдельной квитанцией "account_one=1"
*/
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON

	DECLARE @penalty_old DECIMAL(9, 2) = 0
		  , @penalty_old_new DECIMAL(9, 2) = 0
		  , @PaymAccount_peny DECIMAL(9, 2) = 0
		  , @Penalty_old_edit SMALLINT = 0
		  , @strerror VARCHAR(800)
		  , @paid DECIMAL(9, 2)
		  , @is_peny_serv BIT
		  , @peny_service_id VARCHAR(10)

	IF @sup_id IS NULL
		SET @sup_id = 0

	IF @sup_id = 0
		SELECT @penalty_old = o.penalty_old
			 , @penalty_old_new = o.Penalty_old_new
			 , @PaymAccount_peny = o.PaymAccount_peny
			 , @Penalty_old_edit = COALESCE(o.Penalty_old_edit,0)
			 , @is_peny_serv = ot.is_peny_serv
			 , @peny_service_id = COALESCE(b.peny_service_id, COALESCE(ot.peny_service_id, ''))   -- 01/05/22
		FROM dbo.View_occ_all_lite AS o 
			JOIN dbo.Occupation_Types AS ot ON 
				o.tip_id = ot.id
			JOIN dbo.Buildings AS b ON 
				o.build_id=b.id
		WHERE 
			o.occ = @occ
			AND o.fin_id = @fin_id
	ELSE
		SELECT @penalty_old = os.penalty_old
			 , @penalty_old_new = os.Penalty_old_new
			 , @PaymAccount_peny = os.PaymAccount_peny
			 , @Penalty_old_edit = COALESCE(os.Penalty_old_edit,0)
			 , @is_peny_serv = 0 --ot.is_peny_serv  -- не для поставщиков
			 , @peny_service_id = ''   --COALESCE(ot.peny_service_id, '')
		FROM dbo.Occ_Suppliers AS os 
			JOIN dbo.Occupations o ON 
				os.occ = o.occ
			JOIN dbo.Occupation_Types AS ot ON 
				o.tip_id = ot.id
		WHERE 
			os.occ = @occ
			AND os.fin_id = @fin_id
			AND os.sup_id = @sup_id

	IF @Penalty_old_edit = 0
		SET @penalty_old = @penalty_old - @PaymAccount_peny
	ELSE
		SET @penalty_old = @penalty_old_new

	IF @debug = 1
		PRINT CONCAT('k_raschet_serv_peny_old ', @occ, ' ', @penalty_old, ' ', @penalty_old_new)

	IF @debug = 1
		PRINT '@is_peny_serv' + STR(@is_peny_serv)

	BEGIN TRY

		IF COALESCE(@penalty_old, 0) = 0
		BEGIN
			IF @debug = 1
				PRINT N'Пени нет - очищаем таблички и выходим'

			IF @is_peny_serv = 0
			BEGIN
				UPDATE dbo.Paym_list
				SET penalty_old = 0
				WHERE fin_id = @fin_id
					AND occ = @occ
					AND (sup_id = @sup_id)
			END
			ELSE
				UPDATE dbo.Paym_list
				SET SALDO = 0
				WHERE fin_id = @fin_id
					AND occ = @occ
					AND sup_id = @sup_id
					AND service_id = 'пени'

			RETURN 0
		END

		UPDATE dbo.Paym_list
		SET penalty_old = 0
		WHERE fin_id = @fin_id
			AND occ = @occ
			AND (sup_id = @sup_id)

		IF (@is_peny_serv = 1)
			AND (@sup_id = 0)
		BEGIN
			IF @debug = 1
				PRINT N'пени как услуга'

			BEGIN TRAN

			-- по услуге пени ставим saldo
			MERGE INTO dbo.Paym_list AS Target USING (VALUES(@penalty_old_new))
			AS Source (penalty_old_new)
			ON Target.occ = @occ
				AND Target.fin_id = @fin_id
				AND Target.service_id = N'пени'
				AND Target.sup_id = @sup_id
			WHEN MATCHED
				THEN UPDATE
					SET SALDO = Source.penalty_old_new
			WHEN NOT MATCHED BY Target
				THEN INSERT (occ
						   , fin_id
						   , service_id
						   , sup_id
						   , SALDO)
					VALUES(@occ
						 , @fin_id
						 , N'пени'
						 , @sup_id
						 , @penalty_old_new)
			;

			COMMIT TRAN

			RETURN 0
		END

		DECLARE @dolg DECIMAL(9, 2) = 0
			  , @ostatok DECIMAL(9, 2) = 0
			  , @koef DECIMAL(16, 8)
			  , @penalty_old_out DECIMAL(9, 2) = 0
			  , @penalty_prev DECIMAL(9, 2) = 0

		DECLARE @t TABLE (
			  id INT IDENTITY (1, 1) NOT NULL
			, service_id VARCHAR(10)
			, sup_id INT DEFAULT NULL
			, penalty_prev DECIMAL(9, 2) DEFAULT 0
			, dolg DECIMAL(9, 2) DEFAULT 0
			, paid DECIMAL(9, 2) DEFAULT 0
			, penalty_old DECIMAL(9, 2) DEFAULT 0
			, penalty_new DECIMAL(9, 2) DEFAULT 0
			, is_peny BIT DEFAULT 1
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
						  , penalty_prev
						  , dolg
						  , paid
						  , penalty_old
						  , is_peny)
			SELECT pl.service_id
				 , pl.sup_id
				 , pl.penalty_prev
				 , pl.SALDO
				 , pl.paid
				 , 0
				 , s.is_peny
			FROM dbo.Paym_list AS pl
				JOIN dbo.Services AS s ON pl.service_id = s.id
			--AND s.is_peny = 1
			WHERE pl.fin_id = @fin_id
				AND pl.occ = @occ
				AND (sup_id = @sup_id)

		SELECT @dolg = COALESCE(SUM(dolg), 0)
			 , @paid = COALESCE(SUM(paid), 0)
			 , @penalty_prev = COALESCE(SUM(penalty_prev), 0)
		FROM @t
		WHERE is_peny = 1

		IF @dolg <= 0
			AND @paid > 0
		BEGIN
			UPDATE @t
			SET dolg = paid

			SET @dolg = @paid
		END

		IF @debug = 1
		BEGIN
			PRINT N'Раскидываем пени: ' + STR(@penalty_old, 9, 2) + N' Долг:' + STR(@dolg, 9, 2)+' @penalty_prev='+STR(@penalty_prev,9,2)
			SELECT *
			FROM @t
		END

		-- Раскидываем пени
		IF (@penalty_old > 0)
			AND (@penalty_prev > 0)
		BEGIN
			SELECT @penalty_prev = COALESCE(SUM(penalty_prev), 0)
			FROM @t
			WHERE is_peny = 1
				AND penalty_prev > 0

			SET @koef = @penalty_old / @penalty_prev

			IF @debug = 1
				PRINT N'Коэффициент: ' + STR(@koef, 9, 6) + ' ' + STR(ROUND(@koef, 3))
			IF ROUND(@koef, 3) <> 0
				UPDATE @t
				SET penalty_old = penalty_prev * @koef
				WHERE is_peny = 1
					AND penalty_prev > 0
			ELSE
				-- когда оплата очень маленькая(0.01), пишем его на одну услугу            
				UPDATE @t
				SET penalty_old = @penalty_old
				FROM @t AS p
				WHERE id = (
						SELECT TOP (1) id
						FROM @t
						WHERE is_peny = 1
							AND penalty_prev > 0
						ORDER BY penalty_prev DESC
					)
		END
		ELSE
		IF (@penalty_old > 0)
			AND (@dolg > 0)
		BEGIN
			SELECT @dolg = COALESCE(SUM(dolg), 0)
			FROM @t
			WHERE is_peny = 1
				AND dolg > 0

			SET @koef = @penalty_old / @dolg

			IF @debug = 1
				PRINT N'Коэффициент: ' + STR(@koef, 9, 6) + ' ' + STR(ROUND(@koef, 3))
			IF ROUND(@koef, 3) <> 0
				UPDATE @t
				SET penalty_old = dolg * @koef
				WHERE is_peny = 1
					AND dolg > 0
			ELSE
				-- когда оплата очень маленькая(0.01), пишем его на одну услугу            

				UPDATE @t
				SET penalty_old = @penalty_old
				FROM @t AS p
				WHERE id = (
						SELECT TOP (1) id
						FROM @t
						WHERE is_peny = 1
							AND dolg > 0
						ORDER BY dolg DESC
					)
		END
		ELSE
		BEGIN
			IF @penalty_old < 0
				AND @dolg < 0
			BEGIN
				SELECT @dolg = COALESCE(SUM(dolg), 0)
				FROM @t
				WHERE is_peny = 1
					AND dolg < 0

				SET @koef = @penalty_old / @dolg

				IF @debug = 1
					PRINT N'Коэффициент: ' + STR(@koef, 9, 6) + ' ' + STR(ROUND(@koef, 3))
				IF ROUND(@koef, 3) <> 0
					UPDATE @t
					SET penalty_old = dolg * @koef
					WHERE is_peny = 1
						AND dolg < 0
				ELSE
					-- когда оплата очень маленькая(0.01), пишем его на одну услугу            

					UPDATE @t
					SET penalty_old = @penalty_old
					FROM @t AS p
					WHERE id = (
							SELECT TOP (1) id
							FROM @t
							WHERE is_peny = 1
							ORDER BY dolg DESC
								   , paid DESC
						)
			END
		END
		IF @debug = 1 SELECT 'после раскидки', * FROM @t

		-- Проверяем остатки
		SELECT @ostatok = COALESCE(SUM(penalty_old), 0)
		FROM @t
		SET @ostatok = @penalty_old - @ostatok

		IF @ostatok <> 0
		BEGIN
			IF @debug = 1 PRINT N'Остаток 1: ' + STR(@ostatok, 9, 2)
			UPDATE t1
			SET penalty_old = penalty_old + @ostatok
			FROM @t AS t1
			WHERE t1.id = (
					SELECT TOP (1) id
					FROM @t t2
					WHERE (t2.dolg <> 0 OR t2.paid <> 0)
						AND t2.is_peny = 1
					ORDER BY t2.dolg DESC
						   , t2.paid DESC
				)
			IF EXISTS (
					SELECT SUM(penalty_old)
					FROM @t
					HAVING SUM(penalty_old) = 0
				)
				BEGIN
					IF @debug = 1 PRINT 'если пени вообще не раскидали - кидаем на любую услугу'
					;WITH cte AS(
						SELECT TOP (1) * FROM @t WHERE is_peny = 1
					)
					UPDATE cte
					SET penalty_old = penalty_old + @ostatok;										
				END
			IF @debug = 1 SELECT 'после Остаток 1', * FROM @t
		END

		IF @debug = 1
		BEGIN
			SELECT @ostatok = COALESCE(SUM(penalty_old), 0)
			FROM @t

			SET @ostatok = @penalty_old - @ostatok
			PRINT N'Остаток 2: ' + STR(@ostatok, 9, 2)
		END

		BEGIN TRAN

		UPDATE ps 
		SET ps.penalty_old = COALESCE(t.penalty_old, 0)
		FROM dbo.Paym_list AS ps
			LEFT JOIN @t AS t ON ps.service_id = t.service_id
		WHERE ps.occ = @occ
			AND ps.fin_id = @fin_id
			AND ps.sup_id = @sup_id

		-- для проверки
		SELECT @penalty_old_out = COALESCE(SUM(pl.penalty_old), 0)
		FROM dbo.Paym_list AS pl
		WHERE pl.occ = @occ
			AND pl.fin_id = @fin_id
			AND pl.sup_id = @sup_id

		IF @peny_service_id <> ''
			AND @penalty_old_out = 0
		BEGIN
			IF @debug = 1
				PRINT 'MERGE'
			MERGE dbo.Paym_list AS Target USING (SELECT * FROM @t) AS Source
			ON Target.occ = @occ
				AND Target.fin_id = @fin_id
				AND Target.service_id = Source.service_id
				AND Target.sup_id = Source.sup_id
			WHEN MATCHED
				THEN UPDATE
					SET penalty_old = Source.penalty_old
			WHEN NOT MATCHED BY Target
				THEN INSERT (occ
						   , fin_id
						   , service_id
						   , sup_id
						   , penalty_old)
					VALUES(@occ
						 , @fin_id
						 , Source.service_id
						 , Source.sup_id
						 , penalty_old);

			-- для проверки
			SELECT @penalty_old_out = COALESCE(SUM(pl.penalty_old), 0)
			FROM dbo.Paym_list AS pl
			WHERE pl.occ = @occ
				AND pl.fin_id = @fin_id
				AND (sup_id = @sup_id)
		END
		COMMIT TRAN

		SET @res = CASE
                       WHEN @penalty_old = @penalty_old_out THEN 1
                       ELSE 0
            END
		IF @res = 0
			SET @ostatok = @penalty_old - @penalty_old_out

		IF @res = 0
			AND (COALESCE(@ostatok, 0) <> 0)
		BEGIN
			IF @debug = 1
				PRINT CONCAT('penalty_old=',dbo.NSTR(@penalty_old),', @penalty_old_out=',dbo.NSTR(@penalty_old_out),', @ostatok=', dbo.NSTR(@ostatok))

			-- раскидываем на 1 услугу без доп условий
			;WITH cte AS (
				SELECT TOP (1) * FROM dbo.Paym_list AS ps
				WHERE ps.occ = @occ
					AND ps.fin_id = @fin_id
					AND ps.sup_id = @sup_id
			)
			UPDATE cte
			SET penalty_old = penalty_old + @ostatok;			
			SELECT @res = @@rowcount
			IF @res = 1
				SET @ostatok = 0;
		END

		IF @debug = 1
			PRINT CONCAT('Результат: ', @res, ' ostatok:', @ostatok)

	END TRY
	BEGIN CATCH
		SET @strerror = @strerror + N' Лицевой: ' + LTRIM(STR(@occ))

		EXECUTE k_GetErrorInfo @visible = @debug
							 , @strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1)

	END CATCH

END
go

