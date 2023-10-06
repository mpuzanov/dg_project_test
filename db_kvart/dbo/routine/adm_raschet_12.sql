CREATE   PROCEDURE [dbo].[adm_raschet_12]
(
	@tip_id	  SMALLINT = NULL
   ,@build_id INT	   = NULL
   ,@debug	  BIT	   = 0
)
/*
  Расчёт 12% компенсации по типу фонда
*/
AS
	SET NOCOUNT ON

	DECLARE @strerror VARCHAR(7000)
		   ,@i		  INT = 0

	DECLARE @start_time1 DATETIME = current_timestamp

	BEGIN TRY

		DECLARE curs CURSOR LOCAL FOR

			SELECT
				B.id
			FROM dbo.BUILDINGS B
			JOIN dbo.OCCUPATION_TYPES ot ON 
				B.tip_id = ot.id
			WHERE 
				ot.is_calc_subs12=1 -- только тем кому можно считать субсидию
				AND (B.tip_id = @tip_id OR @tip_id IS NULL)
				AND (B.id = @build_id OR @build_id IS NULL)

		OPEN curs
		FETCH NEXT FROM curs INTO @build_id
		WHILE (@@fetch_status = 0)
		BEGIN
			SET @i = @i + 1
			IF @debug = 1
				RAISERROR (' %d) %d', 10, 1, @i, @build_id) WITH NOWAIT;

			EXEC dbo.ka_add12_proc @build_id, 'отоп';
			EXEC dbo.ka_add12_proc @build_id, 'тепл';
			EXEC dbo.ka_add12_proc @build_id, 'гвод';

			--EXEC dbo.ka_add12_proc @build_id, 'хвод'
			--EXEC dbo.ka_add12_proc @build_id, 'хвс2'			
			--EXEC dbo.ka_add12_proc @build_id, 'гвс2'
			--EXEC dbo.ka_add12_proc @build_id, 'вотв'
			--EXEC dbo.ka_add12_proc @build_id, 'вот2'
			--EXEC dbo.ka_add12_proc @build_id, 'элек'
			--EXEC dbo.ka_add12_proc @build_id, 'эле2'

			FETCH NEXT FROM curs INTO @build_id
		END
		CLOSE curs;
		DEALLOCATE curs;

		IF @debug = 1
			PRINT 'Выполнено за ' + dbo.Fun_GetTimeStr(@start_time1)

	END TRY

	BEGIN CATCH
		SET @strerror = @strerror + ' Код дома: ' + LTRIM(STR(@build_id))

		EXECUTE k_GetErrorInfo @visible = @debug
							  ,@strerror = @strerror OUT

		RAISERROR (@strerror, 16, 1)

	END CATCH
go

