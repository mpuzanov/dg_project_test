CREATE   PROCEDURE [dbo].[adm_del_all_modes]
(
	@build_id1 INT
)
AS
	/*
	
	  Удаляем все режимы и поставщиков в доме и на лицевых счетах
	  ставим "НЕТ"
	
	Пузанов
	
	*/
	SET NOCOUNT ON

	BEGIN TRAN

		DELETE FROM dbo.BUILD_MODE
		WHERE build_id = @build_id1
			AND (mode_id % 1000) <> 0;

		UPDATE c
		SET mode_id = (s.service_no * 1000)
		FROM dbo.Consmodes_list AS c
			JOIN dbo.Occupations AS o 
				ON c.occ = o.occ
			JOIN dbo.Flats AS f
				ON f.id = o.flat_id
			JOIN dbo.Services AS s
				ON c.service_id = s.id
		WHERE 1=1
			AND (c.mode_id % 1000) <> 0
			AND f.bldn_id = @build_id1
			AND o.status_id <> 'закр';			

		DELETE FROM dbo.BUILD_SOURCE
		WHERE build_id = @build_id1
			AND (source_id % 1000) <> 0;

		UPDATE c
		SET source_id = (s.service_no * 1000)
		FROM dbo.Consmodes_list AS c
			JOIN dbo.Occupations AS o 
				ON c.occ = o.occ
			JOIN dbo.Flats AS f 
				ON f.id = o.flat_id
			JOIN dbo.Services AS s 
				ON c.service_id = s.id
		WHERE 1=1
			AND (c.source_id % 1000) <> 0
			AND f.bldn_id = @build_id1
			AND o.status_id <> 'закр';

		COMMIT TRAN
go

