-- =============================================
-- Author:		Пузанов
-- Create date: 09.09.2020
-- Description:	Выборочное удаление информации из базы
-- =============================================
CREATE     PROCEDURE [dbo].[adm_del_info_base]
	@str1		VARCHAR(4000) -- строка с кодами типов фонда через ","
   ,@is_paym	BIT = 0	-- Удаляем начисления
   ,@is_paying  BIT = 0	-- Удаляем платежи
   ,@is_people  BIT = 0	-- Удаляем людей
   ,@is_counter BIT = 0	-- Удаляем информацию по ИПУ
   ,@is_occ_history	BIT = 0	-- Удаляем историю по лицевым счетам
   ,@is_occ		BIT = 0	-- Удаляем лицевые счета
   ,@is_build   BIT = 0	-- Удаляем дома с квартирами
   ,@is_tip		BIT = 0 -- Удаляем полностью тип фонда
AS
/*

DECLARE @tip_str1 VARCHAR(4000)='99,100'
DECLARE @is_paym bit=1
DECLARE @is_paying bit=1
DECLARE @is_people bit=1
DECLARE @is_counter bit=1
DECLARE @is_occ bit=1
DECLARE @is_build bit=1
DECLARE @is_tip bit=1
DECLARE @RC INT

EXECUTE @RC = [dbo].[adm_del_info_base] 
   @tip_str1
  ,@is_paym
  ,@is_paying
  ,@is_people
  ,@is_counter
  ,@is_occ
  ,@is_build
  ,@is_tip
GO

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @ROWS_DEL_DEFAULT INT		   = 100000 -- порция для удаления
		   ,@RowsDeleted	  INT
		   ,@msg			  VARCHAR(200) = '%s' --'tip_id: %i - %s'
		   ,@msg_del		  VARCHAR(200) = '%i. удалили - %i'
		   ,@count			  INT
		   ,@i				  INT

	-- Таблица значениями Типа жил.фонда
	DECLARE @tip_table TABLE(tip_id SMALLINT DEFAULT NULL)

	INSERT INTO @tip_table(tip_id)
	SELECT value FROM STRING_SPLIT(@str1, ',')	WHERE RTRIM(value) <> ''
	--SELECT * FROM @tip_table tt

	SELECT
		@is_paym = COALESCE(@is_paym, 0)
	   ,@is_paying = COALESCE(@is_paying, 0)
	   ,@is_people = COALESCE(@is_people, 0)
	   ,@is_counter = COALESCE(@is_counter, 0)
	   ,@is_occ_history = COALESCE(@is_occ_history, 0)
	   ,@is_occ = COALESCE(@is_occ, 0)
	   ,@is_build = COALESCE(@is_build, 0)

	IF @is_tip = 1
		SELECT
			@is_paym = 1
		   ,@is_paying = 1
		   ,@is_people = 1
		   ,@is_counter = 1
		   ,@is_occ_history = 1
		   ,@is_occ = 1
		   ,@is_build = 1

	IF @is_build = 1
		SELECT
			@is_paym = 1
		   ,@is_paying = 1
		   ,@is_people = 1
		   ,@is_counter = 1
		   ,@is_occ_history = 1
		   ,@is_occ = 1

	IF @is_occ = 1
		SELECT
			@is_paym = 1
		   ,@is_paying = 1
		   ,@is_people = 1
		   ,@is_counter = 1
		   ,@is_occ_history = 1

	IF @is_paym = 1
	BEGIN
		--===================================================
		RAISERROR (@msg, 10, 1, 'PAYM_HISTORY') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION

			DELETE FROM dbo.Paym_history
			WHERE occ IN (SELECT TOP (@RowsDeleted) 
								o.occ 
							FROM dbo.Occupations o
							JOIN @tip_table tt ON 
								tt.tip_id = o.tip_id
						)

			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 0, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'PAYM_LIST') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION

			DELETE FROM dbo.Paym_list
			WHERE occ IN (SELECT TOP (@RowsDeleted) 
								o.occ 
							FROM dbo.Occupations o
							JOIN @tip_table tt ON 
								tt.tip_id = o.tip_id
						)

			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 0, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'INTPRINT') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION

			DELETE FROM dbo.Intprint
			WHERE occ IN (SELECT TOP (@RowsDeleted) 
								o.occ 
							FROM dbo.Occupations o
							JOIN @tip_table tt ON 
								tt.tip_id = o.tip_id
						)

			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'ADDED_PAYMENTS_HISTORY') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION
			
			DELETE FROM dbo.Added_Payments_History
			WHERE id IN (
						SELECT TOP (@RowsDeleted) t.id 
						FROM dbo.Added_Payments_History AS t
						JOIN dbo.Occupations o ON 
							t.occ = o.occ
						JOIN @tip_table tt ON 
							tt.tip_id = o.tip_id
						)

			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 0, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'ADDED_PAYMENTS') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION

			DELETE FROM dbo.Added_Payments 
			WHERE id IN (
						SELECT TOP (@RowsDeleted) t.id
						FROM dbo.Added_Payments AS t
						JOIN dbo.Occupations o ON 
							t.occ = o.occ
						JOIN @tip_table tt ON 
							tt.tip_id = o.tip_id
						)
			
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'PENY_ALL') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION

			DELETE FROM dbo.Peny_all
			WHERE occ1 IN (SELECT TOP (@RowsDeleted) 
								o.occ 
							FROM dbo.Occupations o
							JOIN @tip_table tt ON 
								tt.tip_id = o.tip_id
						)

			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'PENY_DETAIL') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION

			DELETE t1
			FROM dbo.Peny_detail as t1
				JOIN dbo.Peny_all as t2 ON
					t1.fin_id=t2.fin_id
					and t1.occ=t2.occ
			WHERE t2.occ1 IN (SELECT TOP (@RowsDeleted) 
								o.occ 
							FROM dbo.Occupations o
							JOIN @tip_table tt ON 
								tt.tip_id = o.tip_id
						)

			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'PAYM_OCC_BUILD') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION

			DELETE FROM dbo.Paym_occ_build
			WHERE occ IN (SELECT TOP (@RowsDeleted) 
								o.occ 
							FROM dbo.Occupations o
							JOIN @tip_table tt ON 
								tt.tip_id = o.tip_id
						)
			
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'PAYM_ADD') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION

			DELETE dbo.Paym_add
			WHERE id IN (SELECT TOP (@RowsDeleted) 
							t.id
						FROM dbo.Paym_add AS t
						JOIN dbo.Occupations o ON 
							o.occ = t.occ
						JOIN @tip_table tt ON 
							tt.tip_id = o.tip_id
						)
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'ADDED_COUNTERS_ALL') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION

			DELETE FROM dbo.Added_Counters_All
			WHERE id IN (SELECT TOP (@RowsDeleted) 
							t.id
						FROM dbo.Added_Counters_All AS t
						JOIN dbo.Occupations o ON 
							t.occ = o.occ
						JOIN @tip_table tt ON 
							tt.tip_id = o.tip_id
						)
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1			
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
	END
	--***************************************************************************
	IF @is_paying = 1
	BEGIN
		RAISERROR (@msg, 0, 1, 'Paying_cash') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION
			
			DELETE dbo.Paying_cash 
			WHERE paying_id IN (SELECT TOP (@RowsDeleted)
									ph.id
								FROM Payings AS ph 					
								JOIN Occupations o ON 
									ph.occ = o.occ
								JOIN @tip_table tt ON 
									tt.tip_id = o.tip_id
								)
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		RAISERROR (@msg, 10, 1, 'PAYING_SERV') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION
			
			DELETE FROM Paying_serv
			WHERE paying_id IN (SELECT TOP (@RowsDeleted) 
									ph.id
								FROM dbo.Payings AS ph					
								JOIN Occupations o ON 
									ph.occ = o.occ
								JOIN @tip_table tt ON 
									tt.tip_id = o.tip_id
								)			
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'PAYINGS') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION

			DELETE FROM dbo.Payings 
			WHERE id IN (SELECT TOP (@RowsDeleted) 
							ph.id
						FROM dbo.Payings AS ph
						JOIN dbo.Paydoc_packs AS pd ON 
							pd.id = ph.pack_id
						JOIN @tip_table tt ON 
							tt.tip_id = pd.tip_id
						)
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'PAYDOC_PACKS') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION
			
			DELETE FROM dbo.Paydoc_packs
			WHERE id IN (SELECT TOP (@RowsDeleted) 
							ph.id
						FROM dbo.Paydoc_packs AS ph
						JOIN @tip_table tt ON 
							tt.tip_id = ph.tip_id
						)			
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;            
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'BANK_DBF') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION

			DELETE FROM dbo.Bank_Dbf
			WHERE id IN (SELECT TOP (@RowsDeleted) 
							ph.id
						FROM dbo.Bank_Dbf AS ph
						JOIN dbo.Occupations o ON 
							ph.occ = o.occ
						JOIN @tip_table tt ON 
							tt.tip_id = o.tip_id
						)
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
        CHECKPOINT;
	END
	--***************************************************************************	
	IF @is_people = 1
	BEGIN
		RAISERROR (@msg, 10, 1, 'PEOPLE_HISTORY') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION

			DELETE FROM dbo.People_history
			WHERE occ IN (SELECT TOP (@RowsDeleted) 
								o.occ 
							FROM dbo.Occupations o
							JOIN @tip_table tt ON 
								tt.tip_id = o.tip_id
						)
				
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'PEOPLE_2') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			DELETE FROM dbo.People_2
			WHERE id IN (SELECT TOP (@RowsDeleted) 
							ph.id
						FROM dbo.People_2 AS ph
						JOIN dbo.People p ON 
							ph.owner_id = p.id
						JOIN dbo.Occupations o ON 
							p.occ = o.occ
						JOIN @tip_table tt ON 
							tt.tip_id = o.tip_id
						)
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'PEOPLE') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION

			DELETE FROM dbo.People
			WHERE id IN (SELECT TOP (@RowsDeleted) 
							ph.id
						FROM dbo.People AS ph
						JOIN dbo.Occupations o ON 
							ph.occ = o.occ
						JOIN @tip_table tt ON 
							tt.tip_id = o.tip_id
						)
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION;
			CHECKPOINT;
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
        CHECKPOINT;
	END

	--***************************************************************************
	IF @is_counter = 1
	BEGIN
		RAISERROR (@msg, 10, 1, 'COUNTER_LIST_ALL') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION

			DELETE FROM dbo.Counter_list_all
			WHERE occ IN (SELECT TOP (@RowsDeleted) 
								o.occ 
							FROM dbo.Occupations o
							JOIN @tip_table tt ON 
								tt.tip_id = o.tip_id
						)

			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION;
			CHECKPOINT;
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		DELETE ph
			FROM dbo.Counter_list_all AS ph
			JOIN dbo.Counters c 
				ON ph.counter_id = c.id
			JOIN dbo.Buildings as b 
				ON c.build_id=b.id
			JOIN @tip_table tt ON tt.tip_id = b.tip_id
		--===================================================
		RAISERROR (@msg, 10, 1, 'COUNTER_PAYM_OCC') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN

			DELETE FROM dbo.Counter_paym_occ
			WHERE occ IN (SELECT TOP (@RowsDeleted) 
								o.occ 
							FROM dbo.Occupations o
							JOIN @tip_table tt ON 
								tt.tip_id = o.tip_id
						)

			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'COUNTER_PAYM2') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN

			DELETE dbo.Counter_paym2
			WHERE occ IN (SELECT TOP (@RowsDeleted) 
								o.occ 
							FROM dbo.Occupations o
							JOIN @tip_table tt ON 
								tt.tip_id = o.tip_id
						)

			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'COUNTER_INSPECTOR') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION
			DELETE FROM dbo.Counter_inspector
			WHERE id IN (SELECT TOP (@RowsDeleted) 
							ci.id
						FROM dbo.Counter_inspector ci
						JOIN dbo.Counters c ON 
							c.id = ci.counter_id
						JOIN dbo.Buildings AS b ON 
							b.id = c.build_id
						JOIN @tip_table tt ON 
							tt.tip_id = b.tip_id
						)
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION;
			CHECKPOINT;
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'COUNTER_PAYM') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			DELETE FROM dbo.Counter_paym
			WHERE counter_id IN (SELECT TOP (@RowsDeleted) 
									c.id
								FROM dbo.Counters c 
								JOIN dbo.Buildings AS b 
									ON b.id = c.build_id
								JOIN @tip_table tt ON 
									tt.tip_id = b.tip_id
								)
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'COUNTERS') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			DELETE FROM dbo.Counters
			WHERE id IN (SELECT TOP (1000) 
							c.id
						FROM dbo.Counters c
						JOIN dbo.Buildings AS b ON 
							b.id = c.build_id
						JOIN @tip_table tt ON 
							tt.tip_id = b.tip_id
						)
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
        CHECKPOINT;
	END
	--***************************************************************************
	IF @is_occ_history = 1
	BEGIN
		RAISERROR (@msg, 10, 1, 'OCC_HISTORY') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION
			DELETE FROM dbo.Occ_history 
			WHERE occ IN (SELECT TOP (1000) 
							o.occ
						FROM dbo.Occupations o
						JOIN @tip_table tt ON 
							tt.tip_id = o.tip_id
						)
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 0, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'CONSMODES_HISTORY') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION
			DELETE FROM dbo.Consmodes_history
			WHERE occ IN (SELECT TOP (1000)
							o.occ
						FROM dbo.Occupations o 					
						JOIN @tip_table tt ON 
							tt.tip_id = o.tip_id
						)
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 0, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'OCC_SUPPLIERS из истории') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION

			DELETE os
			FROM dbo.Occ_Suppliers as os
				JOIN dbo.Occupations o ON
					os.occ=o.occ
			WHERE os.fin_id < o.fin_id  -- ранее текущего периода
				AND os.occ IN (SELECT TOP (1000)
								o.occ
							FROM dbo.Occupations o 					
							JOIN @tip_table tt ON 
								tt.tip_id = o.tip_id
						)
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
	END
	--***************************************************************************
	IF @is_occ = 1
	BEGIN
		--===================================================
		RAISERROR (@msg, 10, 1, 'OCC_SUPPLIERS') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION
			
			DELETE dbo.Occ_Suppliers
			WHERE occ IN (SELECT TOP (@RowsDeleted)
							o.occ
						FROM dbo.Occupations o 					
						JOIN @tip_table tt ON 
							tt.tip_id = o.tip_id
						)

			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'CONSMODES_LIST') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION
			DELETE dbo.Consmodes_list 
			WHERE occ IN (select TOP (@RowsDeleted) 
							o.occ 
						FROM dbo.Occupations o 
						JOIN @tip_table tt ON 
							tt.tip_id = o.tip_id
						)
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'OP_LOG') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN
			BEGIN TRANSACTION
			DELETE dbo.Op_Log 
			WHERE id IN (SELECT TOP (@RowsDeleted) 
							t.id
						FROM dbo.Op_Log AS t
						JOIN dbo.Occupations o 
							ON o.occ = t.occ
						JOIN @tip_table tt ON 
							tt.tip_id = o.tip_id
						)
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'OCCUPATIONS') WITH NOWAIT;

		-- для быстрого удаления лицевых надо отключить индексы и связь с другими таблицами
		ALTER INDEX id_els_gis ON dbo.Occupations DISABLE;
		ALTER INDEX IX_OCCUPATIONS_1 ON dbo.Occupations DISABLE;
		ALTER INDEX tip_id ON dbo.Occupations DISABLE;
		-- ALTER INDEX ALL ON dbo.Occupations DISABLE;

		ALTER TABLE dbo.Occupations  NOCHECK CONSTRAINT FK_OCCUPATIONS_FLATS; 
		ALTER TABLE dbo.Occupations  NOCHECK CONSTRAINT FK_OCCUPATIONS_OCC_STATUSES
		ALTER TABLE dbo.Occupations  NOCHECK CONSTRAINT FK_OCCUPATIONS_OCCUPATION_TYPES
		ALTER TABLE dbo.Occupations  NOCHECK CONSTRAINT FK_OCCUPATIONS_PROPERTY_TYPES
		ALTER TABLE dbo.Occupations  NOCHECK CONSTRAINT FK_OCCUPATIONS_ROOM_TYPES

		ALTER TABLE dbo.ADDED_PAYMENTS  NOCHECK CONSTRAINT FK_ADDED_PAYMENTS_OCCUPATIONS
		ALTER TABLE dbo.CONSMODES_HISTORY  NOCHECK CONSTRAINT FK_CONSMODES_HISTORY_OCCUPATIONS
		ALTER TABLE dbo.COUNTER_LIST_ALL  NOCHECK CONSTRAINT FK_COUNTER_LIST_ALL_OCCUPATIONS
		ALTER TABLE dbo.OCC_HISTORY  NOCHECK CONSTRAINT FK_OCC_HISTORY_OCCUPATIONS
		ALTER TABLE dbo.OCC_SUPPLIERS  NOCHECK CONSTRAINT FK_OCC_SUPPLIERS_OCCUPATIONS
		ALTER TABLE dbo.PAYM_LIST  NOCHECK CONSTRAINT FK_PAYM_LIST_OCCUPATIONS
		RAISERROR ('=== отключили ограничения ===', 10, 1, 'OCCUPATIONS') WITH NOWAIT;

		SELECT
			@count = COALESCE(COUNT(*), 0)
		FROM Occupations o 
		JOIN @tip_table tt ON tt.tip_id = o.tip_id
		SELECT
			@RowsDeleted = 1
		   ,@i = 1
		WHILE (@RowsDeleted > 0)
		BEGIN
			DELETE Occupations
			WHERE occ IN (SELECT TOP (@RowsDeleted) 
							o.occ
							FROM Occupations o
							JOIN @tip_table tt ON 
								tt.tip_id = o.tip_id
						)
			SET @RowsDeleted = @@rowcount
			SET @i = @i + @RowsDeleted
			RAISERROR (' удалили: %i/%i', 10, 1, @i, @count) WITH NOWAIT;
		END
		
		RAISERROR ('=== включаем ===', 10, 1, 'OCCUPATIONS') WITH NOWAIT;
		--ALTER INDEX ALL ON dbo.Occupations REBUILD; 
		ALTER INDEX tip_id ON dbo.Occupations REBUILD; 
		ALTER INDEX IX_OCCUPATIONS_1 ON dbo.Occupations REBUILD;
		ALTER INDEX id_els_gis ON dbo.Occupations REBUILD;

		ALTER TABLE dbo.Occupations  CHECK CONSTRAINT FK_OCCUPATIONS_FLATS;
		ALTER TABLE dbo.Occupations  CHECK CONSTRAINT FK_OCCUPATIONS_OCC_STATUSES
		ALTER TABLE dbo.Occupations  CHECK CONSTRAINT FK_OCCUPATIONS_OCCUPATION_TYPES
		ALTER TABLE dbo.Occupations  CHECK CONSTRAINT FK_OCCUPATIONS_PROPERTY_TYPES
		ALTER TABLE dbo.Occupations  CHECK CONSTRAINT FK_OCCUPATIONS_ROOM_TYPES

		ALTER TABLE dbo.ADDED_PAYMENTS     CHECK CONSTRAINT FK_ADDED_PAYMENTS_OCCUPATIONS
		ALTER TABLE dbo.CONSMODES_HISTORY  CHECK CONSTRAINT FK_CONSMODES_HISTORY_OCCUPATIONS
		ALTER TABLE dbo.COUNTER_LIST_ALL   CHECK CONSTRAINT FK_COUNTER_LIST_ALL_OCCUPATIONS
		ALTER TABLE dbo.OCC_HISTORY        CHECK CONSTRAINT FK_OCC_HISTORY_OCCUPATIONS
		ALTER TABLE dbo.OCC_SUPPLIERS      CHECK CONSTRAINT FK_OCC_SUPPLIERS_OCCUPATIONS
		ALTER TABLE dbo.PAYM_LIST          CHECK CONSTRAINT FK_PAYM_LIST_OCCUPATIONS
	
		RAISERROR ('=== включили ===', 10, 1, 'OCCUPATIONS') WITH NOWAIT;
        CHECKPOINT;
	END
	--***************************************************************************
	IF @is_build = 1
	BEGIN
		RAISERROR (@msg, 10, 1, 'BUILDINGS_HISTORY') WITH NOWAIT;
		SELECT @RowsDeleted = @ROWS_DEL_DEFAULT, @i = 0
		WHILE (@RowsDeleted > 0)
		BEGIN

			DELETE dbo.Buildings_history 
			WHERE bldn_id IN (SELECT TOP (@RowsDeleted) 
								t.bldn_id
							FROM dbo.Buildings_history AS t
							JOIN @tip_table tt ON 
								tt.tip_id = t.tip_id
							)
			SELECT @RowsDeleted = @@rowcount, @i = @i + 1
			RAISERROR (@msg_del, 10, 1, @i, @RowsDeleted) WITH NOWAIT;
		END
		--===================================================
		RAISERROR (@msg, 10, 1, 'BUILD_MODE') WITH NOWAIT;
		DELETE t
			FROM dbo.Build_mode AS t
			JOIN dbo.Buildings b 
				ON t.build_id = b.id
			JOIN @tip_table tt ON tt.tip_id = b.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'BUILD_SOURCE') WITH NOWAIT;
		DELETE t
			FROM dbo.Build_source AS t
			JOIN dbo.Buildings b ON 
				t.build_id = b.id
			JOIN @tip_table tt ON 
				tt.tip_id = b.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'DOM_SVOD_ALL') WITH NOWAIT;
		DELETE c
			FROM dbo.Dom_svod_all c
			JOIN dbo.Buildings AS b 
				ON b.id = c.build_id
			JOIN @tip_table tt ON tt.tip_id = b.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'DOM_SVOD') WITH NOWAIT;
		DELETE c
			FROM dbo.Dom_svod c
			JOIN dbo.Buildings AS b 
				ON b.id = c.build_id
			JOIN @tip_table tt ON tt.tip_id = b.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'DOG_BUILD') WITH NOWAIT;
		DELETE f
			FROM dbo.Dog_build f
			JOIN dbo.Buildings AS b 
				ON b.id = f.build_id
			JOIN dbo.Dog_sup AS ds 
				ON f.dog_int = ds.id
		WHERE EXISTS (SELECT
					*
				FROM @tip_table tt
				WHERE tt.tip_id = b.tip_id)
			OR EXISTS (SELECT
					*
				FROM @tip_table tt
				WHERE tt.tip_id = ds.tip_id)
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'DOG_SUP') WITH NOWAIT;
		DELETE t
			FROM dbo.Dog_sup t
			JOIN @tip_table tt ON tt.tip_id = t.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'ROOMS') WITH NOWAIT;
		DELETE r
			FROM dbo.ROOMS r 
			JOIN dbo.Flats f 
            	ON r.flat_id = f.id
			JOIN dbo.Buildings AS b 
				ON b.id = f.bldn_id            
			JOIN @tip_table tt ON tt.tip_id = b.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;    
        --===================================================    
		RAISERROR (@msg, 10, 1, 'FLATS (FK_FLATS_BUILDINGS)') WITH NOWAIT;
		DELETE f
			FROM dbo.Flats f
			JOIN dbo.Buildings AS b 
				ON b.id = f.bldn_id
			JOIN @tip_table tt ON tt.tip_id = b.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'Services_build') WITH NOWAIT;
		DELETE f
			FROM dbo.Services_build f
			JOIN dbo.Buildings AS b 
				ON b.id = f.build_id
			JOIN @tip_table tt ON tt.tip_id = b.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'Suppliers_build_history') WITH NOWAIT;
		DELETE f
			FROM dbo.Suppliers_build_history f
			JOIN dbo.Buildings AS b 
				ON b.id = f.build_id
			JOIN @tip_table tt ON tt.tip_id = b.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'Suppliers_build') WITH NOWAIT;
		DELETE f
			FROM dbo.Suppliers_build f
			JOIN dbo.Buildings AS b 
				ON b.id = f.build_id
			JOIN @tip_table tt ON tt.tip_id = b.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;

		--===================================================
		RAISERROR (@msg, 10, 1, 'BUILDINGS') WITH NOWAIT;
		DELETE b
			FROM dbo.Buildings AS b
			JOIN @tip_table tt ON tt.tip_id = b.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
        CHECKPOINT;
	END
	--***************************************************************************
	IF @is_tip = 1
	BEGIN
		RAISERROR (@msg, 10, 1, 'OCCUPATION_TYPES_HISTORY') WITH NOWAIT;
		DELETE t
			FROM dbo.Occupation_Types_History t
			JOIN @tip_table tt ON tt.tip_id = t.id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'RATES_COUNTER') WITH NOWAIT;
		DELETE t
			FROM dbo.Rates_counter t
			JOIN @tip_table tt ON tt.tip_id = t.tipe_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'RATES') WITH NOWAIT;
		DELETE t
			FROM dbo.Rates t
			JOIN @tip_table tt ON tt.tip_id = t.tipe_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'MEASUREMENT_UNITS') WITH NOWAIT;
		DELETE t
			FROM dbo.Measurement_units t
			JOIN @tip_table tt ON tt.tip_id = t.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'Service_units') WITH NOWAIT;
		DELETE t
			FROM dbo.Service_units t
			JOIN @tip_table tt ON tt.tip_id = t.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'Services_type_gis') WITH NOWAIT;
		DELETE t
			FROM dbo.Services_type_gis t
			JOIN @tip_table tt ON tt.tip_id = t.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'Services_types') WITH NOWAIT;
		DELETE t
			FROM dbo.Services_types t
			JOIN @tip_table tt ON tt.tip_id = t.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'Suppliers_types_history') WITH NOWAIT;
		DELETE t
			FROM dbo.Suppliers_types_history t
			JOIN @tip_table tt ON tt.tip_id = t.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'Suppliers_types') WITH NOWAIT;
		DELETE t
			FROM dbo.Suppliers_types t
			JOIN @tip_table tt ON tt.tip_id = t.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'Services_type_counters') WITH NOWAIT;
		DELETE t
			FROM dbo.Services_type_counters t
			JOIN @tip_table tt ON tt.tip_id = t.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'SECTOR_TYPES') WITH NOWAIT;
		DELETE t
			FROM dbo.SECTOR_TYPES t
			JOIN @tip_table tt ON tt.tip_id = t.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'SECTOR') WITH NOWAIT;
		DELETE t
			FROM dbo.SECTOR t
		WHERE NOT EXISTS (SELECT
					*
				FROM dbo.Buildings_history tt
				WHERE tt.sector_id = t.id)
			AND NOT EXISTS(SELECT
					*
				FROM dbo.Buildings tt
				WHERE tt.sector_id = t.id)
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'Occ_history') WITH NOWAIT;
		DELETE t
			FROM dbo.Occ_history t
			JOIN @tip_table tt ON tt.tip_id = t.tip_id
		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;
		--===================================================
		RAISERROR (@msg, 10, 1, 'Occupation_types') WITH NOWAIT;

        ALTER TABLE dbo.BUILDINGS  NOCHECK CONSTRAINT FK_BUILDINGS_OCCUPATION_TYPES; 
        ALTER TABLE Cash NOCHECK CONSTRAINT FK_CASH_OCCUPATION_TYPES
        ALTER TABLE DOG_SUP NOCHECK CONSTRAINT FK_DOG_SUP_OCCUPATION_TYPES
        ALTER TABLE OCC_HISTORY NOCHECK CONSTRAINT FK_OCC_HISTORY_OCCUPATION_TYPES
        ALTER TABLE OCCUPATION_TYPES NOCHECK CONSTRAINT FK_OCCUPATION_TYPES_BANK_FORMAT_OUT
        ALTER TABLE OCCUPATIONS NOCHECK CONSTRAINT FK_OCCUPATIONS_OCCUPATION_TYPES
        ALTER TABLE RATES NOCHECK CONSTRAINT FK_RATES_OCCUPATION_TYPES
        ALTER TABLE Sector_types NOCHECK CONSTRAINT FK_Sector_types_Occupation_Types
        ALTER TABLE SERVICE_UNITS NOCHECK CONSTRAINT FK_SERVICE_UNITS_OCCUPATION_TYPES
        ALTER TABLE SERVICES_TYPE_COUNTERS NOCHECK CONSTRAINT FK_SERVICES_TYPE_COUNTERS_OCCUPATION_TYPES
        ALTER TABLE SERVICES_TYPE_GIS NOCHECK CONSTRAINT FK_SERVICES_TYPE_GIS_OCCUPATION_TYPES
        ALTER TABLE SUPPLIERS_TYPES NOCHECK CONSTRAINT FK_SUPPLIERS_TYPES_OCCUPATION_TYPES

		DELETE t
			FROM dbo.Occupation_Types t
			JOIN @tip_table tt ON tt.tip_id = t.id

		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;

        ALTER TABLE dbo.BUILDINGS  CHECK CONSTRAINT FK_BUILDINGS_OCCUPATION_TYPES;
        ALTER TABLE Cash CHECK CONSTRAINT FK_CASH_OCCUPATION_TYPES
        ALTER TABLE DOG_SUP CHECK CONSTRAINT FK_DOG_SUP_OCCUPATION_TYPES
        ALTER TABLE OCC_HISTORY CHECK CONSTRAINT FK_OCC_HISTORY_OCCUPATION_TYPES
        ALTER TABLE OCCUPATION_TYPES CHECK CONSTRAINT FK_OCCUPATION_TYPES_BANK_FORMAT_OUT
        ALTER TABLE OCCUPATIONS CHECK CONSTRAINT FK_OCCUPATIONS_OCCUPATION_TYPES
        ALTER TABLE RATES CHECK CONSTRAINT FK_RATES_OCCUPATION_TYPES
        ALTER TABLE Sector_types CHECK CONSTRAINT FK_Sector_types_Occupation_Types
        ALTER TABLE SERVICE_UNITS CHECK CONSTRAINT FK_SERVICE_UNITS_OCCUPATION_TYPES
        ALTER TABLE SERVICES_TYPE_COUNTERS CHECK CONSTRAINT FK_SERVICES_TYPE_COUNTERS_OCCUPATION_TYPES
        ALTER TABLE SERVICES_TYPE_GIS CHECK CONSTRAINT FK_SERVICES_TYPE_GIS_OCCUPATION_TYPES
        ALTER TABLE SUPPLIERS_TYPES CHECK CONSTRAINT FK_SUPPLIERS_TYPES_OCCUPATION_TYPES

        CHECKPOINT;
        
	END
    RAISERROR ('Обработка выполнена', 10, 1) WITH NOWAIT;

END
go

UILDINGS  NOCHECK CONSTRAINT FK_BUILDINGS_OCCUPATION_TYPES; 
        ALTER TABLE Cash NOCHECK CONSTRAINT FK_CASH_OCCUPATION_TYPES
        ALTER TABLE DOG_SUP NOCHECK CONSTRAINT FK_DOG_SUP_OCCUPATION_TYPES
        ALTER TABLE OCC_HISTORY NOCHECK CONSTRAINT FK_OCC_HISTORY_OCCUPATION_TYPES
        ALTER TABLE OCCUPATION_TYPES NOCHECK CONSTRAINT FK_OCCUPATION_TYPES_BANK_FORMAT_OUT
        ALTER TABLE OCCUPATIONS NOCHECK CONSTRAINT FK_OCCUPATIONS_OCCUPATION_TYPES
        ALTER TABLE RATES NOCHECK CONSTRAINT FK_RATES_OCCUPATION_TYPES
        ALTER TABLE Sector_types NOCHECK CONSTRAINT FK_Sector_types_Occupation_Types
        ALTER TABLE SERVICE_UNITS NOCHECK CONSTRAINT FK_SERVICE_UNITS_OCCUPATION_TYPES
        ALTER TABLE SERVICES_TYPE_COUNTERS NOCHECK CONSTRAINT FK_SERVICES_TYPE_COUNTERS_OCCUPATION_TYPES
        ALTER TABLE SERVICES_TYPE_GIS NOCHECK CONSTRAINT FK_SERVICES_TYPE_GIS_OCCUPATION_TYPES
        ALTER TABLE SUPPLIERS_TYPES NOCHECK CONSTRAINT FK_SUPPLIERS_TYPES_OCCUPATION_TYPES

		DELETE t
			FROM dbo.Occupation_Types t
			JOIN @tip_table tt ON tt.tip_id = t.id
		WHERE (@fin_id1=0)

		SET @RowsDeleted = @@rowcount
		RAISERROR (@msg_del, 0, 1, 1, @RowsDeleted) WITH NOWAIT;

        ALTER TABLE dbo.BUILDINGS  CHECK CONSTRAINT FK_BUILDINGS_OCCUPATION_TYPES;
        ALTER TABLE Cash CHECK CONSTRAINT FK_CASH_OCCUPATION_TYPES
        ALTER TABLE DOG_SUP CHECK CONSTRAINT FK_DOG_SUP_OCCUPATION_TYPES
        ALTER TABLE OCC_HISTORY CHECK CONSTRAINT FK_OCC_HISTORY_OCCUPATION_TYPES
        ALTER TABLE OCCUPATION_TYPES CHECK CONSTRAINT FK_OCCUPATION_TYPES_BANK_FORMAT_OUT
        ALTER TABLE OCCUPATIONS CHECK CONSTRAINT FK_OCCUPATIONS_OCCUPATION_TYPES
        ALTER TABLE RATES CHECK CONSTRAINT FK_RATES_OCCUPATION_TYPES
        ALTER TABLE Sector_types CHECK CONSTRAINT FK_Sector_types_Occupation_Types
        ALTER TABLE SERVICE_UNITS CHECK CONSTRAINT FK_SERVICE_UNITS_OCCUPATION_TYPES
        ALTER TABLE SERVICES_TYPE_COUNTERS CHECK CONSTRAINT FK_SERVICES_TYPE_COUNTERS_OCCUPATION_TYPES
        ALTER TABLE SERVICES_TYPE_GIS CHECK CONSTRAINT FK_SERVICES_TYPE_GIS_OCCUPATION_TYPES
        ALTER TABLE SUPPLIERS_TYPES CHECK CONSTRAINT FK_SUPPLIERS_TYPES_OCCUPATION_TYPES

        CHECKPOINT;
        
	END
    RAISERROR (N'Обработка выполнена', 10, 1) WITH NOWAIT;

END
go

