CREATE   PROCEDURE [dbo].[k_counter_del_cancel]
(
	@id1 INT -- код счетчика
)
AS
	--
	--  Отмена Удаления счетчика
	--
	SET NOCOUNT ON

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	DECLARE	@occ1			INT
			,@service_id1	VARCHAR(10)
			,@build_id1		INT
			,@err			INT
			,@serial_number1	VARCHAR(10)
			,@str1			VARCHAR(100)
			,@Date_Del1		SMALLDATETIME
			,@internal		BIT
			,@flat_id1		INT

	SELECT
		@service_id1 = C.service_id
		,@serial_number1 = C.serial_number
		,@build_id1 = C.build_id
		,@Date_Del1 = C.date_del
		,@internal = C.internal
		,@flat_id1 = C.flat_id
	FROM dbo.COUNTERS AS C
	WHERE id = @id1

	IF dbo.Fun_AccessCounterLic(@build_id1) = 0
	BEGIN
		RAISERROR ('Для Вас работа со счетчиками запрещена!', 16, 1)
		RETURN
	END

	BEGIN TRAN

		-- Ищем показание инспектора с датой закрытия данного счетчика
		UPDATE dbo.COUNTER_INSPECTOR
		SET blocked = 0
		WHERE counter_id = @id1
		AND inspector_date = @Date_Del1

		UPDATE dbo.COUNTERS 
		SET	date_del		= NULL
			,CountValue_del	= 0
			,ReasonDel = NULL
		WHERE id = @id1

		-- добавляем лицевые из этой квартиры
		INSERT
		INTO dbo.COUNTER_LIST_ALL
		(	counter_id
			,Occ
			,service_id
			,occ_counter
			,internal
			,fin_id)
			SELECT
				@id1
				,Occ
				,@service_id1
				,dbo.Fun_GetService_Occ(Occ, @service_id1)
				,@internal
				,O.fin_id
			FROM dbo.OCCUPATIONS AS o 
			WHERE o.flat_id = @flat_id1
			AND o.STATUS_ID <> 'закр'
			AND NOT EXISTS (SELECT
					1
				FROM COUNTER_LIST_ALL cla 
				WHERE cla.counter_id = @id1
				AND cla.Occ = o.Occ
				AND cla.fin_id = O.fin_id)

	COMMIT TRAN

	-- сохраняем в историю изменений
	SET @str1 = 'Отмена удаления счетчика: ' + @serial_number1
	EXEC k_counter_write_log	@id1
								,'счре'
								,@str1
go

