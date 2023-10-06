-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE   FUNCTION [dbo].[fsize]
( 
	@body VARBINARY(MAX)
)
RETURNS DECIMAL(9,2)
WITH SCHEMABINDING
AS
/*
размер параметра в Кбайтах
*/
BEGIN

	RETURN CAST(datalength(@body)/1024.00 AS DECIMAL(9,2))

END
go

