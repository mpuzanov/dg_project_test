CREATE   PROCEDURE [dbo].[k_counter_mode_edit]
(
	@id1		INT -- код изменяемого показателя
	,@mode_new	INT -- новое значение
	,@mode_old	INT	= NULL
)
AS
	/*
-- Изменение режима по счетчику
--

03/06/13
*/
	SET NOCOUNT ON

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	DECLARE	@Str1				VARCHAR(100)
			,@user_edit			SMALLINT
			,@date1				SMALLDATETIME
			,@inspector_date1	SMALLDATETIME
			,@err				INT
			,@mode_old_ci		INT
			,@res				INT
			,@counter_id1		INT
			,@tip_value1		TINYINT
			,@service_id		VARCHAR(10)
			,@internal			BIT
			,@flat_id1			INT
			,@build_id1			INT

	SELECT
		@date1 = dbo.Fun_GetOnlyDate(current_timestamp)
	SELECT
		@user_edit = dbo.Fun_GetCurrentUserId()


	SELECT
		@mode_old_ci = COALESCE(ci.mode_id, 0)
		,@inspector_date1 = inspector_date
		,@counter_id1 = ci.counter_id
		,@tip_value1 = ci.tip_value
		,@service_id = service_id
		,@internal = c.internal
		,@flat_id1 = c.flat_id
		,@build_id1 = c.build_id
	FROM dbo.COUNTER_INSPECTOR AS ci
	JOIN dbo.COUNTERS AS c
		ON ci.counter_id = c.id
	WHERE ci.id = @id1

	IF dbo.Fun_AccessCounterLic(@build_id1) = 0
	BEGIN
		RAISERROR ('Для Вас работа со счетчиками запрещена!', 16, 1)
		RETURN
	END

	IF @mode_old IS NULL
		SET @mode_old = @mode_old_ci
		
	IF @mode_new IS NULL
		SET @mode_new = 0	
		
	IF @mode_old = @mode_old_ci
		UPDATE ci
		SET	mode_id		= @mode_new
			,date_edit	= @date1
			,user_edit	= @user_edit
		FROM dbo.COUNTER_INSPECTOR AS ci
		WHERE ci.id = @id1
		AND ci.mode_id = @mode_old
	ELSE
		RETURN

	-- Делаем перерасчет по счётчикам
	IF @internal = 0
		EXEC dbo.k_counter_raschet_flats	@flat_id1 = @flat_id1
											,@tip_value1 = @tip_value1
											,@debug = 0
	ELSE
		EXEC dbo.k_counter_raschet_flats2	@flat_id1 = @flat_id1
											,@tip_value1 = 1
											,@debug = 0

	-- делаем расчёт квартплаты в квартире
	EXEC k_raschet_flat @flat_id1

	-- сохраняем в историю изменений
	SET @Str1 = 'Стар.знач: ' + LTRIM(STR(@mode_old)) + '.Дата показания:' + CONVERT(VARCHAR(10), @inspector_date1, 104)
	EXEC k_counter_write_log	@counter_id1
								,'счре'
								,@Str1
go

