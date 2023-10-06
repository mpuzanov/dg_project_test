-- =============================================
-- Author:		Пузанов
-- Create date: 29.03.2022
-- Description:	смена знака у перерасчёта
-- =============================================
CREATE     PROCEDURE [dbo].[ka_change_sign]
	@id				INT -- код разового
	,@ZapUpdate		INT	=0 OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE ap 
	SET ap.value = -1*ap.value
	FROM dbo.Added_payments AS ap
	WHERE ap.id = @id
	SELECT
		@ZapUpdate = @@rowcount

END
go

