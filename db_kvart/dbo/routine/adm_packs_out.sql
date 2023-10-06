CREATE   PROCEDURE [dbo].[adm_packs_out]
(
	@pack_id1 INT --код пачки 
   ,@debug	  BIT = 0 -- признак отладки
   ,@ras1	  BIT = 1-- признак перерасчета по лицевым
)
AS
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	/*
		Возврат платежей ошибочно начисленных
		вход: номер пачки
	
		-- Дата изменения: 6.02.2008   (добавил перерасчет лицевых, убал проверку сумм)
	*/


	IF @ras1 IS NULL
		SET @ras1 = 1

	DECLARE @fin_id1	 SMALLINT
		   ,@occ1		 INT
		   ,@i			 INT = 0
		   ,@tip_id		 SMALLINT
		   ,@fin_current SMALLINT

	SELECT
		@fin_id1 = pd.fin_id
	   ,@tip_id = ot.id
	   ,@fin_current = ot.fin_id
	FROM dbo.PAYDOC_PACKS AS pd
	JOIN dbo.OCCUPATION_TYPES AS ot
		ON pd.tip_id = ot.id
	WHERE pd.id = @pack_id1

	IF @tip_id IS NULL
	BEGIN
		RAISERROR ('Пачки: %i не существует!', 16, 1, @pack_id1)
		RETURN
	END

	IF @fin_id1 < @fin_current
	BEGIN
		RAISERROR ('Пачка не закрыта в текущем фин.периоде!', 16, 1)
		RETURN
	END

	CREATE TABLE #payingsID
	(
		id  INT PRIMARY KEY
	   ,occ INT
	)

	-- Выбираем платежи
	INSERT INTO #payingsID
		SELECT
			pl.id
		   ,pl.occ
		FROM dbo.PAYINGS AS pl
		WHERE pl.pack_id = @pack_id1

	IF @debug = 1
		SELECT
			*
		FROM #payingsID

	BEGIN TRAN

		-- открываем платеж
		UPDATE PAYINGS
		SET forwarded = 0
		FROM dbo.PAYINGS AS p1
			JOIN #payingsID AS p2 ON 
				p1.id = p2.id
		

		-- открываем пачку
		UPDATE dbo.PAYDOC_PACKS
		SET forwarded = 0
		   ,date_edit = dbo.Fun_GetOnlyDate(current_timestamp)
		WHERE id = @pack_id1

		COMMIT TRAN

		-- Делаем перерасчет на лицевых из этой пачки

		IF @debug = 1
			PRINT 'Расчитываем квартплату'

		IF @ras1 = 1
		BEGIN

			DECLARE curs CURSOR LOCAL FOR
				SELECT DISTINCT
					occ
				FROM #payingsID
				ORDER BY occ
			OPEN curs
			FETCH NEXT FROM curs INTO @occ1
			WHILE (@@fetch_status = 0)
			BEGIN
				EXEC dbo.k_raschet_2 @occ1 = @occ1
									,@fin_id1 = @fin_id1
									,@people_list = 1

				EXEC dbo.k_raschet_peny @occ1 = @occ1
									   ,@fin_id1 = @fin_id1

				SET @i = @i + 1
				IF @debug = 1					
					RAISERROR ('%d %d', 10, 1, @i, @occ1) WITH NOWAIT;

				FETCH NEXT FROM curs INTO @occ1

			END
			CLOSE curs
			DEALLOCATE curs

		END
go

