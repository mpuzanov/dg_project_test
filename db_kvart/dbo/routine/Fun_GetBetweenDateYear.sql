CREATE   FUNCTION [dbo].[Fun_GetBetweenDateYear]
(
	@dat1 SMALLDATETIME
   ,@dat2 SMALLDATETIME
)
RETURNS INT
AS
BEGIN
	/*
	Функция возвращает кол-во полных лет между двумя датами

	DECLARE @dat1 SMALLDATETIME='19790724', 
			@dat2 SMALLDATETIME=current_timestamp
	SELECT dbo.Fun_GetBetweenDateYear(@dat1,@dat2) AS age
	,DATEDIFF(MONTH,@dat1,@dat2)/12 AS age2  
	
	select DATEDIFF(MONTH,'20771013','20771018')/12 AS age3 -- не правильно

	Здесь вначале находится разница в годах между двумя календарными датами функцией datediff 
	и от неё вычитается 1, если в календарном году даты @dat2 месяц и дата переменной @dat1 
	еще не наступили относительно переменной @dat2.
	*/
	RETURN (DATEDIFF(YEAR, @dat1, @dat2) -
		CASE
			WHEN MONTH(@dat1) < MONTH(@dat2) THEN 0
			WHEN MONTH(@dat1) > MONTH(@dat2) THEN 1
			WHEN DAY(@dat1) > DAY(@dat2) THEN 1
			ELSE 0
		END)

END
go

exec sp_addextendedproperty 'MS_Description', N'Функция возвращает кол-во полных лет между двумя датами', 'SCHEMA',
     'dbo', 'FUNCTION', 'Fun_GetBetweenDateYear'
go

