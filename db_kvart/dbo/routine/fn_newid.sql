-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE   FUNCTION [dbo].[fn_newid]()
RETURNS UNIQUEIDENTIFIER
AS
/*
create view getNewID as select newid() as new_id;
select dbo.fn_newid();
*/
BEGIN
	return (select new_id from getNewID)
END
go

