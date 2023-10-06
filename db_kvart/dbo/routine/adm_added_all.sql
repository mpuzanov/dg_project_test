CREATE   PROCEDURE [dbo].[adm_added_all]
(
	  @fin_id1 SMALLINT -- код финансового периода
	, @tip_id SMALLINT -- тип фонда
)
/*
  Перерасчет тип фонда по заданному финансовому периоду
*/
AS
	SET NOCOUNT ON

	DECLARE @str1 VARCHAR(100)
		  , @occ1 INT
		  , @fin_id_current SMALLINT
		  , @i INT = 0

	SELECT @fin_id_current = dbo.Fun_GetFinCurrent(@tip_id, NULL, NULL, NULL);

	IF @fin_id1 IS NULL
		SET @fin_id1 = @fin_id_current - 1;

	IF @fin_id1 = @fin_id_current
	BEGIN
		RAISERROR ('Ошибка! Фин.перериод должен быть меньше текущего!', 16, 1)
		RETURN -1
	END

	--TRUNCATE TABLE raschet

	DELETE FROM dbo.Added_Payments
	WHERE add_type = 9   -- Тип разового "Общий перерасчет"

	DECLARE curs1 CURSOR FOR
		SELECT Occ
		FROM Occupations
		WHERE status_id <> 'закр'
			AND tip_id = @tip_id
	OPEN curs1
	FETCH NEXT FROM curs1 INTO @occ1
	SET @i = @i + 1

	WHILE (@@fetch_status = 0)
	BEGIN
		-- Расчитываем квартплату

		EXEC k_raschet_2 @occ1
					   , @fin_id1
					   , @added = 1
					   , @alladd = 1

		EXEC ka_add_occ @occ1
					  , @fin_id1

		FETCH NEXT FROM curs1 INTO @occ1
		SET @i = @i + 1
	--   IF @i>1000 BREAK
	--   print str(@i)+' '+str(@occ1)
	END

	CLOSE curs1
	DEALLOCATE curs1
go

