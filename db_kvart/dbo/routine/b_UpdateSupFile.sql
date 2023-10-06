-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[b_UpdateSupFile]
(
	@filedbf_id INT
)
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE b 
	SET	sup_id		= dbo.Fun_GetSUPFromSchetl(SCH_LIC)
		,dog_int	= dbo.Fun_GetDOGFromSchetl(SCH_LIC)
	FROM dbo.BANK_DBF AS b
	WHERE b.filedbf_id = @filedbf_id
	AND SCH_LIC BETWEEN 1 AND 999999999 -- до 9 знаков
END
go

