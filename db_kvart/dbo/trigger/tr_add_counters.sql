-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     TRIGGER [dbo].[tr_add_counters]
ON [dbo].[Counters]
FOR INSERT
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (SELECT
				1
			FROM dbo.Counters AS t
			JOIN INSERTED AS I	ON 
				t.flat_id = I.flat_id
			WHERE 
				t.date_del IS NULL
				AND t.serial_number=i.serial_number
				AND t.id<>i.id
			)
	BEGIN
		DECLARE @address VARCHAR(60), @serial_number VARCHAR(20)
		
		SELECT TOP (1)
			@address = dbo.Fun_GetAdresFlat(t.flat_id)
			, @serial_number = t.serial_number
		FROM dbo.Counters AS t
		JOIN INSERTED AS I	ON 
			t.flat_id = I.flat_id			
		WHERE 
			t.date_del IS NULL
			AND t.serial_number=i.serial_number
			AND t.id<>i.id

		RAISERROR ('Обнаружено несколько одинаковых серийных номеров ИПУ в помещении %s (%s)! Исправьте.', 16, 10, @address, @serial_number)
		ROLLBACK TRANSACTION
		RETURN
	END

	UPDATE t
	SET date_edit = dbo.Fun_GetOnlyDate(current_timestamp)
	, counter_uid = CASE WHEN i.counter_uid IS NULL THEN dbo.fn_newid() ELSE i.counter_uid END
	FROM dbo.Counters AS t
	JOIN INSERTED AS i ON 
		t.id = i.id

END
go

