CREATE   PROCEDURE [dbo].[ka_del_added_build]
(
	@build1			INT
	,@service_id1	VARCHAR(10)	= NULL
	, -- услуга
	@add_type1		SMALLINT
	, -- тип разового
	@doc_no1		VARCHAR(10) -- номер акта
	,@occ1			INT		= NULL
)
AS
	--
	--   Удаление разовых в доме с заданным документом
	--
	/*
	Проверяем в 2 таблицах 
	added_payments
	added_COUNTERS_ALL
	*/
	SET NOCOUNT ON

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	DECLARE @added_id1 INT

	DECLARE @build_occ TABLE(id INT)

	DECLARE @fin_current SMALLINT
	SELECT
		@fin_current = [dbo].[Fun_GetFinCurrent](NULL, @build1, NULL, NULL)


	-- Выбираем разовые по норме
	INSERT INTO @build_occ
		SELECT
			ap.id --, ap.occ, ap.service_id, ap.add_type, ap.doc_no
		FROM dbo.OCCUPATIONS AS o
		JOIN dbo.FLATS AS f 
			ON o.flat_id = f.id
		JOIN dbo.ADDED_PAYMENTS AS ap 
			ON o.occ = ap.occ
		WHERE 
			f.bldn_id = @build1
			AND (ap.service_id = @service_id1 OR @service_id1 IS NULL)
			AND ap.doc_no = @doc_no1
			AND ap.add_type = @add_type1
			AND (ap.occ = @occ1 OR @occ1 IS NULL);

	-- выбираем разовые по счетчикам
	INSERT INTO @build_occ
		SELECT
			ap.id --, ap.occ, ap.service_id, ap.add_type, ap.doc_no
		FROM dbo.Occupations AS o 
		JOIN dbo.Flats AS f 
			ON o.flat_id = f.id
		JOIN dbo.Added_Counters_All AS ap 
			ON o.occ = ap.occ
		WHERE 
			f.bldn_id = @build1
			AND (ap.service_id = @service_id1 OR @service_id1 IS NULL)
			AND ap.doc_no = @doc_no1
			AND ap.add_type = @add_type1
			AND ap.fin_id = @fin_current
			AND (ap.occ = @occ1 OR @occ1 IS NULL);

	--select * from  @build_occ as bo
	--return

	DECLARE curs1 CURSOR FOR
		SELECT
			id
		FROM @build_occ AS bo
	OPEN curs1
	FETCH NEXT FROM curs1 INTO @added_id1
	WHILE (@@fetch_status = 0)
	BEGIN
		EXEC dbo.ka_del_added @added_id1

		FETCH NEXT FROM curs1 INTO @added_id1
	END
	CLOSE curs1
	DEALLOCATE curs1
go

