-- =============================================
-- Author:		Пузанов
-- Create date: 19.09.2016
-- Description:	Изменение поставщика у перерасчёта
-- =============================================
CREATE   PROCEDURE [dbo].[ka_change_sup_id]
	@id				INT -- код разового
	,@sup_id_new	INT -- код нового поставщика
	,@ZapUpdate		INT	=0 OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE ap 
	SET ap.sup_id = @sup_id_new
	FROM [dbo].[ADDED_PAYMENTS] AS ap
	WHERE ap.id = @id
	SELECT
		@ZapUpdate = @@rowcount

END
go

