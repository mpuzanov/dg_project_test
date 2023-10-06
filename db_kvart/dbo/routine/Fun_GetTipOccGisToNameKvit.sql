-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE   FUNCTION [dbo].[Fun_GetTipOccGisToNameKvit]
(
@name_gis VARCHAR(20)
,@roomtype_id VARCHAR(10) = NULL
)
RETURNS VARCHAR(20)
AS
BEGIN
	DECLARE @Result VARCHAR(20) = 
	CASE @name_gis
    	WHEN 'ЛС КР' THEN '' --'КАП'
    	--WHEN '' THEN ''
    	ELSE 'КВП' 
    END

	RETURN @Result

END
go

