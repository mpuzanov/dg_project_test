CREATE   PROCEDURE [dbo].[k_FindFio]
(
	@F1		VARCHAR(50)	= ''
	,@I1	VARCHAR(30)	= ''
	,@O1	VARCHAR(30)	= ''
	,@ROW1	INT			= 0
	,@del1	BIT			= 0   -- по умолчанию ищем среди прописанных
)
AS
	/*
	   Поиск людей по Ф.И.О


	exec k_FindFio @F1='Петров',@I1='А',@O1=''

	*/
	SET NOCOUNT ON

	IF @ROW1 = 0
		OR @ROW1 IS NULL
		SET @ROW1 = 9999

	SELECT TOP (@ROW1)
		o.occ
		,SUBSTRING(o.address, 1, 40) AS 'address'
		,CONCAT(RTRIM(p.[Last_name]),' ',LEFT(p.[First_name],1),'. ',LEFT(p.Second_name,1),'.') AS 'fio'
		,p.birthdate AS 'birthdate'
		,o.status_id AS 'status_id'
		,o.tip_id
		,t.name AS 'tipname'
		,o.TOTAL_SQ
	FROM dbo.People AS p 
	JOIN dbo.Occupations AS o 
		ON p.occ = o.occ
	JOIN dbo.VOcc_types_access AS t 
		ON o.tip_id = t.id
	WHERE Last_name LIKE LTRIM(RTRIM(@F1)) + '%'
	AND First_name LIKE LTRIM(RTRIM(@I1)) + '%'
	AND Second_name LIKE LTRIM(RTRIM(@O1)) + '%'
	AND p.Del = @del1
	ORDER BY o.address
	OPTION(RECOMPILE)
go

