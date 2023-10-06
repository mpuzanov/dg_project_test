CREATE   FUNCTION [dbo].[Fun_GetServiceName]
(
	@service_id1 VARCHAR(10)
)
RETURNS VARCHAR(100)
AS
BEGIN

	RETURN (SELECT
			s.name
		FROM dbo.SERVICES s
		WHERE id = @service_id1)


END
go

