-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[BUILD_MODE_DEL]
ON [dbo].[Build_mode]
FOR DELETE
AS
BEGIN
	SET NOCOUNT ON;

	INSERT
	INTO OP_LOG_MODE
	(	build_id
		,user_id
		,service_id
		,id_old
		,comments
		,app)
		SELECT
			build_id
			,dbo.Fun_GetCurrentUserId()
			,service_id
			,mode_id
			,'Удаляем'
			,SUBSTRING(dbo.fn_app_name(),1,50)
		FROM DELETED d


END
go

