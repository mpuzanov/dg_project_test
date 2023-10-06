-- =============================================
-- Author:		Пузанов
-- Create date: 26.03.2014
-- Description:	Изменение услуги у перерасчёта
-- =============================================
CREATE       PROCEDURE [dbo].[ka_change_service]
	@id				INT -- код разового
	,@service_new	VARCHAR(10) -- код новой услуги
	,@ZapUpdate		INT	=0 OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE ap 
	SET ap.service_id = @service_new
	FROM dbo.Added_payments AS ap
	WHERE ap.id = @id
	SELECT
		@ZapUpdate = @@rowcount

END
go

