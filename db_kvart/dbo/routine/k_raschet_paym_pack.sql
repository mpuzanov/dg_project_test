-- =============================================
-- Author:		Пузанов
-- Create date: 09.08.2018
-- Description:	Раскидка платежей в пачке
-- =============================================
CREATE     PROCEDURE [dbo].[k_raschet_paym_pack]
	  @pack_id INT
	, @debug BIT = 0
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @paying_id1 INT
		  , @occ1 INT
		  , @sup_id1 INT
		  , @fin_id1 SMALLINT
		  , @forwarded1 BIT
		  , @Db_Name VARCHAR(20) = UPPER(DB_NAME())

	-- временная таблица с лицевыми счетами
	DECLARE @t1 TABLE (
		  fin_id SMALLINT
		, occ INT
		, sup_id INT
		, forwarded BIT
		, PRIMARY KEY (fin_id, occ, sup_id)
	)

	BEGIN TRY

		DECLARE cur CURSOR LOCAL FOR
			SELECT p.id
				 , p.occ
				 , p.sup_id
				 , p.fin_id
				 , p.forwarded
			FROM dbo.Payings p
			WHERE p.pack_id = @pack_id

		OPEN cur

		FETCH NEXT FROM cur INTO @paying_id1, @occ1, @sup_id1, @fin_id1, @forwarded1

		WHILE @@fetch_status = 0
		BEGIN
			IF @debug = 1
				RAISERROR ('%d %d %d %d', 10, 1, @paying_id1, @fin_id1, @occ1, @sup_id1) WITH NOWAIT;

			EXEC k_payings_serv_add4 @paying_id = @paying_id1
								   , @debug = 0
			--ELSE
			--	EXEC dbo.k_payings_serv_add3 @paying_id = @paying_id1
			--								,@debug = 0

			IF NOT EXISTS (
					SELECT 1
					FROM @t1
					WHERE fin_id = @fin_id1
						AND occ = @occ1
						AND sup_id = @sup_id1
				)
				INSERT INTO @t1 (fin_id
							   , occ
							   , sup_id
							   , forwarded)
				VALUES(@fin_id1
					 , @occ1
					 , @sup_id1
					 , @forwarded1);

			FETCH NEXT FROM cur INTO @paying_id1, @occ1, @sup_id1, @fin_id1, @forwarded1

		END

		CLOSE cur
		DEALLOCATE cur

		IF @debug = 1
			SELECT *
			FROM @t1

		MERGE dbo.Paym_list WITH (ROWLOCK) AS p USING (
			SELECT p.fin_id
				 , p.occ
				 , ps.service_id
				 , p.sup_id
				 , COALESCE(SUM(ps.value), 0) AS paymaccount
				 , SUM(COALESCE(ps.paymaccount_peny, 0)) AS paymaccount_peny
			FROM dbo.Paying_serv AS ps
				JOIN dbo.Payings p ON ps.paying_id = p.id
				JOIN @t1 t ON t.fin_id = p.fin_id
					AND t.occ = p.occ
					AND t.sup_id = p.sup_id
					AND t.forwarded = cast(1 as bit) -- только закрытые платежи можно кидать на лицевые
			GROUP BY p.fin_id
				   , p.occ
				   , ps.service_id
				   , p.sup_id
		) AS t
		ON p.occ = t.occ
			AND p.service_id = t.service_id
			AND p.sup_id = t.sup_id
		WHEN MATCHED
			AND (p.PaymAccount <> t.PaymAccount OR p.paymaccount_peny <> t.paymaccount_peny)
			THEN UPDATE
				SET -- обновляем оплату
				PaymAccount = t.PaymAccount
			  , paymaccount_peny = t.paymaccount_peny
		WHEN NOT MATCHED -- добавляем строки с оплатой
			THEN INSERT (fin_id
					   , occ
					   , service_id
					   , sup_id
					   , subsid_only
					   , tarif
					   , koef
					   , kol
					   , saldo
					   , value
					   , Added
					   , PaymAccount
					   , paymaccount_peny
					   , Paid)
				VALUES(t.fin_id
					 , t.occ
					 , t.service_id
					 , t.sup_id
					 , 0 -- subsid_only
					 , 0 -- tarif
					 , 1 -- KOEF
					 , 0 -- kol
					 , 0 -- saldo
					 , 0 -- value
					 , 0 -- added
					 , t.PaymAccount
					 , t.paymaccount_peny
					 , 0 -- paid
				);

	END TRY
	BEGIN CATCH

		EXEC dbo.k_err_messages

	END CATCH

END
go

