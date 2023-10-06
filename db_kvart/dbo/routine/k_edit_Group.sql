-- =============================================
-- Author:		Антропов
-- Create date: <Create Date,,>
-- Description:	программа ДПринт
-- =============================================
CREATE PROCEDURE [dbo].[k_edit_Group]
	@id INT
AS
BEGIN

	SET NOCOUNT ON;

	DELETE dbo.PRINT_GROUP
	WHERE id = @id

	DELETE dbo.PRINT_OCC
	WHERE group_id = @id
END
go

