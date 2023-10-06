-- =============================================
-- Author:		Пузанов М.А.
-- Create date: 31.10.2011
-- Description:	Раскидка оплаты пени по услугам каждого платежа
-- =============================================
CREATE                   PROCEDURE [dbo].[k_paying_serv_peny]
(
	  @paying_id INT -- код платежа
	, @Paymaccount_peny DECIMAL(9, 2) = 0
	, @sup_id INT = 0
	, @debug BIT = 0
	, @Paymaccount_peny_out DECIMAL(9, 2) = 0 OUTPUT
)
AS
/*
Раскидываем оплачено пени по платежу

DECLARE @Paymaccount_peny_out DECIMAL(9,2) = 0

EXEC k_paying_serv_peny	@paying_id = 1080036
						,@Paymaccount_peny = 0 -- -30
						,@sup_id = 0 --323
						,@debug = 1
						,@Paymaccount_peny_out = @Paymaccount_peny_out OUTPUT
						
SELECT Paymaccount_peny_out=@Paymaccount_peny_out		

DECLARE @Paymaccount_peny_out DECIMAL(9,2) = 0

EXEC k_paying_serv_peny	@paying_id = 16771931
						,@Paymaccount_peny = 0
						,@sup_id = 0
						,@debug = 1
						,@Paymaccount_peny_out = @Paymaccount_peny_out OUTPUT
						
SELECT Paymaccount_peny_out=@Paymaccount_peny_out		


*/
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON
	
	DECLARE @trancount INT;	
	SET @trancount = @@trancount;

	DECLARE @occ1 INT
		  , @fin_id1 SMALLINT
		  , @fin_pred1 SMALLINT
		  , @service_id VARCHAR(10)
		  , @strerror VARCHAR(800)
		  , @Peny_old DECIMAL(9, 2)
		  , @paying_vozvrat INT
		  , @peny_save BIT
		  , @is_peny_serv BIT
		  , @peny_service_id VARCHAR(10)
		  , @paying_uid UNIQUEIDENTIFIER

	SELECT @occ1 = p.occ
		 , @fin_id1 = PP.fin_id
		 , @sup_id = p.sup_id
		 , @Paymaccount_peny =
							  CASE
								  WHEN p.peny_save = 1 THEN p.Paymaccount_peny     -- берём оплату пени с платежа
								  ELSE @Paymaccount_peny
							  END
		 , @paying_vozvrat = COALESCE(p.paying_vozvrat, 0)
		 , @peny_save = COALESCE(p.peny_save, 0)
		 , @is_peny_serv = CASE
                               WHEN p.sup_id > 0 THEN ''
                               ELSE ot.is_peny_serv
        END
		 , @peny_service_id = CASE
                                  WHEN p.sup_id > 0 THEN ''
                                  ELSE COALESCE(b.peny_service_id, COALESCE(ot.peny_service_id, ''))
        END
		 , @paying_uid= P.paying_uid
	FROM dbo.Payings AS p 
		JOIN dbo.Paydoc_packs AS PP ON 
			PP.id = p.pack_id
		JOIN dbo.Occupation_Types AS ot ON 
			PP.tip_id = ot.id 
		JOIN dbo.Occupations AS o ON 
			p.occ=o.Occ
		JOIN dbo.Flats AS f ON 
			o.flat_id=f.id
		JOIN dbo.Buildings AS b ON 
			f.bldn_id=b.id
	WHERE 
		p.id = @paying_id
		AND p.forwarded = CAST(1 AS BIT)

	SET @fin_pred1 = @fin_id1 - 1
	
	IF @debug = 1
	begin
		SELECT @fin_id1 AS fin_id, @fin_pred1 AS fin_pred, @occ1 as occ1, @Paymaccount_peny as Paymaccount_peny
		PRINT CONCAT('EXEC dbo.k_paying_serv_peny @paying_id=',@paying_id
			,',@Paymaccount_peny=',LTRIM(STR(@Paymaccount_peny, 9, 2)),',@sup_id=',@sup_id,',@debug=', LTRIM(STR(@debug)))
	end

	BEGIN TRY

		IF COALESCE(@Paymaccount_peny, 0) = 0
			OR (@occ1 IS NULL) -- нет закрытого платежа по @paying_id
		BEGIN
			IF @debug = 1
				IF @occ1 IS NULL
					PRINT 'Платеж ' + STR(@paying_id) + ' не закрыт! Раскидывать пени рано.'
				ELSE
					PRINT 'Оплаты пени нет - очищаем таблички и выходим'

			IF @trancount = 0
				BEGIN TRANSACTION
			ELSE
				SAVE TRANSACTION k_paying_serv_peny;

			UPDATE dbo.Paying_serv
			SET Paymaccount_peny = 0
			WHERE paying_id = @paying_id

			UPDATE p
			SET Paymaccount_peny = COALESCE((
				SELECT SUM(Paymaccount_peny)
				FROM dbo.Paying_serv
				WHERE paying_id = @paying_id
			), 0)
			FROM dbo.Payings AS p
			WHERE p.id = @paying_id
				AND p.forwarded = 1

			IF @trancount = 0
				COMMIT TRAN

			RETURN 0
		END

		IF @sup_id = 0
		BEGIN
			SELECT @Peny_old = o.penalty_old
			FROM dbo.View_occ_all_lite o
			WHERE occ = @occ1
				AND o.fin_id = @fin_id1

			IF @Peny_old IS NULL  -- бывает когда фин.период возратили
				SELECT @Peny_old = o.Penalty_itog
				FROM dbo.View_occ_all_lite o
				WHERE occ = @occ1
					AND o.fin_id = @fin_pred1
		END
		ELSE
		BEGIN
			SELECT @Peny_old = os.penalty_old
			FROM dbo.Occ_Suppliers os
			WHERE os.occ = @occ1
				AND os.fin_id = @fin_id1
				AND os.sup_id = @sup_id

			IF @Peny_old IS NULL  -- бывает когда фин.период возратили
				SELECT @Peny_old = (os.Penalty_value + os.Penalty_old_new + os.Penalty_added)
				FROM dbo.Occ_Suppliers os
				WHERE os.occ = @occ1
					AND os.fin_id = @fin_pred1
					AND os.sup_id = @sup_id
		END

	IF @Peny_old IS NULL
	 SELECT @Peny_old=0

	IF @debug=1
		SELECT @Peny_old as Peny_old

	DECLARE @Paymaccount DECIMAL(9, 2) = 0
			, @penalty_old DECIMAL(9, 2) = 0
			, @ostatok DECIMAL(9, 2) = 0
			, @koef DECIMAL(16, 8)

	DECLARE @t TABLE (
			service_id VARCHAR(10)
		, penalty_old DECIMAL(9, 2) DEFAULT 0
		, paymaccount DECIMAL(9, 2) DEFAULT 0
		, Paymaccount_peny DECIMAL(9, 2) DEFAULT 0
		, is_peny BIT DEFAULT 0
		, paying_id INT NOT NULL
	)

	IF @peny_service_id <> ''
	BEGIN
		INSERT INTO @t (service_id
						, penalty_old
						, paymaccount
						, Paymaccount_peny
						, paying_id)
		VALUES(@peny_service_id
				, @Peny_old
				, @Paymaccount
				, @Paymaccount_peny
				, @paying_id)

		GOTO LABEL_SAVE_PAYINGS
	END

	INSERT INTO @t (service_id
					, paymaccount
					, Paymaccount_peny
					, is_peny
					, paying_id)
	SELECT ps.service_id
			, ps.value
			, 0
			, s.is_peny
			, @paying_id
	FROM dbo.Paying_serv AS ps
		JOIN dbo.Services AS s ON 
			ps.service_id = s.id
			--AND s.is_peny = 1
	WHERE ps.paying_id = @paying_id

		-- берём пени за прошлый месяц
		--UPDATE t
		--SET penalty_old = COALESCE(ph.penalty_old, 0) + COALESCE(ph.penalty_serv, 0)
		--FROM @t AS t
		--	JOIN dbo.Paym_history ph ON t.service_id = ph.service_id
		--WHERE ph.occ = @occ1
		--	AND ph.fin_id = @fin_pred1

		-- 21.04.23 будем раскидывать на основании колонки - penalty_prev текущего периода
		UPDATE t
		SET penalty_old = pl.penalty_prev
		FROM @t AS t
			JOIN dbo.Paym_list pl ON 
				t.service_id = pl.service_id
		WHERE pl.occ = @occ1
			AND pl.fin_id = @fin_id1

	SELECT @Paymaccount = COALESCE(SUM(paymaccount), 0)
			, @penalty_old = COALESCE(SUM(penalty_old), 0)
	FROM @t

	IF (@Paymaccount = 0
		AND @Paymaccount_peny <> 0)
	BEGIN
		INSERT INTO @t (service_id, paymaccount, Paymaccount_peny)
		SELECT ps.service_id, ps.value, 0
		FROM dbo.Paying_serv AS ps
		WHERE ps.paying_id = @paying_id;

		SELECT @Paymaccount = COALESCE(SUM(paymaccount), 0)	FROM @t	WHERE paymaccount <> 0;
	END

	IF @debug = 1
	BEGIN
		PRINT 'Раскидываем оплату пени. Оплата: ' + STR(@Paymaccount, 9, 2) + ' Оплата пени:' + STR(@Paymaccount_peny, 9, 2)
		PRINT '@paying_vozvrat: ' + LTRIM(STR(@paying_vozvrat)) + ' @peny_save:' + LTRIM(STR(@peny_save))
		SELECT '@t' AS tbl, * FROM @t
	END

	IF @paying_vozvrat > 0
	BEGIN
		IF @debug = 1
			PRINT 'Оплату пени раскидываем как в платеже возврата только с обратным знаком'
		UPDATE t
		SET Paymaccount_peny = -1 * ps.Paymaccount_peny
		FROM @t AS t
			JOIN dbo.Paying_serv ps ON 
				t.service_id = ps.service_id
		WHERE ps.paying_id = @paying_vozvrat
		IF @@rowcount = 0
			AND @debug = 1
			PRINT 'платёж возврата не найден!'

		GOTO LABEL_SAVE_PAYINGS
	END

	IF @penalty_old <> 0
		AND (@Paymaccount_peny <> 0)
	BEGIN
		SET @koef = @Paymaccount_peny / @penalty_old
		IF @debug = 1
			PRINT 'Раскидываем оплату пени пропорционально предыдущему пени. @koef='+ LTRIM(STR(@koef, 16, 8))

		UPDATE @t
		SET Paymaccount_peny = penalty_old * @koef
		WHERE penalty_old <> 0

		GOTO LABEL_SAVE_PAYINGS
	END

	-- Раскидываем оплату пени пропорционально оплате
	IF (@Paymaccount_peny <> 0)
		AND (@Paymaccount <> 0)
	BEGIN
		SET @koef = @Paymaccount_peny / @Paymaccount
		IF @debug = 1
			PRINT 'Раскидываем оплату пени пропорционально оплате по услугам. @koef='+ LTRIM(STR(@koef, 16, 8))
					
		UPDATE @t
		SET Paymaccount_peny = paymaccount * @koef
		WHERE paymaccount <> 0

	END --if @Paymaccount_peny<>0 

	LABEL_SAVE_PAYINGS:

		-- Проверяем остатки
		SET @ostatok = @Paymaccount_peny - (Select Sum(Paymaccount_peny) From @t)
		
		IF @debug = 1
			PRINT 'Остаток=' + LTRIM(STR(@ostatok, 9, 2))
		IF @ostatok <> 0
		BEGIN			
			SELECT TOP (1) @service_id = service_id	FROM @t	WHERE ABS(Paymaccount_peny) >= ABS(@ostatok)

			IF @service_id IS NULL
				SELECT TOP (1) @service_id = service_id	FROM @t	ORDER BY paymaccount DESC

			IF @service_id IS NULL	
				SELECT TOP (1) @service_id = service_id	FROM @t

			IF @debug = 1
				PRINT 'проверили остаток ' + LTRIM(STR(@ostatok, 9, 2)) + ' и закинули на услугу =' + COALESCE(@service_id, '????')
			
			UPDATE @t SET Paymaccount_peny = Paymaccount_peny + @ostatok	WHERE service_id = @service_id						
		END

		IF @trancount = 0
			BEGIN TRANSACTION
		ELSE
			SAVE TRANSACTION k_paying_serv_peny;

		IF @debug = 1
		BEGIN
			SELECT 'после раскидки @t'
				 , *
			FROM @t
		END

		UPDATE ps 
		SET Paymaccount_peny = COALESCE(t.Paymaccount_peny, 0)  -- у кого услуги нет - обнуляем
		FROM dbo.Paying_serv AS ps
			JOIN dbo.Payings p ON 
				ps.paying_id = p.id
			LEFT JOIN @t AS t ON 
				ps.service_id = t.service_id
		WHERE 
			p.id = @paying_id
			AND p.occ = @occ1
			AND p.fin_id = @fin_id1
			AND p.sup_id = @sup_id

		SELECT @Paymaccount_peny_out = SUM(Paymaccount_peny)
		FROM dbo.Paying_serv
		WHERE paying_id = @paying_id

		IF @peny_service_id <> ''
			AND @Paymaccount_peny_out = 0
		BEGIN
			IF @debug = 1
				PRINT 'MERGE'

			MERGE dbo.Paying_serv AS Target USING (SELECT * FROM @t) AS Source
			ON Target.occ = @occ1
				AND Target.service_id = Source.service_id
				AND Target.sup_id = @sup_id
				AND Target.paying_id=Source.paying_id
			WHEN MATCHED
				THEN UPDATE
					SET Paymaccount_peny = Source.Paymaccount_peny
			WHEN NOT MATCHED BY Target
				THEN INSERT (occ
						   , service_id
						   , paying_id
						   , sup_id
						   , value
						   , Paymaccount_peny)
					VALUES(@occ1
						 , Source.service_id
						 , @paying_id
						 , @sup_id
						 , 0
						 , Source.Paymaccount_peny);

			SELECT @Paymaccount_peny_out = SUM(Paymaccount_peny)
			FROM dbo.Paying_serv
			WHERE paying_id = @paying_id

			IF @debug=1
				SELECT @Paymaccount_peny_out AS Paymaccount_peny_out
		END

		IF COALESCE(@Peny_old, 0) < COALESCE(@Paymaccount_peny_out, 0)
			AND @peny_save = 0 --@occ1 NOT IN (334152)  -- исключения
		BEGIN
			--ROLLBACK TRAN
			DECLARE @Peny_old_str VARCHAR(20) = dbo.FSTR(@Peny_old, 9, 2)
			DECLARE @Paymaccount_peny_out_str VARCHAR(20) = dbo.FSTR(@Paymaccount_peny_out, 9, 2)
			RAISERROR (N'Оплата пени %s больше старого пени %s! Лицевой: %d', 16, 1, @Paymaccount_peny_out_str, @Peny_old_str, @occ1)
			RETURN -1
		END

		UPDATE p
		SET Paymaccount_peny = COALESCE(@Paymaccount_peny_out, 0)
		FROM dbo.Payings AS p
		WHERE 
			p.id = @paying_id
			AND p.forwarded = CAST(1 AS BIT)

		SELECT @Paymaccount_peny_out = NULL

		IF @trancount = 0
			COMMIT TRAN

		-- для проверки
		SELECT @Paymaccount_peny_out = SUM(Paymaccount_peny)
		FROM dbo.Paying_serv
		WHERE paying_id = @paying_id

		IF @Paymaccount_peny_out IS NULL
			SET @Paymaccount_peny_out = 0

		IF @debug = 1
		BEGIN
			SELECT @Paymaccount_peny_out AS Paymaccount_peny_out
				 , @Peny_old AS Peny_old

			SELECT 'результат Paying_serv', *
			FROM dbo.Paying_serv
			WHERE paying_id = @paying_id
		END

	END TRY

	BEGIN CATCH
		DECLARE @xstate INT;
		SELECT @xstate = XACT_STATE();
		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @trancount = 0
			ROLLBACK;
		IF @xstate = 1
			AND @trancount > 0
			ROLLBACK TRANSACTION k_paying_serv_peny;

		SET @strerror = @strerror + ' Лицевой: ' + LTRIM(STR(@occ1))

		EXECUTE k_GetErrorInfo @visible = @debug
							 , @strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1)

	END CATCH

END
go

