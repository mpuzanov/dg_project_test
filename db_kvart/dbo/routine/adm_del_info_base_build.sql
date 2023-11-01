-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE                 PROCEDURE [dbo].[adm_del_info_base_build]
	@str1			VARCHAR(100) -- строка с кодами типов фонда через ","
	,@is_paym		BIT	= 0	-- Удаляем начисления
	,@is_paying		BIT	= 0	-- Удаляем платежи
	,@is_people		BIT	= 0	-- Удаляем людей
	,@is_counter	BIT	= 0	-- Удаляем информацию по ИПУ
	,@is_occ_history	BIT = 0	-- Удаляем историю по лицевым счетам
	,@is_occ		BIT	= 0	-- Удаляем лицевые счета
	,@is_build		BIT	= 0	-- Удаляем дома с квартирами
	,@is_tip		BIT	= 0 -- Удаляем полностью тип фонда
AS
/*

DECLARE @str1 VARCHAR(100)='5795'
DECLARE @is_paym bit=1
DECLARE @is_paying bit=0
DECLARE @is_people bit=0
DECLARE @is_counter bit=0
DECLARE @is_occ bit=0
DECLARE @is_build bit=0
DECLARE @is_tip bit=0
DECLARE @RC INT

EXECUTE @RC = [dbo].[adm_del_info_base_build] 
   @str1
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

	DECLARE @RowsDeleted	  INT
		   ,@msg_del		  VARCHAR(200) = 'удалили - %i'

	-- Таблица значениями 
	DECLARE @build_table TABLE(id INT DEFAULT NULL)
	INSERT INTO @build_table
	SELECT value FROM STRING_SPLIT(@str1, ',') WHERE RTRIM(value) <> ''
	
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

	DECLARE @build_id INT

	DECLARE cur CURSOR LOCAL FOR
		SELECT
			id
		FROM @build_table

	OPEN cur

	FETCH NEXT FROM cur INTO @build_id

	WHILE @@fetch_status = 0
	BEGIN

		IF @is_paym = 1
		BEGIN

			RAISERROR ('%i - [PAYM_HISTORY]', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].[PAYM_HISTORY] AS ph
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - [PAYM_LIST]', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].[PAYM_LIST] AS ph
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - [INTPRINT]', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].INTPRINT AS ph
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - [ADDED_PAYMENTS_HISTORY]', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].[ADDED_PAYMENTS_HISTORY] AS ph
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - [ADDED_PAYMENTS]', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].[ADDED_PAYMENTS] AS ph
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - PENY_ALL', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].PENY_ALL AS ph
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ AND ph.fin_id = o.fin_id
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id

			RAISERROR ('%i - PENY_DETAIL', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].PENY_DETAIL AS ph
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - PAYM_OCC_BUILD', 10, 1, @build_id) WITH NOWAIT;
			DELETE t
				FROM [dbo].PAYM_OCC_BUILD AS t
				JOIN dbo.OCCUPATIONS o
					ON o.occ = t.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - PAYM_ADD', 10, 1, @build_id) WITH NOWAIT;
			DELETE t
				FROM [dbo].PAYM_ADD AS t
				JOIN dbo.OCCUPATIONS o
					ON o.occ = t.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - ADDED_COUNTERS_ALL', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].ADDED_COUNTERS_ALL AS ph
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - [OCC_HISTORY]', 10, 1, @build_id) WITH NOWAIT;
			UPDATE oh SET 
				saldo=0,saldo_serv=0,Value=0,Discount=0,Compens=0,Added=0,PaymAccount=0,PaymAccount_peny=0,
				Paid=0,Paid_minus=0,Paid_old=0,Penalty_value=0,Penalty_old_new=0,Penalty_old=0,
				SaldoAll=0,Paymaccount_ServAll=0,PaidAll=0,AddedAll=0			
				FROM [dbo].[OCC_HISTORY] AS oh
				JOIN dbo.FLATS f
					ON oh.flat_id = f.id
			WHERE f.bldn_id = @build_id

		END
		--***************************************************************************
		IF @is_paying = 1
		BEGIN
			RAISERROR ('%i - Paying_cash', 10, 1, @build_id) WITH NOWAIT;
			DELETE ps
				FROM dbo.Paying_cash ps
				JOIN [dbo].Payings AS ph 
					ON ps.paying_id = ph.id
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;


			RAISERROR ('%i - PAYING_SERV', 10, 1, @build_id) WITH NOWAIT;
			DELETE ps
				FROM PAYING_SERV ps
				JOIN [dbo].PAYINGS AS ph
					ON ps.paying_id = ph.id
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - PAYINGS', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].PAYINGS AS ph
				JOIN OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - BANK_DBF', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].BANK_DBF AS ph
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

		END
		--***************************************************************************	
		IF @is_people = 1
		BEGIN
			RAISERROR ('%i - BUILDINGS_HISTORY', 10, 1, @build_id) WITH NOWAIT;
			DELETE t
				FROM [dbo].BUILDINGS_HISTORY AS t
				JOIN dbo.FLATS f
					ON t.bldn_id = f.bldn_id
				JOIN dbo.OCCUPATIONS o
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - PEOPLE_HISTORY', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].PEOPLE_HISTORY AS ph
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - PEOPLE_2', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].PEOPLE_2 AS ph
				JOIN dbo.PEOPLE p
					ON ph.owner_id = p.id
				JOIN dbo.OCCUPATIONS o
					ON p.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - PEOPLE', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].PEOPLE AS ph
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

		END
		--***************************************************************************
		IF @is_counter = 1
		BEGIN
			RAISERROR ('%i - COUNTER_LIST_ALL', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].COUNTER_LIST_ALL AS ph
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - COUNTER_PAYM_OCC', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].COUNTER_PAYM_OCC AS ph
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - COUNTER_PAYM2', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].COUNTER_PAYM2 AS ph
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - COUNTER_INSPECTOR', 10, 1, @build_id) WITH NOWAIT;
			DELETE ci
				FROM [dbo].BUILDINGS AS t
				JOIN dbo.COUNTERS c
					ON t.id = c.build_id
				JOIN dbo.COUNTER_INSPECTOR ci
					ON c.id = ci.counter_id
				JOIN dbo.FLATS f
					ON t.id = f.bldn_id
				JOIN dbo.OCCUPATIONS o
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - COUNTER_PAYM', 10, 1, @build_id) WITH NOWAIT;
			DELETE ci
				FROM [dbo].BUILDINGS AS t
				JOIN dbo.COUNTERS c
					ON t.id = c.build_id
				JOIN dbo.COUNTER_PAYM ci
					ON c.id = ci.counter_id
			WHERE t.id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - COUNTERS', 10, 1, @build_id) WITH NOWAIT;
			DELETE c
				FROM [dbo].BUILDINGS AS t
				JOIN dbo.COUNTERS c
					ON t.id = c.build_id
			WHERE t.id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

		END
		--***************************************************************************
		IF @is_occ_history = 1
		BEGIN
			RAISERROR ('%i - [OCC_HISTORY]', 10, 1, @build_id) WITH NOWAIT;
			DELETE oh
				FROM dbo.OCC_HISTORY AS oh
				JOIN dbo.FLATS f
					ON oh.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - [CONSMODES_HISTORY]', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].[CONSMODES_HISTORY] AS ph
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - [OCC_SUPPLIERS из истории]', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM dbo.OCC_SUPPLIERS AS ph
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			and ph.fin_id<o.fin_id  -- ранее текущего периода
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;
		END
		--***************************************************************************
		IF @is_occ = 1
		BEGIN
			RAISERROR ('%i - [OCC_SUPPLIERS]', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].[OCC_SUPPLIERS] AS ph
				JOIN OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - [CONSMODES_LIST]', 10, 1, @build_id) WITH NOWAIT;
			DELETE ph
				FROM [dbo].[CONSMODES_LIST] AS ph
				JOIN dbo.OCCUPATIONS o
					ON ph.occ = o.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - OP_LOG', 10, 1, @build_id) WITH NOWAIT;
			DELETE t
				FROM [dbo].OP_LOG AS t
				JOIN dbo.OCCUPATIONS o
					ON o.occ = t.occ
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - OCCUPATIONS', 10, 1, @build_id) WITH NOWAIT;
			DELETE o
				FROM dbo.OCCUPATIONS o
				JOIN dbo.FLATS f
					ON o.flat_id = f.id
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

		END
		--***************************************************************************
		IF @is_build = 1
		BEGIN
			RAISERROR ('%i - [BUILD_MODE]', 10, 1, @build_id) WITH NOWAIT;
			DELETE t
				FROM [dbo].[BUILD_MODE] AS t
			WHERE t.build_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - BUILD_SOURCE', 10, 1, @build_id) WITH NOWAIT;
			DELETE t
				FROM [dbo].BUILD_SOURCE AS t
			WHERE t.build_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - DOM_SVOD_ALL', 10, 1, @build_id) WITH NOWAIT;
			DELETE c
				FROM [dbo].BUILDINGS AS t
				JOIN dbo.DOM_SVOD_ALL c
					ON t.id = c.build_id
			WHERE t.id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - DOM_SVOD', 10, 1, @build_id) WITH NOWAIT;
			DELETE c
				FROM [dbo].BUILDINGS AS t
				JOIN dbo.DOM_SVOD c
					ON t.id = c.build_id
			WHERE t.id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - DOG_BUILD', 10, 1, @build_id) WITH NOWAIT;
			DELETE f
				FROM [dbo].BUILDINGS AS t
				JOIN dbo.DOG_BUILD f
					ON t.id = f.build_id
			WHERE t.id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - DOG_SUP', 10, 1, @build_id) WITH NOWAIT;
			DELETE t
				FROM dbo.DOG_SUP t
			WHERE t.tip_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - ROOMS', 10, 1, @build_id) WITH NOWAIT;
			DELETE r
				FROM dbo.ROOMS r 
				JOIN dbo.Flats f 
            		ON r.flat_id = f.id          
			WHERE f.bldn_id = @build_id
			SET @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 10, 1, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - FLATS', 10, 1, @build_id) WITH NOWAIT;
			DELETE f
				FROM dbo.FLATS f
			WHERE f.bldn_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - Suppliers_build_history', 10, 1, @build_id) WITH NOWAIT;
			DELETE t
				FROM dbo.Suppliers_build_history t
			WHERE t.build_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;
			
			RAISERROR ('%i - Suppliers_build', 10, 1, @build_id) WITH NOWAIT;
			DELETE t
				FROM dbo.Suppliers_build t
			WHERE t.build_id = @build_id
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - BUILDINGS', 10, 1, @build_id) WITH NOWAIT;
			BEGIN TRANSACTION
			DELETE t
				FROM [dbo].BUILDINGS AS t
			WHERE t.id = @build_id
			SELECT @RowsDeleted = @@rowcount
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

		END
		
		CHECKPOINT;

		FETCH NEXT FROM cur INTO @build_id

	END

	CLOSE cur
	DEALLOCATE cur
	RAISERROR ('Обработка выполнена', 10, 1) WITH NOWAIT;
END
go

el, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - ROOMS', 0, 1, @build_id) WITH NOWAIT;
			DELETE r
				FROM dbo.ROOMS r 
				JOIN dbo.Flats f 
            		ON r.flat_id = f.id          
			WHERE f.bldn_id = @build_id
			AND (@fin_id1=0)
			
			SET @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - FLATS', 0, 1, @build_id) WITH NOWAIT;
			DELETE f
				FROM dbo.FLATS f
			WHERE f.bldn_id = @build_id
			AND (@fin_id1=0)
			
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - Suppliers_build_history', 0, 1, @build_id) WITH NOWAIT;
			DELETE t
				FROM dbo.Suppliers_build_history t
			WHERE t.build_id = @build_id
			AND (@fin_id1=0 or t.fin_id=@fin_id1)
			
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;
			
			RAISERROR ('%i - Suppliers_build', 0, 1, @build_id) WITH NOWAIT;
			DELETE t
				FROM dbo.Suppliers_build t
			WHERE t.build_id = @build_id
			AND (@fin_id1=0)
			
			SELECT @RowsDeleted = @@rowcount
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

			RAISERROR ('%i - BUILDINGS', 0, 1, @build_id) WITH NOWAIT;
			BEGIN TRANSACTION
			DELETE t
				FROM dbo.BUILDINGS AS t
			WHERE t.id = @build_id
			AND (@fin_id1=0)
			
			SELECT @RowsDeleted = @@rowcount
			COMMIT TRANSACTION
			CHECKPOINT
			RAISERROR (@msg_del, 0, 1, @RowsDeleted) WITH NOWAIT;

		END
		
		CHECKPOINT;

		FETCH NEXT FROM cur INTO @build_id

	END

	CLOSE cur
	DEALLOCATE cur
	RAISERROR (N'Обработка выполнена', 10, 1) WITH NOWAIT;
END
go

