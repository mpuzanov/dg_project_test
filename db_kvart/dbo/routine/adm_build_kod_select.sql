-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[adm_build_kod_select] 
( @build_id1 int
)
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT b.build_id, b.service_id, b.kod, b.comments
    FROM BUILD_SOURCE_ID as b
	where b.build_id=@build_id1	
    order by b.service_id, b.kod


END
go

