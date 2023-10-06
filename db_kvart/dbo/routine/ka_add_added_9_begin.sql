-- =============================================
-- Author:		Пузанов
-- Create date: 22.12.2016
-- Description:	Перерасчеты (Техническая корректировка на дом)
-- Возврат начислений по домам за фин.периоды
-- =============================================
CREATE       PROCEDURE [dbo].[ka_add_added_9_begin]
(
	  @fin_id SMALLINT -- фин. период 
	, @fin_id2 SMALLINT = NULL -- фин. период по
	, @id_str VARCHAR(8000) -- строка формата: код дома(лицевого);код дома
	, @serv_str VARCHAR(2000) -- строка формата: код услуги:код поставщика;код услуги:код поставщика
	, @doc1 VARCHAR(100) = '' -- документ (комментарий)
	, @doc_no1 VARCHAR(15) = NULL -- номер акта
	, @doc_date1 SMALLDATETIME = NULL -- дата акта
	, @debug BIT = 0 -- показать отладочную информацию
	, @id_occ BIT = 0 -- если = 1 то в @id_str передаються лицевые счета иначе дома
	, @added_true BIT = 1 -- возврат с учётом разовых
	, @data1 SMALLDATETIME = NULL -- с этого дня 
	, @data2 SMALLDATETIME = NULL -- по этот день
	, @add_type1 SMALLINT = 2 -- тех.корректировка
	, @SummaItog DECIMAL(15, 2) = 0 OUTPUT-- Общая сумма возврата
	, @Znak SMALLINT = -1
	, @is_saldo BIT = 0 -- 1-Установить кон.сальдо в 0 (Добор или возврат сальдо)
)
AS
/*
DECLARE	@return_value int,
		@SummaItog decimal(9, 2)

EXEC	@return_value = [dbo].[ka_add_added_9_begin]
		@fin_id = 122,
		@id_str = N'2805',
		@serv_str = N'площ',
		@doc1 = N'тест',
		@doc_no1 = N'888',
		@debug = 1,
		@id_occ = 0,
		@data1 = '20120301',
		@data2 = '20120315',
		@SummaItog = @SummaItog OUTPUT

SELECT	@SummaItog as N'@SummaItog'

SELECT	'Return Value' = @return_value
*/
BEGIN

	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	IF dbo.Fun_GetRejim() <> 'норм'
	BEGIN
		RAISERROR ('База закрыта для редактирования!', 16, 1)
		RETURN
	END

	IF @data1 IS NOT NULL
		SELECT @fin_id=fin_id FROM dbo.Global_values gv WHERE @data1 BETWEEN gv.start_date AND gv.end_date
	IF @data2 IS NOT NULL
		SELECT @fin_id2=fin_id FROM dbo.Global_values gv WHERE @data2 BETWEEN gv.start_date AND gv.end_date

	IF @fin_id2 IS NULL
		SET @fin_id2 = @fin_id
	IF @is_saldo IS NULL
		SET @is_saldo = 0
	IF @is_saldo = 1
		SET @fin_id = @fin_id2

	DECLARE @tmp_SummaItog DECIMAL(15, 2) = 0

	DECLARE @fin_var1 SMALLINT
		  , @start_date1 SMALLDATETIME
		  , @end_date1 SMALLDATETIME

	DECLARE cur CURSOR LOCAL FOR
		SELECT gv.fin_id
			 , gv.start_date
			 , gv.end_date
		FROM dbo.Global_values gv
		WHERE gv.fin_id BETWEEN @fin_id AND @fin_id2
		ORDER BY gv.fin_id
	OPEN cur

	FETCH NEXT FROM cur INTO @fin_var1, @start_date1, @end_date1

	WHILE @@fetch_status = 0
	BEGIN
		IF @data1 BETWEEN @start_date1 AND @end_date1
			SET @start_date1 = @data1
		IF @data2 BETWEEN @start_date1 AND @end_date1
			SET @end_date1 = @data2

		IF @debug = 1
			PRINT CONCAT(@fin_var1,' ',CONVERT(VARCHAR(10), @start_date1, 104),' ', CONVERT(VARCHAR(10), @end_date1, 104))

		EXEC dbo.ka_add_added_9 @fin_id = @fin_var1
							  , @id_str = @id_str
							  , @serv_str = @serv_str
							  , @doc1 = @doc1
							  , @doc_no1 = @doc_no1
							  , @doc_date1 = @doc_date1
							  , @debug = @debug
							  , @id_occ = @id_occ
							  , @added_true = @added_true
							  , @data1 = @start_date1
							  , @data2 = @end_date1
							  , @add_type1 = @add_type1
							  , @SummaItog = @SummaItog OUTPUT
							  , @Znak = @Znak
							  , @is_saldo = @is_saldo

		SELECT @tmp_SummaItog = @tmp_SummaItog + @SummaItog

		IF @debug = 1
			PRINT 'рассчитали: ' + dbo.FSTR(@SummaItog, 9, 2) + ' итого: ' + dbo.FSTR(@tmp_SummaItog, 9, 2)

		FETCH NEXT FROM cur INTO @fin_var1, @start_date1, @end_date1

	END

	CLOSE cur
	DEALLOCATE cur
	SET @SummaItog = @tmp_SummaItog
END
go

