-- =============================================
-- Author:		Пузанов
-- Create date: 02.06.2021
-- Description:	Изменение суммы или кол-ва у перерасчёта
-- =============================================
CREATE       PROCEDURE [dbo].[ka_change_value]
	  @id INT -- код разового
	, @value DECIMAL(9, 2) = NULL -- новая сумма разового
	, @kol_new DECIMAL(9, 4) = NULL -- новое кол-во разового
	, @ZapUpdate INT = 0 OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	IF @value IS NULL
		AND @kol_new IS NULL
		RETURN

	UPDATE ap 
	SET ap.Value = COALESCE(@value, ap.Value)
	  , ap.kol = COALESCE(@kol_new, ap.kol)
	  , user_edit = dbo.Fun_GetCurrentUserId()
	  , date_edit = current_timestamp
	FROM dbo.Added_Payments AS ap
	WHERE ap.id = @id
	SELECT @ZapUpdate = @@rowcount

END
go

