-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Открытие закрытого фин. периода
-- =============================================
CREATE     PROCEDURE [dbo].[adm_open_FinPeriod_build]
(
	@build_id INT
   ,@debug  BIT = 0
)
AS
/*
Возвращаемся период назад по дому

[adm_open_FinPeriod_build] 

*/
BEGIN

	SET NOCOUNT ON;
	SET XACT_ABORT ON

	DECLARE @fin_current	 SMALLINT
		   ,@fin_pred		 SMALLINT
		   ,@start_date_pred SMALLDATETIME

	SELECT
		@fin_current = fin_current
	FROM dbo.Buildings
	WHERE Id = @build_id
		AND is_finperiod_owner=1

	IF @fin_current IS NULL
	BEGIN
		RAISERROR ('У дома нет раздельного фин.учёта', 11, 1)
		RETURN	
	END

	SET @fin_pred = @fin_current - 1

	IF @debug = 1
		PRINT 'Тек.период: ' + STR(@fin_current)
	IF @debug = 1
		PRINT 'Пред.период: ' + STR(@fin_pred)

	-- Проверяем был-ли такой период в истории 
	IF NOT EXISTS (SELECT
				1
			FROM dbo.Buildings_history
			WHERE bldn_id = @build_id
			AND fin_id = @fin_pred)
	BEGIN
		RAISERROR ('Периода с кодом %i нет в истории', 11, 1, @fin_pred)
		RETURN
	END

	SELECT
		@start_date_pred = start_date
	FROM dbo.GLOBAL_VALUES
	WHERE fin_id = @fin_pred

	DECLARE @tabl_occ TABLE
		(
			occ		 INT
		   ,fin_pred	 SMALLINT
		   ,fin_current	 SMALLINT
		   ,build_id INT
		   ,PRIMARY KEY (occ, fin_pred)
		)
	INSERT INTO @tabl_occ
	(occ
	,fin_pred
	,fin_current
	,build_id)
		SELECT
			occ
		   ,@fin_pred
		   ,b.fin_current
		   ,f.bldn_id
		FROM dbo.OCCUPATIONS AS o
			JOIN dbo.FLATS AS f ON o.flat_id = f.Id
			JOIN dbo.Buildings AS b ON f.bldn_id=b.id
		WHERE f.bldn_id = @build_id
		AND o.status_id <> 'закр'
		AND b.is_finperiod_owner=1

	DECLARE @KolOcc INT = 0
	SELECT
		@KolOcc = COUNT(*)
	FROM @tabl_occ
	IF @debug = 1
		PRINT 'Кол-во лицевых: ' + STR(@KolOcc)

	BEGIN TRY

		BEGIN TRAN

		-- Устанавливаем текущим период
		UPDATE dbo.Buildings
		SET fin_current = @fin_pred
		WHERE Id = @build_id
			AND is_finperiod_owner=1

		-- =============== Перерасчёты
		-- Удаление текущих данных
		DELETE t1
			FROM dbo.ADDED_PAYMENTS AS t1
			JOIN @tabl_occ AS t
				ON t1.occ = t.occ

		-- Перенос из истории
		INSERT INTO dbo.ADDED_PAYMENTS
		(fin_id
		,occ
		,service_id
		,add_type
		,value
		,doc
		,data1
		,data2
		,Hours
		,add_type2
		,manual_bit
		,Vin1
		,Vin2
		,doc_no
		,doc_date
		,user_edit
		,dsc_owner_id
		,fin_id_paym
		,comments
		,tnorm2
		,kol
		,repeat_for_fin)
			SELECT
				t1.fin_id
			   ,t1.occ
			   ,service_id
			   ,add_type
			   ,value
			   ,doc
			   ,data1
			   ,data2
			   ,Hours
			   ,add_type2
			   ,manual_bit
			   ,Vin1
			   ,Vin2
			   ,doc_no
			   ,doc_date
			   ,user_edit
			   ,dsc_owner_id
			   ,fin_id_paym
			   ,comments
			   ,tnorm2
			   ,kol
			   ,repeat_for_fin
			FROM dbo.ADDED_PAYMENTS_HISTORY AS t1
			JOIN @tabl_occ AS t
				ON t1.occ = t.occ
				AND t1.fin_id = t.fin_pred

		-- Удаление в истории
		DELETE t1
			FROM dbo.ADDED_PAYMENTS_HISTORY AS t1
			JOIN @tabl_occ AS t
				ON t1.fin_id = t.fin_pred
				AND t1.occ = t.occ

		---- Счётчики
		---- Удаление в истории
		--DELETE t1
		--	FROM dbo.COUNTER_LIST_HISTORY AS t1
		--	JOIN @tabl_occ AS t
		--		ON t1.fin_id = t.fin_id AND t1.occ = t.occ

		-- =============== Начисления
		-- Удаление текущих данных
		DELETE t1
			FROM dbo.PAYM_LIST AS t1
			JOIN @tabl_occ AS t
				ON t1.occ = t.occ

		-- Перенос из истории
		INSERT INTO dbo.PAYM_LIST
		(fin_id
		,occ
		,service_id
		,sup_id
		,subsid_only
		,tarif
		,SALDO
		,value
		,Added
		,Paid
		,paymaccount
		,paymaccount_peny
		,account_one
		,kol
		,unit_id
		,metod
		,is_counter
		,mode_id
		,source_id
		,koef
		,kol_added
		,penalty_serv
		,penalty_old
		,penalty_prev
		,date_start
		,date_end)
			SELECT
				@fin_pred
			   ,p.occ
			   ,service_id
			   ,sup_id
			   ,subsid_only
			   ,tarif
			   ,p.SALDO
			   ,p.value
			   ,p.Added
			   ,p.Paid
			   ,p.paymaccount
			   ,p.paymaccount_peny
			   ,account_one
			   ,kol
			   ,unit_id
			   ,metod
			   ,is_counter
			   ,mode_id
			   ,source_id
			   ,koef
			   ,p.kol_added
			   ,p.penalty_serv
			   ,p.penalty_old
			   ,p.penalty_prev
			   ,p.date_start
			   ,p.date_end
			FROM dbo.PAYM_HISTORY AS p
			JOIN @tabl_occ AS t
				ON p.occ = t.occ
				AND p.fin_id = t.fin_pred

		-- Удаление в истории
		DELETE t1
			FROM dbo.PAYM_HISTORY AS t1
			JOIN @tabl_occ AS t
				ON t1.fin_id = t.fin_pred
				AND t1.occ = t.occ

		UPDATE o1
		SET SALDO=t1.saldo
			,PaymAccount=t1.PaymAccount
			,PaymAccount_peny=t1.PaymAccount_peny
			,Paid=t1.Paid
			,Paid_minus=t1.Paid_minus
			,Penalty_old_new=t1.Penalty_old_new
			,Penalty_old=t1.Penalty_old
			,penalty_added=t1.penalty_added
			,penalty_value=t1.penalty_value
            ,saldo_edit=t1.saldo_edit		 
		  	,Added=t1.Added
		    ,comments_print=t1.comments_print
			,AddedAll=t1.AddedAll
			,SaldoAll=t1.SaldoAll
			,PaidAll=t1.PaidAll
		FROM dbo.Occupations as o1
			JOIN @tabl_occ AS o ON o1.occ=o.occ
			JOIN dbo.OCC_HISTORY AS t1 ON o.occ=t1.occ AND t1.fin_id=o.fin_pred

		-- Удаление из истории
		-- OCC_HISTORY
		DELETE t1
			FROM dbo.OCC_HISTORY AS t1
			JOIN @tabl_occ AS t
				ON t1.fin_id = t.fin_pred
				AND t1.occ = t.occ

		-- BUILDING_HISTORY
		DELETE FROM bh
			FROM dbo.BUILDINGS_HISTORY AS bh
			JOIN @tabl_occ AS o
				ON bh.bldn_id = o.build_id
				AND bh.fin_id = o.fin_pred

		-- CONSMODES_HISTORY
		DELETE FROM ch
			FROM dbo.CONSMODES_HISTORY AS ch
			JOIN @tabl_occ AS o
				ON ch.occ = o.occ
				AND ch.fin_id = o.fin_pred

		--DELETE FROM dbo.OCCUPATION_TYPES_HISTORY
		--WHERE Id = @tip_id
		--	AND fin_id = @fin_pred

		--DELETE FROM dbo.SUPPLIERS_TYPES_HISTORY
		--WHERE tip_id = @tip_id
		--	AND fin_id = @fin_pred

		DELETE o1
		FROM dbo.Peny_all as o1
			JOIN @tabl_occ AS o ON o1.occ=o.occ AND o1.fin_id=o.fin_current

		UPDATE o1
		SET fin_id = @fin_pred
		FROM dbo.Occupations as o1
			JOIN @tabl_occ AS o ON o1.occ=o.occ
		

		COMMIT TRAN

	END TRY

	BEGIN CATCH

		EXEC dbo.k_err_messages

	END CATCH

END
go

