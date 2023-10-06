-- =============================================
-- Author:		Пузанов
-- Create date: 31.08.2015
-- Description:	Изменение типа у перерасчёта
-- =============================================
CREATE   PROCEDURE [dbo].[ka_change_addtype]
	@id				INT -- код разового
	,@add_type_new	INT -- код нового типа перерасчёта
	,@ZapUpdate		INT	=0 OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE ap 
	SET ap.add_type = @add_type_new
	FROM [dbo].[ADDED_PAYMENTS] AS ap
	WHERE ap.id = @id
	SELECT
		@ZapUpdate = @@rowcount

END
go

