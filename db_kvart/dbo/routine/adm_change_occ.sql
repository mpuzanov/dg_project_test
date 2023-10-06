CREATE   PROCEDURE [dbo].[adm_change_occ]
/*
 Процедура смены единых лицевых счетов

 declare @Result BIT
 exec adm_change_occ @occ1=888100,@occ_new=888001, @Result=@Result OUT, @debug=1
 print @Result

*/
(
	@occ1		INT
	,@occ_new	INT	= NULL OUTPUT
	,@Result	BIT	= 0 OUTPUT
	,@debug		BIT	= 0
)
AS
	SET NOCOUNT ON
	SET XACT_ABORT ON

	SET @Result = 0

	IF @occ_new = 0
		SET @occ_new = NULL

	DECLARE	@user_id1		SMALLINT
			,@msg			VARCHAR(100)
			,@str_occ_new	VARCHAR(9)
			,@str_occ		VARCHAR(9)
			,@table_name	VARCHAR(100)
			,@str_update	VARCHAR(200)
			,@tip_id1		SMALLINT -- тип жилого фонда
			,@err_str		VARCHAR(400)
			,@rang_max		INT	= 0

	IF NOT EXISTS (SELECT
				1
			FROM dbo.OCCUPATIONS AS o 
			WHERE occ = @occ1)
	BEGIN
		RAISERROR ('Лицевой счёт %i не найден!', 16, 1, @occ1);
		RETURN -1
	END

	SELECT
		@tip_id1 = o.tip_id
	FROM dbo.OCCUPATIONS AS o 
	WHERE occ = @occ1;

	IF @occ_new IS NULL
	BEGIN
		-- Создаем единый код лицевого счета автоматически
		EXEC dbo.k_occ_new	@tip_id1
							,@occ_new = @occ_new OUTPUT
							,@rang_max = @rang_max OUTPUT

		IF (@occ_new IS NULL)
			OR @occ_new = 0
		BEGIN
			ROLLBACK TRAN

			SET @err_str = 'Не удалось создать лицевой счёт! в типе фонда %s.' + CHAR(13)

			IF @rang_max = 0
				SET @err_str = @err_str + 'Закончился диапазон чисел для него!'
			RAISERROR (@err_str, 16, 1, @tip_id1)
			RETURN -1
		END

	END

	IF EXISTS (SELECT
				1
			FROM dbo.OCCUPATIONS AS o 
			WHERE occ = @occ_new)
	BEGIN
		RAISERROR ('Лицевой счёт %i уже есть в базе!', 16, 1, @occ_new);
		RETURN -1
	END

	IF @occ1 = @occ_new
	BEGIN
		RAISERROR ('Лицевые счета совпадают!', 16, 1, @occ_new);
		RETURN -1
	END

	--SELECT STR(@occ_new,9),STR(@occ1,6)
	SELECT
		@str_occ_new = STR(@occ_new, 9)
		,@str_occ = STR(@occ1, 9)

	BEGIN TRAN

		if @debug=1  PRINT 'отключение ограничений'

		ALTER TABLE dbo.OCC_SUPPLIERS NOCHECK CONSTRAINT FK_OCC_SUPPLIERS_OCCUPATIONS
		ALTER TABLE dbo.COUNTER_LIST_ALL NOCHECK CONSTRAINT FK_COUNTER_LIST_ALL_OCCUPATIONS
		ALTER TABLE dbo.COMP_SERV_ALL NOCHECK CONSTRAINT FK_COMP_SERV_ALL_COMPENSAC_ALL
		if @debug=1  PRINT 'отключили'

		UPDATE dbo.OCCUPATIONS WITH (ROWLOCK)
		SET occ = @occ_new
		WHERE occ = @occ1

		if @debug=1  PRINT 'в OCCUPATIONS изменили'
		--****************************************************
		if @debug=1  PRINT 'переименование во всех таблицах где встречается поле OCC'
		DECLARE curs CURSOR LOCAL FOR
			SELECT
				a.name
			FROM sys.tables a 
			INNER JOIN sys.syscolumns b
				ON a.object_id = b.id
			WHERE b.name = 'occ'
			AND a.type = 'U'
			AND a.is_memory_optimized=0
			ORDER BY a.name
		OPEN curs
		FETCH NEXT FROM curs INTO @table_name

		WHILE (@@fetch_status = 0)
		BEGIN
			SET @str_update = CONCAT(
			'UPDATE t SET occ=',@str_occ_new,' FROM ',@table_name,' as t WHERE occ=',@str_occ,
			' AND NOT EXISTS(SELECT occ FROM ',@table_name,' WHERE occ=',@str_occ_new,')') 			
			IF @debug = 1
				RAISERROR (@str_update, 10, 1) WITH NOWAIT;

			EXECUTE (@str_update)

			FETCH NEXT FROM curs INTO @table_name
		END

		CLOSE curs
		DEALLOCATE curs

		if @debug=1  PRINT 'включение ограничений'

		ALTER TABLE dbo.OCC_SUPPLIERS CHECK CONSTRAINT FK_OCC_SUPPLIERS_OCCUPATIONS
		ALTER TABLE dbo.COUNTER_LIST_ALL CHECK CONSTRAINT FK_COUNTER_LIST_ALL_OCCUPATIONS
		ALTER TABLE dbo.COMP_SERV_ALL CHECK CONSTRAINT FK_COMP_SERV_ALL_COMPENSAC_ALL

	COMMIT TRAN


	SELECT
		@user_id1 = dbo.Fun_GetCurrentUserId()
	
	if @debug=1  PRINT 'сохраняем в историю изменений'
	INSERT INTO IZMLIC
	(	datizm
		,jeu1
		,schtl1
		,jeu2
		,schtl2
		,user_id)
	VALUES (current_timestamp
			,0
			,@occ1
			,0
			,@occ_new
			,@user_id1)

	IF @@error != 0
	BEGIN
		ROLLBACK TRAN
		RAISERROR ('Ошибка сохранения истории изменения ', 16, 1)
		RETURN 1
	END

	-- сохраняем в историю изменений
	SET @msg = 'Прежний л/сч: ' + @str_occ
	EXEC k_write_log	@occ1 = @occ_new
						,@oper1 = 'рдлс'
						,@comments1 = @msg

	SET @Result = 1 -- Изменения успешно сделаны
go

