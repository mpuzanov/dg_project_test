CREATE   PROCEDURE [dbo].[k_counter_fin_edit]
(
	  @id1 INT -- код изменяемого показателя
	, @fin_new SMALLINT -- новое значение
	, @fin_old SMALLINT = NULL
)
AS
	/*
-- Изменение фин. периода по показанию счетчика
--

27/02/14
*/
	SET NOCOUNT ON

	IF dbo.Fun_GetRejim() <> N'норм'
	BEGIN
		RAISERROR (N'База закрыта для редактирования!', 16, 1)
	END

	DECLARE @Str1 VARCHAR(100)
		  , @user_edit SMALLINT
		  , @date1 SMALLDATETIME
		  , @inspector_date1 SMALLDATETIME
		  , @err INT
		  , @fin_old_ci SMALLINT
		  , @fin_current SMALLINT
		  , @res INT
		  , @counter_id1 INT
		  , @tip_value1 TINYINT
		  , @service_id VARCHAR(10)
		  , @internal BIT
		  , @flat_id1 INT
		  , @build_id1 INT

	SELECT @date1 = dbo.Fun_GetOnlyDate(current_timestamp)
	SELECT @user_edit = dbo.Fun_GetCurrentUserId()

	SELECT @fin_old_ci = COALESCE(ci.fin_id, 0)
		 , @inspector_date1 = inspector_date
		 , @counter_id1 = ci.counter_id
		 , @tip_value1 = ci.tip_value
		 , @service_id = service_id
		 , @internal = c.internal
		 , @flat_id1 = c.flat_id
		 , @build_id1 = c.build_id
	FROM dbo.Counter_inspector AS ci
		JOIN dbo.Counters AS c ON ci.counter_id = c.id
	WHERE ci.id = @id1

	IF dbo.Fun_AccessCounterLic(@build_id1) = 0
	BEGIN
		RAISERROR (N'Для Вас работа со счетчиками запрещена!', 16, 1)
	END

	SELECT @fin_current = dbo.Fun_GetFinCurrent(NULL, @build_id1, NULL, NULL)

	IF @fin_old IS NULL
		SET @fin_old = @fin_old_ci

	IF @fin_new = @fin_old
		OR @fin_new > @fin_current
		RETURN

-- 	IF @fin_old - @fin_new > 1
-- 	BEGIN
-- 		RAISERROR (N'Нельзя менять период больше чем на 1!', 16, 1)
-- 	END

	IF @fin_old = @fin_old_ci
		UPDATE ci
		SET fin_id = @fin_new
		  , date_edit = @date1
		  , user_edit = @user_edit
		FROM dbo.Counter_inspector AS ci
		WHERE ci.id = @id1
			AND ci.fin_id = @fin_old
	ELSE
		RETURN

	-- Делаем перерасчет по счётчикам
	IF @internal = 0
		EXEC dbo.k_counter_raschet_flats @flat_id1 = @flat_id1
									   , @tip_value1 = @tip_value1
									   , @debug = 0
	ELSE
		EXEC dbo.k_counter_raschet_flats2 @flat_id1 = @flat_id1
										, @tip_value1 = 1
										, @debug = 0

	-- делаем расчёт квартплаты в квартире
	EXEC k_raschet_flat @flat_id1

	-- сохраняем в историю изменений
	SET @Str1 = N'Стар.знач фин.периода: ' + dbo.Fun_NameFinPeriod(@fin_old) + ' -> ' + dbo.Fun_NameFinPeriod(@fin_new) +
	N' Дата показания: ' + CONVERT(VARCHAR(15), @inspector_date1, 103)
	EXEC k_counter_write_log @counter_id1 = @counter_id1
						   , @oper1 = N'счре'
						   , @comments1 = @Str1
go

