CREATE   PROCEDURE [dbo].[ka_repeat_cancel]
(
	@added_id1 INT
)
AS
	/*
	
	отмена повтора разового
	
	*/

	SET NOCOUNT ON

	DECLARE @occ1 INT

	SELECT
		@occ1 = occ
	FROM dbo.ADDED_PAYMENTS 
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

	UPDATE dbo.ADDED_PAYMENTS 
	SET repeat_for_fin = NULL
	WHERE id = @added_id1

	-- сохраняем в историю изменений
	EXEC k_write_log	@occ1
						,'раз!'
						,'отмена повтора разового'
go

