-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   TRIGGER [dbo].[BUILD_MODE_add]
ON [dbo].[Build_mode]
FOR INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	INSERT
	INTO OP_LOG_MODE
	(	build_id
		,user_id
		,service_id
		,id_new
		,comments
		,app)
		SELECT
			build_id
			,dbo.Fun_GetCurrentUserId()
			,service_id
			,mode_id
			,'Добавляем'
			,SUBSTRING(dbo.fn_app_name(),1,50)
		FROM INSERTED i


END
go

