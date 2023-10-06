-- =============================================
-- Author:		Пузанов
-- Create date: 25.04.2007
-- Description:	Для перерасчетов показываем начисления по услуге и общую площадь дома
-- =============================================
CREATE         PROCEDURE [dbo].[ka_show_value_build]
(
    @build_id1    INT,
    @service_id1  VARCHAR(10),
    @fin_id1      SMALLINT,
    @fin_id2      SMALLINT = NULL,
    @paid_source  DECIMAL(15, 2)     OUTPUT,
    @paid         DECIMAL(15, 2)     OUTPUT,
    @total_sq     DECIMAL(15, 2)     OUTPUT,
    @total_sq_no  DECIMAL(15, 2)     OUTPUT,
    @total_arenda DECIMAL(15, 2)     OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @fin_current1 SMALLINT
	SELECT @fin_current1 = dbo.Fun_GetFinCurrent(NULL, @build_id1, NULL, NULL)

	IF @fin_id2 IS NULL
		SELECT @fin_id2 = @fin_current1

	DECLARE @service_id2  VARCHAR(10) -- Если расчёт по ОТОПЛЕНИЕ УКС суммируем с обычным ОТОПЛЕНИЕМ
	
	IF @service_id1='ото2' SET @service_id2='отоп'
	ELSE SET @service_id2=@service_id1
	
	-- таблица по лицевым
	CREATE TABLE #t1(
		fin_id SMALLINT,
		occ INT,
		paid DECIMAL(15, 2),
		total_sq DECIMAL(10, 4),
		total_sq_no DECIMAL(10, 4)
	)

	-- выходная таблица по домам
	CREATE TABLE #t2(
		fin_id SMALLINT,
		fin VARCHAR(20) COLLATE database_default,
		paid_source DECIMAL(15, 2), -- начисленно поставщиком
		paid DECIMAL(15, 2), -- начисленно нами
		total_sq DECIMAL(10, 4), -- общая площадь где есть начисления
		total_sq_no DECIMAL(10, 4) -- общая площадь где нет начислений
	)

	CREATE TABLE #t3(
		fin_id SMALLINT,
		paid_source DECIMAL(15, 2)
	)

	INSERT INTO #t3
	SELECT fin_id
		 , sum(value_source) AS value_source
	FROM
		dbo.BUILD_SOURCE_VALUE AS bs 
	WHERE
		bs.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND bs.service_id IN (@service_id1,@service_id2)
		AND bs.build_id = @build_id1
	GROUP BY
		fin_id

	-- заполняем площади
	INSERT INTO #t1
	SELECT fin_id = o.fin_id
		 , occ = o.occ
		 , paid = 0
		 , total_sq = total_sq
		 , total_sq_no = 0
	FROM
		dbo.View_OCC_ALL AS o 
		JOIN dbo.FLATS AS f 
			ON o.flat_id = f.id
	WHERE
		f.bldn_id = @build_id1
		AND o.fin_id BETWEEN @fin_id1 AND @fin_id2
		AND o.status_id <> 'закр'


	UPDATE #t1
	SET
		paid = ph.paid --ph.value+ph.added     -- 23/10/2007 добавил +ph.added с учетом разовых
	FROM
		#t1 AS o 
		JOIN dbo.View_PAYM AS ph
			ON o.occ = ph.occ AND o.fin_id = ph.fin_id
	WHERE
		ph.service_id IN (@service_id1,@service_id2)
		AND
		ph.subsid_only = 0

	IF @fin_id2 >= @fin_current1
	BEGIN
		INSERT INTO #t1
		SELECT fin_id = @fin_current1
			 , occ = o.occ
			 , paid = 0
			 , total_sq = total_sq
			 , total_sq_no = 0
		FROM
			dbo.VOCC AS o 
			JOIN dbo.FLATS AS f
				ON o.flat_id = f.id
		WHERE
			f.bldn_id = @build_id1
			AND o.status_id <> 'закр'

		UPDATE #t1
		SET
			paid = ph.paid
		FROM
			#t1 AS o 
			JOIN dbo.PAYM_LIST AS ph 
				ON o.occ = ph.occ
		WHERE
			o.fin_id = @fin_current1
			AND
			ph.service_id IN (@service_id1,@service_id2)
			AND
			ph.subsid_only = 0
	END --IF @fin_id2=@fin_current1


	UPDATE #t1
	SET
		total_sq_no = total_sq, total_sq = 0
	WHERE
		paid = 0

	INSERT INTO #t2
	SELECT fin_id
		 , 'fin' = dbo.Fun_NameFinPeriod(fin_id)
		 , paid_source = 0
		 , paid = sum(paid)
		 , total_sq = sum(total_sq)
		 , total_sq_no = sum(total_sq_no)
	--into #t2
	FROM
		#t1
	GROUP BY
		fin_id
	ORDER BY
		fin_id DESC

	UPDATE #t2
	SET
		paid_source = #t3.paid_source
	FROM
		#t2, #t3
	WHERE
		#t2.fin_id = #t3.fin_id


	SELECT fin
		 , paid_source
		 , paid
		 , total_sq
		 , total_sq_no
	FROM
		#t2

   select @total_arenda=arenda_sq
   FROM dbo.View_BUILD_ALL AS vb
   WHERE bldn_id=@build_id1 AND fin_id=@fin_current1

	SELECT @paid_source = sum(paid_source)
		 , @paid = sum(paid)
		 , @total_sq = avg(total_sq)
		 , @total_sq_no = avg(total_sq_no)		 
	FROM
		#t2

END
go

