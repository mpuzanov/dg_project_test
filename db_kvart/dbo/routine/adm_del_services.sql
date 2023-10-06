CREATE   PROCEDURE [dbo].[adm_del_services]
(
	@id1   VARCHAR(10)
   ,@debug BIT = 0
--
)
AS
	/*
	Удаление услуги
		
		
	14.02.2005
	Пузанов М.А.
		
	dbo.adm_del_services 'ремт'
	*/
	SET NOCOUNT ON

	SELECT
		@id1 = LTRIM(RTRIM(@id1))

	IF EXISTS (SELECT 1
			FROM dbo.Paym_history
			WHERE service_id = @id1)
	BEGIN
		RAISERROR ('Удалить услугу НЕЛЬЗЯ она есть в истории', 16, 1)
		RETURN
	END

	DECLARE @err INT

BEGIN TRY

	BEGIN TRAN

		IF @debug = 1
			PRINT 'Удаляем услугу на лицевых счетах'

		DELETE FROM dbo.Consmodes_list
		WHERE service_id = @id1


		IF @debug = 1
			PRINT 'Удаляем услугу на начислениях'

		DELETE FROM dbo.Paym_list
		WHERE service_id = @id1


		IF @debug = 1
			PRINT 'Удаляем услугу на нормах по услуге'

		DELETE FROM dbo.Service_units
		WHERE service_id = @id1


		IF @debug = 1
			PRINT 'Удаляем Режим потребления в домах'

		DELETE FROM dbo.Build_mode
		WHERE service_id = @id1

		IF @debug = 1
			PRINT 'Удаляем Поставщиков в домах'

		DELETE FROM dbo.Build_source
		WHERE service_id = @id1

		IF @debug = 1
			PRINT 'Удаляем Режимы потребления по услуге'

		DELETE FROM dbo.Cons_modes
		WHERE service_id = @id1

		IF @debug = 1
			PRINT 'Удаляем Поставщиков по услуге'

		DELETE FROM dbo.Suppliers
		WHERE service_id = @id1

		IF @debug = 1
			PRINT 'Удаляем нормы по услуге'

		DELETE FROM dbo.Measurement_units
		WHERE NOT EXISTS (SELECT
					id
				FROM dbo.Cons_modes
				WHERE id = mode_id)

		IF @debug = 1
			PRINT 'Удаляем льготы по услуге'

		DELETE FROM dbo.Discounts
		WHERE service_id = @id1
		
		IF @debug = 1
			PRINT 'Удаляем услугу'

		DELETE FROM dbo.services WITH (ROWLOCK)
		WHERE id = @id1
		
		IF @debug = 1
			PRINT 'Услуга удалена!'

	COMMIT TRAN

END TRY
BEGIN CATCH
	EXEC dbo.k_err_messages
END CATCH
go

