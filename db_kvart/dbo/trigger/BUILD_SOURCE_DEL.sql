-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[BUILD_SOURCE_DEL]
ON [dbo].[Build_source]
FOR DELETE
AS
BEGIN
	SET NOCOUNT ON;

	INSERT
	INTO Op_log_mode
	(	build_id
		,user_id
		,service_id
		,id_old
		,comments
		,app
		,is_mode)
		SELECT
			build_id
			,dbo.Fun_GetCurrentUserId()
			,service_id
			,d.source_id
			,'Удаляем'
			,SUBSTRING(dbo.fn_app_name(),1,50)
			,2
		FROM DELETED d


END
go

