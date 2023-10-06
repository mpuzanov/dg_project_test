CREATE   PROCEDURE [dbo].[adm_del_serv_build]
(
	  @build_id INT
	, @service_id VARCHAR(10)
	, @mode_id INT
	, @source_id INT
	, @roomtype_id VARCHAR(10) = NULL
	, @debug BIT = 0
)
AS
	/*

	exec adm_del_serv_build @build_id=1031, @service_id='вотд',@mode_id=55000,@source_id=55000,@roomtype_id=NULL

	Удаление услуги без режимов

	Пузанов М.А.
	
	*/
	SET NOCOUNT ON

	IF ((@mode_id % 1000) != 0)
		OR ((@source_id % 1000) != 0)
	BEGIN
		RAISERROR ('Удалять можно только услуги с режимом и поставщиком "Нет"', 16, 1);
		RETURN 1
	END

	DECLARE @LogTableDel TABLE (
		  occ INT NOT NULL
		, service_id VARCHAR(10) NOT NULL
		, mode_id INT NOT NULL
		, source_id INT NOT NULL
		, roomtype_id VARCHAR(10)
	)

	BEGIN TRAN

		DELETE cl
		OUTPUT DELETED.occ, DELETED.service_id, DELETED.mode_id, DELETED.source_id, o.roomtype_id
		INTO @LogTableDel
		FROM dbo.Flats AS f
			JOIN dbo.Occupations AS o ON 
				f.id = o.flat_id
			JOIN dbo.Consmodes_list AS cl ON 
				o.occ = cl.occ
		WHERE 
			f.bldn_id = @build_id
			AND cl.service_id = @service_id
			AND cl.mode_id = @mode_id
			AND cl.source_id = @source_id
			AND (o.roomtype_id = @roomtype_id OR @roomtype_id IS NULL)
			AND NOT EXISTS (
				SELECT *
				FROM Paym_list pl
				WHERE pl.occ = o.occ
					AND pl.service_id = @service_id
					AND (pl.saldo <> 0 OR pl.paid <> 0 OR pl.debt <> 0)
			)
		DELETE bm
		FROM dbo.Build_mode AS bm
			JOIN @LogTableDel AS t ON 
				bm.service_id = t.service_id
				AND bm.mode_id = t.mode_id
		WHERE build_id = @build_id
			AND NOT EXISTS (
				SELECT 1
				FROM dbo.Flats AS f
					JOIN dbo.Occupations AS o ON 
						f.id = o.flat_id
					JOIN dbo.Consmodes_list AS cl ON 
						o.occ = cl.occ
				WHERE f.bldn_id = @build_id
					AND cl.service_id = t.service_id
					AND cl.mode_id = t.mode_id
					AND cl.source_id = t.source_id
					AND (o.roomtype_id = t.roomtype_id OR t.roomtype_id IS NULL)
			)
		DELETE bs
		FROM dbo.Build_source AS bs
			JOIN @LogTableDel AS t ON 
				bs.service_id = t.service_id
				AND bs.source_id = t.source_id
		WHERE build_id = @build_id
			AND NOT EXISTS (
				SELECT 1
				FROM dbo.Flats AS f
					JOIN dbo.Occupations AS o ON 
						f.id = o.flat_id
					JOIN dbo.Consmodes_list AS cl ON 
						o.occ = cl.occ
				WHERE f.bldn_id = @build_id
					AND cl.service_id = t.service_id
					AND cl.mode_id = t.mode_id
					AND cl.source_id = t.source_id
					AND (o.roomtype_id = t.roomtype_id OR t.roomtype_id IS NULL)
			)
	COMMIT TRAN

	if @debug=1
		SELECT * FROM @LogTableDel;
go

