-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE       PROCEDURE [dbo].[padeg_fio_test]
(
@padeg NVARCHAR(1) = 'Д'  -- 'Д' 'Р' 'Т'  -- падеж для тестирования
,@count_test INT = 100
,@last_name_pattern NVARCHAR(30) = '%%'
,@first_name_pattern NVARCHAR(30) = '%%'
,@second_name_pattern NVARCHAR(30) = '%%'
,@debug BIT = 0
)
AS
/*
exec padeg_fio_test @padeg='Д', @count_test=5000, @debug=0, @last_name_pattern='%%', @first_name_pattern='%%',@second_name_pattern=NULL
exec padeg_fio_test @padeg='Р', @count_test=5000, @debug=0, @last_name_pattern='%%', @first_name_pattern='%%',@second_name_pattern=NULL
exec padeg_fio_test @padeg='Т', @count_test=5000, @debug=0, @last_name_pattern='%%', @first_name_pattern='%%',@second_name_pattern=NULL

SELECT TOP 1000 * FROM dbo.People WHERE Last_name LIKE '%ава'
SELECT TOP 1000 * FROM dbo.People WHERE First_name LIKE 'Марьям%'
SELECT TOP 1000 * FROM dbo.People WHERE second_name LIKE '%Оглы'  --Оглы (сын)
SELECT TOP 1000 * FROM dbo.People WHERE second_name LIKE '%Кызы'  --Кызы (дочь)

*/
BEGIN
	SET NOCOUNT ON;

	SELECT @padeg=COALESCE(@padeg, 'Д')
	SELECT @last_name_pattern=COALESCE(@last_name_pattern, '%%')
	SELECT @first_name_pattern=COALESCE(@first_name_pattern, '%%')
	SELECT @second_name_pattern=COALESCE(@second_name_pattern, '%%')

	DECLARE @question NVARCHAR(30)
	SELECT @question = CASE @padeg
		WHEN 'Д' THEN 'справка выдана кому?'
		WHEN 'Р' THEN 'заявление от кого?'
		WHEN 'Т' THEN 'проживает совместно с кем?'
		ELSE '?'
	END

	DECLARE @t TABLE(
	owner_id INT PRIMARY KEY
	,occ INT
	,Last_name NVARCHAR(30) DEFAULT ''
	,First_name NVARCHAR(30) DEFAULT ''
	,Second_name NVARCHAR(30) DEFAULT ''
	,sex NVARCHAR(10) DEFAULT NULL
	,fio_in NVARCHAR(100) DEFAULT NULL
	,fio_out NVARCHAR(100) DEFAULT NULL
	)

	INSERT INTO @t(owner_id, occ, Last_name, First_name, Second_name, sex, fio_in)
	SELECT TOP (@count_test) p.id, p.occ,
		Last_name, First_name, Second_name,
                             CASE
                                 WHEN sex = 1 THEN 'МУЖ'
                                 ELSE CASE
                                          WHEN sex = 0 THEN 'ЖЕН'
                                          ELSE NULL
                                     END
                                 END AS sex		
		,CONCAT(LTRIM(RTRIM(Last_name)), ' ', LTRIM(RTRIM(First_name)), ' ', LTRIM(RTRIM(Second_name)))
	From dbo.People p 
	WHERE p.DateDel is NULL		
		AND p.sex IS NOT NULL
		AND p.Last_name LIKE @last_name_pattern
		AND p.First_name LIKE @first_name_pattern
		AND p.Second_name LIKE @second_name_pattern
		AND p.Last_name NOT IN ('Неизвестное','ООО','Муниципалитет')
			--(SELECT value FROM STRING_SPLIT('Неизвестное;ООО',';'))
	ORDER BY p.id DESC

	DECLARE @sex NVARCHAR(10)
		,@Last_name NVARCHAR(30)=''
		,@First_name NVARCHAR(30)=''
		,@Second_name NVARCHAR(30)=''
		,@owner_id INT
	DECLARE @fio_test TABLE(fio NVARCHAR(100))

	--=============================================================
	DECLARE curs1 CURSOR LOCAL FOR
		SELECT owner_id, Last_name, First_name, Second_name, sex FROM @t	ORDER BY owner_id
	OPEN curs1
	FETCH NEXT FROM curs1 INTO @owner_id, @Last_name, @First_name, @Second_name, @sex
	WHILE (@@fetch_status = 0)
	BEGIN
		--DELETE FROM @fio_test
		--INSERT INTO @fio_test EXEC dbo.padeg_fio 
		--	@Last_name=@Last_name, @First_name=@First_name, @Second_name=@Second_name,
		--	@padeg=@padeg, @sex=@sex, @debug=@debug
		
		--UPDATE t
		--SET fio_out=t2.fio		
		--from @t t
		--	,@fio_test as t2
		--where t.owner_id=@owner_id

		UPDATE t
		SET fio_out=(SELECT [dbo].[Fun_padeg_fio](@Last_name,@First_name,@Second_name,@padeg,@sex))
		from @t t
		where t.owner_id=@owner_id

		FETCH NEXT FROM curs1 INTO @owner_id, @Last_name, @First_name, @Second_name, @sex
	END
	CLOSE curs1
	DEALLOCATE curs1
	--=============================================================

	SELECT * FROM (
		SELECT occ, owner_id, fio_in, sex, 
		@padeg AS padeg, @question as question, 
		fio_out, 
		dbo.Fun_Падеж(fio_in, @padeg, sex) AS fio1 From @t ) as t
	WHERE fio_out<>fio1

END
go

