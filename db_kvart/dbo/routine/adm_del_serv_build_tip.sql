CREATE   PROCEDURE [dbo].[adm_del_serv_build_tip]
(
	  @tip_id INT = NULL
	  ,@debug BIT = 0
)
AS
	/*

	EXEC adm_del_serv_build_tip @tip_id=1

	Удаление услуг без режимов по типу фонда
	
	Пузанов М.А.
	
	*/
	SET NOCOUNT ON


	DECLARE @build_id INT
		  , @mode_id INT
		  , @source_id INT
		  , @service_id VARCHAR(10)
		  , @roomtype_id VARCHAR(10)

	DECLARE cur CURSOR LOCAL FOR
		SELECT DISTINCT f.bldn_id
					  , cl.service_id
					  , cl.mode_id
					  , cl.source_id
					  , o.roomtype_id
		FROM dbo.Occupations AS o
			JOIN dbo.Flats AS f ON 
				f.id = o.flat_id
			JOIN dbo.Consmodes_list AS cl ON 
				o.occ = cl.occ
		WHERE 
			(@tip_id IS NULL OR o.tip_id = @tip_id)
			AND cl.mode_id % 1000 = 0
			AND cl.source_id % 1000 = 0

	OPEN cur

	FETCH NEXT FROM cur INTO @build_id, @service_id, @mode_id, @source_id, @roomtype_id

	WHILE @@fetch_status = 0
	BEGIN
		if @debug=1
			PRINT CONCAT('@build_id=',@build_id,', @service_id=', @service_id,', @mode_id=',@mode_id,', @source_id=',@source_id,', @roomtype_id=', @roomtype_id)

		IF (@mode_id % 1000 = 0)
			AND (@source_id % 1000 = 0)

			EXEC dbo.adm_del_serv_build @build_id = @build_id
									  , @service_id = @service_id
									  , @mode_id = @mode_id
									  , @source_id = @source_id
									  , @roomtype_id = @roomtype_id

		FETCH NEXT FROM cur INTO @build_id, @service_id, @mode_id, @source_id, @roomtype_id

	END

	CLOSE cur
	DEALLOCATE cur
go

