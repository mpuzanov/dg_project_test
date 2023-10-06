-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE     PROCEDURE [dbo].[rep_ssas_1]
	  @tip_id SMALLINT = NULL
	, @fin_id1 SMALLINT = NULL
	, @fin_id2 SMALLINT = NULL
	, @build INT = NULL
	, @number_query SMALLINT = 1
AS
/*
exec rep_ssas_1 @tip_id=131  -- kr1
exec rep_ssas_1 @tip_id=131, @number_query=2  -- kr1
exec rep_ssas_1 @tip_id=131, @fin_id1=245, @fin_id2=250
exec rep_ssas_1 @tip_id=1, @fin_id1=245, @fin_id2=250, @build=6786

exec rep_ssas_1 @tip_id=3, @fin_id1=245, @fin_id2=250 -- komp, naim
exec rep_ssas_1 @tip_id=137, @fin_id1=245, @fin_id2=250, @build=4820 -- komp_spdu
exec rep_ssas_1 @tip_id=27, @fin_id1=245, @fin_id2=250, @build=520  -- kvart
*/
BEGIN
	SET NOCOUNT ON;

	SET @number_query=coalesce(@number_query,1)

	DECLARE @db_name VARCHAR(15) = DB_NAME()
	DECLARE @tip VARCHAR(10) = LTRIM(STR(@tip_id))
	DECLARE @str VARCHAR(MAX)
	
	DECLARE @fin_current SMALLINT
	SELECT @fin_current = dbo.Fun_GetFinCurrent(@tip_id, NULL, NULL, NULL)

	IF @fin_id1 IS NULL
		SET @fin_id1 = @fin_current-1

	IF @fin_id2 IS NULL
		AND @fin_id1 IS NOT NULL
		SET @fin_id2 = @fin_id1

	IF @number_query=1
	BEGIN
		SET @str = '
		--WITH 
		--MEMBER [Measures].[Оплачено_по_услугам] AS [Measures].[Оплачено]-[Measures].[Оплачено_пени], FORMAT_STRING="Currency"
		SELECT
		non empty ({
		[Measures].[Нач_сальдо],
		[Measures].[Начислено],
		[Measures].[Разовые],
		[Measures].[Пост_начисления],
		[Measures].[Оплачено],
		[Measures].[Оплачено_пени],
		[Measures].[Оплачено_по_услугам],
		[Measures].[Кон_сальдо],
		[Measures].[ПениНовое],
		[Measures].[ПениИтог],
		[Measures].[Количество],
		[Measures].[Кол_разовых],
		[Measures].[Задолженность]
		})
		ON COLUMNS,
		non empty crossjoin (
		[Фин периоды].[Дата].[Дата], '
	
		IF @tip_id IS NOT NULL
			SET @str = @str + ' [Типы жилого фонда].[Тип фонда].&['+@tip+'],'
		ELSE
			SET @str = @str + ' [Типы жилого фонда].[Тип фонда].[Тип фонда],'

		SET @str = @str +' [Дома].[Дома].[Дом],
		[Услуги].[Услуги].[Услуга]
		) 
		ON ROWS
		from [Начисления]
		where
		{ [Фин периоды].[Код периода].[Код периода].&['+LTRIM(STR(@fin_id1))+']  :  [Фин периоды].[Код периода].[Код периода].&['+LTRIM(STR(@fin_id2))+'] }	
		';
	END
	ELSE --IF @number_query=2
	BEGIN
		SET @str = '
		SELECT
		non empty ({
		[Measures].[Нач_сальдо],
		[Measures].[Начислено],
		[Measures].[Разовые],
		[Measures].[Пост_начисления],
		[Measures].[Оплачено],
		[Measures].[Оплачено_пени],
		[Measures].[Оплачено_по_услугам],
		[Measures].[Кон_сальдо],
		[Measures].[ПениНовое],
		[Measures].[ПениИтог],
		[Measures].[Количество],
		[Measures].[Кол_разовых],
		[Measures].[Задолженность]
		})
		ON COLUMNS,
		non empty crossjoin ('
	
		IF @tip_id IS NOT NULL
			SET @str = @str + ' [Типы жилого фонда].[Тип фонда].&['+@tip+'],'
		ELSE
			SET @str = @str + ' [Типы жилого фонда].[Тип фонда].[Тип фонда],'

		SET @str = @str +' [Лицевые].[От улицы до лицевого].[Лицевой],
		[Услуги].[Услуги].[Услуга]
		) 
		ON ROWS
		from [Начисления]
		where
		{ [Фин периоды].[Код периода].[Код периода].&['+LTRIM(STR(@fin_id1))+']  :  [Фин периоды].[Код периода].[Код периода].&['+LTRIM(STR(@fin_id2))+'] }	
		';
	END

	IF @build IS NOT NULL
		SET @str = @str + ' * [Дома].[Код дома].[Код дома].&['+LTRIM(STR(@build))+'] '
	
	SET @str = @str + ' CELL PROPERTIES formatted_value'

	IF @db_name IN ('NAIM') 
		EXECUTE (@str) AT SSAS_NAIM
	ELSE
		IF @db_name IN ('KVART') -- спду
			EXECUTE (@str) AT SSAS_KVART
		ELSE
			EXECUTE (@str) AT SSAS

END
go

