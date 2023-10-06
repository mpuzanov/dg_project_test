CREATE   FUNCTION [dbo].[Fun_GetAge]
(
	@peolpe_id INT
	,@date SMALLDATETIME = NULL
)
RETURNS INT
AS
BEGIN
	/*
	Функция возвращает кол-во полных лет гражданина на заданную или текущую дату

	DECLARE @peolpe_id INT = 150352
	SELECT dbo.Fun_GetAge(@peolpe_id, NULL) AS age
	SELECT dbo.Fun_GetAge(@peolpe_id, '20200101') AS age

	Здесь вначале находится разница в годах между двумя календарными датами функцией datediff 
	и от неё вычитается 1, если в календарном году даты @dat2 месяц и дата переменной @dat1 
	еще не наступили относительно переменной @dat2.
	*/
	IF @date IS NULL SET @date = CURRENT_TIMESTAMP
	DECLARE @age SMALLINT

	SELECT @age=(DATEDIFF(YEAR, P.Birthdate, @date) -
		CASE
			WHEN MONTH(P.Birthdate) < MONTH(@date) THEN 0
			WHEN MONTH(P.Birthdate) > MONTH(@date) THEN 1
			WHEN DAY(P.Birthdate) > DAY(@date) THEN 1
			ELSE 0
		END)
		FROM dbo.People p 
		WHERE id=@peolpe_id

	RETURN @age
END
go

exec sp_addextendedproperty 'MS_Description', N'Функция возвращает кол-во полных лет гражданина', 'SCHEMA', 'dbo',
     'FUNCTION', 'Fun_GetAge'
go

