-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Виртуальная таблица чисел
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetNums]
(	
@low AS BIGINT
,@high AS BIGINT
)
RETURNS TABLE 
AS
/*
SELECT n FROM dbo.Fun_getNums(900000001,900001000)

=================================================

DECLARE 
@start AS SMALLDATETIME='20120101'
,@end AS SMALLDATETIME='20151201'

SELECT DATEADD(MONTH,n,@start) as dt, 
DATENAME(month, DATEADD(MONTH,n,@start))+' '+DATENAME(YEAR, DATEADD(MONTH,n,@start)) AS strmonth
FROM dbo.Fun_getNums(0,DATEDIFF(MONTH,@start,@end)) AS Nums;

*/

RETURN (
WITH L0
AS
(SELECT
		c
	FROM (VALUES (1), (1)) AS D (c)),
L1
AS
(SELECT
		1 AS c
	FROM L0 AS A
	CROSS JOIN L0 AS B),
L2
AS
(SELECT
		1 AS c
	FROM L1 AS A
	CROSS JOIN L1 AS B),
L3
AS
(SELECT
		1 AS c
	FROM L2 AS A
	CROSS JOIN L2 AS B),
L4
AS
(SELECT
		1 AS c
	FROM L3 AS A
	CROSS JOIN L3 AS B),
L5
AS
(SELECT
		1 AS c
	FROM L4 AS A
	CROSS JOIN L4 AS B),
Nums
AS
(SELECT
		ROW_NUMBER() OVER (ORDER BY (SELECT
				NULL)
		) AS rownum
	FROM L5)
SELECT TOP (CASE
                WHEN @high > @low THEN @high
                ELSE @low
                END - @low + 1)
	@low + rownum - 1 AS n
FROM Nums
ORDER BY rownum
)
go

