-- =============================================
-- Author:		Пузанов
-- Create date: 03.02.2012
-- Description:	Находим количество дней недопоставки по лицевому и услуге
-- =============================================
CREATE     FUNCTION [dbo].[Fun_GetKolDayNo_Serv]
(
	  @occ INT
	, @service_id VARCHAR(10)
	, @dat1 SMALLDATETIME
	, @dat2 SMALLDATETIME
)
/*
select dbo.Fun_GetKolDayNo_Serv(@occ1,p.service_id,tf.data1, tf.data2)
select dbo.Fun_GetKolDayNo_Serv(267978,'гвод','20111202', '20120119')
*/
RETURNS DECIMAL(4, 2)
AS
BEGIN

	DECLARE @kolDayNo DECIMAL(4, 2) = 0
		  , @SumkolDayNo DECIMAL(4, 2) = 0
		  , @data_start SMALLDATETIME = NULL
		  , @data_end SMALLDATETIME = NULL
		  , @hours_no DECIMAL(5, 2) = 0

	DECLARE @t_data TABLE (
		  data_start SMALLDATETIME
		, data_end SMALLDATETIME
		, kolDayNo SMALLINT
		, hours_no SMALLINT DEFAULT 0
	)

	-- проверяем недопоставку в этом периоде где часы=0
	INSERT INTO @t_data (data_start
					   , data_end
					   , kolDayNo)
	SELECT data1
		 , data2
		 , 0
	FROM dbo.View_added
	WHERE Occ = @occ
		AND service_id = @service_id
		AND add_type = 1
		AND @dat1 < data2
		AND @dat2 > data1
		AND COALESCE([Hours], 0) = 0

	DECLARE curs CURSOR LOCAL FOR
		SELECT data_start
			 , data_end
			 , kolDayNo
		FROM @t_data
	OPEN curs
	FETCH NEXT FROM curs INTO @data_start, @data_end, @kolDayNo

	WHILE (@@fetch_status = 0)
	BEGIN
		IF @data_start IS NOT NULL
		BEGIN
			-- расчитываем количество дней
			IF @dat1 > @data_start
				SET @data_start = @dat1
			IF @dat2 < @data_end
				SET @data_end = @dat2
			SET @kolDayNo = DATEDIFF(DAY, @data_start, @data_end) + 1
			SET @SumkolDayNo = @SumkolDayNo + @kolDayNo
		END

		FETCH NEXT FROM curs INTO @data_start, @data_end, @kolDayNo
	END

	CLOSE curs
	DEALLOCATE curs

	DELETE FROM @t_data

	-- Проверяем по часам недопоставку
	INSERT INTO @t_data (data_start
					   , data_end
					   , kolDayNo
					   , hours_no)
	SELECT data1
		 , data2
		 , 0
		 , [Hours]
	FROM dbo.View_added
	WHERE Occ = @occ
		AND service_id = @service_id
		AND add_type = 1
		AND @dat1 < data2
		AND @dat2 > data1
		AND [Hours] > 0

	IF EXISTS (SELECT * FROM @t_data)
	BEGIN
		DECLARE @KolDayHours DECIMAL(4, 2)
		DECLARE curs CURSOR LOCAL FOR
			SELECT data_start
				 , data_end
				 , kolDayNo
				 , hours_no
			FROM @t_data
		OPEN curs
		FETCH NEXT FROM curs INTO @data_start, @data_end, @kolDayNo, @hours_no

		WHILE (@@fetch_status = 0)
		BEGIN
			IF @data_start IS NOT NULL
			BEGIN
				-- расчитываем количество дней
				IF @dat1 > @data_start
					SET @data_start = @dat1
				IF @dat2 < @data_end
					SET @data_end = @dat2
				SELECT @kolDayNo = DATEDIFF(DAY, @data_start, @data_end)
					 , @KolDayHours = @hours_no / 24

				IF @KolDayHours < @kolDayNo
					SET @kolDayNo = @KolDayHours
				SET @SumkolDayNo = @SumkolDayNo + @kolDayNo
			END

			FETCH NEXT FROM curs INTO @data_start, @data_end, @kolDayNo, @hours_no
		END

		CLOSE curs
		DEALLOCATE curs
	END--IF EXISTS(SELECT * FROM @t_datA)


	RETURN @SumkolDayNo

END
go

