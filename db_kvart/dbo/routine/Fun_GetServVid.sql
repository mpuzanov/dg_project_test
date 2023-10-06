-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE   FUNCTION [dbo].[Fun_GetServVid]
(
	@service_id VARCHAR(10)
)
RETURNS VARCHAR(10)
/* 
select dbo.Fun_GetServVid('хвс2')
*/
AS
BEGIN

	DECLARE @ResultVar VARCHAR(10)

	SET @ResultVar =
		CASE
			WHEN @service_id IN ('хвод', 'хвс2') THEN 'хвод'
			WHEN @service_id IN ('гвод', 'гвс2') THEN 'гвод'
			WHEN @service_id IN ('отоп', 'ото2') THEN 'отоп'
			WHEN @service_id IN ('элек', 'эле2') THEN 'элек'
			WHEN @service_id IN ('вотв', 'вот2') THEN 'вотв'
			ELSE @service_id
		END

	RETURN @ResultVar

END
go

