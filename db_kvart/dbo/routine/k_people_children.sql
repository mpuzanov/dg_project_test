CREATE   PROCEDURE [dbo].[k_people_children]
(
	@occ1			INT
	,@Children		BIT		= 1 -- выдаем детей по лицевому
	,@listok_id1	SMALLINT	= 0
)
/*

Выдаем детей или взрослых на лицевом счете

Если @listok_id1 = 0 то выводим из таблицы PEOPLE
Если @listok_id1 = 1 то выводим из таблицы PEOPLE_LISTOK
с листками прибытия
Если @listok_id1 = 2 то выводим из таблицы PEOPLE_LISTOK
с листками убытия

автор: Пузанов М.А.
17.09.2004

*/
AS

	SET NOCOUNT ON

	SET LANGUAGE Russian

	DECLARE	@CurrentDate	DATETIME
			,@Date1			DATETIME
			,@D1			DATETIME
			,@D2			DATETIME
	SET @CurrentDate = current_timestamp

	SET @Date1 = DATEADD(YEAR, -14, @CurrentDate) -- 14 лет 
	--print @Date1

	IF @Children IS NULL
		SET @Children = 1
	IF @listok_id1 IS NULL
		SET @listok_id1 = 0

	IF @Children = 1
		SELECT
			@D1 = @Date1
			,@D2 = @CurrentDate
	ELSE
		SELECT
			@D1 = '19000101'
			,@D2 = @Date1

	IF @listok_id1 = 0
		SELECT
			id
			,SUBSTRING(last_name + ' ' + first_name + ' ' + second_name + ' | д.рожд:' + CONVERT(CHAR(14), birthdate, 106), 1, 120) AS FiO
			,OwnerParent
		FROM dbo.PEOPLE
		WHERE occ = @occ1
		AND Del = 0
		AND birthdate BETWEEN @D1 AND @D2


	IF @listok_id1 > 0
		SELECT
			id
			,SUBSTRING(last_name + ' ' + first_name + ' ' + second_name + ' | д.рожд:' + CONVERT(CHAR(14), birthdate, 106), 1, 120) AS FiO
			,OwnerParent
		FROM dbo.PEOPLE_LISTOK
		WHERE occ = @occ1
		AND listok_id = @listok_id1
		AND birthdate BETWEEN @D1 AND @D2
go

