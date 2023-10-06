-- =============================================
-- Author:		Пузанов М.А.
-- Create date: 17.01.07
-- Description:	Импорт субсидий из внешней программы
-- =============================================
CREATE       PROCEDURE [dbo].[k_komp_insert]
	@occ1			INT
	,@dateRaschet	SMALLDATETIME
	,@dateNazn		SMALLDATETIME
	,@dateEnd		SMALLDATETIME
	,@sumkomp		DECIMAL(9, 2)	= 0
	,@sumkomp_noext	DECIMAL(9, 2)	= 0
	,@sumkvart		DECIMAL(9, 2)	= 0
	,@sumnorm		DECIMAL(9, 2)	= 0
	,@doxod			DECIMAL(9, 2)	= 0
	,@metod			SMALLINT		= 0
	,@kol_people	SMALLINT		= 0
	,@realy_people	SMALLINT		= 0
	,@transfer_bank	BIT				= 0
	,@owner_id		INT				= NULL
	,@comments		VARCHAR(30)		= NULL
	,@sum_pm		DECIMAL(9, 2)	= 0
	,@Str_serv_sum	VARCHAR(2000)	= NULL
	,@count_add		SMALLINT		= 0 OUTPUT  -- Если 1 то добавили запись
AS
BEGIN

	SET NOCOUNT ON;

	SELECT
		@count_add = 0

	DECLARE @ExtSubsidia BIT = 0
	SELECT TOP 1
		@ExtSubsidia = ExtSubsidia
	FROM dbo.GLOBAL_VALUES
	ORDER BY fin_id DESC -- последний фин период

	IF @ExtSubsidia = 0
	BEGIN
		PRINT 'Субсидии расчитываються в программе расчета квартплаты'
		-- импорт отменен
		RETURN @count_add
	END

	IF NOT EXISTS (SELECT
				1
			FROM dbo.OCCUPATIONS
			WHERE occ = @occ1)
	BEGIN
		PRINT 'Лицевой счет не найден'
		-- импорт отменен
		RETURN @count_add
	END

	DECLARE @finperiod SMALLINT
	SELECT
		@finperiod = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

BEGIN TRY

	IF EXISTS (SELECT
				*
			FROM dbo.COMPENSAC_ALL
			WHERE occ = @occ1
			AND fin_id = @finperiod)
	BEGIN
		--print 'Обновляем субсидию'
		UPDATE [dbo].[COMPENSAC_ALL]
		SET	[dateRaschet]		= @dateRaschet
			,[dateNazn]			= @dateNazn
			,[DateEnd]			= @dateEnd
			,[sumkomp]			= @sumkomp
			,[sumkomp_noext]	= @sumkomp_noext
			,[sumkvart]			= @sumkvart
			,[sumnorm]			= @sumnorm
			,[Doxod]			= @doxod
			,[metod]			= @metod
			,[kol_people]		= @kol_people
			,[realy_people]		= @realy_people
			,[KOEF]				= 0
			,[avto]				= 0
			,[FinPeriod]		= @finperiod
			,[transfer_bank]	= @transfer_bank
			,[owner_id]			= @owner_id
			,[comments]			= @comments
			,[sum_pm]			= @sum_pm
		WHERE occ = @occ1
		AND fin_id = @finperiod
	END
	ELSE
	BEGIN
		--print 'Добавляем субсидию'
		INSERT
		INTO [dbo].[COMPENSAC_ALL]
		(	fin_id
			,[occ]
			,[dateRaschet]
			,[dateNazn]
			,[DateEnd]
			,[sumkomp]
			,[sumkomp_noext]
			,[sumkvart]
			,[sumnorm]
			,[Doxod]
			,[metod]
			,[kol_people]
			,[realy_people]
			,[KOEF]
			,[avto]
			,[FinPeriod]
			,[transfer_bank]
			,[owner_id]
			,[comments]
			,[sum_pm])
		VALUES (@finperiod, @occ1, @dateRaschet, @dateNazn, @dateEnd, @sumkomp, @sumkomp_noext, @sumkvart, @sumnorm, @doxod, @metod, @kol_people, @realy_people, 0, 0, @finperiod, @transfer_bank, @owner_id, @comments, @sum_pm)
	END

	SELECT
		@count_add = 1

	DELETE FROM dbo.COMP_SERV_ALL
	WHERE occ = @occ1
		AND fin_id = @finperiod

	-- Таблица с новыми значениями 
	DECLARE @t1 TABLE
		(
			service_id	VARCHAR(10)
			,sum1		DECIMAL(9, 2)
		)

	INSERT
	INTO @t1
		SELECT
			pole1
			,pole2
		FROM dbo.Fun_charlist_to_table(@Str_serv_sum, ';')

	-- Проверяем все ли правильные услуги(есть код в SERVICES)
	IF EXISTS (SELECT
				*
			FROM @t1
			WHERE service_id NOT IN (SELECT
					id
				FROM dbo.View_SERVICES))
	BEGIN
		RAISERROR ('Ошибка в формирование строки услуг для субсидий!', 16, 1)
		RETURN 1
	END


	INSERT
	INTO dbo.COMP_SERV_ALL
	(	fin_id
		,occ
		,service_id
		,tarif
		,value_socn
		,value_paid
		,value_subs)
		SELECT
			@finperiod
			,@occ1
			,service_id
			,0
			,0
			,0
			,sum1
		FROM @t1
		WHERE sum1 <> 0

	RETURN @count_add

END TRY
BEGIN CATCH
	EXEC dbo.k_err_messages
END CATCH

END
go

