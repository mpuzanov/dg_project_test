-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	Добавление(перенос) сальдо с одной услуги к другой с помощью разовых
-- =============================================
CREATE             PROCEDURE [dbo].[adm_saldo_serv_transfer_added]
(
	  @tip_id SMALLINT
	, @service_new VARCHAR(10) -- прибавляем на эту услугу
	, @service_old VARCHAR(10) -- берём с этой услуги
	, @build_id INT = NULL
	, @saldo_minus BIT = 0  -- 1 - перенос только переплат
	, @result_transfer BIT = 0 OUTPUT -- результат переноса
	, @debug BIT = 0
	, @add_type SMALLINT = 17 --Тех корректировка (нет в ПД)
)
AS
/*
exec adm_saldo_serv_transfer_added @tip_id=1,@build_id=6786,@saldo_minus=0, @service_new='вотв',@service_old='вГВС',@debug=1

*/
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON
	
	if @add_type is null
	    set @add_type = 17
	
	DECLARE @tran_count INT
	    ,@tran_name varchar(50) = 'adm_saldo_serv_transfer_added'
	SET @tran_count = @@trancount;

	IF @saldo_minus IS NULL
		SET @saldo_minus = 0

	IF (@service_new = @service_old)
	--AND (@source_new = @source_old)
	BEGIN
		RAISERROR (N'Источник и получатель одинаковы!', 16, 1);
	END


	DECLARE @doc VARCHAR(100) = N'перенос сальдо'
		  , @doc_no VARCHAR(10) = '885'
		  , @doc_date DATE = current_timestamp
		  , @user_edit INT = dbo.Fun_GetCurrentUserId() 
	
	DECLARE @Saldo DECIMAL(15, 2) = 0
		  , @Saldo_from DECIMAL(15, 2) = 0
		  , @Debt_new DECIMAL(15, 2) = 0
		  , @Debt_old DECIMAL(15, 2) = 0

	-- выбираем л/сч с которых надо перенести сальдо
	SELECT O.Occ
		 , O.fin_id
		 , P.SALDO AS SALDO
		 , P.service_id AS service_id
		 , P.source_id AS source_id
		 , P.sup_id
	INTO #t_occ
	FROM dbo.Occupations O 
		JOIN dbo.Flats F ON 
			F.id = O.flat_id
		JOIN dbo.Occupation_Types OT ON 
			OT.id = O.tip_id
		JOIN dbo.Paym_list P ON 
			P.Occ = O.Occ
			AND P.fin_id = OT.fin_id
			AND P.service_id = @service_old
	WHERE 
		O.tip_id = @tip_id
		AND (F.bldn_id = @build_id OR @build_id IS NULL)
		--AND O.status_id <> 'закр'

	IF @saldo_minus = 1
		DELETE FROM #t_occ
		WHERE saldo >= 0

	SELECT @Saldo_from = SUM(saldo)
	FROM #t_occ

	IF @debug = 1
		SELECT *
		FROM #t_occ

	SELECT @Debt_old = SUM(pl.debt), @Saldo = SUM(pl.saldo)
	FROM dbo.Paym_list pl
		JOIN #t_occ to1 ON 
			pl.Occ = to1.Occ
	WHERE pl.service_id = @service_new;

	BEGIN TRY
		IF @tran_count = 0
			BEGIN TRANSACTION
		ELSE
			SAVE TRANSACTION @tran_name;

		-- добавляем разовые на плюс
		INSERT INTO Added_Payments (fin_id
								  , Occ
								  , service_id
								  , sup_id
								  , add_type
								  , value
								  , doc
								  , doc_no
								  , doc_date
								  , user_edit
								  , date_edit)
		SELECT fin_id
			 , Occ
			 , @service_new
			 , sup_id
			 , @add_type
			 , saldo
			 , @doc
			 , @doc_no
			 , @doc_date
			 , @user_edit
			 , current_timestamp
		FROM #t_occ

		-- добавляем разовые на минус
		INSERT INTO Added_Payments (fin_id
								  , Occ
								  , service_id
								  , sup_id
								  , add_type
								  , value
								  , doc
								  , doc_no
								  , doc_date
								  , user_edit
								  , date_edit)
		SELECT fin_id
			 , Occ
			 , @service_old
			 , sup_id
			 , @add_type
			 , -1 * saldo
			 , @doc
			 , @doc_no
			 , @doc_date
			 , @user_edit
			 , current_timestamp
		FROM #t_occ

		-- обновить dbo.Paym_list
		UPDATE pl
		SET added = COALESCE((
			SELECT SUM(value)
			FROM dbo.Added_Payments ap
			WHERE Occ = pl.occ
				AND service_id = pl.service_id
				AND ap.sup_id = pl.sup_id
				AND fin_id = pl.fin_id
		), 0)
		FROM dbo.Paym_list AS pl
			JOIN #t_occ t ON pl.Occ = t.Occ
				AND pl.fin_id = t.fin_id
				AND pl.service_id IN (@service_new, @service_old)
		
		IF @debug = 1
			SELECT pl.*
			FROM dbo.Paym_list AS pl
				JOIN #t_occ t ON 
					pl.Occ = t.Occ
					AND pl.fin_id = t.fin_id
					AND pl.service_id IN (@service_new, @service_old)


		SELECT @Debt_new = SUM(pl.debt)
		FROM dbo.Paym_list pl
			JOIN #t_occ to1 ON 
				pl.Occ = to1.Occ
		WHERE pl.service_id = @service_new


		IF @debug = 1
			SELECT @Saldo AS Saldo
				 , @Debt_old AS Debt_old
				 , @Saldo_from AS Saldo_from
				 , @Debt_new AS Debt_new
				 , @service_old AS service_from
				 , @service_new AS service_new


		IF (@Debt_old + @Saldo_from) = @Debt_new
		BEGIN
			SET @result_transfer = 1;
			IF @tran_count = 0
				COMMIT TRANSACTION;
		END
		ELSE
		BEGIN
			IF @tran_count = 0
				ROLLBACK TRANSACTION
			IF @debug = 1
				SELECT CONCAT(N'Суммы не сходяться!(',LTRIM(STR((@Debt_old + @Saldo_from), 9, 2)),'<>',LTRIM(STR(@Debt_new, 9, 2)),') Отменяем перенос')
		END

		IF @result_transfer = 0
			RETURN

		-- записываем в LOG	
		DECLARE @var1 INT
			  , @comments1 VARCHAR(100)
		SELECT @comments1 = CONCAT(N'с услуги: <',@service_old,'>-><',@service_new,'> с помощью разовых')

		DECLARE cursor_name CURSOR FOR
			SELECT Occ
			FROM #t_occ

		OPEN cursor_name;

		FETCH NEXT FROM cursor_name INTO @var1;

		WHILE @@fetch_status = 0
		BEGIN
			EXEC dbo.k_write_log @occ1 = @var1
							   , @oper1 = N'слдо'
							   , @comments1 = @comments1

			FETCH NEXT FROM cursor_name INTO @var1;
		END

		CLOSE cursor_name;
		DEALLOCATE cursor_name;

		DROP TABLE IF EXISTS #MyLogTable;
		DROP TABLE IF EXISTS #t_occ;

	END TRY
	BEGIN CATCH
		DECLARE @xstate INT;
		SELECT @xstate = XACT_STATE();
		IF @xstate = -1
			ROLLBACK;
		IF @xstate = 1
			AND @tran_count = 0
			ROLLBACK;
		IF @xstate = 1
			AND @tran_count > 0
			ROLLBACK TRANSACTION @tran_name;

		DECLARE @strerror VARCHAR(4000) = ''
		EXECUTE k_GetErrorInfo @visible = 0
							 , @strerror = @strerror OUT
		RAISERROR (@strerror, 16, 1)

	END CATCH

END
go

