-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[ka_change_repeat_for_fin]
( @id int
 ,@repeat_for_fin	SMALLINT		= NULL-- повтор перерасчета по заданные период
 ,@ZapUpdate		INT	= 0 OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE ap 
	SET ap.repeat_for_fin = @repeat_for_fin
	FROM Added_Payments AS ap
	WHERE ap.id = @id
	SELECT
		@ZapUpdate = @@rowcount

END
go

