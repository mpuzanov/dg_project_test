CREATE   PROCEDURE [dbo].[adm_services]
AS
	SET NOCOUNT ON

	SELECT
		*
	FROM dbo.View_SERVICES
	ORDER BY name
go

