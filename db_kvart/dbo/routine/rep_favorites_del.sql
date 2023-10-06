-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[rep_favorites_del]
(
	  @id1 INT
)
AS
BEGIN
	SET NOCOUNT ON;

	DELETE FROM dbo.Reports_favorites
	WHERE id = @id1
END
go

