CREATE   PROCEDURE [dbo].[k_showkomp]
(
	@occ1 INT
)
AS
	/*
	Показываем субсидию на лицевом
	
	DCARD
	*/
	SET NOCOUNT ON

	SET LANGUAGE Russian

	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = dbo.Fun_GetFinCurrent(NULL, NULL, NULL, @occ1)

	IF EXISTS (SELECT
				*
			FROM dbo.View_COMPENSAC AS c 
			WHERE occ = @occ1
			AND fin_id = @fin_current)
	BEGIN
		SELECT
			[Дата назн.] = CONVERT(CHAR(12), dateNazn, 106)
			,[Дата оконч.] = CONVERT(CHAR(12), dateEnd, 106)
			,[Дата расч.] = CONVERT(CHAR(12), dateRaschet, 106)
			,[Субсидия] = CONVERT(CHAR(10), sumkomp)
			,[без внеш.усл.] = CONVERT(CHAR(12), sumkomp_noext)
			,[Сумма кварт.] = CONVERT(CHAR(12), sumkvart)
			,[Сумма по норме.] = CONVERT(CHAR(15), sumnorm)
			,[Сред.мес.доход] = CONVERT(CHAR(15), doxod)
			,[Метод] = metod
			,[Кол.чел.] = kol_people
			,[Проживает] = realy_people
			,[Перерасчет] =
				CASE avto
					WHEN 1 THEN 'Да        '
					ELSE 'Нет       '
				END
			,[Получатель] = SUBSTRING(dbo.Fun_InitialsPeople(c.owner_id), 1, 20)
			,[в банк] = 'Да    '
			,[Прожиточный] = CONVERT(CHAR(12), sum_pm)
			,[Коментарий] = comments
			,owner_id
		FROM dbo.View_COMPENSAC AS c
		WHERE occ = @occ1
		AND fin_id = @fin_current
	END
	ELSE
		SELECT
			[Описание] = 'Субсидии нет'
go

