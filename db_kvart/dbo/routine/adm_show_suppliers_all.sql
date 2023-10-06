-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[adm_show_suppliers_all]
AS
BEGIN
	SET NOCOUNT ON;
	SELECT * FROM dbo.View_SUPPLIERS_ALL
END
go

