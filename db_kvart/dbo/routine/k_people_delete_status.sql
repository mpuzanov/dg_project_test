CREATE   PROCEDURE [dbo].[k_people_delete_status]
(
	  @occ INT
	, @debug BIT = 0
)
AS
	/*
	Процедура выписки или смены статуса регистации гражданина по окончанию статуса регистрации
	*/

	SET NOCOUNT ON

	IF dbo.Fun_GetRejimOccAll(@occ) <> 'норм'
	BEGIN
		--RAISERROR('База закрыта для редактирования!',16,1)
		IF @debug = 1
			PRINT 'База закрыта для редактирования!'
		RETURN
	END

	IF NOT EXISTS (
			SELECT 1
			FROM dbo.People 
			WHERE Occ = @occ
				AND Del = 0
				AND DateEnd IS NOT NULL
				AND Status2_id <> 'пост'
				AND AutoDelPeople > 0
		)
	BEGIN
		IF @debug = 1 PRINT 'нет данных для обработки'
		RETURN
	END

	DECLARE @id INT
		  , @CurrentDate SMALLDATETIME = dbo.Fun_GetOnlyDate(current_timestamp)
		  , @DateEnd SMALLDATETIME
		  , @Reason INT
		  , @status2_id VARCHAR(10)
		  , @status_name VARCHAR(20)
		  , @comments VARCHAR(100)
		  , @Initials VARCHAR(30)
		  , @fin_current SMALLINT
		  , @end_finperiod SMALLDATETIME
		  , @AutoDelPeople SMALLINT   -- 1 - Выписать, 2 - Восстановить статус

	IF EXISTS (
			SELECT 1
			FROM dbo.Reason_extract
			WHERE id = 6
		)
		SET @Reason = 6 -- закончилась врем. регистр.
	ELSE
		SET @Reason = 0

	DECLARE curs CURSOR LOCAL FOR
		SELECT p.id
			 , p.Status2_id
			 , p.DateEnd
			 , CONCAT(RTRIM(Last_name),' ',LEFT(First_name,1),'. ',LEFT(Second_name,1),'.')
			 , b.fin_current
			 , cp.end_date
			 , p.AutoDelPeople
		FROM dbo.People AS p 
			JOIN dbo.Occupations AS o ON 
				p.Occ = o.Occ
			JOIN dbo.Occupation_Types AS ot ON 
				o.tip_id = ot.id
			JOIN dbo.Person_statuses AS ps ON 
				p.Status2_id = ps.id
			JOIN dbo.Flats AS f ON 
				o.flat_id=f.id
			JOIN dbo.Buildings AS b ON 
				f.bldn_id=b.id
			JOIN dbo.Calendar_period AS cp ON 
				b.fin_current=cp.fin_id
		WHERE o.Occ = @occ
			AND p.DateEnd IS NOT NULL
			AND p.Del = 0
			AND p.DateEnd < @CurrentDate  -- статус регистрации прошел
			AND p.Status2_id <> 'пост'
			--AND ot.payms_value = 1
			AND ot.raschet_no = 0
			AND p.AutoDelPeople > 0
		OPTION (RECOMPILE)
	OPEN curs
	FETCH NEXT FROM curs INTO @id, @status2_id, @DateEnd, @Initials, @fin_current, @end_finperiod, @AutoDelPeople

	WHILE (@@fetch_status = 0)
	BEGIN		
		IF @debug = 1
			PRINT CONCAT(@id, ' ', @status2_id, ' ', CONVERT(VARCHAR(10), @DateEnd, 104), ' ', @Initials)
		
		IF @DateEnd=@end_finperiod
			SET @status2_id='-' -- пока не меняем

		-- 1 - Выписать
		IF @status2_id IN ('врем', '1016') AND @AutoDelPeople=1 -- Временная регистрация,  Врем. проп. (для субсидий
		BEGIN
			IF @debug = 1
				PRINT 'выписываем гражданина'

			EXEC dbo.k_people_delete @owner_id1 = @id
									   , @MarkDel = 1 -- Выписать человека или удалить из тек.фин.периода
									   , @KraiNew = NULL -- Край, республика
									   , @RaionNew = NULL -- Район
									   , @TownNew = NULL --  Город, пгт
									   , @VillageNew = NULL -- Село, деревня
									   , @StreetNew = NULL -- Улица
									   , @Nom_DomNew = NULL -- Новый дом
									   , @Nom_kvrNew = NULL -- Новая кваритра
									   , @Reason = @Reason -- Код причины выписки
									   , @DateDel1 = @DateEnd -- Дата выписки
									   , @DateDeath1 = NULL -- Дата смерти
									   , @is_job = 1
									   , @comments_log ='автовыписка'
		END
		-- 2 - Восстановить статус
		IF @status2_id IN ('1004','1020') AND @AutoDelPeople=2 -- врем.отсутствует, Временно отсутствует ТБО
		BEGIN
			IF @debug = 1
				PRINT 'Восстанавливаем постоянную регистрацию'

			SELECT @status_name=short_name
			FROM dbo.Person_statuses 
			WHERE id=@status2_id

			UPDATE dbo.People 
			SET Status2_id = 'пост'
			  , DateEnd = NULL
			  , AutoDelPeople = NULL
			WHERE id = @id

			SET @comments = CONCAT('Смена статуса рег. ', @Initials, ' (<',@status_name,'> до ',CONVERT(VARCHAR(10), @DateEnd, 104),')')
			EXEC dbo.k_write_log @occ1 = @occ
						   , @oper1 = N'рдчл'
						   , @comments1 = @comments

		END

		FETCH NEXT FROM curs INTO @id, @status2_id, @DateEnd, @Initials, @fin_current, @end_finperiod, @AutoDelPeople
	END

	CLOSE curs
	DEALLOCATE curs
go

