CREATE   PROCEDURE [dbo].[ka_del_added_type]
(
	@occ1		INT
	,@add_type1	SMALLINT
)
AS
	--
	--   Удаление разовых по лицевому и типу 
	--
	/*
	Проверяем в 2 таблицах 
	added_payments
	added_COUNTERS_all
	*/

	IF dbo.Fun_AccessAddLic(@occ1) = 0
	BEGIN
		RAISERROR ('Для Вас работа с Разовыми запрещена', 16, 1)
		RETURN
	END
	IF dbo.Fun_GetRejimOcc(@occ1) <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	SET NOCOUNT ON

	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = [dbo].[Fun_GetFinCurrent](NULL, NULL, NULL, @occ1)

	-- Удаляем разовый из added_payments
	DELETE FROM dbo.ADDED_PAYMENTS 
	WHERE occ = @occ1
		AND add_type = @add_type1



	-- Изменить значения в таблице paym_list
	UPDATE pl 
	SET added = coalesce((SELECT
			SUM(value)
		FROM dbo.ADDED_PAYMENTS ap
		WHERE ap.occ = @occ1
		AND ap.service_id = pl.service_id
		AND ap.sup_id = pl.sup_id)
	, 0)
	FROM dbo.PAYM_LIST AS pl
	WHERE occ = @occ1


	-- Удаляем разовый из added_COUNTERS_ALL
	DELETE FROM dbo.ADDED_COUNTERS_ALL 
	WHERE occ = @occ1
		AND add_type = @add_type1
		AND fin_id = @fin_current

	-- Изменить значения в таблице paym_COUNTER
	UPDATE pl 
	SET added = coalesce((SELECT
			SUM(ac.value)
		FROM dbo.ADDED_COUNTERS_ALL AS ac
		WHERE ac.occ = @occ1
		AND ac.service_id = pl.service_id
		AND ac.fin_id = @fin_current)
	, 0)
	FROM dbo.PAYM_COUNTER_ALL AS pl
	WHERE occ = @occ1
	AND fin_id = @fin_current


	-- сохраняем в историю изменений
	EXEC k_write_log	@occ1
						,'раз!'
go

