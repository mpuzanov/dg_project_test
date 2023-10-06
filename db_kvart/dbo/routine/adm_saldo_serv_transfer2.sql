-- =============================================
-- Author:		Пузанов
-- Create date: 
-- Description:	Добавление(перенос) сальдо с одной услуги к другой
-- =============================================
CREATE               PROCEDURE [dbo].[adm_saldo_serv_transfer2]
(
	  @tip_id SMALLINT
	, @service_new VARCHAR(10) -- прибавляем на эту услугу
	, @service_old VARCHAR(10) -- берём с этой услуги
	, @build_id INT = NULL
	, @saldo_minus BIT = 0  -- 1 - перенос только переплат
	, @source_new INT  -- прибавляем на этого поставщика по услуги
	, @source_old INT  -- берём с этого поставщика по услуги
	, @result_transfer BIT = 0 OUTPUT -- результат переноса
	, @debug BIT = 0
)
AS
/*
exec adm_saldo_serv_transfer @tip_id=52,@build_id=6819,@saldo_minus=1
							,@service_new='площ',@service_old='хвод'
							,@source_new=1112,@source_old=3000
							,@debug=1

*/
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON

	DECLARE @trancount INT;
	SET @trancount = @@trancount;

	IF @saldo_minus IS NULL
		SET @saldo_minus = 0

	IF @source_new IS NULL
		OR @source_old IS NULL
	BEGIN
		RAISERROR ('Поставщики должны быть заданы!', 16, 1);
		RETURN 1;
	END

	IF (@service_new = @service_old)
		AND (@source_new = @source_old)
	BEGIN
		RAISERROR ('Источник и получатель одинаковы!', 16, 1);
		RETURN 1;
	END


	DECLARE @account_one BIT
		  , @mode_id_NOT INT
		  , @sup_id_new INT

	SELECT TOP (1) @account_one = t.account_one
			   , @sup_id_new = CASE
                                   WHEN account_one = 1 THEN t.sup_id
                                   ELSE 0
        END
	FROM dbo.View_suppliers t
	WHERE id = @source_new
		AND t.service_id = @service_new

	SELECT TOP (1) @mode_id_NOT = t.id
	FROM dbo.Cons_modes t
	WHERE t.service_id = @service_new
		AND (id % 1000) = 0

	IF @debug = 1
		SELECT @source_new AS source_new
			 , @source_old AS source_old
			 , @sup_id_new AS sup_id_new
			 , @mode_id_NOT AS mode_id_NOT

	CREATE TABLE #MyLogTable (
		  ActionTaken NVARCHAR(10) COLLATE database_default
		, Occ INT
		, Old_Saldo DECIMAL(9, 2)
		, Old_service_id VARCHAR(10) COLLATE database_default
		, Old_sup_id INT
		, New_Saldo DECIMAL(9, 2)
		, New_service_id VARCHAR(10) COLLATE database_default
		, New_sup_id INT
	);

	DECLARE @Saldo_old DECIMAL(15, 2) = 0
		  , @Saldo_old2 DECIMAL(15, 2) = 0
		  , @Saldo_new DECIMAL(15, 2) = 0		  
		  , @Saldo_new_to DECIMAL(15, 2) = 0

	-- выбираем л/сч с которых надо перенести сальдо
	SELECT O.Occ
		 , O.fin_id
		 , P.SALDO AS SALDO
		 , P.service_id AS service_id
		 , P.source_id AS source_id
		 , P.sup_id
	INTO #t_occ
	FROM dbo.Occupations O 
		JOIN dbo.Flats F ON F.id = O.flat_id
		JOIN dbo.Occupation_Types OT ON OT.id = O.tip_id
		JOIN dbo.Paym_list P ON P.Occ = O.Occ
			AND P.fin_id = OT.fin_id
			AND P.service_id = @service_old
			AND P.source_id = @source_old
	WHERE O.tip_id = @tip_id
		AND (F.bldn_id = @build_id OR @build_id IS NULL)
		AND O.status_id <> 'закр'

	IF @saldo_minus = 1
		DELETE FROM #t_occ
		WHERE saldo >= 0

	SELECT @Saldo_old = SUM(saldo)
	FROM #t_occ

	SELECT @Saldo_old2 = SUM(pl.saldo)
	FROM Paym_list pl
		JOIN #t_occ to1 ON pl.Occ = to1.Occ
	WHERE pl.service_id=@service_new

	IF @debug = 1
	BEGIN
    	SELECT @Saldo_old AS Saldo_old
			  ,@Saldo_old2 AS Saldo_old2
		SELECT * FROM #t_occ
    END
		

	BEGIN TRY
		IF @trancount = 0
			BEGIN TRANSACTION
		ELSE
			SAVE TRANSACTION adm_saldo_serv_transfer;

		MERGE dbo.Paym_list PL USING (
			SELECT to1.*
			FROM #t_occ to1
		) AS t
		ON PL.Occ = t.Occ
			AND PL.fin_id = t.fin_id
			AND PL.service_id = @service_new
			AND PL.source_id = @source_new
		WHEN MATCHED 
			THEN UPDATE
				SET PL.saldo = PL.saldo + t.saldo
		WHEN NOT MATCHED
			THEN INSERT (Occ
					   , service_id
					   , sup_id
					   , subsid_only
					   , account_one
					   , tarif
					   , saldo
					   , fin_id
					   , source_id)
				VALUES(t.Occ
					 , @service_new
					 , @sup_id_new
					 , 0 -- subsid_only
					 , @account_one
					 , 0 -- tarif
					 , t.saldo
					 , t.fin_id
					 , @source_new)
		OUTPUT $ACTION
			 , INSERTED.Occ
			 , DELETED.saldo
			 , DELETED.service_id
			 , DELETED.sup_id
			 , INSERTED.saldo
			 , INSERTED.service_id
			 , INSERTED.sup_id INTO #MyLogTable
		;

		IF @debug = 1
			SELECT *
			FROM #MyLogTable

		UPDATE PL 
		SET saldo = 0
		FROM #t_occ to1
			JOIN dbo.Paym_list PL ON PL.Occ = to1.Occ
				AND PL.fin_id = to1.fin_id
		WHERE PL.service_id = @service_old
			AND PL.source_id = @source_old

		UPDATE O
		SET saldo_edit = 1
		FROM dbo.Occupations O
			JOIN #t_occ to1 ON O.Occ = to1.Occ

		SELECT @Saldo_new = SUM(pl.saldo)
		FROM dbo.Paym_list pl
			JOIN #t_occ to1 ON pl.Occ = to1.Occ AND pl.fin_id = to1.fin_id
		WHERE pl.service_id = @service_new
			AND pl.source_id = @source_new
			AND pl.sup_id = @sup_id_new

		IF @debug = 1
		BEGIN
			SELECT pl.*
			FROM Paym_list pl
				JOIN #t_occ to1 ON pl.Occ = to1.Occ
			WHERE pl.service_id IN (@service_old, @service_new)
			ORDER BY pl.Occ
				   , pl.service_id

			SELECT @Saldo_old AS Saldo_old
			     , @Saldo_old2 AS Saldo_old2
				 , @Saldo_new AS Saldo_new
		END

		INSERT dbo.Consmodes_list (Occ
								 , service_id
								 , sup_id
								 , source_id
								 , mode_id
								 , subsid_only
								 , is_counter
								 , account_one
								 , lic_source
								 , occ_serv
								 , dog_int
								 , fin_id)
		SELECT pl.Occ
			 , @service_new
			 , @sup_id_new
			 , @source_new
			 , @mode_id_NOT
			 , 0 AS subsid_only
			 , 0
			 , @account_one
			 , ''
			 , ''
			 , NULL AS dog_int
			 , pl.fin_id
		FROM dbo.Paym_list pl
			JOIN #t_occ to1 ON pl.Occ = to1.Occ
			LEFT JOIN dbo.Consmodes_list cl ON pl.Occ = cl.Occ
				AND pl.service_id = cl.service_id
				AND pl.sup_id = cl.sup_id
		WHERE pl.service_id = @service_new
			AND pl.sup_id = @sup_id_new
			AND pl.source_id = @source_new
			AND cl.sup_id IS NULL

		IF (@Saldo_old + @Saldo_old2) = @Saldo_new
		BEGIN
			SET @result_transfer = 1;
			IF @trancount = 0
				COMMIT TRANSACTION;
		END
		ELSE
		BEGIN
			IF @trancount = 0
				ROLLBACK TRANSACTION
			IF @debug = 1
				SELECT CONCAT('Суммы не сходяться!(',LTRIM(STR((@Saldo_old + @Saldo_old2), 9, 2)),'<>',LTRIM(STR(@Saldo_new, 9, 2)),') Отменяем перенос')
		END

		IF @result_transfer = 0
			RETURN

		-- записываем в LOG	
		DECLARE @var1 INT
			  , @comments1 VARCHAR(100)
		SELECT @comments1 = CONCAT('с услуги: <',@service_old,'>-><',@service_new,'>,поставщик: <',LTRIM(STR(@source_old)),'>-><',LTRIM(STR(@source_new)),'>')

		DECLARE cursor_name CURSOR FOR
			SELECT Occ
			FROM #t_occ

		OPEN cursor_name;

		FETCH NEXT FROM cursor_name INTO @var1;

		WHILE @@fetch_status = 0
		BEGIN
			EXEC dbo.k_write_log @occ1 = @var1
							   , @oper1 = 'слдо'
							   , @comments1 = @comments1

			FETCH NEXT FROM cursor_name INTO @var1;
		END

		CLOSE cursor_name;
		DEALLOCATE cursor_name;

		DROP TABLE IF EXISTS #MyLogTable
		DROP TABLE IF EXISTS #t_occ

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
			ROLLBACK TRANSACTION adm_saldo_serv_transfer;

		DECLARE @strerror VARCHAR(4000) = ''
		EXECUTE k_GetErrorInfo @visible = 0
							 , @strerror = @strerror OUT
		RAISERROR (@strerror, 16, 1)

	END CATCH

END
go

