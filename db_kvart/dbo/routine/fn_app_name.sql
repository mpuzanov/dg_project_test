-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE   FUNCTION [dbo].[fn_app_name]
(
)
RETURNS NVARCHAR(128)
WITH SCHEMABINDING
AS
BEGIN
	
	RETURN APP_NAME();

END
go

