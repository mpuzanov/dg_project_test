CREATE   PROCEDURE [dbo].[ka_del_added]
(
	@added_id1 INT
)
AS
	/*
	Удаление разового


	Проверяем в 2 таблицах 
	added_payments
	added_COUNTERS_ALL
	*/

	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE @fin_current SMALLINT
	DECLARE @occ1 INT

	SELECT
		@occ1 = occ
	FROM dbo.ADDED_PAYMENTS
	WHERE id = @added_id1

	IF @occ1 IS NULL
		SELECT
			@occ1 = occ
		FROM dbo.ADDED_COUNTERS_ALL
		WHERE id = @added_id1

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

	SELECT
		@fin_current = [dbo].[Fun_GetFinCurrent](NULL, NULL, NULL, @occ1)

	BEGIN TRAN

		-- Удаляем разовый из added_payments
		DELETE FROM dbo.ADDED_PAYMENTS 
		WHERE id = @added_id1

		-- Изменить значения в таблице paym_list
		UPDATE pl WITH (ROWLOCK)
		SET added = COALESCE((SELECT
				SUM(value)
			FROM dbo.ADDED_PAYMENTS AS ap
			WHERE ap.occ = @occ1
			AND ap.service_id = pl.service_id
			AND ap.sup_id=pl.sup_id)
		, 0)
		FROM dbo.PAYM_LIST AS pl
		WHERE occ = @occ1

		-- Удаляем разовый из added_COUNTERS_ALL
		DELETE FROM dbo.ADDED_COUNTERS_ALL 
		WHERE id = @added_id1

		-- Изменить значения в таблице paym_list
		UPDATE pl 
		SET added = COALESCE((SELECT
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

	COMMIT TRAN
go

