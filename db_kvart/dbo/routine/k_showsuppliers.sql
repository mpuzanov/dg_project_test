CREATE   PROCEDURE [dbo].[k_showsuppliers]
(
	@service_id1 VARCHAR(10)
)
AS
	SET NOCOUNT ON
	SELECT
		s1.*
	FROM dbo.View_SUPPLIERS AS s1 
	WHERE service_id = @service_id1
go

