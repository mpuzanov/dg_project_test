-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE   FUNCTION [dbo].[fget_app]
(
)
RETURNS NVARCHAR(128)
WITH SCHEMABINDING
AS
BEGIN
	
	RETURN APP_NAME();

END
go

