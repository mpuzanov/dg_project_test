-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[adm_build_norma] 
( @build_id INT )
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT * FROM dbo.Build_occ_norma WHERE build_id=@build_id
END
go

