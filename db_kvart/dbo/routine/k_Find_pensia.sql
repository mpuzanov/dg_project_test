CREATE   PROCEDURE [dbo].[k_Find_pensia]
(
	@fin_id1	SMALLINT
	,@F1		VARCHAR(20)	= ''
	,@I1		VARCHAR(20)	= ''
	,@O1		VARCHAR(20)	= ''
	,@ROW1		INT			= 0
	,@ORGAN_ID1	SMALLINT	= 1
)
AS
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT
				*
			FROM AccessSubsidOper)
	BEGIN
		RAISERROR ('Для Вас работа с Субсидиями запрещена', 16, 1)
		RETURN
	END

	SET LANGUAGE Russian

	SELECT TOP (@ROW1)
		FAMILY AS [Фамилия]
		,SUBSTRING([name], 1, 12) AS [Имя]
		,SUBSTRING(FATHER, 1, 15) AS [Отчество]
		,CONVERT(CHAR(12), D_ROGD, 106) AS [Дата_рожд.]
		,SUBSTRING(STREET, 1, 16) AS [Улица]
		,HOUSE AS [Дом]
		,KORP AS [Корп.]
		,FLAT AS [Кв.]
		,sum1
		,SUM2
		,SUM3
		,ITOGO
		,CASE raion
			WHEN 1 THEN 'Индустриальный'
			WHEN 2 THEN 'Ленинский'
			WHEN 3 THEN 'Октябрьский'
			WHEN 4 THEN 'Первомайский'
			WHEN 5 THEN 'Устиновский'
			ELSE 'Неизвестно'
		END AS [Район]
		,NAI_PEN AS [Вид]
		,RAB AS [Работает]
		,PUNKT AS [Город]
		,OSNOVAN AS [Номера_дел]
	FROM dbo.PENSIA AS p 
	WHERE fin_id = @fin_id1
	AND LTRIM(FAMILY) LIKE @F1 + '%'
	AND (p.[name] LIKE @I1 + '%')
	AND ((FATHER LIKE @O1 + '%')
	OR (FATHER IS NULL))
	AND ORGAN_ID = @ORGAN_ID1
go

