-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	генератор случайных вещественных чисел
-- =============================================
CREATE   PROCEDURE [dbo].[k_RandReal]
(
	@start REAL, -- начало диапазона
	@end REAL,	 -- конец диапазона
	@count INT   -- кол-во чисел для возврата
)
AS
BEGIN
/*
возможное использование

exec k_RandReal @start=12, @end=15, @count=25

declare @t_rand table(id int, randomNum REAL)
insert into @t_rand exec k_RandReal @start=12, @end=15, @count=25
select * from @t_rand

*/

SET NOCOUNT ON;

DECLARE @range INT=@end-@start

;WITH randowvalues
AS(
	SELECT 1 id, CAST(RAND(CHECKSUM(NEWID()))*@range AS REAL) + @start randomnumber
	UNION  ALL
	SELECT id + 1, CAST(RAND(CHECKSUM(NEWID()))*@range AS REAL) + @start randomnumber
	FROM randowvalues
	WHERE 
		id < @count  
	)

SELECT id,randomnumber
FROM randowvalues
OPTION(MAXRECURSION 0)

END
go

