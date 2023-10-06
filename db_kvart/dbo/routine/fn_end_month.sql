-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE   FUNCTION [dbo].[fn_end_month]
(
@dat datetime
)
RETURNS date
AS
BEGIN
	
	RETURN EOMONTH(@dat)

END
go

