CREATE   PROCEDURE [dbo].[rep_FindFio]
(
	@F1		VARCHAR(20)	= ''
	,@I1	VARCHAR(20)	= ''
	,@O1	VARCHAR(20)	= ''
)
AS
	/*
	Поиск людей по Ф.И.О.
	Отчет: peopleFIO.fr3

	exec rep_FindFio @F1='Пуз'

	*/
	SET NOCOUNT ON


	DECLARE @rowcount INT = 1000

	IF @F1 = ''
		AND @I1 = ''
		AND @O1 = ''
	SELECT @F1 = '?',@I1 = '?',@O1 = '?'
	

	SELECT TOP (@rowcount)
		o.occ
		,o.address AS [address]
		,p.Last_name
		,p.First_name
		,p.Second_name
		,p.Birthdate
		,p.DateReg
		,p.DateDel
		,CASE p.sex
				WHEN 0 THEN 'жен'
				WHEN 1 THEN 'муж'
				WHEN 2 THEN 'орг'
				ELSE 'неизв'
		END AS sex
	FROM dbo.People AS p 
	JOIN dbo.Occupations AS o ON 
		p.occ = o.occ
	WHERE 
		Last_name LIKE @F1 + '%'
		AND First_name LIKE @I1 + '%'
		AND Second_name LIKE @O1 + '%'

	ORDER BY p.DateDel, o.address
go

