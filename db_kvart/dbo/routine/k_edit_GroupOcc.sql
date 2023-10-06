-- =============================================
-- Author:		Антропов
-- Create date: <Create Date,,>
-- Description:	программа ДПринт
-- =============================================
CREATE PROCEDURE [dbo].[k_edit_GroupOcc]
	(@occ  int
	,@group_id int)
AS
BEGIN
	
	SET NOCOUNT ON;

delete	Print_occ 
where	occ=@occ
		and group_id=@group_id
END
go

