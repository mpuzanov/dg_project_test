-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[BUILD_SOURCE_ADD]
ON [dbo].[Build_source]
FOR INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	INSERT
	INTO Op_log_mode
	(	build_id
		,user_id
		,service_id
		,id_new
		,comments
		,app
		,is_mode)
		SELECT
			build_id
			,dbo.Fun_GetCurrentUserId()
			,service_id
			,i.source_id
			,'Добавляем'
			,SUBSTRING(dbo.fn_app_name(),1,50)
			,2
		FROM INSERTED i


END
go

