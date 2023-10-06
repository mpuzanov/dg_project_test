CREATE   PROCEDURE [dbo].[adm_CloseDay]
(
	  @closedate1 DATETIME = NULL -- За эту дату надо закрыть дни
	, @ras1 BIT = 0 -- признак перерасчета
	, @ras_peny BIT = 1 -- признак перерасчета пени(для расчёта оплат пени)
	, @debug BIT = 0
	, @tip_id SMALLINT = NULL -- Тип фонда
	, @pack_id INT = NULL -- если нужно закрыть одну пачку  
	, @sup_id INT = NULL -- закрыть только по поставщику
	, @bank_id INT = NULL -- закрыть только по банку(организации)
	, @kolPacksClose INT = 0 OUTPUT
)
AS
	/*
Закрываем платежи
(заносим суммы оплат на лицевые счета)


DECLARE @kolPacksClose	INT
EXEC adm_CloseDay @closedate1='20160126',@debug=1, @kolPacksClose=@kolPacksClose OUT
SELECT @kolPacksClose

*/
	SET NOCOUNT ON
	SET XACT_ABORT ON;
	DECLARE @trancount INT;
	SET @trancount = @@trancount;

	DECLARE @Kol INT
		  , @occ1 INT
		  , @service_id1 VARCHAR(10)
		  , @fin_id1 SMALLINT
		  , @occ_sup INT

	IF @kolPacksClose IS NULL
		SET @kolPacksClose = 0

	IF @closedate1 IS NULL
		AND @pack_id IS NULL
		RETURN

	IF @closedate1 IS NULL
		AND @pack_id IS NOT NULL
		SELECT @closedate1 = pd.day
		FROM dbo.Paydoc_packs AS pd
		WHERE pd.id = @pack_id

	--IF @debug = 1
	--	PRINT @closedate1

	IF EXISTS (
			SELECT 1
			FROM dbo.Paydoc_packs AS pd 
				JOIN dbo.View_paycoll_orgs AS po ON 
					pd.fin_id = po.fin_id
					AND pd.source_id = po.id
				CROSS APPLY (
					SELECT RSumma = COALESCE(SUM(p.value), 0)
						 , Rcommission = SUM(COALESCE(p.commission, 0))
					FROM dbo.Payings AS p 
					WHERE p.pack_id = pd.id
				) AS rp
			WHERE 
				day = @closedate1
				AND (pd.total <> rp.RSumma OR pd.checked = 0 OR pd.blocked = 1 OR COALESCE(pd.commission, 0) <> COALESCE(rp.Rcommission, 0))
				AND (@tip_id IS NULL OR pd.tip_id = @tip_id)
				AND (@pack_id IS NULL OR pd.id = @pack_id)
				AND (@sup_id IS NULL OR pd.sup_id = @sup_id)
				AND (@bank_id IS NULL OR po.bank_id = @bank_id)
		)
	BEGIN
		RAISERROR ('Закрыть день нельзя, потому что имеются плохие(не сходятся суммы оплаты или комиссии) или заблокированные пачки', 16, 1)
		RETURN 1
	END

	IF EXISTS (
			SELECT 1
			FROM dbo.View_payings_lite AS t1
			WHERE 
				t1.day = @closedate1
				AND t1.forwarded = CAST(0 AS BIT)
				AND t1.paying_manual = CAST(1 AS BIT)
				AND (t1.pack_id = @pack_id OR @pack_id IS NULL)
				AND NOT EXISTS (
					SELECT SUM(t2.value)
					FROM dbo.Paying_serv AS t2 
					WHERE t2.paying_id = t1.id
					GROUP BY t2.paying_id
					HAVING SUM(t2.value) = t1.value
						--AND SUM(t2.paymaccount_peny) = t1.paymaccount_peny  -- оплату ппени не проверяем
						AND SUM(t2.commission) = t1.commission
				)
		)
	BEGIN
		RAISERROR ('Закрыть день нельзя, потому что имеются плохие пачки(не сходятся суммы по услугам или комиссии)', 16, 10)
		RETURN 1
	END

	IF EXISTS(
		SELECT 1 FROM dbo.Paydoc_packs AS t1 
			JOIN dbo.Global_values as gv ON 
				t1.fin_id=gv.fin_id
		WHERE t1.day = @closedate1
			AND t1.forwarded = CAST(0 AS BIT)
			AND (t1.id = @pack_id OR @pack_id IS NULL)
			AND t1.day>gv.end_date
		)
	BEGIN
		RAISERROR ('Закрыть день нельзя, потому что имеются плохие пачки(ДАТА позже окончания фин.периода)', 16, 10)
		RETURN 1
	END

	-- Пачки
	DECLARE @packsTmp TABLE (
		  id INT PRIMARY KEY
		, fin_id SMALLINT
		, tip_id SMALLINT
		, fin_current SMALLINT -- текущий фин период типа фонда
		, sup_id INT DEFAULT NULL
	)

	-- Платежи
	DECLARE @payingsTmp TABLE (
		  id INT PRIMARY KEY
		, occ INT
		, service_id VARCHAR(10)
		, value DECIMAL(15, 2)
		, fin_id SMALLINT
		, sup_id INT
		, pack_id INT
	)

	BEGIN TRY

		-- Выбираем пачки для закрытия
		INSERT INTO @packsTmp (id
							 , fin_id
							 , tip_id
							 , fin_current
							 , sup_id)
		SELECT pd.id
			 , pd.fin_id
			 , tip_id
			 , VT.fin_id
			 , pd.sup_id
		FROM dbo.Paydoc_packs AS pd
			JOIN dbo.View_paycoll_orgs AS po ON 
				pd.source_id = po.id --AND pd.fin_id=po.fin_id
			JOIN dbo.VOcc_types AS VT ON 
				pd.tip_id = VT.id -- для ограничения доступа по типам фонда	
		WHERE 
			pd.[day] = @closedate1
			AND checked = CAST(1 AS BIT)
			AND forwarded = CAST(0 AS BIT)
			AND blocked = CAST(0 AS BIT) -- не заблокированна
			AND (@tip_id IS NULL OR tip_id = @tip_id)
			AND (@pack_id IS NULL OR pd.id = @pack_id)
			AND (@sup_id IS NULL OR pd.sup_id = @sup_id)
			AND (@bank_id IS NULL OR po.bank_id = @bank_id)

		SET @kolPacksClose = @@rowcount

		-- если текущий фин период типа фонда не совпадает с пачкой(создавали до перехода на новый месяц)
		UPDATE @packsTmp
		SET fin_id = fin_current
		WHERE fin_id <> fin_current

		--SELECT
		--	@kolPacksClose = COUNT(id)
		--FROM @packsTmp
		--PRINT @kolPacksClose

		-- Выбираем платежи для закрытия
		INSERT INTO @payingsTmp (id
							   , occ
							   , service_id
							   , value
							   , fin_id
							   , sup_id
							   , pack_id)
		SELECT pl.id
			 , pl.occ
			 , service_id
			 , pl.value
			 , pd.fin_id
			 , pl.sup_id
			 , pack_id
		FROM dbo.Payings AS pl
			JOIN @packsTmp AS pd ON 
				pl.pack_id = pd.id
			JOIN dbo.Occupations AS o ON 
				o.occ = pl.occ
		SET @Kol = @@rowcount
		--SELECT
		--	@Kol = COUNT(id)
		--FROM @payingsTmp

		IF @debug = 1
			PRINT 'Кол-во платежей: %d' + STR(@Kol)

		IF @Kol = 0
			RETURN 0;

		-- Открываем транзакцию 
		IF @trancount = 0
			BEGIN TRANSACTION
		ELSE
			SAVE TRANSACTION adm_CloseDay;

		--************************************************************
		-- Если есть платежи по закрытым лицевым выдаем первый такой лицевой
		DECLARE @value_close1 VARCHAR(10)
			  , @occ_close_str1 VARCHAR(100) = ''
			  , @pack_err_str VARCHAR(100) = ''
			  , @user_id1 SMALLINT
			  , @msg VARCHAR(400) = ''

		SET @value_close1 = 0

		SELECT @value_close1 = @value_close1 + p1.value
			 , @occ_close_str1 = @occ_close_str1 + STR(o.occ) + ','
			 , @pack_err_str = @pack_err_str + STR(p1.pack_id) + ','
		FROM @payingsTmp AS p1
			JOIN dbo.Occupations AS o ON 
				o.occ = p1.occ
		WHERE o.status_id = 'закр'

		IF @occ_close_str1 <> ''
		BEGIN
			SET @msg = N'Лицевые: ' + @occ_close_str1 + ' уже закрыты!' + CHAR(13) + CHAR(10) + 'Сумма:' + @value_close1 + ' Пачки: ' + @pack_err_str + CHAR(13) + CHAR(10) + 'День закрыть нельзя!'
			RAISERROR (@msg, 16, 1)
			RETURN 1
		END

		SELECT @user_id1 = dbo.Fun_GetCurrentUserId()
		--**************************************************************

		IF @debug = 1
			SELECT '@payingsTmp' as tbl, id, occ, value FROM @payingsTmp ORDER BY id

		-- Помечаем пачки и платежи как закрытые
		UPDATE p
		SET forwarded = 1
		  , fin_id = pt.fin_id  -- проставляем фин.период из пачки 11.08.18
		FROM dbo.Payings AS p
			JOIN @packsTmp AS pt ON p.pack_id = pt.id

		-- Обновляем код договора если есть поставщик
		UPDATE p
		SET dog_int = (
			SELECT TOP 1 os.dog_int
			FROM dbo.Occ_Suppliers AS os
			WHERE os.occ = p.occ
				AND os.sup_id = p.sup_id
				AND os.fin_id = pt.fin_id
		)
		FROM dbo.Payings AS p
			JOIN @packsTmp AS pt ON 
				p.pack_id = pt.id
		WHERE 
			p.sup_id IS NOT NULL
			AND p.dog_int IS NULL

		UPDATE p
		SET forwarded = 1
		  , date_edit = current_timestamp
		  , user_edit = @user_id1
		  , fin_id = pt.fin_id
		FROM dbo.Paydoc_packs AS p
			JOIN @packsTmp AS pt ON p.id = pt.id

		IF @trancount = 0
			COMMIT TRANSACTION;

		-- Обновляем последний день оплаты по типу фонда
		UPDATE ot 
		SET LastPaymDay = (
			SELECT TOP (1) p.[day]
			FROM dbo.Paydoc_packs p 
			WHERE p.checked = CAST(1 AS BIT)
				AND p.fin_id = ot.fin_id
				AND p.tip_id = ot.id
			GROUP BY day
			HAVING SUM(p.docsnum)>=ot.last_paym_day_count_payments
			ORDER BY day DESC
		)
		FROM dbo.Occupation_Types AS ot
		WHERE EXISTS (
				SELECT 1
				FROM @packsTmp
				WHERE tip_id = ot.id
			)

		-- кол-во платежей в день для того чтобы считать его последним днём оплаты по фонду
		DECLARE @MinCount INT = 1

		---- Обновляем последний день оплаты по поставщику
		UPDATE st
		SET LastPaymDay = (
			SELECT TOP (1) p.[day]
			FROM dbo.Paydoc_packs AS p 
			WHERE p.checked = CAST(1 AS BIT)
				AND p.fin_id = pt.fin_current
				AND p.tip_id = pt.tip_id
				AND p.sup_id = st.sup_id
			GROUP BY day
			HAVING SUM(p.docsnum)>=@MinCount
			ORDER BY day DESC
		)
		FROM @packsTmp AS pt
			JOIN dbo.Suppliers_types AS st ON pt.tip_id = st.tip_id
				AND pt.sup_id = st.sup_id

		IF @debug = 1
			PRINT 'Расскидываем по услугам платежи в курсоре'

		BEGIN
			DECLARE some_cur CURSOR LOCAL FOR
				SELECT DISTINCT occ
							  , fin_id
							  , sup_id
				FROM @payingsTmp

			OPEN some_cur

			WHILE 1 = 1
			BEGIN
				FETCH NEXT FROM some_cur INTO @occ1, @fin_id1, @sup_id

				IF @@fetch_status <> 0
					BREAK


				EXEC dbo.k_raschet_paymaccount @occ1 = @occ1
											 , @debug = @debug

				IF @ras_peny = 1
				BEGIN
					IF @debug = 1
						PRINT 'расчёт пени'

					IF COALESCE(@sup_id, 0) = 0
					BEGIN
						IF @debug = 1
							PRINT 'k_raschet_peny'
						EXEC k_raschet_peny @occ1 = @occ1
										  , @debug = @debug
					END
					ELSE
					BEGIN
						SET @occ_sup = NULL;

						SELECT @occ_sup = occ_sup
						FROM dbo.Occ_Suppliers AS OS 
						WHERE OS.occ = @occ1
							AND OS.sup_id = @sup_id
							AND OS.fin_id = @fin_id1;

						IF @occ_sup IS NOT NULL
						BEGIN
							IF @debug = 1
								PRINT 'k_raschet_peny_sup_new'
							EXEC k_raschet_peny_sup_new @occ_sup = @occ_sup
													  , @fin_id1 = @fin_id1
													  , @debug = @debug
						END
					END
				END

				IF @ras1 = 1
				BEGIN
					IF @debug = 1
						PRINT 'расчёт квартплаты'
					EXEC k_raschet_2 @occ1=@occ1, @fin_id1=@fin_id1
				END

			END

			DEALLOCATE some_cur
		END


	END TRY

	BEGIN CATCH

		DECLARE @xstate INT;
		SELECT @xstate = XACT_STATE();

		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @trancount = 0
			ROLLBACK
		IF @xstate = 1
			AND @trancount > 0
			ROLLBACK TRANSACTION adm_CloseDay;

		DECLARE @strerror VARCHAR(4000) = ''
		SET @strerror = CONCAT('День: ', CONVERT(VARCHAR(12), @closedate1, 104))
		--EXEC dbo.k_err_messages

		EXECUTE k_GetErrorInfo @visible = @debug
							 , @strerror = @strerror OUT
		IF @debug = 1
			PRINT @strerror

		RAISERROR (@strerror, 16, 1);

	END CATCH
go

